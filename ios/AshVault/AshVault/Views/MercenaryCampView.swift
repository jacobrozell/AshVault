import SwiftUI

/// Hire mercenaries with run gold. Ownership persists across runs and descents.
struct MercenaryCampView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: isLandscape ? 2 : 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mercenary Camp")
                    .font(.headline)
                Spacer()
                Label("+\(engine.mercenaryDPS) DPS", systemImage: "person.3.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.mana)
            }

            Text(Narrative.Term.campFlavor)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(isLandscape ? 1 : nil)

            if !isLandscape {
                Text("Milestone ×2 at 25, 50, 100…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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

        return Button {
            engine.hireMercenary(merc)
        } label: {
            HStack(spacing: 10) {
                Text(merc.icon).font(.title2).accessibilityDecorative()
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(merc.name)
                            .font(.subheadline.bold())
                        Spacer()
                        Text("×\(owned)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("\(merc.dps(count: owned)) DPS · \(merc.blurb)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(isLandscape ? 1 : 2)
                    if !isLandscape {
                        Text(merc.lore)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                    if let next {
                        Text("Next ×2 at \(next) owned")
                            .font(.caption2)
                            .foregroundStyle(Theme.mana)
                    }
                }
                Label(Formatting.short(cost), systemImage: "centsign.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.gold)
            }
            .padding(10)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(affordable ? 1 : 0.5)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
        .accessibilityLabel("\(merc.name), \(owned) owned, \(Formatting.short(cost)) gold")
    }
}
