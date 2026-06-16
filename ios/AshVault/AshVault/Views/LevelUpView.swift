import SwiftUI

struct LevelUpView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var appeared = false

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        ScrollFit {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        upgradeOptions
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 22) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                        heroSection
                        upgradeOptions
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
        .onAppear { appeared = true }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 10 : 22) {
            if !isLandscape && !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                Spacer(minLength: 12)
            }
            ScaledEmoji("⬆️", style: isLandscape ? .title : .largeTitle)
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: appeared)
            Text("Level Up!")
                .font(.gameDisplay(compactHeight: isLandscape))
                .adaptiveMinimumScaleFactor(0.75, dynamicTypeSize: dynamicTypeSize)
                .foregroundStyle(Theme.gold)
            Text("Level \(engine.player.level) → \(engine.player.level + 1)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.gold)
            Text("Choose a stat to boost. It rises by the larger amount; the others still grow a little.")
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

    private var upgradeOptions: some View {
        VStack(spacing: isLandscape ? 8 : 14) {
            ForEach(Player.Upgrade.allCases, id: \.self) { upgrade in
                upgradeButton(upgrade)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func upgradeButton(_ upgrade: Player.Upgrade) -> some View {
        Button {
            engine.chooseUpgrade(upgrade)
        } label: {
            Group {
                if dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(upgrade.label, systemImage: upgrade.icon)
                            .font(.title3.bold())
                        Text(detail(upgrade))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        Image(systemName: upgrade.icon)
                        Text(upgrade.label)
                            .font(isLandscape ? .headline.bold() : .title3.bold())
                        Spacer()
                        Text(detail(upgrade))
                            .font(isLandscape ? .caption : .subheadline)
                    }
                }
            }
            .padding(.vertical, isLandscape ? 10 : 16)
            .padding(.horizontal, isLandscape ? 12 : 18)
            .frame(maxWidth: .infinity)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(upgrade.label), \(detail(upgrade))")
        .accessibilityHint("Choose this stat boost")
    }

    private func detail(_ upgrade: Player.Upgrade) -> String {
        switch upgrade {
        case .attack:  return "+10 ATK"
        case .defense: return "+10 DEF"
        case .health:  return "+20 HP"
        }
    }
}
