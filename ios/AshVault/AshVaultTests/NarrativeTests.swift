@testable import AshVault
import XCTest

final class NarrativeTests: XCTestCase {

    func testTutorialLinesAreNonEmpty() {
        for i in 0..<Narrative.tutorialLineCount {
            XCTAssertFalse(Narrative.text(for: .tutorial(index: i)).isEmpty)
        }
    }

    func testWelcomeIncludesName() {
        let line = Narrative.text(for: .welcome(name: "Test"))
        XCTAssertTrue(line.contains("Test"))
    }

    func testLayerEntryBeats() {
        XCTAssertNotNil(Narrative.layerEntry(layer: 1))
        XCTAssertNotNil(Narrative.layerEntry(layer: 2))
        XCTAssertNotNil(Narrative.layerEntry(layer: 5))
        XCTAssertNotNil(Narrative.layerEntry(layer: 10))
        XCTAssertNotNil(Narrative.layerEntry(layer: 11))
    }

    func testBossSpawnBeats() {
        XCTAssertTrue(Narrative.text(for: .bossSpawn(isFinalBoss: true))
            .contains(Narrative.Term.theSinter))
        XCTAssertTrue(Narrative.text(for: .bossSpawn(isFinalBoss: false))
            .contains("warden"))
    }

    func testVaultHeartEpilogueMentionsAsh() {
        XCTAssertTrue(Narrative.text(for: .vaultHeartEpilogue).localizedCaseInsensitiveContains("ash"))
    }

    func testNoDragonOrEmpireInTutorial() {
        for i in 0..<Narrative.tutorialLineCount {
            let line = Narrative.text(for: .tutorial(index: i))
            XCTAssertFalse(line.localizedCaseInsensitiveContains("dragon"))
            XCTAssertFalse(line.localizedCaseInsensitiveContains("empire"))
        }
    }

    func testAscensionBeatsMentionAshTree() {
        XCTAssertTrue(Narrative.text(for: .ascensionFollowUp).contains("Ash Tree"))
        XCTAssertTrue(Narrative.text(for: .ascensionGained(shards: 5)).contains("Ash Shards"))
        XCTAssertTrue(Narrative.text(for: .progressionAfterDragon).contains("Withdraw"))
    }

    func testOnboardingPagesAreComplete() {
        XCTAssertFalse(Narrative.Onboarding.pages.isEmpty)
        for page in Narrative.Onboarding.pages {
            XCTAssertFalse(page.title.isEmpty)
            XCTAssertFalse(page.body.isEmpty)
            XCTAssertFalse(page.bullets.isEmpty, "page \(page.id)")
            for bullet in page.bullets {
                XCTAssertFalse(bullet.isEmpty)
            }
        }
    }

    func testOnboardingAvoidsLegacyNames() {
        let allText = Narrative.Onboarding.pages.flatMap { [$0.title, $0.body] + $0.bullets }
        for text in allText {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Soul Shard"))
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Abyss"))
        }
    }

    func testTerminologyAvoidsLegacyNames() {
        let terms = [
            Narrative.Term.ashShards,
            Narrative.Term.ashTree,
            Narrative.Term.ashGallery,
            Narrative.Term.withdrawToShrine,
            Narrative.Term.titleSubtitle,
            Narrative.Term.abandonRunFooter,
            Narrative.Term.abandonRunAccessibilityHint,
            Narrative.Term.autoWithdrawActiveFooter(pending: 3),
            Narrative.Term.autoWithdrawThreshold(8),
        ]
        for term in terms {
            XCTAssertFalse(term.localizedCaseInsensitiveContains("Soul Shard"))
            XCTAssertFalse(term.localizedCaseInsensitiveContains("Soul Tree"))
            XCTAssertFalse(term.localizedCaseInsensitiveContains("Relic Museum"))
            XCTAssertFalse(term.localizedCaseInsensitiveContains("Abyss"))
        }
    }
}
