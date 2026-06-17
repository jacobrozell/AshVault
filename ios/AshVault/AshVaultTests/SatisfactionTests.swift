import XCTest
@testable import AshVault

/// Long-horizon satisfaction proxies — verifies the idle RPG loop delivers
/// permanent growth, session hooks, and meta power curves.
///
/// Run alone: `xcodebuild test -only-testing:AshVaultTests/SatisfactionTests`
@MainActor
final class SatisfactionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    // MARK: - Session 1 hook (progressive-unlock-spec §14)

    func testLayer1CompletesWithinEngagementBudget() {
        guard let seed = (UInt64(1)...UInt64(32)).first(where: {
            PlaytestHarness.runLayer1(seed: $0) != nil
        }) else {
            XCTFail("No seed completed ring 1 within tick budget")
            return
        }
        guard let result = PlaytestHarness.runLayer1(seed: seed) else {
            XCTFail("Layer 1 did not complete (seed \(seed))")
            return
        }
        XCTAssertEqual(result.kills, SatisfactionBenchmarks.layer1KillCount,
                       "Ring 1 should clear all guardians")
        XCTAssertLessThan(result.ticks, SatisfactionBenchmarks.maxLayer1Ticks,
                          "Layer 1 should finish within ~2 min on auto-battle")
        XCTAssertGreaterThan(result.gold, 0, "Layer 1 should award gold")
    }

    // MARK: - North star: permanent numbers go up

    func testPrestigeLoopBanksPermanentShards() throws {
        guard let seed = PlaytestHarness.firstFreshClearingSeed(in: 1...64) else {
            throw XCTSkip("No seed cleared campaign from fresh save yet — tune survivor pacing")
        }
        guard let outcome = PlaytestHarness.runPrestigeLoops(seed: seed, loops: 1) else {
            XCTFail("Prestige loop failed before first descent (seed \(seed))")
            return
        }

        let history = outcome.shardHistory
        XCTAssertEqual(history.count, 2, "Should record start and post-descent shard totals")
        XCTAssertGreaterThan(history[1], history[0],
                             "Shard total should rise after first descent")
        XCTAssertGreaterThan(outcome.treeMight, 0, "Should spend shards on permanent Might")
        XCTAssertEqual(outcome.descents, 1)
    }

    func testEachPrestigeLoopYieldsMeaningfulShards() throws {
        guard let seed = PlaytestHarness.firstClearingSeed(in: 1...64) else {
            throw XCTSkip("No seed cleared 10-ring campaign yet — tune survivor pacing")
        }
        guard let result = PlaytestHarness.runCampaign(seed: seed) else {
            XCTFail("Campaign did not clear (seed \(seed))")
            return
        }
        XCTAssertGreaterThanOrEqual(result.pendingShards,
                                    SatisfactionBenchmarks.minFirstCampaignShards)
        XCTAssertGreaterThan(result.runGold, SatisfactionBenchmarks.minFirstCampaignGold)
    }

    // MARK: - Meta investment pays off

    func testMightInvestmentSpeedsCampaign() throws {
        guard let seed = (UInt64(1)...UInt64(32)).first(where: { s in
            PlaytestHarness.runCampaign(seed: s, maxTicks: 300_000, spendMightLevels: 0) != nil
                && PlaytestHarness.runCampaign(seed: s, maxTicks: 300_000, spendMightLevels: 8) != nil
        }) else {
            throw XCTSkip("No seed cleared campaign for might comparison yet")
        }
        guard let baseline = PlaytestHarness.runCampaign(seed: seed, maxTicks: 300_000, spendMightLevels: 0),
              let invested = PlaytestHarness.runCampaign(seed: seed, maxTicks: 300_000, spendMightLevels: 8) else {
            XCTFail("Campaign did not clear for speed comparison (seed \(seed))")
            return
        }

        let speedup = 1.0 - Double(invested.ticks) / Double(baseline.ticks)
        print("=== Might speedup seed \(seed): \(Int(speedup * 100))% (\(baseline.ticks) → \(invested.ticks) ticks) ===")
        XCTAssertGreaterThan(speedup, SatisfactionBenchmarks.minCampaignSpeedupFromMight,
                             "8 Might levels should measurably shorten campaign")
    }

    func testWardInvestmentDeepensEndlessRun() throws {
        guard let seed = PlaytestHarness.firstClearingSeed(in: 1...64) else {
            throw XCTSkip("No clearing seed for endless comparison yet")
        }
        guard let baseline = PlaytestHarness.runEndlessUntilDeath(seed: seed, wardLevels: 0),
              let warded = PlaytestHarness.runEndlessUntilDeath(seed: seed, wardLevels: 12) else {
            XCTFail("Endless run did not reach defeat (seed \(seed))")
            return
        }

        print("=== Ward depth seed \(seed): L\(baseline.layer) → L\(warded.layer) ===")
        XCTAssertGreaterThanOrEqual(
            warded.layer - baseline.layer,
            SatisfactionBenchmarks.minEndlessDepthGainFromWard,
            "Ward should push endless depth deeper before death"
        )
    }

    // MARK: - Reward density (two numbers going up per session)

    func testCampaignProducesMultipleRewardRails() throws {
        guard let seed = PlaytestHarness.firstClearingSeed(in: 1...64) else {
            throw XCTSkip("No clearing seed for reward-rail check yet")
        }
        guard let result = PlaytestHarness.runCampaign(seed: seed) else {
            XCTFail("Campaign did not clear (seed \(seed))")
            return
        }

        // Run-scoped rewards
        XCTAssertGreaterThan(result.runGold, 0)
        XCTAssertGreaterThan(result.pendingShards, 0)
        // Layer progression (at least layers 1–5 visited)
        XCTAssertGreaterThanOrEqual(result.layerTicks.count, 8,
                                      "Campaign should traverse most rings before Vault Heart")
        for layer in 1...min(8, Balance.vaultHeartLayer) {
            XCTAssertGreaterThan(result.layerTicks[layer, default: 0], 0,
                                 "Layer \(layer) should take measurable time")
        }
    }

    func testFreshRunStartsStrongerAfterMetaSpend() {
        clearPersistence()
        PrestigeStore.save(50)
        PrestigeStore.saveTree([SkillNode.might.rawValue: 5, SkillNode.vitality.rawValue: 3])
        let invested = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: 1))
        invested.startGame(named: "Playtest")

        clearPersistence()
        PrestigeStore.save(0)
        PrestigeStore.saveTree([:])
        let baseline = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: 1))
        baseline.startGame(named: "Playtest")

        XCTAssertGreaterThan(invested.player.attack, baseline.player.attack)
        XCTAssertGreaterThan(invested.player.maxHp, baseline.player.maxHp)
    }
}
