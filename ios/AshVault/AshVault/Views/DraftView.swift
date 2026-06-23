import SwiftUI

/// Kill-bar draft — pick 1 of 3 run-scoped upgrades (survivor crawl).
struct DraftView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        PhaseScroll {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        RunPhaseTitle(title: "Draft Pick", emoji: "✨")
                        optionsSection
                    }
                } else {
                    VStack(spacing: 12) {
                        RunPhaseTitle(title: "Draft Pick", emoji: "✨")
                        BuildPanelView(compact: true)
                        optionsSection
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Choose One", systemImage: "hand.point.up.left.fill")
            VStack(spacing: isLandscape ? 8 : 10) {
                ForEach(engine.draftOptions) { pick in
                    draftButton(pick)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func draftButton(_ pick: DraftPick) -> some View {
        Button {
            engine.chooseDraft(pick)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: pick.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.gold)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pick.title)
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                    Text(pick.blurb)
                        .font(.subheadline)
                        .foregroundStyleBodySecondary()
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, isLandscape ? 10 : 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panelElevated)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(pick.title), \(pick.blurb)")
        .accessibilityHint("Choose this draft upgrade")
    }
}
