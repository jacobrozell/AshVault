import SwiftUI

/// Scroll container for short run-phase screens (no forced full-height stretch).
struct PhaseScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .frame(maxWidth: .infinity)
        }
    }
}

/// Compact phase title — pairs with RunTopBar caption (no duplicate body copy).
struct RunPhaseTitle: View {
    let title: String
    var emoji: String? = nil
    @Environment(\.isLandscapeLayout) private var isLandscape

    var body: some View {
        VStack(spacing: isLandscape ? 6 : 10) {
            if let emoji {
                ScaledEmoji(emoji, style: isLandscape ? .title2 : .title)
            }
            Text(title)
                .font(.gameDisplay(compactHeight: isLandscape))
                .foregroundStyle(Theme.gold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Uppercase section label for run screens — makes panels scannable at a glance.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption2.weight(.bold))
                }
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.55)
            }
            .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyleBodySecondary()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Persistent run HUD pinned above every in-run phase: settings · stats · withdraw.
struct RunTopBar: View {
    @EnvironmentObject var engine: GameEngine
    var onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 8) {
                settingsButton
                statsScroller
                    .frame(maxWidth: .infinity)
                withdrawButton
                    .layoutPriority(1)
            }

            if engine.phase == .combat {
                combatContextRow
            } else if let caption = phaseCaption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyleBodySecondary()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.actionBar)
        .overlay(alignment: .bottom) {
            Divider().overlay(Theme.panelStroke)
        }
    }

    private var settingsButton: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape.fill")
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.panelStroke))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens settings and abandon run")
    }

    private var statsScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                RunStatPill(label: "Ring", value: "\(engine.layer)", icon: "square.3.layers.3d")
                if engine.phase == .combat {
                    RunStatPill(
                        label: "Foe",
                        value: "\(engine.enemyIndex)/\(Balance.enemiesPerLayer)",
                        icon: "person.fill"
                    )
                }
                RunStatPill(
                    label: "Gold",
                    value: Formatting.short(engine.player.gold),
                    icon: "centsign.circle.fill",
                    tint: Theme.gold
                )
                RunStatPill(
                    label: "Supplies",
                    value: "\(engine.supplies)",
                    icon: "flame.fill",
                    tint: engine.suppliesStarved ? Theme.hpRed : Theme.gold
                )
                RunStatPill(
                    label: "Level",
                    value: "\(engine.player.level)",
                    icon: "arrow.up.circle.fill",
                    tint: Theme.gold
                )
            }
        }
    }

    private var withdrawButton: some View {
        Button { engine.enterAscension() } label: {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Withdraw")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(engine.totalShards)")
                        .font(.caption2.bold().monospacedDigit())
                        .contentTransition(.numericText())
                }
            }
            .foregroundStyle(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.purple.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.35)))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Narrative.Term.withdrawAccessibility(shards: engine.totalShards))
        .accessibilityHint("Opens withdrawal to the Surface Camp")
    }

    /// Combat-only second row: foe context + draft progress on one line.
    private var combatContextRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(combatContextLabel)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text("\(engine.runStats.killsSinceDraft)/\(engine.draftKillsNeeded) kills")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyleBodySecondary()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule()
                        .fill(Theme.gold.opacity(0.85))
                        .frame(width: max(4, geo.size.width * engine.draftKillProgress))
                }
            }
            .frame(height: 5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(combatContextLabel). Draft progress, "
            + "\(engine.runStats.killsSinceDraft) of \(engine.draftKillsNeeded) kills"
        )
    }

    private var combatContextLabel: String {
        let boss = engine.enemy.isBoss ? " · Boss" : ""
        return "vs \(engine.enemy.name)\(boss)"
    }

    private var phaseCaption: String? {
        switch engine.phase {
        case .combat:
            return nil
        case .draft:
            return "Pick one upgrade for this run."
        case .ringChoice:
            return Narrative.Term.wardenFallenChoice
        case .ringIngress:
            return "Entering Ring \(engine.layer). Choose your path."
        case .sealedRoom:
            return "The Vault Heart waits. This choice cannot be undone."
        case .levelUp:
            return "Your delver grows stronger."
        case .shop:
            return "Spend gold before descending again."
        case .ascension:
            return "Bank Ash Shards to grow permanent power."
        case .title, .oathSelect, .defeat, .victory:
            return nil
        }
    }
}

private struct RunStatPill: View {
    let label: String
    let value: String
    let icon: String
    var tint: Color? = nil

    var body: some View {
        Label(value, systemImage: icon)
            .font(.caption2.bold())
            .foregroundStyle(tint ?? .primary.opacity(0.9))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Theme.panel, in: Capsule())
            .overlay(Capsule().stroke(Theme.panelStroke))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label), \(value)")
    }
}

/// Title-screen chrome — settings without overlapping hero stats.
struct TitleTopBar: View {
    var onSettings: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.panelStroke))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens audio settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
