import SwiftUI
import XCTest
@testable import AshVault

final class AccessibilityHelpersTests: XCTestCase {
    func testAccessibilitySizeThreshold() {
        XCTAssertFalse(DynamicTypeSize.large.ashvaultUsesAccessibilityLayout)
        XCTAssertTrue(DynamicTypeSize.accessibility1.ashvaultUsesAccessibilityLayout)
        XCTAssertTrue(DynamicTypeSize.accessibility5.ashvaultUsesAccessibilityLayout)
    }

    func testCombatLayoutDecisions() {
        XCTAssertTrue(AccessibilityLayout.combatPortraitScrolls(
            isLandscape: false,
            dynamicTypeSize: .accessibility3
        ))
        XCTAssertFalse(AccessibilityLayout.combatPortraitScrolls(
            isLandscape: true,
            dynamicTypeSize: .accessibility3
        ))
        XCTAssertFalse(AccessibilityLayout.combatPortraitScrolls(
            isLandscape: false,
            dynamicTypeSize: .large
        ))
        XCTAssertTrue(AccessibilityLayout.combatMovesStackVertically(dynamicTypeSize: .accessibility3))
        XCTAssertFalse(AccessibilityLayout.combatMovesStackVertically(dynamicTypeSize: .large))
    }

    func testMetaLayoutDecisions() {
        XCTAssertTrue(AccessibilityLayout.usesSideBySideLayout(isLandscape: true, dynamicTypeSize: .large))
        XCTAssertFalse(AccessibilityLayout.usesSideBySideLayout(isLandscape: true, dynamicTypeSize: .accessibility3))
        XCTAssertEqual(
            AccessibilityLayout.metaGridColumnCount(
                isLandscape: true,
                dynamicTypeSize: .accessibility3,
                portraitColumns: 2,
                landscapeColumns: 3
            ),
            1
        )
        XCTAssertEqual(
            AccessibilityLayout.metaGridColumnCount(
                isLandscape: false,
                dynamicTypeSize: .large,
                portraitColumns: 2,
                landscapeColumns: 3
            ),
            2
        )
        XCTAssertTrue(AccessibilityLayout.showsExpandedCardCopy(isLandscape: true, dynamicTypeSize: .accessibility2))
        XCTAssertFalse(AccessibilityLayout.showsExpandedCardCopy(isLandscape: true, dynamicTypeSize: .large))
        XCTAssertNil(AccessibilityLayout.compactLineLimit(
            isLandscape: true,
            dynamicTypeSize: .accessibility3,
            compactLimit: 2
        ))
        XCTAssertEqual(
            AccessibilityLayout.compactLineLimit(
                isLandscape: true,
                dynamicTypeSize: .large,
                compactLimit: 2
            ),
            2
        )
    }
}
