import XCTest
@testable import AshVault

final class GameAnalyticsTests: XCTestCase {
    func testSanitizedParametersAllowlist() {
        let result = GameAnalytics.sanitizedParameters(from: [
            "reason": "defeat",
            "layer": "3",
            "player_name": "secret",
            "level": "7",
        ])

        XCTAssertEqual(result["reason"], "defeat")
        XCTAssertEqual(result["layer"], "3")
        XCTAssertEqual(result["level"], "7")
        XCTAssertNil(result["player_name"])
    }

    func testSanitizedParametersTruncateLongValues() {
        let long = String(repeating: "x", count: 120)
        let result = GameAnalytics.sanitizedParameters(from: ["reason": long])
        XCTAssertEqual(result["reason"]?.count, 100)
    }

    func testEventNamesAreStable() {
        XCTAssertEqual(GameAnalyticsEvent.appOpen.name, "app_open")
        XCTAssertEqual(GameAnalyticsEvent.runStarted.name, "run_started")
        XCTAssertEqual(GameAnalyticsEvent.runEnded(reason: "defeat", layer: 1, level: 2).name, "run_ended")
        XCTAssertEqual(GameAnalyticsEvent.prestigeCompleted(shards: 3, totalShards: 10).parameters["total_shards"], "10")
        XCTAssertEqual(
            GameAnalyticsEvent.achievementUnlocked(id: "firstBlood", category: "crawl").name,
            "achievement_unlocked"
        )
        let achievementParams = GameAnalytics.sanitizedParameters(from: [
            "id": "dragonSlain",
            "category": "crawl",
            "secret": "nope",
        ])
        XCTAssertEqual(achievementParams["id"], "dragonSlain")
        XCTAssertEqual(achievementParams["category"], "crawl")
        XCTAssertNil(achievementParams["secret"])
    }
}
