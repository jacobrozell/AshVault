import SwiftUI

struct LevelUpView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLandscapeLayout) private var isLandscape
    @State private var appeared = false

    var body: some View {
        ScrollFit {
            Group {
                if isLandscape {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        upgradeOptions
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 22) {
                        Spacer(minLength: 12)
                        heroSection
                        upgradeOptions
                        Spacer(minLength: 12)
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
            if !isLandscape { Spacer(minLength: 12) }
            ScaledEmoji("⬆️", style: isLandscape ? .title : .largeTitle)
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: appeared)
            Text("Level Up!")
                .font(.gameDisplay(compactHeight: isLandscape))
                .minimumScaleFactor(0.75)
                .foregroundStyle(Theme.gold)
            Text("Choose a stat to boost. It rises by the larger amount; the others still grow a little.")
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if !isLandscape { Spacer(minLength: 12) }
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
            HStack {
                Image(systemName: upgrade.icon)
                Text(upgrade.label)
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                Spacer()
                Text(detail(upgrade))
                    .font(isLandscape ? .caption : .subheadline)
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
