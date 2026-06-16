import XCTest
@testable import AshVault

final class TypeChartTests: XCTestCase {

    func testEmberWeakVsStoneAspect() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .ember, enemyAspect: .stone, enemyTags: []),
            .resist
        )
    }

    func testEmberWeakVsUndeadTag() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .ember, enemyAspect: .arc, enemyTags: [.undead]),
            .weak
        )
    }

    func testEmberResistsAgainstStoneOnlyWhenNotWeak() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .frost, enemyAspect: .venom, enemyTags: []),
            .resist
        )
    }

    func testFrostWeakVsWildTag() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .frost, enemyAspect: .arc, enemyTags: [.wild]),
            .weak
        )
    }

    func testNeutralWhenNoMatch() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .frost, enemyAspect: .arc, enemyTags: []),
            .neutral
        )
    }

    func testArcWeakVsStoneAspect() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .arc, enemyAspect: .stone, enemyTags: []),
            .weak
        )
    }

    func testArcResistVsEmberAspect() {
        XCTAssertEqual(
            TypeChart.effectiveness(spellElement: .arc, enemyAspect: .ember, enemyTags: []),
            .resist
        )
    }
}
