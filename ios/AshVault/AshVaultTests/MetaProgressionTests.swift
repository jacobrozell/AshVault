import XCTest
@testable import AshVault

@MainActor
final class MetaProgressionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testMercenaryCostScalesGeometrically() {
        let first = Mercenary.goblinSlayer.cost(owned: 0)
        let second = Mercenary.goblinSlayer.cost(owned: 1)
        XCTAssertGreaterThan(second, first)
    }

    func testMercenaryMilestoneDoublesDPS() {
        let beforeMilestone = Mercenary.archer.dps(count: 24)
        let atMilestone = Mercenary.archer.dps(count: 25)
        XCTAssertGreaterThan(atMilestone, beforeMilestone)
        XCTAssertGreaterThan(atMilestone, beforeMilestone * 15 / 10) // ~×1.5+ jump
    }

    func testHireMercenaryPersistsAndAddsDPS() {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        e.player.addGold(10_000)
        advanceToShop(e)
        XCTAssertEqual(e.phase, .shop)

        let dpsBefore = e.mercenaryDPS
        e.hireMercenary(.goblinSlayer)
        XCTAssertGreaterThan(e.mercenaryDPS, dpsBefore)
        XCTAssertEqual(MetaStore.loadMercenaryCounts()["goblinSlayer"], 1)
    }

    func testRelicDuplicateGrantsGold() {
        MetaStore.saveDiscoveredRelics(Set(Relic.allCases.map(\.rawValue)))
        let e = GameEngine(playerName: "Hero", rng: alwaysHitRNG())
        e.startGame(named: "Hero")
        while e.phase == .combat, e.enemyIndex < 5 {
            e.enemy.hp = 1
            e.perform(.attack)
        }
        let goldBefore = e.player.gold
        e.enemy.hp = 1
        e.perform(.attack) // boss kill → duplicate relic gold (pool empty)
        XCTAssertGreaterThan(e.player.gold, goldBefore)
    }

    func testOfflineWorksWithoutAutoBattle() {
        let lastSeen = Date().addingTimeInterval(-7200)
        let save = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 25, maxAttack: 25,
            defense: 10, maxDefense: 10, luck: 3, level: 1, gold: 0,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 1, enemyIndex: 1, scaleLevel: 0,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: false,
            runGoldEarned: 0, lastSeen: lastSeen
        )
        SaveStore.write(save)
        MetaStore.saveMercenaryCounts(["goblinSlayer": 10])

        let e = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertGreaterThan(e.player.gold, 0)
        XCTAssertNotNil(e.offlineReport)
        XCTAssertFalse(e.offlineReport!.wasAutoBattle)
    }

    /// Regression: a 2h absence on a mid run must not fund a Knight outright.
    func testOfflineGoldStaysBelowKnightSpamThreshold() {
        let lastSeen = Date().addingTimeInterval(-7200)
        let save = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 35, maxAttack: 35,
            defense: 10, maxDefense: 10, luck: 3, level: 3, gold: 0,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 2, enemyIndex: 2, scaleLevel: 1,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: true,
            runGoldEarned: 0, lastSeen: lastSeen
        )
        SaveStore.write(save)
        MetaStore.saveMercenaryCounts(["goblinSlayer": 10, "archer": 5])

        let e = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertLessThan(e.player.gold, Mercenary.knight.baseCost)
    }

    func testOfflineTimeCapLimitsEarnings() {
        let capSeconds = Balance.baseOfflineHours * 3600
        let baseSave = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 30, maxAttack: 30,
            defense: 10, maxDefense: 10, luck: 3, level: 2, gold: 0,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 2, enemyIndex: 1, scaleLevel: 1,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: true,
            runGoldEarned: 0, lastSeen: Date()
        )

        var overCap = baseSave
        overCap.lastSeen = Date().addingTimeInterval(-capSeconds - 7200)
        SaveStore.write(overCap)
        let over = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        let goldOverCap = over.player.gold

        clearPersistence()
        var atCap = baseSave
        atCap.lastSeen = Date().addingTimeInterval(-capSeconds)
        SaveStore.write(atCap)
        let capped = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))

        XCTAssertEqual(goldOverCap, capped.player.gold)
        XCTAssertTrue(over.offlineReport!.hitCap)
        XCTAssertEqual(over.offlineReport!.creditedDuration, capSeconds, accuracy: 1)
    }

    func testAutoDescendTriggersOnThreshold() {
        PrestigeStore.save(5)
        AutoDescendSettings.setEnabled(true)
        AutoDescendSettings.setMinShards(4)
        defer { AutoDescendSettings.setEnabled(false) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        e.autoBattle = true
        while e.pendingShards < 4 {
            if e.phase == .combat {
                e.enemy.hp = 1
                e.perform(.attack)
            } else {
                advanceCombat(e)
            }
        }
        XCTAssertGreaterThanOrEqual(e.pendingShards, 4)
        while e.phase != .combat { advanceCombat(e) }
        let shardsBefore = e.totalShards
        e.tick()
        XCTAssertGreaterThan(e.totalShards, shardsBefore)
    }

    func testRelicEquipToggle() {
        MetaStore.saveDiscoveredRelics([Relic.luckyCharm.rawValue])
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertFalse(e.isRelicEquipped(.luckyCharm))
        e.toggleEquipRelic(.luckyCharm)
        XCTAssertTrue(e.isRelicEquipped(.luckyCharm))
        e.toggleEquipRelic(.luckyCharm)
        XCTAssertFalse(e.isRelicEquipped(.luckyCharm))
    }

    // MARK: - Helpers

    private func advanceCombat(_ e: GameEngine) {
        switch e.phase {
        case .combat:  e.enemy.hp = 1; e.perform(.attack)
        case .levelUp: e.chooseUpgrade(.attack)
        case .shop:    e.leaveShop()
        case .victory: e.continueEndless()
        default:       break
        }
    }

    private func advanceToShop(_ e: GameEngine) {
        while e.phase != .shop {
            advanceCombat(e)
        }
    }
}
