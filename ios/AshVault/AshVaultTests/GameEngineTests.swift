import XCTest
@testable import AshVault

@MainActor
final class GameEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        return e
    }

    func testStartGameEntersCombatOnFirstEnemy() {
        let e = engine()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 1)
        XCTAssertEqual(e.enemyIndex, 1)
        XCTAssertFalse(e.log.isEmpty)
    }

    func testKillAwardsGoldAndSpawnsNext() {
        let e = engine()
        let goldBefore = e.player.gold
        let reward = e.enemy.generateGold()
        e.enemy.hp = 1
        e.perform(.attack)
        XCTAssertEqual(e.player.gold, goldBefore + reward)
        XCTAssertGreaterThan(e.enemyIndex, 1)
        XCTAssertEqual(e.phase, .combat)
    }

    func testBossKillTriggersRingChoice() {
        let e = engine()
        killBossRing(e)
        XCTAssertEqual(e.phase, .ringChoice)
        XCTAssertEqual(e.layer, 1)
        XCTAssertTrue(e.awaitingRingAdvance)
    }

    func testCampOpensShopThenCombat() {
        let e = engine()
        killBossRing(e)
        campAndAdvance(e)
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 2)
        XCTAssertEqual(e.enemyIndex, 1)
    }

    func testBuyPermanentUpgradeChargesAndScales() {
        let e = engine()
        killBossRing(e)
        e.enterCamp()
        e.player.addGold(1000)
        let atkBefore = e.player.attack
        let first = e.price(.whetstone)
        e.buy(.whetstone)
        XCTAssertEqual(e.player.attack, atkBefore + 5)
        XCTAssertEqual(e.price(.whetstone),
                       Int((Double(first) * Balance.shopPriceGrowth).rounded()))
    }

    func testBuyBlockedWhenBroke() {
        let e = engine()
        killBossRing(e)
        e.enterCamp()
        e.player.spendGold(e.player.gold)
        let goldBefore = e.player.gold
        let maxHpBefore = e.player.maxHp
        e.buy(.heartVial)
        XCTAssertEqual(e.player.gold, goldBefore)
        XCTAssertEqual(e.player.maxHp, maxHpBefore)
    }

    func testPotionPurchaseAndUse() {
        let e = engine()
        killBossRing(e)
        e.enterCamp()
        e.player.addGold(1000)
        e.buy(.potion)
        XCTAssertEqual(e.player.potions, 1)
        e.leaveShop()
        e.player.hp = 1
        e.usePotion()
        XCTAssertEqual(e.player.potions, 0)
        XCTAssertGreaterThan(e.player.hp, 1)
    }

    func testPlayerDeathEndsRun() {
        let e = engine()
        e.player.hp = 1
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertEqual(e.phase, .defeat)
        XCTAssertFalse(e.player.isAlive)
    }

    func testFirstDeathShowsTwistOnce() {
        FirstDeathBeat.reset()
        defer { FirstDeathBeat.reset() }
        let e = engine()
        e.player.hp = 1
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertTrue(e.log.contains { $0.text.contains("idle game") })
        XCTAssertTrue(FirstDeathBeat.hasShown)

        let e2 = engine()
        e2.player.hp = 1
        e2.enemy.hp = 999
        e2.perform(.attack)
        XCTAssertEqual(e2.log.filter { $0.text.contains("idle game") }.count, 0)
    }

    func testHealMoveDoesNotMentionPotion() {
        let e = GameEngine(playerName: "Hero", rng: alwaysMissRNG())
        e.startGame(named: "Hero")
        e.player.takeHit(30)
        e.perform(.heal)
        XCTAssertTrue(e.log.contains { $0.text.contains("catch your breath") })
        XCTAssertFalse(e.log.contains { $0.text.contains("quaff") })
    }

    func testCampaignHitsAreCapped() {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 99))
        e.startGame(named: "Hero")
        while !(e.layer == Balance.vaultHeartLayer
                && e.enemyIndex == Balance.enemiesPerLayer && e.phase == .combat) {
            resolveNonCombatPhases(e)
            if e.phase == .victory { e.continueEndless() }
            if e.phase == .combat { e.enemy.hp = 1; e.perform(.attack) }
        }
        let uncapped = max(0, e.enemy.attack - e.player.defense)
        XCTAssertGreaterThanOrEqual(uncapped, e.player.maxHp / 2)
        let hpBefore = e.player.hp
        e.perform(.attack)
        let loss = hpBefore - e.player.hp
        let cap = max(1, e.player.maxHp * Balance.maxCampaignHitPercent / 100)
        XCTAssertLessThanOrEqual(loss, cap)
        XCTAssertGreaterThan(loss, 0)
    }

    func testAutoBattleTickFightsAutomatically() {
        let e = engine()
        e.enemy.hp = 1
        e.autoBattle = true
        e.tick()
        XCTAssertGreaterThan(e.enemyIndex, 1)
    }

    func testTickIsNoopWhenAutoOff() {
        let e = engine()
        e.enemy.hp = 1
        let idx = e.enemyIndex
        e.tick()
        XCTAssertEqual(e.enemyIndex, idx)
    }

    func testSaveAndRestoreRoundTrip() {
        SaveStore.clear()
        defer { SaveStore.clear() }
        let a = engine()
        a.enemy.hp = 1
        a.perform(.attack)
        let gold = a.player.gold
        let idx = a.enemyIndex
        a.save()

        let b = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(b.player.gold, gold)
        XCTAssertEqual(b.enemyIndex, idx)
        XCTAssertEqual(b.player.name, "Hero")
        XCTAssertEqual(b.phase, .combat)
    }

    func testAscendBanksShardsAndBoostsStartingPower() {
        SaveStore.clear()
        PrestigeStore.save(0)
        defer { SaveStore.clear(); PrestigeStore.save(0) }

        let e = engine()
        let baseAttack = e.player.attack
        killBossRing(e)
        e.pushDeeper()
        let expectedShards = e.pendingShards
        XCTAssertGreaterThan(expectedShards, 0)

        e.enterAscension()
        e.ascend()

        XCTAssertEqual(e.totalShards, expectedShards)
        XCTAssertEqual(e.availableShards, expectedShards)
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 1)
        XCTAssertEqual(e.player.attack, baseAttack)
    }

    func testSkillTreeSpendBoostsNextRun() {
        SaveStore.clear()
        PrestigeStore.save(50)
        PrestigeStore.saveTree([:])
        defer { SaveStore.clear(); PrestigeStore.save(0); PrestigeStore.saveTree([:]) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(e.availableShards, 50)
        let costFirst = e.cost(.might)
        e.upgradeNode(.might)
        XCTAssertEqual(e.level(of: .might), 1)
        XCTAssertEqual(e.availableShards, 50 - costFirst)

        e.startGame(named: "Hero")
        XCTAssertGreaterThan(e.player.attack, 25)
    }

    func testWardDamageReductionScalesWithLevels() {
        SaveStore.clear()
        PrestigeStore.save(1000)
        PrestigeStore.saveTree([:])
        defer { SaveStore.clear(); PrestigeStore.save(0); PrestigeStore.saveTree([:]) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(e.damageReduction, 0.0, accuracy: 1e-9)
        for _ in 0..<5 { e.upgradeNode(.ward) }
        XCTAssertEqual(e.level(of: .ward), 5)
        XCTAssertEqual(e.damageReduction, 0.15, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(e.damageReduction, Balance.maxDamageReduction)
    }

    func testCannotUpgradeBeyondAffordableShards() {
        SaveStore.clear()
        PrestigeStore.save(0)
        PrestigeStore.saveTree([:])
        defer { SaveStore.clear() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertFalse(e.canUpgrade(.might))
        e.upgradeNode(.might)
        XCTAssertEqual(e.level(of: .might), 0)
    }

    func testAutomationClearsRingChoiceWhenUnlocked() {
        SaveStore.clear()
        PrestigeStore.save(Balance.automationUnlockShards)
        defer { SaveStore.clear(); PrestigeStore.save(0) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        e.autoBattle = true
        killBossRing(e)
        XCTAssertEqual(e.phase, .ringChoice)
        e.tick()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 2)
    }

    func testAutomationLockedBeforeFirstPrestige() {
        SaveStore.clear()
        PrestigeStore.save(0)
        let e = engine()
        XCTAssertFalse(e.automationUnlocked)
        killBossRing(e)
        XCTAssertEqual(e.phase, .ringChoice)
        e.autoBattle = true
        e.tick()
        XCTAssertEqual(e.phase, .ringChoice)
    }

    func testSigilBlockedWithoutMana() {
        let e = engine()
        e.player.spendMana(e.player.mana)
        let countBefore = e.log.count
        e.performSigil(.emberBolt)
        XCTAssertTrue(e.log.last?.text.contains("Not enough mana") == true)
        XCTAssertEqual(e.log.count, countBefore + 1)
    }

    func testDraftTriggersAfterKillBar() {
        let e = engine()
        for _ in 0..<e.draftKillsNeeded {
            XCTAssertEqual(e.phase, .combat)
            e.enemy.hp = 1
            e.perform(.attack)
        }
        XCTAssertEqual(e.phase, .draft)
        XCTAssertEqual(e.draftOptions.count, 3)
    }
}
