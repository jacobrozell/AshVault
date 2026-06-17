import SwiftUI

/// Ring 7 moral fork — COPY bark sheets or LEAVE with hidden oil (Cave Record echo).
struct SealedRoomView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        ScrollFit {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        choiceSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 22) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                        heroSection
                        choiceSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 10 : 20) {
            ScaledEmoji("📋", style: isLandscape ? .title : .largeTitle)
            Text("The Clerk's Nook")
                .font(.gameDisplay(compactHeight: isLandscape))
                .foregroundStyle(Theme.gold)
            Text(Narrative.Codex.sealedRoomIntro)
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Who owns truth when both factions lie?")
                .font(.caption.bold())
                .foregroundStyle(Theme.mana)
        }
        .frame(maxWidth: .infinity)
    }

    private var choiceSection: some View {
        VStack(spacing: 14) {
            Button {
                engine.chooseSealedRoom(copy: true)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Copy the bark sheets", systemImage: "doc.on.doc.fill")
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                    Text("Unlock Clerk Bera in the Codex. Truth travels — and so does blame.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, isLandscape ? 12 : 16)
                .padding(.horizontal, 16)
                .background(Theme.gold)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                engine.chooseSealedRoom(copy: false)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Leave them", systemImage: "flame.fill")
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                    Text("+\(Balance.sealedRoomLeaveSupplyBonus) supply from a hidden oil stash.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, isLandscape ? 12 : 16)
                .padding(.horizontal, 16)
                .background(Theme.panel)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
}
