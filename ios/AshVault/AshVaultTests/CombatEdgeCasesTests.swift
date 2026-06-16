import XCTest
@testable import AshVault

@MainActor
final class CombatEdgeCasesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine(rng: ScriptedRandom = ScriptedRandom(fallback: 9)) -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: rng)
        e.startGame(named: "Hero")
        return e
    }

    func testAttackMissLeavesEnemyUnharmed() {
        let e = engine(rng: alwaysMissRNG())
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertEqual(e.enemy.hp, 999)
        XCTAssertTrue(e.log.contains { $0.text.contains("You missed") })
    }

    func testEnemyRetaliationMiss() {
        let e = engine(rng: combatRNG([9, 99, 0])) // hit, no crit, enemy misses
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertTrue(e.log.contains { $0.text.contains("missed") })
    }

    func testHeavySpendsManaAndRegens() {
        let e = engine(rng: combatRNG([9, 99]))
        e.enemy.hp = 999
        let manaStart = e.player.mana
        e.perform(.heavy)
        let expected = min(e.player.maxMana, manaStart - Balance.heavyManaCost + Balance.manaRegenPerTurn)
        XCTAssertEqual(e.player.mana, expected)
    }

    func testEmberBoltSpendsMana() {
        let e = engine(rng: combatRNG([99]))
        e.enemy.hp = 999
        e.player.restoreMana(100)
        let manaStart = e.player.mana
        e.performSigil(.emberBolt)
        XCTAssertEqual(e.player.mana, manaStart - Balance.emberBoltManaCost + Balance.manaRegenPerTurn)
    }

    func testVenomLashDamagePlusPoisonTick() {
        let e = engine(rng: combatRNG([99]))
        e.sigilLoadout.slots[1] = .venomLash
        e.enemy.hp = 999
        e.player.restoreMana(100)
        let def = SpellCatalog.definition(for: .venomLash)
        let result = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: e.combatAttack,
            targetDefense: e.enemy.defense,
            targetAspect: e.enemy.aspect,
            targetTags: e.enemy.tags,
            castMultiplier: 1.0,
            useSpellBaseFormula: true
        ))
        let dot = max(1, e.player.level)
        e.performSigil(.venomLash)
        XCTAssertEqual(999 - e.enemy.hp, result.finalDamage + dot)
    }

    func testUsePotionInCombatHealsFifteenTimesLevel() {
        let e = engine(rng: alwaysMissRNG())
        e.player.addPotions(1)
        e.player.takeHit(40)
        let hpBefore = e.player.hp
        e.usePotion()
        XCTAssertEqual(e.player.hp, hpBefore + 15 * e.player.level)
        XCTAssertEqual(e.player.potions, 0)
    }

    func testUseEtherInCombatRefillsMana() {
        let e = engine(rng: alwaysMissRNG())
        e.player.addEthers(1)
        e.player.spendMana(e.player.mana)
        e.useEther()
        XCTAssertEqual(e.player.mana, e.player.maxMana)
        XCTAssertEqual(e.player.ethers, 0)
    }

    func testDeadPlayerCannotUseConsumables() {
        let e = engine()
        e.player.hp = 0
        e.player.addPotions(1)
        e.player.addEthers(1)
        e.usePotion()
        e.useEther()
        XCTAssertEqual(e.player.potions, 1)
        XCTAssertEqual(e.player.ethers, 1)
    }

    func testSpawnCounterIncrementsOnNewEnemy() {
        let e = engine()
        let counter = e.spawnCounter
        e.enemy.hp = 1
        e.perform(.attack)
        XCTAssertEqual(e.spawnCounter, counter + 1)
    }

    func testLogTruncatesAtEightyLines() {
        let e = engine(rng: alwaysMissRNG())
        e.enemy.hp = 999_999
        for _ in 0..<45 { e.perform(.attack) }
        XCTAssertLessThanOrEqual(e.log.count, 80)
    }

    func testClearPopupIgnoresStaleId() {
        let e = engine()
        e.enemy.hp = 1
        e.perform(.attack)
        guard let popup = e.popup else {
            XCTFail("Expected popup")
            return
        }
        e.clearPopup(UUID())
        XCTAssertEqual(e.popup?.id, popup.id)
        e.clearPopup(popup.id)
        XCTAssertNil(e.popup)
    }

    func testDragonSpawnsOnLayerFiveBoss() {
        let e = engine()
        while !(e.layer == 5 && e.enemyIndex == 5 && e.phase == .combat) {
            if e.phase == .levelUp { e.chooseUpgrade(.attack) }
            if e.phase == .shop { e.leaveShop() }
            if e.phase == .victory { e.continueEndless() }
            if e.phase == .combat { e.enemy.hp = 1; e.perform(.attack) }
        }
        XCTAssertEqual(e.enemy.name, Narrative.Term.ashDragon)
        XCTAssertEqual(e.enemy.maxHp, 150)
        XCTAssertEqual(e.enemy.attack, 100)
    }

    func testBuyLogsInsufficientGold() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        e.player.spendGold(e.player.gold)
        e.buy(.potion)
        XCTAssertTrue(e.log.contains { $0.text.contains("Not enough gold") })
    }

    func testCanAffordReflectsBalance() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        XCTAssertTrue(e.canAfford(.potion))
        e.player.spendGold(e.player.gold)
        XCTAssertFalse(e.canAfford(.potion))
    }

    func testSetNewRecordStaysFalseWhenNotImproved() {
        BestRun(layer: 99, level: 99, gold: 999_999).save()
        let e = engine()
        XCTAssertFalse(e.setNewRecord)
        e.enemy.hp = 1
        e.perform(.attack)
        XCTAssertFalse(e.setNewRecord)
    }

    func testStunnedPlayerPerformsNoAttackDamage() {
        let e = engine(rng: alwaysHitRNG())
        e.enemy.hp = 999
        e.player.applyStatus(.stun, turns: 1, magnitude: 0)
        e.perform(.attack)
        XCTAssertEqual(e.enemy.hp, 999)
    }
}
