import SwiftUI

/// Prestige screen — withdraw to the Shrine and bank Ash Shards.
struct AscensionView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showTree = false

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        PhaseScroll {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        RunPhaseTitle(title: Narrative.Term.withdrawToShrine, emoji: "🔮")
                        actionSection
                    }
                } else {
                    VStack(spacing: 14) {
                        RunPhaseTitle(title: Narrative.Term.withdrawToShrine, emoji: "🔮")
                        actionSection
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showTree) { SkillTreeView() }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "This Run", systemImage: "chart.bar.fill")
            Panel {
                VStack(spacing: 8) {
                    row("Shards to spend", "\(engine.availableShards)")
                    row("Run gold", Formatting.short(engine.runGoldEarned))
                    if engine.runStats.bossKillsThisRun > 0 {
                        row("Wardens slain", "+\(engine.runStats.bossKillsThisRun)")
                    }
                    row("Depth bonus", "+\(engine.crawlDepthBonus)")
                    row("Shards to gain", "+\(engine.pendingShards)")
                }
                .foregroundStyle(.primary)
            }

            if engine.runStats.layersClearedThisRun > 0 || engine.runStats.enemiesSlain > 0 {
                SectionHeader(title: "Depth Reached", systemImage: "square.3.layers.3d")
                Panel {
                    VStack(spacing: 8) {
                        row("Rings cleared", "\(engine.runStats.layersClearedThisRun)")
                        row("Guardians slain", "\(engine.runStats.enemiesSlain)")
                        row("Deepest ring", "\(engine.layer)")
                    }
                    .foregroundStyle(.primary)
                }
            }

            if engine.pendingShards == 0 {
                Text(Narrative.Term.ascensionEmptyHint)
                    .font(.caption)
                    .foregroundStyleBodySecondary()
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { showTree = true } label: {
                Label(Narrative.Term.openAshTree, systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
            }

            Button {
                engine.ascend()
            } label: {
                Text(engine.pendingShards > 0
                     ? Narrative.Term.withdrawGainShards(engine.pendingShards)
                     : Narrative.Term.withdrawAnyway)
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 10 : 14)
                    .background(.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint(Narrative.Term.withdrawAccessibility)

            Button { engine.cancelAscension() } label: {
                Text(Narrative.Term.keepCrawling)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).bold()
        }
        .font(.subheadline)
    }
}
