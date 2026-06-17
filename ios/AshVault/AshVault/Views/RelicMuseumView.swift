import SwiftUI

/// Collection of boss-dropped relics. Equip up to three passives.
struct RelicMuseumView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 10

    private var gridColumns: [GridItem] {
        let count = AccessibilityLayout.metaGridColumnCount(
            isLandscape: isLandscape,
            dynamicTypeSize: dynamicTypeSize,
            portraitColumns: 2,
            landscapeColumns: 3
        )
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollFit {
                VStack(spacing: 16) {
                    summaryHeader
                    relicGrid
                    lifetimeSection
                }
                .padding()
            }
            .navigationTitle(Narrative.Term.ashGallery)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summaryHeader: some View {
        Panel {
            VStack(spacing: 8) {
                Text("\(engine.discoveredRelics.count)/\(Relic.allCases.count) discovered")
                    .font(.headline)
                Text(Narrative.Term.galleryHeader)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var relicGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(Relic.allCases) { relic in
                relicCard(relic)
            }
        }
    }

    private func relicCard(_ relic: Relic) -> some View {
        let discovered = engine.isRelicDiscovered(relic)
        let equipped = engine.isRelicEquipped(relic)

        return Button {
            if discovered { engine.toggleEquipRelic(relic) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(discovered ? relic.icon : "❓")
                        .font(.title2)
                        .accessibilityDecorative()
                    Spacer()
                    if equipped {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.gold)
                    }
                }
                Text(discovered ? relic.name : "???")
                    .font(.subheadline.bold())
                    .foregroundStyle(discovered ? .primary : .secondary)
                Text(discovered ? "\(relic.blurb) \(relic.lore)" : "Defeat wardens to discover.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if discovered {
                    Label(relic.anchor.label, systemImage: relic.anchor.icon)
                        .font(.caption2)
                        .foregroundStyle(Theme.mana)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(cardPadding)
            .background(equipped ? Theme.gold.opacity(0.15) : Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(equipped ? Theme.gold : Theme.panelStroke, lineWidth: equipped ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(discovered ? 1 : 0.55)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!discovered)
        .accessibilityLabel(discovered ? relic.name : "Undiscovered relic")
        .accessibilityHint(discovered ? "Double tap to equip or unequip" : "")
    }

    private var lifetimeSection: some View {
        Panel {
            VStack(alignment: .leading, spacing: 6) {
                Text("Lifetime")
                    .font(.subheadline.bold())
                statRow("Gold earned", Formatting.short(engine.lifetime.totalGoldEarned))
                statRow("Enemies slain", "\(engine.lifetime.totalKills)")
                statRow("Bosses slain", "\(engine.lifetime.totalBossKills)")
                statRow("Descents", "\(engine.lifetime.totalDescents)")
                statRow("Deaths", "\(engine.lifetime.totalDeaths)")
                statRow("Revives", "\(engine.lifetime.totalRevives)")
                statRow("Runs started", "\(engine.lifetime.totalRunsStarted)")
                statRow("Deepest ring", "\(engine.lifetime.deepestLayer)")
            }
            .font(.caption)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}

/// Brief celebration when a new relic drops in combat.
struct RelicFoundView: View {
    let relic: Relic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var scrollsPortrait: Bool {
        !isLandscape && dynamicTypeSize.ashvaultUsesAccessibilityLayout
    }

    var body: some View {
        Group {
            if isLandscape {
                HStack(spacing: 20) {
                    relicSummary
                    Spacer(minLength: 0)
                    dismissButton
                        .frame(maxWidth: 200)
                }
                .padding()
            } else if scrollsPortrait {
                ScrollView {
                    VStack(spacing: 20) {
                        relicSummary
                        dismissButton
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    relicSummary
                    Spacer()
                    dismissButton
                }
                .padding()
            }
        }
        .presentationDetents(isLandscape ? [.fraction(0.55)] : [.medium, .large])
    }

    private var relicSummary: some View {
        VStack(spacing: 16) {
            ScaledEmoji(relic.icon, style: isLandscape ? .title : .largeTitle)
            Text(Narrative.Term.relicFoundTitle)
                .font(isLandscape ? .title2.bold() : .title.bold())
                .foregroundStyle(Theme.gold)
            Text(relic.name)
                .font(isLandscape ? .title3.bold() : .title2.bold())
            Text(relic.lore)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(relic.blurb)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var dismissButton: some View {
        Button { dismiss() } label: {
            Text(Narrative.Term.relicFoundButton)
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, isLandscape ? 12 : 14)
                .background(Theme.gold)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
