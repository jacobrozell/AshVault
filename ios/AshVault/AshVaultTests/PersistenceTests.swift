import XCTest
@testable import AshVault

@MainActor
final class PersistenceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero", automaticOath: .hound)
        return e
    }

    func testBestRunSaveAndLoadRoundTrip() {
        let run = BestRun(layer: 4, level: 6, gold: 1200)
        run.save()
        let loaded = BestRun.load()
        XCTAssertEqual(loaded.layer, 4)
        XCTAssertEqual(loaded.level, 6)
        XCTAssertEqual(loaded.gold, 1200)
        XCTAssertTrue(loaded.hasRecord)
    }

    func testSaveRestoresRingChoicePhase() {
        let a = engine()
        killBossRing(a)
        XCTAssertEqual(a.phase, .ringChoice)
        a.save()

        let b = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(b.phase, .ringChoice)
        XCTAssertEqual(b.layer, 1)
        XCTAssertTrue(b.awaitingRingAdvance)
    }

    func testSaveRestoresShopPhase() {
        let a = engine()
        killBossRing(a)
        a.enterCamp()
        a.player.addGold(500)
        a.buy(.potion)
        a.save()

        let b = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(b.phase, .shop)
        XCTAssertEqual(b.player.potions, 1)
    }

    func testSaveClearsOnDefeat() {
        let e = engine()
        e.player.hp = 1
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertEqual(e.phase, .defeat)
        XCTAssertNil(SaveStore.read())
    }

    func testOfflineReducedWhenAutoBattleOff() {
        let save = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 25, maxAttack: 25,
            defense: 10, maxDefense: 10, luck: 3, level: 1, gold: 100,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 1, enemyIndex: 1, scaleLevel: 0,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: false,
            runGoldEarned: 0, lastSeen: Date().addingTimeInterval(-7200)
        )
        SaveStore.write(save)

        let e = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertGreaterThan(e.player.gold, 100)
        XCTAssertNotNil(e.offlineReport)
        XCTAssertFalse(e.offlineReport!.wasAutoBattle)
    }

    func testOfflineSkippedForBriefAbsence() {
        let save = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 25, maxAttack: 25,
            defense: 10, maxDefense: 10, luck: 3, level: 1, gold: 0,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 1, enemyIndex: 1, scaleLevel: 0,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: true,
            runGoldEarned: 0, lastSeen: Date().addingTimeInterval(-30)
        )
        SaveStore.write(save)

        let e = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(e.player.gold, 0)
        XCTAssertNil(e.offlineReport)
    }

    func testRecordRunSetsNewRecordFlag() {
        let e = engine()
        XCTAssertFalse(e.setNewRecord)
        e.enemy.hp = 1
        e.perform(.attack)
        XCTAssertTrue(e.setNewRecord)
        XCTAssertTrue(e.best.gold > 0)
    }

    func testVictoryShownOnlyOnce() {
        let e = engine()
        while !(e.layer == Balance.vaultHeartLayer
                && e.enemyIndex == Balance.enemiesPerLayer && e.phase == .combat) {
            resolveNonCombatPhases(e)
            if e.phase == .shop { e.leaveShop() }
            if e.phase == .victory { e.continueEndless() }
            if e.phase == .combat { e.enemy.hp = 1; e.perform(.attack) }
        }
        e.enemy.hp = 1
        e.perform(.attack)
        resolveNonCombatPhases(e)
        if e.phase == .shop { e.leaveShop() }
        XCTAssertEqual(e.phase, .victory)

        e.continueEndless()
        killBossRing(e)
        campAndAdvance(e)
        XCTAssertEqual(e.phase, .combat)
    }

    func testRestorePreservesPurchaseCounts() {
        let a = engine()
        killBossRing(a)
        a.enterCamp()
        a.player.addGold(1000)
        a.buy(.whetstone)
        a.save()

        let b = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(b.price(.whetstone),
                       Int((Double(ShopItem.whetstone.basePrice) * Balance.shopPriceGrowth).rounded()))
    }

    func testAbandonRunClearsSaveAndReturnsToTitle() {
        let e = engine()
        e.save()
        XCTAssertNotNil(SaveStore.read())
        e.abandonRun()
        XCTAssertEqual(e.phase, .title)
        XCTAssertNil(SaveStore.read())
        XCTAssertFalse(e.autoBattle)
    }

    func testStartGameResetsRunState() {
        let e = engine()
        e.autoBattle = true
        for _ in 1...Balance.enemiesPerLayer { e.enemy.hp = 1; e.perform(.attack); resolveNonCombatPhases(e) }
        e.startGame(named: "Hero", automaticOath: .hound)
        XCTAssertEqual(e.layer, 1)
        XCTAssertEqual(e.enemyIndex, 1)
        XCTAssertFalse(e.autoBattle)
        XCTAssertEqual(e.runGoldEarned, 0)
        XCTAssertFalse(e.clearedFinalBoss)
    }
}
