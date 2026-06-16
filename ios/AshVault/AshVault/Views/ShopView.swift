import SwiftUI

/// Between-layers shop. Spend gold on consumables and permanent upgrades.
struct ShopView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLandscapeLayout) private var isLandscape
    @State private var appeared = false

    private var gridColumns: [GridItem] {
        let count = isLandscape ? 3 : 2
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    var body: some View {
        ScrollFit {
            Group {
                if isLandscape {
                    HStack(alignment: .top, spacing: 16) {
                        headerSection
                        shopSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 18) {
                        Spacer(minLength: 12)
                        headerSection
                        shopSection
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
        .onAppear { appeared = true }
    }

    private var headerSection: some View {
        VStack(spacing: isLandscape ? 10 : 18) {
            if !isLandscape { Spacer(minLength: 12) }
            ScaledEmoji("🪙", style: isLandscape ? .title2 : .title)
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                .animation(.spring(response: 0.5, dampingFraction: 0.55), value: appeared)
            Text("Merchant")
                .font(.gameDisplay(compactHeight: isLandscape))
                .minimumScaleFactor(0.75)
                .foregroundStyle(Theme.gold)

            Label("\(Formatting.short(engine.player.gold)) gold", systemImage: "centsign.circle.fill")
                .font(isLandscape ? .subheadline.bold() : .headline)
                .foregroundStyle(Theme.gold)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: engine.player.gold)

            if engine.player.potions > 0 || engine.player.ethers > 0 {
                HStack(spacing: 14) {
                    if engine.player.potions > 0 {
                        Text("🧪 ×\(engine.player.potions)").accessibilityLabel("\(engine.player.potions) potions")
                    }
                    if engine.player.ethers > 0 {
                        Text("🔮 ×\(engine.player.ethers)").accessibilityLabel("\(engine.player.ethers) ethers")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if !isLandscape { Spacer(minLength: 12) }
        }
        .frame(maxWidth: isLandscape ? 180 : .infinity)
    }

    private var shopSection: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: gridColumns, spacing: isLandscape ? 8 : 12) {
                ForEach(ShopItem.allCases) { item in
                    itemCard(item)
                }
            }

            MercenaryCampView()

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
        let affordable = engine.canAfford(item)
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
                    .minimumScaleFactor(0.8)
                if !isLandscape {
                    Text(item.blurb)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: isLandscape ? 72 : 96, alignment: .topLeading)
            .padding(isLandscape ? 8 : 12)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(affordable ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
        .accessibilityLabel("\(item.name), \(Formatting.short(cost)) gold")
        .accessibilityHint(affordable ? item.blurb : "Not enough gold")
    }
}
