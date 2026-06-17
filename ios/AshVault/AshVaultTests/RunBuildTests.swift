import XCTest
@testable import AshVault

final class RunBuildTests: XCTestCase {

    func testRunRelicCapIsSix() {
        XCTAssertEqual(Balance.maxRunRelics, 6)
        XCTAssertEqual(RunRelic.allCases.count, 9)
    }

    func testSynergyWeightBoostsMatchingDrafts() {
        var build = RunBuild.empty
        build.runRelics = [.cinderHeart, .coalTinder]
        let weight = build.synergyWeight(for: .burn, equipped: [.emberBolt])
        XCTAssertGreaterThan(weight, 0)
        XCTAssertEqual(weight, Balance.draftSynergyWeightBase * 3)
    }

    func testDraftPoolProducesThreePicks() {
        let rng = ScriptedRandom([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let picks = RunDraft.rollOptions(rng: rng, build: .empty, equipped: [.emberBolt])
        XCTAssertEqual(picks.count, 3)
    }

    func testDraftApplyAddsRunRelic() {
        var build = RunBuild.empty
        var player = Player(name: "T")
        let pick = DraftPick.relic(.frostCrown)
        RunDraft.apply(pick, to: player, build: &build, loadout: SigilLoadout())
        XCTAssertTrue(build.has(.frostCrown))
        XCTAssertEqual(build.draftsTaken, 1)
    }

    func testEvolutionUnlockEligibility() {
        var build = RunBuild.empty
        build.inkBySpell[SpellID.emberBolt.rawValue] = Balance.evolutionInkThreshold
        build.burnProcs = Balance.meteorBurnProcsNeeded
        let evo = SigilEvolution.eligibleUnlock(for: .emberBolt, build: build)
        XCTAssertEqual(evo, .meteor)
    }

    func testGlacierConditionTracksChills() {
        var build = RunBuild.empty
        build.chillProcs = Balance.glacierChillProcsNeeded
        build.inkBySpell[SpellID.frostShard.rawValue] = Balance.evolutionInkThreshold
        XCTAssertEqual(SigilEvolution.eligibleUnlock(for: .frostShard, build: build), .glacier)
    }

    func testDraftPickRoundTripID() {
        let picks: [DraftPick] = [
            .stat(.sharpBlade),
            .relic(.greedSeal),
            .evolutionInk(spell: .emberBolt, amount: 3),
            .sigilTune(.frostChill),
            .evolutionUnlock(spell: .emberBolt, evolution: .meteor)
        ]
        for pick in picks {
            let restored = RunDraft.decodePicks(from: [pick.id])
            XCTAssertEqual(restored.first, pick)
        }
    }
}
