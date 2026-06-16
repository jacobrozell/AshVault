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
        ScrollFit {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        actionSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 20) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                        heroSection
                        actionSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
        .sheet(isPresented: $showTree) { SkillTreeView() }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 10 : 20) {
            if !isLandscape && !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                Spacer(minLength: 12)
            }
            ScaledEmoji("🔮", style: isLandscape ? .title : .largeTitle)
            Text(Narrative.Term.withdrawToShrine)
                .font(.gameDisplay(compactHeight: isLandscape))
                .adaptiveMinimumScaleFactor(0.75, dynamicTypeSize: dynamicTypeSize)
                .foregroundStyle(.purple)
                .multilineTextAlignment(.center)
            Text(Narrative.Term.ascensionBody)
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !isLandscape && !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                Spacer(minLength: 12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Panel {
                VStack(spacing: 8) {
                    row("Shards to spend", "\(engine.availableShards)")
                    row("Shards to gain", "+\(engine.pendingShards)")
                }
                .foregroundStyle(.primary)
            }

            if engine.pendingShards == 0 {
                Text(Narrative.Term.ascensionEmptyHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Shards = √(gold earned this run ÷ \(Int(Balance.prestigeShardDivisor))). Bank them in the Ash Tree for permanent power.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
