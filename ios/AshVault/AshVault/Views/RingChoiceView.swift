import SwiftUI

/// After a warden falls — push deeper or camp to spend gold.
struct RingChoiceView: View {
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
                        heroSection
                        choiceSection
                    }
                } else {
                    VStack(spacing: 14) {
                        heroSection
                        choiceSection
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 8 : 12) {
            RunPhaseTitle(title: "Ring Cleared", emoji: "🛡️")
            Label {
                Text("\(engine.campSupplyCost) supplies to camp")
                    .font(.caption.weight(.semibold))
            } icon: {
                Image(systemName: "flame.fill")
            }
            .foregroundStyle(engine.supplies < engine.campSupplyCost ? Theme.hpRed : Theme.gold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (engine.supplies < engine.campSupplyCost ? Theme.hpRed : Theme.gold).opacity(0.12),
                in: Capsule()
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var choiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Next Step", systemImage: "signpost.right.fill")
            VStack(spacing: 10) {
                Button {
                    engine.pushDeeper()
                } label: {
                    Label("Push Deeper", systemImage: "arrow.down.circle.fill")
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 12 : 14)
                        .background(Theme.gold)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityHint("Skip the shop and enter the next ring")

                Button {
                    engine.enterCamp()
                } label: {
                    Label("Make Camp", systemImage: "tent.fill")
                        .font(isLandscape ? .headline.bold() : .title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 12 : 14)
                        .background(Theme.panelElevated)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityHint("Open the shop to buy supplies before the next ring")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
