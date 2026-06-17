import XCTest
@testable import AshVault

final class WardenCatalogTests: XCTestCase {

    func testNamedWardensForCampaignRings() {
        let rng = ScriptedRandom(fallback: 0)
        XCTAssertEqual(WardenCatalog.wardenKind(for: 2, rng: rng).name, "Turnkey Hess")
        XCTAssertEqual(WardenCatalog.wardenKind(for: 4, rng: rng).name, "Pink Bloom")
        XCTAssertEqual(WardenCatalog.wardenKind(for: 6, rng: rng).name, "Echo Sergeant")
        XCTAssertEqual(WardenCatalog.wardenKind(for: 8, rng: rng).name, "Malvek's Shade")
        XCTAssertEqual(WardenCatalog.wardenKind(for: 10, rng: rng).name, Narrative.Term.theSinter)
    }

    func testRingNames() {
        XCTAssertEqual(RingName.title(ring: 2), "Graffiti Gallery")
        XCTAssertEqual(RingName.title(ring: 10), "Vault Heart")
    }

    func testCodexUnlocksByRing() {
        XCTAssertTrue(Codex.unlocks(forRing: 1).contains(.nwPenitentiary))
        XCTAssertTrue(Codex.unlocks(forRing: 2).contains(.twoHands))
    }

    func testMirrorVaultModifierExists() {
        XCTAssertEqual(RingModifier.mirrorVault.title, "Mirror Vault")
    }
}

@MainActor
final class SealedRoomTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testRingSevenWardenTriggersSealedRoom() {
        let e = GameEngine(rng: ScriptedRandom(fallback: 9))
        startTestRun(e)
        advanceToRing(e, target: 7)
        killBossRing(e)
        XCTAssertEqual(e.phase, .sealedRoom)
    }

    func testCopyChoiceUnlocksBeraCodex() {
        let e = GameEngine(rng: ScriptedRandom(fallback: 9))
        startTestRun(e)
        advanceToRing(e, target: 7)
        killBossRing(e)
        e.chooseSealedRoom(copy: true)
        XCTAssertTrue(e.discoveredCodex.contains(.clerkBera))
        XCTAssertEqual(e.phase, .ringChoice)
    }

    private func advanceToRing(_ e: GameEngine, target: Int) {
        while e.layer < target {
            killBossRing(e)
            resolveNonCombatPhases(e)
            if e.phase == .sealedRoom {
                e.chooseSealedRoom(copy: false)
            }
            if e.phase == .ringChoice {
                e.pushDeeper()
                resolveNonCombatPhases(e)
            }
        }
    }
}
