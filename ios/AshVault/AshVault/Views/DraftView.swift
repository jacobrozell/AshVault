import SwiftUI

/// Kill-bar draft — pick 1 of 3 run-scoped upgrades (survivor crawl).
struct DraftView: View {
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
        .onAppear { appeared = true }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 10 : 22) {
            ScaledEmoji("✨", style: isLandscape ? .title : .largeTitle)
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: appeared)
            Text("Draft Pick")
                .font(.gameDisplay(compactHeight: isLandscape))
                .foregroundStyle(Theme.gold)
            Text("The vault yields power. Choose one upgrade for this run.")
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var optionsSection: some View {
        VStack(spacing: isLandscape ? 8 : 14) {
            ForEach(engine.draftOptions) { option in
                draftButton(option)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func draftButton(_ option: DraftOption) -> some View {
        Button {
            engine.chooseDraft(option)
        } label: {
            HStack {
                Image(systemName: option.icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                    Text(option.blurb)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, isLandscape ? 10 : 16)
            .padding(.horizontal, isLandscape ? 12 : 18)
            .frame(maxWidth: .infinity)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(option.title), \(option.blurb)")
        .accessibilityHint("Choose this draft upgrade")
    }
}
