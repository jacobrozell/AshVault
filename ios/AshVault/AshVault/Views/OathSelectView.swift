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
        ScrollFit {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        optionsSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 22) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                        heroSection
                        optionsSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
        .onAppear {
            highlighted = MetaStore.loadDelverOath()
        }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 10 : 20) {
            ScaledEmoji("📜", style: isLandscape ? .title : .largeTitle)
            Text("Swear Your Oath")
                .font(.gameDisplay(compactHeight: isLandscape))
                .foregroundStyle(Theme.gold)
            Text("The mountain remembers how you descend. Choose one oath for this delve.")
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyleBodySecondary()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var optionsSection: some View {
        VStack(spacing: isLandscape ? 8 : 14) {
            ForEach(DelverOath.allCases) { oath in
                oathButton(oath)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func oathButton(_ oath: DelverOath) -> some View {
        let isHighlighted = highlighted == oath
        return Button {
            engine.chooseDelverOath(oath)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: oath.icon)
                    .font(.title2)
                    .frame(width: 36)
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
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
                    Text(oath.flavor)
                        .font(.caption)
                        .foregroundStyleBodySecondary()
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, isLandscape ? 10 : 16)
            .padding(.horizontal, isLandscape ? 12 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel)
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
