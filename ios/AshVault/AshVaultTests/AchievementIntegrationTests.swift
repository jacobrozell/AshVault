import XCTest
@testable import AshVault

@MainActor
final class AchievementIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testAchievementStateCodableRoundTrip() throws {
        var state = AchievementState.empty
        state.unlock(.firstBlood, reward: .none, date: Date(timeIntervalSince1970: 100))
        state.unlock(.dragonSlain, reward: .accountGoldPercent(1), date: Date(timeIntervalSince1970: 200))
        state.lastSeenUnlockedCount = 1

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(AchievementState.self, from: data)

        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.bonusGoldPercent, 1)
    }

    func testAchievementStateMigrationDefaultsMissingKeys() throws {
        let json = """
        {"unlocked":["firstBlood"],"unlockedAt":{},"bonusGoldPercent":0,"bonusStartingHpPercent":0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AchievementState.self, from: json)
        XCTAssertEqual(decoded.lastSeenUnlockedCount, 0)
        XCTAssertFalse(decoded.backfillSummaryDismissed)
    }

    func testMarkViewedClearsUnread() {
        var state = AchievementState.empty
        state.unlock(.firstBlood, reward: .none)
        state.unlock(.firstFall, reward: .none)
        XCTAssertTrue(state.hasUnread)
        state.markViewed()
        XCTAssertFalse(state.hasUnread)
    }

    func testEnemyKillUnlocksFirstBlood() {
        let e = GameEngine(playerName: "A", rng: combatRNG([], fallback: 9))
        e.startGame(named: "A", automaticOath: .hound)
        var safety = 0
        while e.phase == .combat && !e.achievementState.contains(.firstBlood) && safety < 60 {
            if e.player.mana >= SpellCatalog.definition(for: .emberBolt).manaCost {
                e.performSigil(.emberBolt)
            } else {
                e.perform(.attack)
            }
            safety += 1
        }
        XCTAssertTrue(e.achievementState.contains(.firstBlood))
        XCTAssertEqual(e.pendingAchievementUnlock, .firstBlood)
    }

    func testAscensionUnlocksFirstWithdrawal() {
        let e = GameEngine(playerName: "A", rng: combatRNG([], fallback: 9))
        e.startGame(named: "A", automaticOath: .hound)
        e.enterAscension()
        e.ascend()
        XCTAssertTrue(e.achievementState.contains(.firstWithdrawal))
        XCTAssertTrue(e.achievementState.unlocked.contains(AchievementID.firstWithdrawal.rawValue))
    }

    func testDismissBackfillSummaryPersists() {
        MetaStore.saveAchievements({
            var s = AchievementState.empty
            s.unlock(.firstBlood, reward: .none)
            return s
        }())
        let e = GameEngine(playerName: "A")
        XCTAssertNotNil(e.achievementBackfillCount)
        e.dismissAchievementBackfillSummary()
        XCTAssertNil(e.achievementBackfillCount)
        XCTAssertTrue(e.achievementState.backfillSummaryDismissed)
        let reloaded = MetaStore.loadAchievements()
        XCTAssertTrue(reloaded.backfillSummaryDismissed)
    }

    func testCritUnlocksSecretTrophy() {
        let e = GameEngine(playerName: "A", rng: SeededRandom(seed: 42))
        e.startGame(named: "A", automaticOath: .hound)
        // Force crit path: luck 3 → high crit chance; attack until crit lands.
        var safety = 0
        while !e.achievementState.contains(.firstCrit) && safety < 80 {
            e.perform(.attack)
            safety += 1
        }
        XCTAssertTrue(e.achievementState.contains(.firstCrit))
    }
}
