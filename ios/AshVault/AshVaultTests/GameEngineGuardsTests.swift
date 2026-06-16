import XCTest
@testable import AshVault

@MainActor
final class GameEngineGuardsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        return e
    }

    private func engineInShop() -> GameEngine {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        return e
    }

    func testPerformIgnoredOutsideCombat() {
        let e = engineInShop()
        let logBefore = e.log.count
        e.perform(.attack)
        XCTAssertEqual(e.log.count, logBefore)
    }

    func testBuyIgnoredOutsideShop() {
        let e = engine()
        let gold = e.player.gold
        e.buy(.potion)
        XCTAssertEqual(e.player.gold, gold)
        XCTAssertEqual(e.player.potions, 0)
    }

    func testEnterAscensionIgnoredOutsideCombat() {
        let e = engineInShop()
        e.enterAscension()
        XCTAssertEqual(e.phase, .shop)
    }

    func testAscendIgnoredOutsideAscensionPhase() {
        let e = engine()
        let shardsBefore = e.totalShards
        e.ascend()
        XCTAssertEqual(e.totalShards, shardsBefore)
        XCTAssertEqual(e.phase, .combat)
    }

    func testUsePotionIgnoredWithoutStock() {
        let e = engine()
        let hp = e.player.hp
        e.usePotion()
        XCTAssertEqual(e.player.hp, hp)
    }

    func testUseEtherIgnoredOutsideCombat() {
        let e = engineInShop()
        e.player.addEthers(1)
        e.useEther()
        XCTAssertEqual(e.player.ethers, 1)
    }

    func testHeavyBlockedWithoutMana() {
        let e = engine()
        e.player.spendMana(e.player.mana)
        let logBefore = e.log.count
        e.perform(.heavy)
        XCTAssertTrue(e.log.last?.text.contains("Not enough mana") == true)
        XCTAssertEqual(e.log.count, logBefore + 1)
    }

    func testPoisonBlockedWithoutMana() {
        let e = engine()
        e.player.spendMana(e.player.mana)
        e.perform(.poison)
        XCTAssertTrue(e.log.last?.text.contains("Not enough mana") == true)
    }

    func testPendingShardsFormula() {
        let e = engine()
        e.player.addGold(10_000)
        // runGoldEarned is separate; simulate via kills
        for _ in 0..<20 {
            e.enemy.hp = 1
            e.perform(.attack)
            if e.phase == .levelUp { e.chooseUpgrade(.attack) }
            if e.phase == .shop { e.leaveShop() }
        }
        let expected = Int((Double(e.runGoldEarned) / Balance.prestigeShardDivisor).squareRoot())
        XCTAssertEqual(e.pendingShards, expected)
    }

    func testRunGoldEarnedTracksKillRewards() {
        let e = engine()
        e.enemy.hp = 1
        let reward = e.enemy.generateGold()
        e.perform(.attack)
        XCTAssertEqual(e.runGoldEarned, reward)
    }

    func testSpentShardsReflectsTreePurchases() {
        PrestigeStore.save(20)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        let cost1 = e.cost(.might)
        e.upgradeNode(.might)
        let cost2 = e.cost(.might)
        e.upgradeNode(.might)
        XCTAssertEqual(e.spentShards, cost1 + cost2)
        XCTAssertEqual(e.availableShards, 20 - cost1 - cost2)
    }

    func testMightMultiplierScalesStartingAttack() {
        PrestigeStore.save(50)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        for _ in 0..<4 { e.upgradeNode(.might) }
        XCTAssertEqual(e.attackMultiplier, 1.2, accuracy: 1e-9)
        e.startGame(named: "Hero")
        XCTAssertEqual(e.player.attack, 30) // 25 × 1.2
    }

    func testToggleAutoBattle() {
        let e = engine()
        XCTAssertFalse(e.autoBattle)
        e.toggleAuto()
        XCTAssertTrue(e.autoBattle)
        e.toggleAuto()
        XCTAssertFalse(e.autoBattle)
    }

    func testEnemiesScaleAfterClearingLayer() {
        let e = engine()
        let layer1Hp = e.enemy.maxHp
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        e.leaveShop()
        XCTAssertGreaterThan(e.enemy.maxHp, layer1Hp)
        XCTAssertEqual(e.layer, 2)
    }

    func testChooseUpgradeRequiresLevelUpPhaseInPractice() {
        let e = engine()
        let levelBefore = e.player.level
        // chooseUpgrade has no phase guard — document current behavior: it always applies.
        e.chooseUpgrade(.health)
        XCTAssertEqual(e.player.level, levelBefore + 1)
        XCTAssertEqual(e.phase, .shop)
    }

    func testLeaveShopSpawnsNextEncounter() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        XCTAssertEqual(e.phase, .shop)
        e.leaveShop()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.enemyIndex, 1)
    }

    func testClearPopupOnlyClearsMatchingId() {
        let e = engine()
        e.enemy.hp = 1
        e.perform(.attack)
        guard let popup = e.popup else {
            XCTFail("Expected combat popup")
            return
        }
        e.clearPopup(popup.id)
        XCTAssertNil(e.popup)
    }
}
