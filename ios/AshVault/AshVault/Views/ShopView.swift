import SwiftUI

/// Between-layers shop. Spend gold on consumables and permanent upgrades.
struct ShopView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 12

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    private var gridColumns: [GridItem] {
        let count = AccessibilityLayout.metaGridColumnCount(
            isLandscape: isLandscape,
            dynamicTypeSize: dynamicTypeSize,
            portraitColumns: 2,
            landscapeColumns: 3
        )
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    private var showsItemBlurb: Bool {
        AccessibilityLayout.showsExpandedCardCopy(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        ScrollFit {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        RunPhaseTitle(title: "Merchant", emoji: "🪙")
                        shopSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 14) {
                        RunPhaseTitle(title: "Merchant", emoji: "🪙")
                        shopSection
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, isLandscape ? 8 : 4)
        }
    }

    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if engine.player.potions > 0 || engine.player.ethers > 0 || engine.player.phoenixAshes > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "In Your Pack", systemImage: "backpack.fill")
                    HStack(spacing: 14) {
                        if engine.player.potions > 0 {
                            Text("🧪 ×\(engine.player.potions)").accessibilityLabel("\(engine.player.potions) potions")
                        }
                        if engine.player.ethers > 0 {
                            Text("🔮 ×\(engine.player.ethers)").accessibilityLabel("\(engine.player.ethers) ethers")
                        }
                        if engine.player.phoenixAshes > 0 {
                            Text("🔥 ×1").accessibilityLabel("Phoenix Ash, one revive remaining")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyleBodySecondary()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Supplies", systemImage: "cart.fill")
                LazyVGrid(columns: gridColumns, spacing: isLandscape ? 8 : 10) {
                    ForEach(ShopItem.allCases) { item in
                        itemCard(item)
                    }
                }
            }

            MercenaryCampView()

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: Narrative.Term.sigilBench, systemImage: "wand.and.stars")
                SigilLoadoutView(showsTitle: false)
            }

            Button {
                engine.leaveShop()
            } label: {
                Text(Narrative.Term.breakSeal(layer: engine.layer))
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 10 : 14)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Leaves the shop and continues the crawl")
        }
        .frame(maxWidth: .infinity)
    }

    private func itemCard(_ item: ShopItem) -> some View {
        let cost = engine.price(item)
        let canBuy = engine.canBuy(item)
        return Button {
            engine.buy(item)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.icon).font(.title2).accessibilityDecorative()
                    Spacer()
                    Label(Formatting.short(cost), systemImage: "centsign.circle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.gold)
                }
                Text(item.name)
                    .font(isLandscape ? .caption.bold() : .subheadline.bold())
                    .adaptiveMinimumScaleFactor(0.85, dynamicTypeSize: dynamicTypeSize)
                    .fixedSize(horizontal: false, vertical: true)
                if showsItemBlurb {
                    Text(item.blurb)
                        .font(.caption2)
                        .foregroundStyleBodySecondary()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(cardPadding)
            .background(Theme.panelElevated)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(canBuy ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!canBuy)
        .accessibilityLabel("\(item.name), \(Formatting.short(cost)) gold")
        .accessibilityHint(canBuy ? item.blurb : "Cannot buy right now")
    }
}
