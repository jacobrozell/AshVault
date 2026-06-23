import SwiftUI

/// Hire mercenaries with run gold. Ownership persists across runs and descents.
struct MercenaryCampView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 10

    private var gridColumns: [GridItem] {
        let count = AccessibilityLayout.metaGridColumnCount(
            isLandscape: isLandscape,
            dynamicTypeSize: dynamicTypeSize,
            portraitColumns: 1,
            landscapeColumns: 2
        )
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    private var showsExpandedCopy: Bool {
        AccessibilityLayout.showsExpandedCardCopy(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Mercenary Camp",
                systemImage: "person.3.fill",
                subtitle: "+\(engine.mercenaryDPS) DPS · permanent hires"
            )

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Mercenary.allCases) { merc in
                    mercCard(merc)
                }
            }
        }
    }

    private func mercCard(_ merc: Mercenary) -> some View {
        let owned = engine.mercenaryCounts[merc, default: 0]
        let cost = engine.mercenaryCost(merc)
        let affordable = engine.canHire(merc)
        let next = Mercenary.nextMilestone(after: owned)
        let stacksVertically = dynamicTypeSize.ashvaultUsesAccessibilityLayout

        return Button {
            engine.hireMercenary(merc)
        } label: {
            Group {
                if stacksVertically {
                    VStack(alignment: .leading, spacing: 8) {
                        mercCardHeader(merc, owned: owned, cost: cost)
                        mercCardBody(merc, owned: owned, next: next)
                    }
                } else {
                    HStack(spacing: 10) {
                        Text(merc.icon).font(.title2).accessibilityDecorative()
                        VStack(alignment: .leading, spacing: 3) {
                            mercCardHeader(merc, owned: owned, cost: nil)
                            mercCardBody(merc, owned: owned, next: next)
                        }
                        Spacer(minLength: 0)
                        Label(Formatting.short(cost), systemImage: "centsign.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
            .padding(cardPadding)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(affordable ? 1 : 0.5)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
        .accessibilityLabel("\(merc.name), \(owned) owned, \(Formatting.short(cost)) gold")
    }

    @ViewBuilder
    private func mercCardHeader(_ merc: Mercenary, owned: Int, cost: Int?) -> some View {
        HStack {
            if cost != nil {
                Text(merc.icon).font(.title2).accessibilityDecorative()
            }
            Text(merc.name)
                .font(.subheadline.bold())
            Spacer()
            Text("×\(owned)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            if let cost {
                Label(Formatting.short(cost), systemImage: "centsign.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.gold)
            }
        }
    }

    @ViewBuilder
    private func mercCardBody(_ merc: Mercenary, owned: Int, next: Int?) -> some View {
        Text("\(merc.dps(count: owned)) DPS · \(merc.blurb)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .adaptiveLineLimit(isLandscape ? 1 : 2, isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
            .fixedSize(horizontal: false, vertical: true)
        if showsExpandedCopy {
            Text(merc.lore)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .adaptiveLineLimit(2, isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let next {
            Text("Next ×2 at \(next) owned")
                .font(.caption2)
                .foregroundStyle(Theme.mana)
        }
    }
}
