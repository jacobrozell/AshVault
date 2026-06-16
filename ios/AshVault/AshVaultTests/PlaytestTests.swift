import XCTest
@testable import AshVault

/// Headless auto-battle campaign run for pacing diagnostics.
/// Run alone: `xcodebuild test -only-testing:AshVaultTests/PlaytestTests`
@MainActor
final class PlaytestTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
        PrestigeStore.save(Balance.automationUnlockShards)
    }

    func testAutoBattleCampaignPacingSeedSweep() {
        var cleared = 0
        for seed in UInt64(1)...UInt64(32) {
            clearPersistence()
            PrestigeStore.save(Balance.automationUnlockShards)
            if runCampaign(seed: seed, maxTicks: 50_000) != nil {
                cleared += 1
            }
        }
        print("=== Seed sweep: \(cleared)/32 campaigns cleared via auto-battle ===")
        XCTAssertGreaterThanOrEqual(cleared, 4, "At least ~12% of seeds should clear campaign on auto-battle")
    }

    func testAutoBattleCampaignPacing() {
        guard let seed = (UInt64(1)...UInt64(32)).first(where: {
            clearPersistence()
            PrestigeStore.save(Balance.automationUnlockShards)
            return runCampaign(seed: $0, maxTicks: 50_000) != nil
        }) else {
            XCTFail("No seed in 1...32 cleared the campaign on auto-battle")
            return
        }

        clearPersistence()
        PrestigeStore.save(Balance.automationUnlockShards)
        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        e.toggleAuto()

        var ticks = 0
        var layerTicks: [Int: Int] = [:]
        var ticksAtLayerStart = 0
        var trackedLayer = e.layer
        let maxTicks = 50_000

        while ticks < maxTicks {
            if e.phase == .victory, e.clearedFinalBoss {
                layerTicks[trackedLayer, default: 0] += ticks - ticksAtLayerStart
                print("=== Auto-battle campaign playtest (seed \(seed)) ===")
                dumpPacing(layerTicks: layerTicks, total: ticks, engine: e)
                XCTAssertGreaterThan(e.runGoldEarned, 2_000, "Campaign should earn meaningful gold")
                XCTAssertGreaterThanOrEqual(e.pendingShards, 4, "First campaign should yield several Ash Shards")
                if let layer4 = layerTicks[4] {
                    XCTAssertLessThan(layer4, 200, "Layer 4 auto-battle should stay under ~3 min")
                }
                return
            }

            if e.layer != trackedLayer {
                layerTicks[trackedLayer, default: 0] += ticks - ticksAtLayerStart
                trackedLayer = e.layer
                ticksAtLayerStart = ticks
            }

            if e.phase == .victory {
                e.continueEndless()
            } else {
                e.tick()
            }
            ticks += 1
        }

        XCTFail("Campaign did not finish within \(maxTicks) ticks (seed \(seed))")
    }

    /// Runs auto-battle until victory or defeat. Returns tick count on clear, nil on death.
    private func runCampaign(seed: UInt64, maxTicks: Int) -> Int? {
        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        e.toggleAuto()
        var ticks = 0
        while ticks < maxTicks {
            if e.phase == .defeat { return nil }
            if e.phase == .victory, e.clearedFinalBoss { return ticks }
            if e.phase == .victory { e.continueEndless() } else { e.tick() }
            ticks += 1
        }
        return nil
    }

    private func dumpPacing(layerTicks: [Int: Int], total: Int, engine: GameEngine) {
        for layer in 1...5 {
            print("  layer \(layer): \(layerTicks[layer, default: 0]) ticks (~\(layerTicks[layer, default: 0])s at 1 Hz)")
        }
        print("  total: \(total) ticks, level \(engine.player.level), run gold \(engine.runGoldEarned)")
        print("  pending Ash Shards: \(engine.pendingShards), phase: \(engine.phase)")
    }
}
