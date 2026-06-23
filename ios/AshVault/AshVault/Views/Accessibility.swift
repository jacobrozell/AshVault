import SwiftUI

extension View {
    /// Hide decorative visuals from VoiceOver while keeping them on screen.
    func accessibilityDecorative() -> some View {
        accessibilityHidden(true)
    }

    @ViewBuilder
    func adaptiveMinimumScaleFactor(_ factor: CGFloat, dynamicTypeSize: DynamicTypeSize) -> some View {
        if AccessibilityLayout.allowsMinimumScaleFactor(dynamicTypeSize: dynamicTypeSize) {
            minimumScaleFactor(factor)
        } else {
            self
        }
    }

    @ViewBuilder
    func adaptiveLineLimit(
        _ compactLimit: Int?,
        isLandscape: Bool,
        dynamicTypeSize: DynamicTypeSize
    ) -> some View {
        if let limit = AccessibilityLayout.compactLineLimit(
            isLandscape: isLandscape,
            dynamicTypeSize: dynamicTypeSize,
            compactLimit: compactLimit
        ) {
            lineLimit(limit)
        } else {
            self
        }
    }
}

extension DynamicTypeSize {
    /// True at AX1 and above — use for layout reflow decisions.
    var ashvaultUsesAccessibilityLayout: Bool {
        self >= .accessibility1
    }
}

enum AccessibilityLayout {
    /// Move buttons stack vertically at accessibility sizes so labels are not clipped.
    static func combatMovesStackVertically(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.ashvaultUsesAccessibilityLayout
    }

    /// Side-by-side hero + content panels (landscape only, default text sizes).
    static func usesSideBySideLayout(isLandscape: Bool, dynamicTypeSize: DynamicTypeSize) -> Bool {
        isLandscape && !dynamicTypeSize.ashvaultUsesAccessibilityLayout
    }

    /// Show full card blurbs and lore (portrait, or any accessibility size).
    static func showsExpandedCardCopy(isLandscape: Bool, dynamicTypeSize: DynamicTypeSize) -> Bool {
        !isLandscape || dynamicTypeSize.ashvaultUsesAccessibilityLayout
    }

    /// Shrink-to-fit is OK at default sizes; reflow instead at AX sizes.
    static func allowsMinimumScaleFactor(dynamicTypeSize: DynamicTypeSize) -> Bool {
        !dynamicTypeSize.ashvaultUsesAccessibilityLayout
    }

    /// Column count for shop/relic grids; collapses to one column at accessibility sizes.
    static func metaGridColumnCount(
        isLandscape: Bool,
        dynamicTypeSize: DynamicTypeSize,
        portraitColumns: Int,
        landscapeColumns: Int
    ) -> Int {
        if dynamicTypeSize.ashvaultUsesAccessibilityLayout {
            return 1
        }
        return isLandscape ? landscapeColumns : portraitColumns
    }

    /// Line limit for secondary copy; unlimited at accessibility sizes.
    static func compactLineLimit(
        isLandscape: Bool,
        dynamicTypeSize: DynamicTypeSize,
        compactLimit: Int?
    ) -> Int? {
        if dynamicTypeSize.ashvaultUsesAccessibilityLayout {
            return nil
        }
        return compactLimit
    }
}
