import SwiftUI

/// Edit the three sigil slots before a run or between layers at the merchant.
struct SigilLoadoutView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sigil Bench", systemImage: "sparkles")
                .font(isLandscape ? .subheadline.bold() : .headline.bold())
                .foregroundStyle(Theme.mana)

            Text("Slot up to three sigils for combat.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(0..<SigilLoadout.slotCount, id: \.self) { slot in
                slotRow(slot)
            }

            if !unassignedMastered.isEmpty {
                Text("Mastered sigils")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                FlowSigilPicker(spells: unassignedMastered) { spell in
                    if let vacant = engine.sigilLoadout.slots.firstIndex(where: { $0 == nil }) {
                        engine.equipSigil(spell, slot: vacant)
                    }
                }
            }

            if engine.phase == .shop {
                shopScrollsSection
            }
        }
        .padding(cardPadding)
        .background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sigil loadout editor")
    }

    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 12

    private var unassignedMastered: [SpellID] {
        let equipped = Set(engine.sigilLoadout.equipped)
        return SpellID.allCases
            .filter { engine.sigilMastery.mastered.contains($0) && !equipped.contains($0) }
    }

    @ViewBuilder
    private var shopScrollsSection: some View {
        Divider().padding(.vertical, 4)
        Text("Scrolls for sale")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
        ForEach(SpellCatalog.shopScrolls) { spell in
            scrollRow(spell)
        }
    }

    private func slotRow(_ slot: Int) -> some View {
        HStack(spacing: 8) {
            Text("Slot \(slot + 1)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            if let spell = engine.sigilLoadout.slots[slot] {
                let def = SpellCatalog.definition(for: spell)
                HStack {
                    Image(systemName: def.element.sfSymbol)
                    Text(def.displayName)
                        .font(.caption.bold())
                    Spacer()
                    Button {
                        engine.clearSigilSlot(slot)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Clear slot \(slot + 1)")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(def.element.color.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("Vacant sigil slot")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(Theme.panelStroke)
                    )
            }
        }
    }

    private func scrollRow(_ spell: SpellID) -> some View {
        let def = SpellCatalog.definition(for: spell)
        let owned = engine.sigilMastery.mastered.contains(spell)
        let price = engine.sigilScrollPrice(spell)
        let canBuy = engine.canBuySigilScroll(spell)
        return Button {
            engine.buySigilScroll(spell)
        } label: {
            HStack {
                Image(systemName: def.element.sfSymbol)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(def.displayName) scroll")
                        .font(.caption.bold())
                    Text(def.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if owned {
                    Text("Known")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.gold)
                } else {
                    Label(Formatting.short(price), systemImage: "centsign.circle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(10)
            .background(Theme.track)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(owned ? 0.55 : (canBuy ? 1 : 0.45))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(owned || !canBuy)
        .accessibilityLabel(owned ? "\(def.displayName), already mastered" : "\(def.displayName) scroll, \(price) gold")
    }
}

/// Simple wrap of tappable sigil chips for assigning to vacant slots.
private struct FlowSigilPicker: View {
    let spells: [SpellID]
    let onPick: (SpellID) -> Void

    var body: some View {
        FlexibleSigilWrap(spells: spells, onPick: onPick)
    }
}

private struct FlexibleSigilWrap: View {
    let spells: [SpellID]
    let onPick: (SpellID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(spells) { spell in
                let def = SpellCatalog.definition(for: spell)
                Button {
                    onPick(spell)
                } label: {
                    Label(def.displayName, systemImage: def.element.sfSymbol)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(def.element.color.opacity(0.3))
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}
