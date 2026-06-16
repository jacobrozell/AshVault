import SwiftUI

/// Spend Ash Shards on permanent prestige upgrades. Reachable from the title
/// screen and the ascension screen.
struct SkillTreeView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 12

    private var gridColumns: [GridItem] {
        let count = AccessibilityLayout.metaGridColumnCount(
            isLandscape: isLandscape,
            dynamicTypeSize: dynamicTypeSize,
            portraitColumns: 1,
            landscapeColumns: 2
        )
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    private var showsBlurb: Bool {
        AccessibilityLayout.showsExpandedCardCopy(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Label(Narrative.Term.ashShardsAvailable(engine.availableShards), systemImage: "sparkles")
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                        .foregroundStyle(.purple)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: engine.availableShards)
                        .padding(.top, 4)
                        .accessibilityLabel("\(engine.availableShards) ash shards available")

                    LazyVGrid(columns: gridColumns, spacing: isLandscape ? 8 : 12) {
                        ForEach(SkillNode.allCases) { node in
                            card(node)
                        }
                    }
                }
                .padding(isLandscape ? 12 : 16)
            }
            .navigationTitle(Narrative.Term.ashTree)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityHint("Closes the ash tree")
                }
            }
        }
    }

    private func card(_ node: SkillNode) -> some View {
        let lvl = engine.level(of: node)
        let maxed = lvl >= node.maxLevel
        let cost = engine.cost(node)
        let affordable = engine.canUpgrade(node)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: isLandscape ? 8 : 12) {
                ScaledEmoji(node.icon, style: isLandscape ? .title2 : .title)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(node.name)
                            .font(isLandscape ? .subheadline.bold() : .headline)
                            .adaptiveMinimumScaleFactor(0.85, dynamicTypeSize: dynamicTypeSize)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Lv \(lvl)/\(node.maxLevel)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    if showsBlurb {
                        Text(node.blurb)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            Button { engine.upgradeNode(node) } label: {
                Text(maxed ? "MAX" : "\(cost) ◆")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(affordable ? Color.purple : Theme.panel)
                    .foregroundStyle(affordable ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!affordable)
            .accessibilityLabel(maxed ? "\(node.name), max level" : "Upgrade \(node.name) for \(cost) shards")
            .accessibilityHint(node.blurb)
        }
        .padding(cardPadding)
        .background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
