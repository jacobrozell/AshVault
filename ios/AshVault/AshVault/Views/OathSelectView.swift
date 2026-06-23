import SwiftUI

/// Pre-run oath picker — Hound, Mast, or Kite before the first encounter.
struct OathSelectView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var highlighted: DelverOath?

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        PhaseScroll {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        optionsSection
                    }
                } else {
                    VStack(spacing: 14) {
                        heroSection
                        optionsSection
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .onAppear {
            highlighted = MetaStore.loadDelverOath()
        }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 8 : 12) {
            RunPhaseTitle(title: "Swear Your Oath", emoji: "📜")
            Text("The mountain remembers how you descend.")
                .font(.caption)
                .foregroundStyleBodySecondary()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Choose an Oath", systemImage: "scroll.fill")
            VStack(spacing: isLandscape ? 8 : 10) {
                ForEach(DelverOath.allCases) { oath in
                    oathButton(oath)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func oathButton(_ oath: DelverOath) -> some View {
        let isHighlighted = highlighted == oath
        return Button {
            engine.chooseDelverOath(oath)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: oath.icon)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(oath.title)
                            .font(isLandscape ? .headline.bold() : .title3.bold())
                        if isHighlighted {
                            Text("Last oath")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.2))
                                .foregroundStyle(Theme.gold)
                                .clipShape(Capsule())
                        }
                    }
                    Text(oath.statLine)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.mana)
                    Text(oath.perkSummary)
                        .font(.subheadline)
                        .foregroundStyleBodySecondary()
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, isLandscape ? 10 : 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panelElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isHighlighted ? Theme.gold : Theme.panelStroke, lineWidth: isHighlighted ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(oath.title). \(oath.statLine). \(oath.perkSummary)")
        .accessibilityHint("Swear this oath and begin the descent")
    }
}
