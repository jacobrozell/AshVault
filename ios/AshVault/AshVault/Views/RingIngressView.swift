import SwiftUI

/// New ring: modifier banner + Hades-style door fork (ring 2+).
struct RingIngressView: View {
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
                        bannerSection
                        doorsSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 22) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 8)
                        }
                        bannerSection
                        doorsSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
    }

    private var bannerSection: some View {
        VStack(spacing: isLandscape ? 10 : 16) {
            ScaledEmoji("🚪", style: isLandscape ? .title : .largeTitle)
            Text("Ring \(engine.layer)")
                .font(.gameDisplay(compactHeight: isLandscape))
                .foregroundStyle(Theme.gold)
            if let mod = engine.currentRingModifier {
                VStack(spacing: 6) {
                    Label(mod.title, systemImage: mod.icon)
                        .font(.headline)
                        .foregroundStyle(Theme.mana)
                    Text(mod.blurb)
                        .font(.gameSubtitle(compactHeight: isLandscape))
                        .multilineTextAlignment(.center)
                        .foregroundStyleBodySecondary()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            }
            suppliesRow
            if let scout = engine.scoutedNextRingModifier, engine.delverOath == .kite {
                kiteScoutBanner(scout)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func kiteScoutBanner(_ mod: RingModifier) -> some View {
        VStack(spacing: 6) {
            Label("Kite scout — Ring \(engine.layer + 1)", systemImage: "wind")
                .font(.caption.bold())
                .foregroundStyle(Theme.gold)
            Label(mod.title, systemImage: mod.icon)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.mana)
            Text(mod.blurb)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyleBodySecondary()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.panel.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.35)))
    }

    private var suppliesRow: some View {
        Label("\(engine.supplies) supplies", systemImage: "flame.fill")
            .font(.caption.bold())
            .foregroundStyle(engine.suppliesStarved ? .red : Theme.gold)
            .accessibilityLabel("\(engine.supplies) supplies remaining")
    }

    private var doorsSection: some View {
        VStack(spacing: 12) {
            Text("Choose a path")
                .font(.headline)
            ForEach(engine.doorOffers) { offer in
                Button {
                    engine.chooseDoor(offer)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: offer.kind.icon)
                            .font(.title2)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(offer.kind.title)
                                .font(.headline)
                            Text(offer.kind.subtitle)
                                .font(.caption)
                                .foregroundStyleBodySecondary()
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .background(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityHint("Enter the \(offer.kind.title) route")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
