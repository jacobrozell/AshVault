import XCTest
@testable import AshVault

@MainActor
final class PrestigeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero", automaticOath: .hound)
        return e
    }

    func testWardCapsAtMaxDamageReduction() {
        PrestigeStore.save(1_000_000)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        for _ in 0..<25 { e.upgradeNode(.ward) }
        XCTAssertEqual(e.damageReduction, Balance.maxDamageReduction, accuracy: 1e-9)
    }

    func testFortuneMultiplierScalesWithLevels() {
        PrestigeStore.save(200)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        for _ in 0..<3 { e.upgradeNode(.fortune) }
        XCTAssertEqual(e.goldMultiplier, 1.18, accuracy: 1e-9)
    }

    func testVitalityMultiplierScalesWithLevels() {
        PrestigeStore.save(200)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        for _ in 0..<2 { e.upgradeNode(.vitality) }
        XCTAssertEqual(e.hpMultiplier, 1.12, accuracy: 1e-9)
        e.startGame(named: "Hero", automaticOath: .hound)
        XCTAssertEqual(e.player.maxHp, 67) // 60 × 1.12 rounded
    }

    func testAscendAddsPendingShardsToTotal() {
        PrestigeStore.save(10)
        defer { clearPersistence() }
        let e = engine()
        killBossRing(e)
        e.pushDeeper()
        let pending = e.pendingShards
        XCTAssertGreaterThan(pending, 0)
        e.enterAscension()
        e.ascend()
        XCTAssertEqual(e.totalShards, 10 + pending)
    }

    func testPrestigeStoreRoundTrip() {
        PrestigeStore.save(42)
        PrestigeStore.saveTree(["might": 3, "ward": 2])
        XCTAssertEqual(PrestigeStore.load(), 42)
        XCTAssertEqual(PrestigeStore.loadTree()["might"], 3)
        XCTAssertEqual(PrestigeStore.loadTree()["ward"], 2)
    }

    func testAutomationClearsRingChoice() {
        PrestigeStore.save(Balance.automationUnlockShards)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero", automaticOath: .hound)
        e.autoBattle = true
        killBossRing(e)
        XCTAssertEqual(e.phase, .ringChoice)
        e.tick()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 2)
    }

    func testAutomationClearsDraft() {
        PrestigeStore.save(Balance.automationUnlockShards)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero", automaticOath: .hound)
        e.autoBattle = true
        while e.phase == .combat, e.runStats.killsSinceDraft < e.draftKillsNeeded {
            e.enemy.hp = 1
            e.perform(.attack)
        }
        XCTAssertEqual(e.phase, .draft)
        e.tick()
        XCTAssertEqual(e.phase, .combat)
    }

    func testMightStacksMultiplicatively() {
        PrestigeStore.save(1_000_000)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        for _ in 0..<10 { e.upgradeNode(.might) }
        XCTAssertEqual(e.level(of: .might), 10)
        XCTAssertEqual(e.attackMultiplier, 1.5, accuracy: 1e-9)
        e.startGame(named: "Hero", automaticOath: .hound)
        XCTAssertEqual(e.player.attack, 38) // 25 × 1.5 rounded
    }

    func testPatienceCapsOfflineEfficiency() {
        PrestigeStore.save(1_000_000)
        defer { clearPersistence() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        for _ in 0..<25 { e.upgradeNode(.patience) }
        XCTAssertEqual(e.offlineEfficiency, Balance.maxOfflineEfficiency, accuracy: 1e-9)
    }

    func testAscendWithZeroShardsStillWithdraws() {
        let e = engine()
        XCTAssertEqual(e.pendingShards, 0)
        e.enterAscension()
        e.ascend()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertTrue(e.log.contains { $0.text.contains(Narrative.text(for: .ascensionEmpty)) })
    }

    func testCancelAscensionIgnoredOutsideAscension() {
        let e = engine()
        e.cancelAscension()
        XCTAssertEqual(e.phase, .combat)
    }
}
