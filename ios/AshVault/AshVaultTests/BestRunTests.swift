import XCTest
@testable import AshVault

final class BestRunTests: XCTestCase {

    func testEmptyHasNoRecord() {
        XCTAssertFalse(BestRun.empty.hasRecord)
    }

    func testLayerProgressCountsAsRecord() {
        XCTAssertTrue(BestRun(layer: 2, level: 1, gold: 0).hasRecord)
    }

    func testGoldProgressCountsAsRecord() {
        XCTAssertTrue(BestRun(layer: 1, level: 1, gold: 50).hasRecord)
    }

    func testLevelProgressCountsAsRecord() {
        XCTAssertTrue(BestRun(layer: 1, level: 3, gold: 0).hasRecord)
    }
}
