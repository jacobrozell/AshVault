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
            ScaledEmoji("🛡️", style: isLandscape ? .title : .largeTitle)
            Text("Ring Cleared")
                .font(.gameDisplay(compactHeight: isLandscape))
                .foregroundStyle(Theme.gold)
            Text("Ring \(engine.layer) is yours. Push deeper into the vault, or make camp and spend gold.")
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("Camp costs \(engine.campSupplyCost) supplies", systemImage: "flame.fill")
                .font(.caption.bold())
                .foregroundStyle(engine.supplies < engine.campSupplyCost ? .red : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var choiceSection: some View {
        VStack(spacing: 14) {
            Button {
                engine.pushDeeper()
            } label: {
                Label("Push Deeper", systemImage: "arrow.down.circle.fill")
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 12 : 16)
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
                    .padding(.vertical, isLandscape ? 12 : 16)
                    .background(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Open the shop to buy supplies before the next ring")
        }
        .frame(maxWidth: .infinity)
    }
}
