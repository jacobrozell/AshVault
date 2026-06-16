import XCTest
@testable import AshVault

final class FirebaseBootstrapTests: XCTestCase {
    func testShouldConfigureIsFalseWithoutProductionPlist() {
        XCTAssertFalse(FirebaseBootstrap.shouldConfigure)
    }
}
