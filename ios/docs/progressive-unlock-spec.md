# AshVault — Progressive Unlock Onboarding Spec

**Status:** Planned future update (not shipped)  
**Target:** Month 2 polish pass (after core meta systems)  
**Related:** [game-design-spec.md](game-design-spec.md) · [ashvault-narrative-plan.md](ashvault-narrative-plan.md) · [pacing-spec.md](pacing-spec.md) · [long-term-idle.md](long-term-idle.md)

---

## 0. What ships today (baseline)

The live build uses **soft teaching** only — no feature gating beyond one prestige gate.

| System | Current behavior |
|--------|------------------|
| Tutorial | Three lore lines in combat log at `startGame` (`Narrative.Beat.tutorial`) |
| Combat moves | All six visible from fight 1 |
| Auto-battle | Toggle always enabled; label shows "(full auto)" only after automation unlock |
| Consumables | Potion/Ether row always visible in combat |
| Withdraw (✨) | Always visible in combat header |
| Shop | Merchant items + `MercenaryCampView` together, no tab lock |
| Ash Tree | Title link hidden until `totalShards > 0`; reachable from ascension anytime |
| Ash Gallery | Always on title; undiscovered relics show `???` |
| Automation | Hard gate: `totalShards >= Balance.automationUnlockShards` (1) |
| Milestone copy | One-shot combat-log lines for first shard, relic, merc, automation (`Narrative.Beat.milestone*`) |
| Coach marks | None |
| `hasSeen*` flags | Planned in narrative doc; **not** in `MetaStore` yet |

This spec describes the **fully gated progressive unlock** system to replace dump-everything-at-once with teach-by-playing. Implementation is deferred; the doc is the source of truth for when we build it.

---

## 1. Problem & goals

### Problem

New crawlers see six combat moves, shop + merc camp, withdraw, gallery, and idle toggles before they understand any of them. The three-line lore tutorial sets tone but does not teach mechanics. Retention risk: overwhelm on run 1, confusion about Ash Shards until run 2+.

### Goals

1. **Time to first action &lt; 10s** — name entry → Attack within one fight.
2. **One new concept per milestone** — never introduce two major systems in the same beat.
3. **No punitive locks** — core combat always playable; fallbacks prevent soft-locks.
4. **Respect veterans** — grandfather existing saves; no re-tutorial for returning players.
5. **Minimal UI chrome** — combat log + at most two coach overlays; no wizard.

### Non-goals

- Replacing `Narrative.swift` lore bible or renaming code identifiers.
- Gating Ash Tree nodes, merc tiers, or relic drop rates.
- Achievement-screen unlocks (separate Month 2 feature).

---

## 2. Approach: progressive unlock vs. full onboarding

| | Full onboarding (rejected) | Progressive unlock (this spec) |
|--|---------------------------|--------------------------------|
| First minute | Modal tour or multi-screen explain | Fight immediately with 3 moves |
| Teaching | Front-loaded | Contextual, tied to triggers |
| Skip risk | High | N/A — unlocks are gameplay |
| Idle layer | Explained upfront | Earned (automation still at 1 shard) |
| Maintenance | Copy drift vs. UI | Triggers live next to `GameEngine` hooks |

**Decision:** Ship progressive unlock as a **future update**. Until then, keep the current three-line tutorial and existing automation gate.

---

## 3. Design principles

1. **Unlock at the moment of need** — Withdraw after Layer 1 boss; Merc Camp after first purchase; Gallery on title after first relic.
2. **Never lock core combat** — Attack, Dodge, Heal always available from fight 1.
3. **Reveal, don't lecture** — Combat-log beat + optional one-shot coach mark; no multi-step tutorial.
4. **Meta unlocks persist** — Shrine features stay once revealed. Run-scoped unlocks reset each crawl.
5. **Idle layer is earned** — Automation stays at `totalShards >= 1` (existing `automationUnlocked`).
6. **Show locked, don't hide (except Gallery)** — Greyed controls with hints teach what's coming; Ash Gallery is the exception (hidden until first relic).

---

## 4. Resolved product decisions

| Question | Decision |
|----------|----------|
| Move unlock pace | **Spread across Layer 1** — one mana move per kill (enemies 2–4). |
| Withdraw timing | **After Layer 1 boss** (primary). Defeat reinforces if never opened (see §6.2). |
| Coach marks | **Overlays only** for Withdraw (first tap) and Level-up (first screen). Shop/Merc/consumables = combat log only. |
| Ash Gallery on title | **Hidden** until first relic discovered. |
| Implementation timing | **Future update** — spec now, build in phased PRs later. |

---

## 5. Complete unlock matrix

Legend: **Meta** = persists forever · **Run** = resets on `startGame` · **Existing** = already shipped gate

| Feature | Scope | Unlock trigger | Fallback | UI when locked |
|---------|-------|----------------|----------|----------------|
| Attack, Dodge, Heal | Run | `startGame` | — | Always active |
| Heavy Strike | Meta | Kill enemy 2 (L1) | All mana moves on first boss kill | Grey slot + hint |
| Ember Bolt (sigil) | Meta | Kill enemy 3 (L1) | Starter on later runs | Grey sigil slot + hint |
| Venom Lash scroll | Meta | Kill enemy 4 (L1) | Starter Ember on later runs | Grey sigil slot + hint |
| Level-up screen | Run | First boss kill | — | Existing phase gate |
| Shop | Run | First boss kill | — | Existing phase gate |
| Auto-battle toggle | Run | First boss kill | First `phase == .levelUp` | Visible, disabled + hint |
| Consumable row | Run | First potion or ether bought | — | Hidden (not greyed) |
| Mercenary Camp | Meta | First shop purchase (any item) | `gold >= cheapestMercCost` | Tab/section 🔒 |
| Withdraw (✨) | Run | Layer 1 boss killed | First defeat | Hidden in header |
| Ash Tree (title) | Meta | First ascension with shards &gt; 0 | `totalShards >= 1` | Hidden (existing) |
| Automation | Meta | **Existing:** `totalShards >= 1` | — | Settings disabled + hint |
| Ash Gallery (title) | Meta | First relic discovered | `discoveredRelics.count > 0` | Hidden |
| Relic equip UI | Meta | First relic discovered | Same | Gallery read-only until then |
| Deep AshVault CTA | Run | Dragon slain | — | Existing victory flow |
| Offline explainer | Meta | First merc hire | — | One-shot on next `OfflineReportView` |
| Full tree tooltips | Meta | `totalDescents >= 3` | — | Short labels before |

---

## 6. Unlock timeline — first run

### 6.1 Act I — Layer 1 combat

| Trigger | `GameEngine` hook | Unlocks | Combat log (`Narrative.Beat`) |
|---------|-------------------|---------|-------------------------------|
| `startGame` | `startGame()` | Attack, Dodge, Heal | `.unlockMovesIntro` → *"Three moves. Learn the rhythm."* |
| `enemyIndex == 2` killed | `onEnemyKilled()` | Heavy Strike | `.unlockMove(.heavy)` |
| `enemyIndex == 3` killed | `onEnemyKilled()` | Ember Bolt (sigil slot 1) | `.unlockSigil(.emberBolt)` |
| `enemyIndex == 4` killed | `onEnemyKilled()` | Venom Lash scroll (shop) | `.unlockSigilScroll(.venomLash)` |
| First boss kill | `onEnemyKilled()` → level-up | Level-up, Shop, Auto-battle | `.unlockAutoBattle` |

**Locked move slot:** greyed, non-tappable, hint *"Defeat more guardians"*. Optional subtle pulse when one kill away from next move.

**Auto-battle:** toggle visible from fight 1, **disabled** until first boss kill. Hint: *"Unlocked after your first warden."*

**Tutorial lines:** Replace current 3-line lore dump with `.unlockMovesIntro` only at start; layer/boss lore unchanged.

### 6.2 Act II — Shop & withdraw

| Trigger | Hook | Unlocks | Teaching |
|---------|------|---------|----------|
| `phase == .shop` (first time) | `enterShop()` or first shop tick | Merchant grid only | Log: *"Spend gold here. Permanents last the whole run."* |
| First `buy(item)` | `buy(_:)` | Mercenary Camp | `milestoneFirstMercenary` (existing) |
| First potion/ether bought | `buy(_:)` | Consumable row in combat | `.unlockConsumables` |
| Layer 1 boss killed | same as Act I boss | Withdraw ✨ in header | `.unlockWithdraw` |

**Withdraw — first tap:** coach overlay (see §7.2). Flag `hasSeenCoachWithdraw`.

**Withdraw — death without ever opening ascension:** `GameOverView(won: false)` appends `Narrative.Term.defeatWithdrawHint` (no overlay).

**Level-up — first screen:** coach overlay (see §7.2). Flag `hasSeenCoachLevelUp`.

### 6.3 Act III — Meta (cross-run)

| Trigger | Hook | Unlocks | Teaching |
|---------|------|---------|----------|
| `performAscension`, shards gained | `performAscension()` | Ash Tree on title, automation | Existing `milestoneFirstShard`, `milestoneAutomationUnlock` |
| First relic in pool | `rollRelicDrop()` | Ash Gallery on title, equip UI | `milestoneFirstRelic` + title reveal animation |
| First `hireMercenary` | `hireMercenary(_:)` | Offline one-shot | Next `foregrounded()` → extended `OfflineReportView` once |
| Dragon slain | `onVictory` | Deep AshVault | Existing crown-seal beats |
| `totalDescents >= 3` | `startGame` check | Full Ash Tree descriptions | UI-only in `SkillTreeView` |

---

## 7. UI patterns

### 7.1 Locked control

```
┌─────────────────────────────┐
│  🔒  Heavy Strike           │
│  Defeat more guardians      │
└─────────────────────────────┘
```

- 40% opacity, non-tappable.
- `accessibilityLabel`: *"Heavy Strike, locked. Defeat more guardians."*
- Optional: 1px gold pulse on border when `enemyIndex == nextUnlockAfter - 1`.

### 7.2 Coach marks (two only)

| Screen | When | Copy | Dismiss | Flag |
|--------|------|------|---------|------|
| `LevelUpView` | First visit ever | *"Pick one. Bosses make you stronger."* | Tap anywhere | `hasSeenCoachLevelUp` |
| `AscensionView` | First open via ✨ | *"Bank Ash Shards at the Shrine. You lose this run's gold, but shards grow the Ash Tree forever."* | Tap anywhere | `hasSeenCoachWithdraw` |

Implementation: lightweight `CoachMarkOverlay` modifier — dimmed scrim, card + arrow, no multi-step pager. Respects Reduce Motion (fade only, no arrow bounce).

Shop, Merc Camp, consumables: **combat log only** — no overlay.

### 7.3 Ash Gallery (title)

- **Before first relic:** no button on `TitleView`.
- **On first relic:** insert gallery link with short scale-in animation; log + optional haptic `.success`.
- **Mid-run:** `RelicFoundView` sheet unchanged.

### 7.4 Unlock fanfare (polish phase)

- Move unlock: brief gold flash on new button + log line (no full-screen modal).
- Sound: reuse existing reward SFX at low volume.
- Skip fanfare when `accessibilityReduceMotion`.

---

## 8. Narrative copy catalog

Add to `Narrative.swift` when implementing. All player-facing strings stay centralized.

### New `Beat` cases

| Case | Text |
|------|------|
| `.unlockMovesIntro` | *"Three moves. Learn the rhythm."* |
| `.unlockMove(Heavy)` | *"Put your weight behind it — costs mana, hits harder."* |
| `.unlockMove(Magic)` | *"Shape the ash into a bolt."* |
| `.unlockMove(Poison)` | *"A cut that keeps bleeding."* |
| `.unlockAutoBattle` | *"Let the crawl fight while you watch."* |
| `.unlockConsumables` | *"Your potions and ethers are ready in battle."* |
| `.unlockWithdraw` | *"You can retreat to the Shrine — distill this run's gold into Ash Shards."* |
| `.unlockShopIntro` | *"Spend gold here. Permanents last the whole run."* |
| `.unlockMercCamp` | *(reuse `milestoneFirstMercenary`)* |
| `.unlockOfflineCamp` | *"The camp keeps working the upper rings while you're away."* |

### New `Term` strings

| Key | Text |
|-----|------|
| `lockedMoveHint` | *"Defeat more guardians"* |
| `lockedAutoBattleHint` | *"Unlocked after your first warden"* |
| `lockedMercCampHint` | *"Hire sellswords after your first purchase"* |
| `defeatWithdrawHint` | *"Next crawl, withdraw before you fall — the Shrine keeps your ash."* |
| `coachLevelUp` | *"Pick one. Bosses make you stronger."* |
| `coachWithdraw` | *"Bank Ash Shards at the Shrine. You lose this run's gold, but shards grow the Ash Tree forever."* |

---

## 9. Technical design

### 9.1 `Feature` enum (query surface)

```swift
enum Feature: String, CaseIterable, Codable {
  case moveHeavy, moveMagic, movePoison
  case autoBattle, consumables, withdraw
  case mercCamp, ashGallery, ashTree
  case relicEquip, automation
}
```

`GameEngine`:

```swift
func isUnlocked(_ feature: Feature) -> Bool
func unlockHint(for feature: Feature) -> String?
mutating func checkUnlocks(after event: UnlockEvent)
```

Views call `isUnlocked` — no scattered `totalShards` / `enemyIndex` checks in SwiftUI.

### 9.2 `UnlockState` in `MetaStore`

```swift
struct UnlockState: Codable, Equatable {
    // Meta — never reset
    var unlockedMoves: Set<String>       // default: attack, dodge, heal
    var hasUnlockedMercCamp: Bool
    var hasUnlockedAshGallery: Bool
    var hasUnlockedAshTree: Bool
    var hasSeenCoachLevelUp: Bool
    var hasSeenCoachWithdraw: Bool
    var hasSeenOfflineCampHint: Bool

    // Per-run — serialized inside GameSave OR ephemeral on GameEngine
    var runUnlockedAutoBattle: Bool
    var runUnlockedWithdraw: Bool
    var runUnlockedConsumables: Bool
    var runShopPurchases: Int
    var hasOpenedAscension: Bool         // for defeat hint
}
```

**Persistence key:** `meta.unlocks.v1` in `MetaStore`. Per-run fields live in `GameSave` under `unlocks: UnlockState.RunSlice` so mid-run restore preserves gating.

### 9.3 `UnlockEvent` triggers

```swift
enum UnlockEvent {
    case gameStarted
    case enemyKilled(index: Int, layer: Int, wasBoss: Bool)
    case enteredShop
    case purchased(ShopItem)
    case hiredMercenary
    case openedAscension
    case ascended(shardsGained: Int)
    case relicDiscovered
    case defeated
    case descendedCount(Int)
}
```

Call `checkUnlocks(after:)` at the end of each hook; append log beats only when a feature **newly** unlocks.

### 9.4 Grandfather migration

On first load of `meta.unlocks.v1` when key missing, derive from existing data:

```swift
func migrateUnlockState() -> UnlockState {
    var s = UnlockState.default
    let shards = PrestigeStore.loadShards()
    let relics = MetaStore.loadDiscoveredRelics()
    let lifetime = MetaStore.loadLifetime()
    if lifetime.totalBossKills > 0 {
        s.unlockedMoves = Set(Move.allCases.map(\.rawValue))
        s.runUnlockedAutoBattle = true
        s.runUnlockedWithdraw = true
    }
    if shards >= 1 { s.hasUnlockedAshTree = true; /* coaches seen */ }
    if !relics.isEmpty { s.hasUnlockedAshGallery = true }
    if MetaStore.loadMercenaryCounts().values.contains(where: { $0 > 0 }) {
        s.hasUnlockedMercCamp = true
    }
    return s
}
```

Returning players never see coaches or locked moves.

---

## 10. Files to touch (implementation checklist)

| File | Changes |
|------|---------|
| `Models/MetaStore.swift` | `UnlockState`, load/save, migration |
| `Models/GameSave.swift` | Per-run unlock slice in save blob |
| `Models/GameEngine.swift` | `Feature`, `checkUnlocks`, hook calls, defeat hint flag |
| `Models/Narrative.swift` | New beats + terms |
| `Views/CombatView.swift` | Move grid gating, auto toggle disabled, withdraw hidden, consumables hidden |
| `Views/ShopView.swift` | Merc camp lock wrapper |
| `Views/ContentView.swift` (`TitleView`) | Gallery hidden until unlock |
| `Views/LevelUpView.swift` | Coach overlay |
| `Views/AscensionView.swift` | Coach overlay |
| `Views/GameOverView.swift` | Defeat withdraw hint |
| `Views/OfflineReportView.swift` | One-shot camp line |
| `Views/RelicMuseumView.swift` | Equip lock until first relic |
| `Views/CoachMarkOverlay.swift` | **New** — shared modifier |
| `AshVaultTests/UnlockStateTests.swift` | **New** — triggers, fallbacks, migration |
| `AshVaultTests/NarrativeTests.swift` | New beat strings non-empty |

---

## 11. Implementation phases (future PRs)

| Phase | Deliverable | Depends on |
|-------|-------------|------------|
| **A** | `UnlockState` + migration + `Feature` API + tests | — |
| **B** | Layer 1 move gating + kill hooks + log beats | A |
| **C** | Auto-battle disable, consumable hide, shop merc lock | A |
| **D** | Withdraw hide/reveal + defeat hint | A, C |
| **E** | Coach overlays (level-up, withdraw) | D |
| **F** | Ash Gallery title hide + first-relic reveal | A |
| **G** | Offline one-shot, tree tooltip depth, unlock fanfare | F |
| **H** | Docs sync: `game-design-spec.md` § UI, remove "planned" banner here | All |

Ship phases A–D as MVP gated onboarding; E–G as polish. Each phase should be independently testable.

---

## 12. Testing plan

### Unit (`UnlockStateTests`)

- Each `UnlockEvent` flips exactly the expected flags.
- Fallbacks fire when primary trigger skipped (death before boss → withdraw).
- Migration grandfathers veterans with boss kills / shards / relics.
- Per-run state restores from `GameSave` correctly.

### UI / integration

- Fresh install: only 3 moves at fight 1; 6 moves after L1 boss path.
- Coach marks show once; never on second account/device after flag set.
- Gallery absent on title until relic; appears on same run as first drop.

### Regression

- `GameEngineTests`, `MetaProgressionTests`, `NarrativeTests` stay green.
- Layer 1 death rate in playtest ≤ baseline (move gating must not spike difficulty).

---

## 13. Acceptance criteria (done = ship)

- [ ] New player sees ≤3 combat moves until they earn more through play.
- [ ] Withdraw hidden until Layer 1 boss; defeat hint if never opened.
- [ ] Ash Gallery hidden on Shrine until first relic.
- [ ] Exactly two coach overlays in entire game (level-up, withdraw).
- [ ] Veterans with existing saves skip all gates and coaches.
- [ ] All new strings in `Narrative.swift`; no scattered literals.
- [ ] `game-design-spec.md` updated to describe gated vs. legacy behavior.
- [ ] Status in this doc changed to **Shipped** with date.

---

## 14. Success metrics (playtest)

| Metric | Target |
|--------|--------|
| Time to first Attack | &lt; 10s from title |
| Reach first shop without opening Settings | &gt; 90% of playtesters |
| Understand Ash Shards by end of run 2 | Qualitative — can explain withdraw |
| Layer 1 death rate | No increase vs. current build |
| Session 1 length | ≥ one full Layer 1 ring (engagement, not bounce) |

---

## 15. Out of scope (this feature)

- Achievement screen or lifetime-stat unlock trees
- Per–Ash Tree node gating (all five visible when tree opens)
- Cutscenes, voiced lines, branching quests
- Gating endless mode or relic drop rates
- Renaming persistence keys or `SkillNode` / `Relic` types
- Full modal onboarding wizard (alternative rejected in §2)

---

## 16. Relationship to other roadmap items

| Doc / feature | Interaction |
|---------------|-------------|
| [ashvault-narrative-plan.md](ashvault-narrative-plan.md) | Implements proposed `hasSeen*` flags via `UnlockState` |
| [long-term-idle.md](long-term-idle.md) Month 2 | Progressive unlock listed as polish/retention |
| Achievements (Month 2) | Separate; may reuse `LifetimeStats` thresholds |
| Abyss Essence (Month 2) | Do not gate behind this onboarding |
| [future-work.md](future-work.md) | Log entry when implementation starts |

---

## 17. Changelog

| Date | Change |
|------|--------|
| 2026-06-15 | Initial spec from design discussion |
| 2026-06-15 | Decisions locked: spread moves, boss withdraw, two coaches, hide gallery |
| 2026-06-15 | Full doc pass; marked **planned future update** |
