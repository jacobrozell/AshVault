import XCTest
@testable import AshVault

@MainActor
final class CombatMovesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine(rng: ScriptedRandom = ScriptedRandom(fallback: 9)) -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: rng)
        e.startGame(named: "Hero")
        return e
    }

    private func reachBoss(_ e: GameEngine) {
        while e.enemyIndex < 5 {
            e.enemy.hp = 1
            e.perform(.attack)
        }
        XCTAssertTrue(e.enemy.isBoss)
    }

    func testDodgeSuccessRestoresHpAndMana() {
        let e = engine(rng: combatRNG([], fallback: 0))
        e.player.takeHit(40)
        XCTAssertEqual(e.player.hp, 20)
        let manaBefore = e.player.mana
        e.perform(.dodge)
        XCTAssertTrue(
            e.log.contains { $0.text.contains("Dodged!") },
            e.log.map(\.text).joined(separator: "\n")
        )
        XCTAssertEqual(e.player.hp, 25)
        XCTAssertEqual(e.player.mana, min(e.player.maxMana, manaBefore + 4))
    }

    func testDodgeFailDealsDamage() {
        let e = engine(rng: alwaysHitRNG())
        e.enemy.hp = 999
        let hpBefore = e.player.hp
        e.perform(.dodge)
        XCTAssertLessThan(e.player.hp, hpBefore)
    }

    func testHealAtFullHpIsNoOp() {
        let e = engine()
        let hp = e.player.hp
        let logBefore = e.log.count
        e.perform(.heal)
        XCTAssertEqual(e.player.hp, hp)
        XCTAssertTrue(e.log.last?.text.contains("full health") == true)
        XCTAssertEqual(e.log.count, logBefore + 1)
    }

    func testHealRestoresAndTriggersRetaliation() {
        let e = engine(rng: alwaysMissRNG())
        e.player.takeHit(30)
        let hpBefore = e.player.hp
        e.perform(.heal)
        XCTAssertGreaterThan(e.player.hp, hpBefore)
        XCTAssertTrue(e.log.contains { $0.text.contains("restore") })
    }

    func testHeavyStrikeDealsMoreDamageThanAttack() {
        let heavy = engine(rng: combatRNG([9, 99]))
        heavy.enemy.hp = 999
        heavy.perform(.heavy)
        let heavyDmg = 999 - heavy.enemy.hp

        let basic = engine(rng: combatRNG([9, 99]))
        basic.enemy.hp = 999
        basic.perform(.attack)
        let basicDmg = 999 - basic.enemy.hp

        XCTAssertGreaterThan(heavyDmg, basicDmg)
    }

    func testEmberBoltIgnoresDefense() {
        let e = engine(rng: combatRNG([99])) // no burn proc
        e.enemy.hp = 999
        e.player.restoreMana(100)
        let def = SpellCatalog.definition(for: .emberBolt)
        let expected = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: e.combatAttack,
            targetDefense: e.enemy.defense,
            targetAspect: e.enemy.aspect,
            targetTags: e.enemy.tags,
            castMultiplier: 1.0,
            useSpellBaseFormula: true
        )).finalDamage
        e.performSigil(.emberBolt)
        XCTAssertEqual(999 - e.enemy.hp, expected)
    }

    func testEmberBoltCanApplyBurn() {
        let e = engine(rng: combatRNG([0, 0])) // burn procs; retaliation misses
        e.enemy.hp = 999
        e.player.restoreMana(100)
        e.performSigil(.emberBolt)
        XCTAssertTrue(e.enemy.statuses.contains { $0.kind == .burn })
    }

    func testVenomLashAppliesPoison() {
        let e = engine(rng: combatRNG([99]))
        e.sigilLoadout.slots[1] = .venomLash
        e.enemy.hp = 999
        e.player.restoreMana(100)
        e.performSigil(.venomLash)
        XCTAssertTrue(e.enemy.statuses.contains { $0.kind == .poison })
        XCTAssertTrue(e.log.contains { $0.text.contains("Poison will deal") })
    }

    func testCritDoublesDamage() {
        let crit = engine(rng: combatRNG([9, 0]))
        crit.enemy.hp = 999
        crit.perform(.attack)
        let critDmg = 999 - crit.enemy.hp

        let normal = engine(rng: combatRNG([9, 99]))
        normal.enemy.hp = 999
        normal.perform(.attack)
        let normalDmg = 999 - normal.enemy.hp

        XCTAssertGreaterThan(critDmg, normalDmg)
        XCTAssertTrue(crit.log.contains { $0.text.contains("Critical") })
    }

    func testLethalAttackSkipsRetaliation() {
        let e = engine(rng: alwaysHitRNG())
        e.enemy.hp = 1
        let hpBefore = e.player.hp
        e.perform(.attack)
        XCTAssertEqual(e.player.hp, hpBefore)
    }

    func testPlayerStunSkipsTurn() {
        let e = engine(rng: alwaysHitRNG())
        e.enemy.hp = 999
        e.player.applyStatus(.stun, turns: 1, magnitude: 0)
        let hpBefore = e.player.hp
        e.perform(.attack)
        XCTAssertTrue(e.log.contains { $0.text.contains("stunned and skip") })
        XCTAssertLessThan(e.player.hp, hpBefore)
    }

    func testManaRegenPerTurn() {
        let e = engine(rng: combatRNG([]))
        e.enemy.hp = 999
        e.player.spendMana(5)
        let manaBefore = e.player.mana
        e.perform(.attack)
        XCTAssertEqual(e.player.mana, min(e.player.maxMana, manaBefore + Balance.manaRegenPerTurn))
    }

    func testWardReducesIncomingDamage() {
        PrestigeStore.save(500)
        PrestigeStore.saveTree([:])
        defer { clearPersistence() }

        let warded = GameEngine(playerName: "Hero", rng: combatRNG([9, 99, 9], fallback: 9))
        for _ in 0..<5 { warded.upgradeNode(.ward) }
        warded.startGame(named: "Hero")
        warded.enemy.hp = 999
        let hpBefore = warded.player.hp
        warded.perform(.attack)
        let wardedLoss = hpBefore - warded.player.hp

        clearPersistence()
        let vanilla = engine(rng: combatRNG([9, 99, 9], fallback: 9))
        vanilla.enemy.hp = 999
        let vanillaHp = vanilla.player.hp
        vanilla.perform(.attack)
        let vanillaLoss = vanillaHp - vanilla.player.hp

        XCTAssertGreaterThan(vanillaLoss, 0)
        XCTAssertGreaterThan(vanillaLoss, wardedLoss)
    }

    func testBossPoisonOnHit() {
        let e = engine(rng: ScriptedRandom(fallback: 9))
        reachBoss(e)
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertTrue(e.player.statuses.contains { $0.kind == .poison })
    }

    func testBurnTickKillsEnemyViaEndRound() {
        let e = engine(rng: alwaysMissRNG())
        let idxBefore = e.enemyIndex
        e.enemy.hp = 3
        e.enemy.applyStatus(.burn, turns: 2, magnitude: 3)
        e.perform(.dodge)
        XCTAssertEqual(e.enemyIndex, idxBefore + 1)
    }

    func testAutoMoveHealsWhenHurt() {
        let e = engine(rng: alwaysHitRNG())
        e.autoBattle = true
        e.enemy.hp = 999
        e.player.hp = 20
        e.tick()
        XCTAssertTrue(e.log.contains { $0.text.contains("restore") })
    }
}
