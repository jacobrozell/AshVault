import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let won: Bool

    @State private var appeared = false

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        ScrollFit {
            Group {
                if sideBySide {
                    HStack(alignment: .top, spacing: 16) {
                        heroSection
                        resultsSection
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 20) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                        heroSection
                        resultsSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, isLandscape ? 12 : 0)
        }
        .onAppear { appeared = true }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 10 : 20) {
            if !isLandscape && !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                Spacer(minLength: 12)
            }
            ScaledEmoji(won ? "🌫️" : "💀", style: isLandscape ? .title : .largeTitle)
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.4))
                .rotationEffect(.degrees(reduceMotion ? 0 : (appeared ? 0 : -15)))
                .animation(.spring(response: 0.6, dampingFraction: 0.55), value: appeared)
            Text(won ? "VICTORY!" : "You Died")
                .font(.gameDisplay(compactHeight: isLandscape))
                .adaptiveMinimumScaleFactor(0.75, dynamicTypeSize: dynamicTypeSize)
                .foregroundStyle(won ? Theme.gold : Theme.hpRed)
            Text(won
                 ? Narrative.Term.victorySubtitle
                 : Narrative.Term.defeatSubtitle)
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if engine.setNewRecord {
                Label("New best run!", systemImage: "trophy.fill")
                    .font(.footnote.bold())
                    .foregroundStyle(Theme.gold)
            }
            if !isLandscape && !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                Spacer(minLength: 12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Run Summary", systemImage: "list.bullet.clipboard")
            Panel {
                VStack(alignment: .leading, spacing: 6) {
                    row("Hero", engine.player.name)
                    row("Level reached", "\(engine.player.level)")
                    row("Ring reached", "\(engine.layer) — \(RingName.title(ring: engine.layer))")
                    row("Guardians slain", "\(engine.runStats.enemiesSlain)")
                    row("Gold collected", Formatting.short(engine.player.gold))
                    if engine.lastDeathSalvagedShards > 0 {
                        row("Shards salvaged", "+\(engine.lastDeathSalvagedShards)")
                    }
                    Divider().background(Theme.panelStroke)
                    row("Best ring", "\(engine.best.layer)")
                    row("Best gold", Formatting.short(engine.best.gold))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Run summary. Hero \(engine.player.name). "
                + "Level \(engine.player.level). Ring \(engine.layer). "
                + "Gold \(Formatting.short(engine.player.gold)). "
                + "Best layer \(engine.best.layer). Best gold \(Formatting.short(engine.best.gold))."
            )

            if !engine.runStats.expeditionLog.isEmpty {
                SectionHeader(title: "Expedition Log", systemImage: "map.fill")
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(engine.runStats.expeditionLog.enumerated()), id: \.offset) { _, line in
                            Text("· \(line)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if won {
                Panel {
                    Text(Narrative.Term.progressionAfterVictory)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    engine.continueEndless()
                } label: {
                    actionLabel(Narrative.Term.enterDeepAshVault, Theme.mana)
                }
                .buttonStyle(PressableButtonStyle())
            }

            Button {
                engine.startGame(named: engine.player.name)
            } label: {
                actionLabel(won ? "New Run" : "Try Again", Theme.gold, dark: true)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).bold()
        }
        .font(.subheadline)
    }

    private func actionLabel(_ text: String, _ color: Color, dark: Bool = false) -> some View {
        Text(text)
            .font(isLandscape ? .headline.bold() : .title3.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLandscape ? 10 : 14)
            .background(color)
            .foregroundStyle(dark ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
