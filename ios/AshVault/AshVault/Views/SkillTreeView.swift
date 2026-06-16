import SwiftUI

/// Spend Ash Shards on permanent prestige upgrades. Reachable from the title
/// screen and the ascension screen.
struct SkillTreeView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: isLandscape ? 2 : 1)
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
        return HStack(spacing: isLandscape ? 8 : 12) {
            Text(node.icon)
                .font(isLandscape ? .title2 : .largeTitle)
                .accessibilityDecorative()
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(node.name)
                        .font(isLandscape ? .subheadline.bold() : .headline)
                        .minimumScaleFactor(0.85)
                    Text("Lv \(lvl)/\(node.maxLevel)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if !isLandscape {
                    Text(node.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Button { engine.upgradeNode(node) } label: {
                Text(maxed ? "MAX" : "\(cost) ◆")
                    .font(.caption.bold())
                    .padding(.vertical, isLandscape ? 6 : 8)
                    .padding(.horizontal, isLandscape ? 8 : 12)
                    .background(affordable ? Color.purple : Theme.panel)
                    .foregroundStyle(affordable ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!affordable)
            .accessibilityLabel(maxed ? "\(node.name), max level" : "Upgrade \(node.name) for \(cost) shards")
            .accessibilityHint(node.blurb)
        }
        .padding(isLandscape ? 8 : 12)
        .background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
