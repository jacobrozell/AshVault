import SwiftUI

/// Brief celebration when a warden drops a run relic.
struct RunRelicFoundView: View {
    let relic: RunRelic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: relic.icon)
                .font(.system(size: isLandscape ? 44 : 52))
                .foregroundStyle(Theme.gold)
            Text("Run Relic")
                .font(isLandscape ? .title2.bold() : .title.bold())
                .foregroundStyle(Theme.gold)
            Text(relic.title)
                .font(isLandscape ? .title3.bold() : .title2.bold())
            Text(relic.blurb)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Label(relic.synergy.label, systemImage: relic.synergy.icon)
                .font(.caption.bold())
                .foregroundStyle(Theme.mana)
            Button { dismiss() } label: {
                Text("Forge On")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .presentationDetents(isLandscape ? [.fraction(0.5)] : [.medium])
    }
}

/// Combat HUD: equipped sigils, evolutions, and run relic synergies.
struct BuildPanelView: View {
    @EnvironmentObject var engine: GameEngine

    private var synergies: Set<SynergyTag> {
        engine.runBuild.activeSynergies(equipped: engine.sigilLoadout.equipped)
    }

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Build", systemImage: "square.grid.2x2.fill")
                        .font(.caption.bold())
                    Spacer()
                    if synergies.count >= 2 {
                        Label("Synergy", systemImage: "link")
                            .font(.caption2.bold())
                            .foregroundStyle(Theme.gold)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(engine.sigilLoadout.slots.indices, id: \.self) { i in
                        sigilChip(engine.sigilLoadout.slots[i])
                    }
                    Spacer(minLength: 0)
                }
                if !engine.runBuild.runRelics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(engine.runBuild.runRelics) { relic in
                                relicChip(relic)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(buildAccessibilityLabel)
    }

    private var buildAccessibilityLabel: String {
        let sigils = engine.sigilLoadout.equipped.map { SpellCatalog.definition(for: $0).displayName }
        let relics = engine.runBuild.runRelics.map(\.title)
        return "Build: sigils \(sigils.joined(separator: ", ")); relics \(relics.joined(separator: ", "))"
    }

    @ViewBuilder
    private func sigilChip(_ spell: SpellID?) -> some View {
        if let spell {
            let def = SpellCatalog.definition(for: spell)
            let evo = engine.runBuild.evolution(for: spell)
            VStack(spacing: 2) {
                Image(systemName: def.element.sfSymbol)
                    .font(.caption)
                    .foregroundStyle(def.element.color)
                if let evo {
                    Text(evo.title)
                        .font(.system(size: 9, weight: .bold))
                        .lineLimit(1)
                } else if engine.runBuild.ink(for: spell) > 0 {
                    Text("\(engine.runBuild.ink(for: spell)) ink")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 40)
            .background(def.element.color.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(evo != nil ? Theme.gold.opacity(0.8) : Theme.panelStroke))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Theme.panelStroke)
                .frame(width: 44, height: 40)
        }
    }

    private func relicChip(_ relic: RunRelic) -> some View {
        let highlighted = synergies.filter { $0 == relic.synergy }.count >= 2
        return VStack(spacing: 2) {
            Image(systemName: relic.icon)
                .font(.caption)
            Text(relic.synergy.label)
                .font(.system(size: 8, weight: .bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(highlighted ? Theme.gold.opacity(0.25) : Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(highlighted ? Theme.gold : Theme.panelStroke))
        .accessibilityLabel("\(relic.title), \(relic.synergy.label) synergy")
    }
}
