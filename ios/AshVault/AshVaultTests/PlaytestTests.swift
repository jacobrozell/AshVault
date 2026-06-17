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

    /// Prints per-seed clear/death stats — run with: -only-testing:AshVaultTests/PlaytestTests/testPrintCampaignDiagnostics
    func testPrintCampaignDiagnostics() {
        print("\n=== Campaign diagnostics (seeds 1-32, auto-battle) ===")
        var cleared = 0
        var deaths: [Int: Int] = [:]
        for seed in UInt64(1)...UInt64(32) {
            if let r = PlaytestHarness.runCampaign(seed: seed, maxTicks: 300_000) {
                cleared += 1
                let mins = Double(r.ticks) / 60.0
                print(String(format: "seed %2d: CLEAR %4d ticks (~%.1f min) gold=%d shards=%d",
                             seed, r.ticks, mins, r.runGold, r.pendingShards))
                for layer in 1...Balance.vaultHeartLayer {
                    let t = r.layerTicks[layer, default: 0]
                    if t > 0 { print("         ring \(layer): \(t)s") }
                }
            } else if let d = PlaytestHarness.runUntilDefeat(seed: seed, maxTicks: 300_000) {
                deaths[d.layer, default: 0] += 1
                print("seed \(seed): DEATH ring \(d.layer) @ \(d.ticks)s  gold=\(d.gold)")
            }
        }
        print("Cleared \(cleared)/32. Death histogram: \(deaths)")

        print("\n=== Manual combat timing (first 5 clearing seeds) ===")
        var manualPrinted = 0
        for seed in UInt64(1)...UInt64(32) {
            guard let r = PlaytestHarness.runCampaign(seed: seed, maxTicks: 300_000, manualCombat: true) else {
                continue
            }
            manualPrinted += 1
            let mins = Double(r.ticks) / 60.0
            print(String(format: "seed %2d: CLEAR %4d ticks (~%.1f min) gold=%d",
                         seed, r.ticks, mins, r.runGold))
            if manualPrinted >= 5 { break }
        }
        if manualPrinted == 0 { print("  (no seeds cleared on manual harness)") }
    }

    func testAutoBattleCampaignPacingSeedSweep() {
        var cleared = 0
        for seed in UInt64(1)...UInt64(32) {
            if PlaytestHarness.runCampaign(seed: seed, maxTicks: 300_000) != nil {
                cleared += 1
            }
        }
        print("=== Seed sweep: \(cleared)/32 campaigns cleared via auto-battle ===")
        XCTAssertGreaterThanOrEqual(cleared, 1,
                                    "At least one seed should clear the 10-ring campaign on auto-battle")
    }

    func testAutoBattleCampaignPacing() {
        guard let result = (UInt64(1)...UInt64(32)).compactMap({
            PlaytestHarness.runCampaign(seed: $0, maxTicks: 300_000)
        }).first else {
            XCTFail("No seed in 1...32 cleared the campaign on auto-battle")
            return
        }

        print("=== Auto-battle campaign playtest (seed \(result.seed)) ===")
        for layer in 1...Balance.vaultHeartLayer {
            print("  layer \(layer): \(result.layerTicks[layer, default: 0]) ticks")
        }
        let minutes = Double(result.ticks) / 60.0
        print("  total: \(result.ticks) ticks (~\(String(format: "%.1f", minutes)) min), run gold \(result.runGold)")
        print("  pending Ash Shards: \(result.pendingShards)")

        XCTAssertGreaterThan(result.runGold, 2_000, "Campaign should earn meaningful gold")
        XCTAssertGreaterThanOrEqual(result.pendingShards, Balance.vaultHeartShardBonus,
                                    "Vault Heart run should yield meaningful Ash Shards")
        // North star: ~20–30 min manual; auto a bit longer. Cap auto campaign at ~45 min.
        XCTAssertLessThan(result.ticks, 2_700, "Auto campaign should beat Vault Heart under ~45 min")
    }
}
