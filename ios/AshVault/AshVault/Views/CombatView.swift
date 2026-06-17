import SwiftUI

struct CombatView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var movesStackVertically: Bool {
        AccessibilityLayout.combatMovesStackVertically(dynamicTypeSize: dynamicTypeSize)
    }

    @State private var headerShowsLabels = CombatHeaderHints.showsLabels

    private var buildPanelIsCompact: Bool {
        engine.runBuild.runRelics.isEmpty
            && engine.runBuild.activeSynergies(equipped: engine.sigilLoadout.equipped).count < 2
    }

    private var enemySpriteIsCompact: Bool {
        !engine.enemy.isBoss && engine.enemyIndex > 1
    }

    var body: some View {
        Group {
            if isLandscape {
                ScrollFit {
                    landscapeLayout
                }
            } else {
                portraitStickyLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .modifier(Shake(amount: reduceMotion ? 0 : 7,
                        animatableData: CGFloat(engine.shakeTrigger)))
        .animation(.linear(duration: 0.3), value: engine.shakeTrigger)
        // Hybrid idle: ~1 Hz tick drives auto-battle (no-op when it's off).
        .onReceive(Timer.publish(every: Balance.tickSeconds, on: .main, in: .common).autoconnect()) { _ in
            engine.tick()
        }
        .sheet(item: Binding(get: { engine.newRelicFound },
                             set: { engine.newRelicFound = $0 })) { relic in
            RelicFoundView(relic: relic)
        }
        .sheet(item: Binding(get: { engine.newRunRelicFound },
                             set: { engine.newRunRelicFound = $0 })) { relic in
            RunRelicFoundView(relic: relic)
        }
    }

    private var buildPanel: some View {
        BuildPanelView(compact: buildPanelIsCompact)
    }

    /// Portrait: scrollable midsection + sticky auto/moves bar at the bottom.
    private var portraitStickyLayout: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 10) {
                    headerBar
                    buildPanel
                    enemyStage
                    combatLogSection
                    playerStatus
                    consumablesRow
                    sigilButtons
                }
                .padding(.bottom, 8)
            }
            combatActionBar
        }
    }

    private var combatActionBar: some View {
        VStack(spacing: 8) {
            Divider().overlay(Theme.panelStroke)
            autoToggle
            moveButtons
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Theme.actionBar.ignoresSafeArea(edges: .bottom))
    }

    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            headerBar
            buildPanel
            draftInlineBar
            HStack(alignment: .top, spacing: 10) {
                enemyStage
                    .frame(maxWidth: .infinity)
                VStack(spacing: 8) {
                    combatLogSection
                        .frame(minHeight: 88, maxHeight: movesStackVertically ? nil : 200)
                    playerStatus
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 8) {
                    autoToggle
                    consumablesRow
                    sigilButtons
                    moveButtons
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var combatLogSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Event log", systemImage: "text.alignleft")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            CombatLogView(
                lines: engine.log,
                minHeight: isLandscape ? 100 : 160,
                maxHeight: isLandscape ? 180 : 220
            )
        }
    }

    /// Auto-battle on/off control.
    private var autoToggle: some View {
        Button { engine.toggleAuto() } label: {
            Label(autoLabel, systemImage: engine.autoBattle ? "pause.circle.fill" : "play.circle.fill")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(engine.autoBattle ? Theme.mana.opacity(0.85) : Theme.panel)
                .foregroundStyle(engine.autoBattle ? .white : .primary)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.panelStroke))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(engine.autoBattle ? "Double tap to turn off auto-battle" : "Double tap to turn on auto-battle")
    }

    /// Floating combat number for the given target (player vs. enemy), if any.
    @ViewBuilder private func popupOverlay(onPlayer: Bool) -> some View {
        if let p = engine.popup, p.onPlayer == onPlayer {
            FloatingPopup(popup: p, onClear: { engine.clearPopup($0) })
                .id(p.id)
                .allowsHitTesting(false)
        }
    }

    /// Kill-bar progress toward the next draft pick (inline under header).
    private var draftInlineBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption2.bold())
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.panel)
                    Capsule()
                        .fill(Theme.gold.opacity(0.85))
                        .frame(width: max(4, geo.size.width * engine.draftKillProgress))
                }
            }
            .frame(height: 6)
            Text("\(engine.runStats.killsSinceDraft)/\(engine.draftKillsNeeded)")
                .font(.caption2.monospacedDigit())
                .foregroundStyleBodySecondary()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Draft progress, \(engine.runStats.killsSinceDraft) of \(engine.draftKillsNeeded) kills")
    }

    private var headerBar: some View {
        Group {
            if dynamicTypeSize.ashvaultUsesAccessibilityLayout && !isLandscape {
                accessibilityHeaderBar
            } else {
                compactHeaderBar
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var compactHeaderBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                headerStat("Ring \(engine.layer)", icon: "square.3.layers.3d", hint: "Ring")
                Spacer(minLength: 0)
                headerStat("\(engine.supplies)", icon: "flame.fill", hint: "Supplies",
                           tint: engine.suppliesStarved ? .red : Theme.gold)
                Spacer(minLength: 0)
                headerStat("Lv \(engine.player.level)", icon: "arrow.up.circle.fill", hint: "Level", tint: Theme.gold)
                Spacer(minLength: 0)
                headerStat("\(engine.enemyIndex)/\(Balance.enemiesPerLayer)", icon: "person.fill", hint: "Foe")
                Spacer(minLength: 0)
                headerStat(Formatting.short(engine.player.gold), icon: "centsign.circle.fill", hint: "Gold", tint: Theme.gold)
                Spacer(minLength: 0)
                withdrawButton
            }
            if !isLandscape {
                draftInlineBar
            }
        }
        .font(isLandscape ? .caption.bold() : .caption.bold())
        .foregroundStyle(.primary.opacity(0.9))
        .contentShape(Rectangle())
        .onTapGesture {
            if headerShowsLabels {
                headerShowsLabels = false
                CombatHeaderHints.dismiss()
            }
        }
    }

    private func headerStat(_ value: String, icon: String, hint: String, tint: Color? = nil) -> some View {
        VStack(spacing: 2) {
            Label(value, systemImage: icon)
                .foregroundStyle(tint ?? .primary.opacity(0.9))
                .labelStyle(.titleAndIcon)
            if headerShowsLabels {
                Text(hint)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyleBodySecondary()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hint), \(value)")
    }

    /// Two-row header so layer/gold labels do not clip at large text sizes.
    private var accessibilityHeaderBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Ring \(engine.layer)", systemImage: "square.3.layers.3d")
                Spacer()
                Label("\(engine.supplies)", systemImage: "flame.fill")
                    .foregroundStyle(engine.suppliesStarved ? .red : Theme.gold)
                Spacer()
                Label("Lv \(engine.player.level)", systemImage: "arrow.up.circle.fill")
                    .foregroundStyle(Theme.gold)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: engine.player.level)
                Spacer()
                Label("\(engine.enemyIndex)/\(Balance.enemiesPerLayer)", systemImage: "person.fill")
            }
            HStack {
                Label(Formatting.short(engine.player.gold), systemImage: "centsign.circle.fill")
                    .foregroundStyle(Theme.gold)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: engine.player.gold)
                Spacer()
                withdrawButton
            }
            if !isLandscape {
                draftInlineBar
            }
        }
        .font(.subheadline.bold())
        .foregroundStyle(.primary.opacity(0.85))
    }

    private var withdrawButton: some View {
        Button { engine.enterAscension() } label: {
            Label("\(engine.totalShards)", systemImage: "sparkles")
                .foregroundStyle(.purple)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Narrative.Term.withdrawAccessibility(shards: engine.totalShards))
        .accessibilityHint("Opens withdrawal to the Shrine")
    }

    private var enemyStage: some View {
        Panel(elevated: true) {
            VStack(spacing: 10) {
                HStack {
                    Text(engine.enemy.name)
                        .font(.headline)
                        .foregroundStyle(Theme.tint(engine.enemy.tint))
                    aspectBadge(engine.enemy.aspect)
                    if engine.enemy.isBoss {
                        Text("BOSS")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.hpRed)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("Lv \(engine.enemy.level)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                StatusBadges(statuses: engine.enemy.statuses)
                enemySprite
                StatBar(value: engine.enemy.hp, maxValue: engine.enemy.maxHp,
                        tint: Theme.hpRed, label: "Enemy HP")
                HStack(spacing: 16) {
                    statChip("burst.fill", engine.enemy.attack)
                    statChip("shield.lefthalf.filled", engine.enemy.defense)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(enemyAccessibilityLabel)
    }

    private var enemyAccessibilityLabel: String {
        var parts = [engine.enemy.name, "level \(engine.enemy.level)"]
        if engine.enemy.isBoss { parts.append("boss") }
        parts.append("\(engine.enemy.aspect.displayName) aspect")
        parts.append("\(engine.enemy.hp) of \(engine.enemy.maxHp) hit points")
        parts.append("attack \(engine.enemy.attack), defense \(engine.enemy.defense)")
        return parts.joined(separator: ", ")
    }

    /// Enemy sprite: gently idles, flashes on hit, and animates in on spawn.
    private var enemySprite: some View {
        let compact = enemySpriteIsCompact
        let size: CGFloat = compact ? (isLandscape ? 44 : 56) : (isLandscape ? 56 : 72)
        return Text(engine.enemy.sprite)
            .font(.system(compact ? (isLandscape ? .title3 : .title) : (isLandscape ? .title : .largeTitle)))
            .accessibilityDecorative()
            .frame(width: size, height: size)
            .background(Theme.tint(engine.enemy.tint).opacity(0.2))
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.tint(engine.enemy.tint).opacity(0.5), lineWidth: 2))
            .scaleEffect(engine.enemyFlash ? 1.15 : 1.0)
            .opacity(engine.enemyFlash ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: engine.enemyFlash)
            .modifier(IdleBob())
            .id(engine.spawnCounter)
            .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(insertion: .scale(scale: 0.4).combined(with: .opacity),
                                      removal: .opacity))
            .animation(reduceMotion ? .easeInOut(duration: 0.25)
                                    : .spring(response: 0.45, dampingFraction: 0.6),
                       value: engine.spawnCounter)
            .overlay(alignment: .top) { popupOverlay(onPlayer: false).offset(y: -8) }
            .onChange(of: engine.enemyFlash) { flash in
                if flash {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        engine.enemyFlash = false
                    }
                }
            }
    }

    private var playerStatus: some View {
        Panel(elevated: true) {
            VStack(spacing: 8) {
                HStack {
                    Text(engine.player.name).font(.headline)
                    Spacer()
                    Text("Lv \(engine.player.level)")
                        .font(.caption.bold().monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.gold.opacity(0.25))
                        .foregroundStyle(Theme.gold)
                        .clipShape(Capsule())
                }
                StatusBadges(statuses: engine.player.statuses)
                StatBar(value: engine.player.hp, maxValue: engine.player.maxHp,
                        tint: Theme.hpGreen, label: "HP")
                StatBar(value: engine.player.mana, maxValue: engine.player.maxMana,
                        tint: Theme.mana, label: "Mana")
                HStack(spacing: 16) {
                    statChip("burst.fill", engine.player.attack)
                    statChip("shield.lefthalf.filled", engine.player.defense)
                    statChip("dice.fill", engine.player.luck)
                    if engine.mercenaryDPS > 0 {
                        Label("+\(engine.mercenaryDPS)", systemImage: "person.3.fill")
                            .foregroundStyle(Theme.mana)
                    }
                    if engine.damageReduction > 0 {
                        Label("\(Int(engine.damageReduction * 100))%", systemImage: "shield.fill")
                            .foregroundStyle(.purple)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(playerAccessibilityLabel)
        .overlay(alignment: .top) { popupOverlay(onPlayer: true).offset(y: -6) }
        .scaleEffect(engine.playerFlash ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: engine.playerFlash)
        .onChange(of: engine.playerFlash) { flash in
            if flash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    engine.playerFlash = false
                }
            }
        }
    }

    private var playerAccessibilityLabel: String {
        "\(engine.player.name), level \(engine.player.level), "
        + "\(engine.player.hp) of \(engine.player.maxHp) hit points, "
        + "\(engine.player.mana) of \(engine.player.maxMana) mana, "
        + "attack \(engine.player.attack), defense \(engine.player.defense), luck \(engine.player.luck)"
    }

    /// Quick-use consumables, shown only when the player is carrying some.
    @ViewBuilder private var consumablesRow: some View {
        if engine.player.potions > 0 || engine.player.ethers > 0 || engine.player.phoenixAshes > 0 {
            HStack(spacing: 10) {
                if engine.player.phoenixAshes > 0 {
                    passiveConsumableBadge("🔥", "Phoenix Ash", hint: "Auto-revive once if you fall")
                }
                if engine.player.potions > 0 {
                    consumableButton("🧪", "Potion", count: engine.player.potions) {
                        engine.usePotion()
                    }
                }
                if engine.player.ethers > 0 {
                    consumableButton("🔮", "Ether", count: engine.player.ethers) {
                        engine.useEther()
                    }
                }
            }
        }
    }

    private func consumableButton(_ icon: String, _ name: String,
                                  count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon).accessibilityDecorative()
                Text("\(name) ×\(count)").font(.caption.bold())
            }
            .padding(.vertical, 8).padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Use \(name), \(count) remaining")
    }

    private func passiveConsumableBadge(_ icon: String, _ name: String, hint: String) -> some View {
        HStack(spacing: 6) {
            Text(icon).accessibilityDecorative()
            Text(name).font(.caption.bold())
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Theme.panel.opacity(0.85))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.gold.opacity(0.45)))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel("\(name). \(hint)")
    }

    private var autoLabel: String {
        guard engine.autoBattle else { return "Auto-Battle: Off" }
        return engine.automationUnlocked ? "Auto-Battle: On (full auto)" : "Auto-Battle: On"
    }

    private func aspectBadge(_ aspect: Element) -> some View {
        HStack(spacing: 3) {
            Image(systemName: aspect.sfSymbol)
            Text(aspect.displayName)
        }
        .font(.caption2.bold())
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(aspect.color.opacity(0.25))
        .foregroundStyle(aspect.color)
        .clipShape(Capsule())
        .accessibilityLabel("\(aspect.displayName) aspect")
    }

    private var sigilButtons: some View {
        HStack(spacing: isLandscape ? 6 : 8) {
            ForEach(0..<SigilLoadout.slotCount, id: \.self) { slot in
                sigilButton(slot: slot)
            }
        }
    }

    private func sigilButton(slot: Int) -> some View {
        Group {
            if let spell = engine.sigilLoadout.slots[slot] {
                sigilMoveButton(spell)
            } else {
                vacantSigilButton(slot: slot)
            }
        }
    }

    private func sigilMoveButton(_ spell: SpellID) -> some View {
        let def = SpellCatalog.definition(for: spell)
        let affordable = engine.player.mana >= def.manaCost
        let eff = TypeChart.effectiveness(
            spellElement: def.element,
            enemyAspect: engine.enemy.aspect,
            enemyTags: engine.enemy.tags
        )
        return Button {
            engine.performSigil(spell)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: def.element.sfSymbol)
                    Text(def.displayName)
                        .font(isLandscape ? .caption2.bold() : .caption.bold())
                        .lineLimit(1)
                }
                Text(def.subtitle)
                    .font(.caption2)
                    .opacity(0.9)
                    .lineLimit(1)
                Text("\(def.manaCost) mana")
                    .font(.caption2)
            }
            .padding(.vertical, isLandscape ? 8 : 10)
            .padding(.horizontal, isLandscape ? 6 : 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(def.element.color.opacity(affordable ? 0.75 : 0.35))
            .foregroundStyle(.white)
            .overlay(sigilEffectivenessBorder(eff))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(affordable ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
        .accessibilityLabel(sigilAccessibilityLabel(def, affordable: affordable, effectiveness: eff))
    }

    private func sigilEffectivenessBorder(_ eff: Effectiveness) -> some View {
        Group {
            switch eff {
            case .weak:
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.gold, lineWidth: 2)
            case .resist:
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color.white.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                    )
            case .neutral:
                EmptyView()
            }
        }
    }

    private func vacantSigilButton(slot: Int) -> some View {
        Text("Vacant")
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
            .padding(.vertical, isLandscape ? 8 : 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Theme.panelStroke)
            )
            .accessibilityLabel("Vacant sigil slot \(slot + 1)")
    }

    private func sigilAccessibilityLabel(_ def: SpellDefinition, affordable: Bool,
                                         effectiveness: Effectiveness) -> String {
        var label = "\(def.displayName), \(def.element.displayName) sigil, \(def.manaCost) mana"
        switch effectiveness {
        case .weak:    label += ", super effective"
        case .resist:  label += ", not very effective"
        case .neutral: break
        }
        if !affordable { label += ", not enough mana" }
        return label
    }

    private var moveButtons: some View {
        Group {
            if movesStackVertically {
                VStack(spacing: 10) {
                    ForEach(Move.allCases) { moveButton($0) }
                }
            } else {
                let columns = isLandscape
                    ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                    : [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: isLandscape ? 6 : 10) {
                    ForEach(Move.allCases) { moveButton($0) }
                }
            }
        }
        .padding(.bottom, 6)
    }

    private func moveButton(_ move: Move) -> some View {
        let affordable = engine.player.mana >= move.manaCost
        return Button {
            engine.perform(move)
        } label: {
            HStack {
                Image(systemName: move.sfSymbol)
                VStack(alignment: .leading, spacing: 1) {
                    Text(move.displayName)
                        .font(isLandscape ? .caption.bold() : .subheadline.bold())
                        .lineLimit(movesStackVertically ? nil : 1)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(move.subtitle)
                        .font(.caption2)
                        .opacity(0.9)
                        .lineLimit(movesStackVertically ? nil : 1)
                        .fixedSize(horizontal: false, vertical: true)
                    if move.manaCost > 0 {
                        Text("\(move.manaCost) mana").font(.caption2)
                    }
                }
                Spacer()
            }
            .padding(.vertical, movesStackVertically ? 14 : (isLandscape ? 8 : 12))
            .padding(.horizontal, isLandscape ? 8 : 12)
            .frame(maxWidth: .infinity)
            .background(buttonColor(move))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(affordable ? 1 : 0.4)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
        .accessibilityLabel(moveAccessibilityLabel(move, affordable: affordable))
        .accessibilityHint(affordable ? "Performs \(move.displayName)" : "Not enough mana")
    }

    private func moveAccessibilityLabel(_ move: Move, affordable: Bool) -> String {
        var label = "\(move.displayName), \(move.subtitle)"
        if move.manaCost > 0 {
            label += ", \(move.manaCost) mana"
        }
        return label
    }

    private func buttonColor(_ move: Move) -> Color {
        switch move {
        case .attack: return Color.red.opacity(0.7)
        case .heavy:  return Color.orange.opacity(0.7)
        case .dodge:  return Color.teal.opacity(0.7)
        case .heal:   return Theme.hpGreen.opacity(0.8)
        }
    }

    private func statChip(_ symbol: String, _ value: Int) -> some View {
        Label("\(value)", systemImage: symbol)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: value)
    }
}

/// Row of small status pills (🔥 Burn, ☠️ Poison ×n, 💫 Stun, …) with the
/// turns remaining. Renders nothing when there are no statuses.
private struct StatusBadges: View {
    let statuses: [StatusEffect]
    var body: some View {
        if !statuses.isEmpty {
            HStack(spacing: 6) {
                    ForEach(statuses) { s in
                    HStack(spacing: 2) {
                        Text(s.kind.badge).accessibilityDecorative()
                        if s.stacks > 1 { Text("×\(s.stacks)").font(.caption2.bold()) }
                        Text("\(s.turnsRemaining)").font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Theme.track)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(s.kind.label), \(s.stacks) stacks, \(s.turnsRemaining) turns left")
                }
                Spacer(minLength: 0)
            }
            .font(.caption2)
            .transition(.opacity)
        }
    }
}

/// A slow, looping vertical float to give sprites a sense of life.
/// Honours Reduce Motion by staying still.
private struct IdleBob: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false
    func body(content: Content) -> some View {
        content
            .offset(y: (up && !reduceMotion) ? -6 : 4)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: up)
            .onAppear { if !reduceMotion { up = true } }
    }
}

/// A combat number/word that rises and fades over a combatant, then removes
/// itself via `onClear`. Honours Reduce Motion (fades in place, no travel).
private struct FloatingPopup: View {
    let popup: CombatPopup
    let onClear: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        Text(popup.text)
            .font(popup.flavor == .crit || popup.flavor == .weak ? .title3.weight(.heavy) : .headline.bold())
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            .scaleEffect((popup.flavor == .crit || popup.flavor == .weak) && !animate && !reduceMotion ? 1.4 : 1.0)
            .offset(y: (animate && !reduceMotion) ? -44 : 0)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { animate = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { onClear(popup.id) }
            }
    }

    private var color: Color {
        switch popup.flavor {
        case .damage: return Theme.hpRed
        case .crit:   return Theme.gold
        case .weak:   return Theme.gold
        case .heal:   return Theme.hpGreen
        case .miss:   return .secondary
        }
    }
}

/// Auto-scrolling combat log.
struct CombatLogView: View {
    let lines: [LogLine]
    var minHeight: CGFloat = 160
    var maxHeight: CGFloat = 220

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if lines.isEmpty {
                        Text("Combat events appear here.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("placeholder")
                    }
                    ForEach(lines) { line in
                        Text(line.text)
                            .font(font(for: line.kind))
                            .lineSpacing(3)
                            .foregroundStyle(color(for: line.kind))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, line.spacedAbove ? 10 : 0)
                            .id(line.id)
                            .accessibilityLabel(line.text)
                    }
                }
                .padding(12)
            }
            .scrollIndicators(.visible)
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .background(Theme.logBackground)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Combat log")
            .accessibilityValue(lines.last?.text ?? "No events yet")
            .accessibilityAddTraits(.updatesFrequently)
            .onAppear { scrollToLatest(proxy) }
            .onChange(of: lines.last?.id) { _ in scrollToLatest(proxy) }
        }
    }

    private func font(for kind: LogLine.Kind) -> Font {
        switch kind {
        case .system, .danger, .reward:
            return .callout.weight(.semibold)
        default:
            return .callout
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard let last = lines.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func color(for kind: LogLine.Kind) -> Color {
        switch kind {
        case .info:      return .primary
        case .playerHit: return Theme.hpGreen
        case .enemyHit:  return Theme.hpRed
        case .miss:      return .secondary
        case .reward:    return Theme.logGold
        case .system:    return Theme.mana
        case .danger:    return Theme.hpRed
        }
    }
}
