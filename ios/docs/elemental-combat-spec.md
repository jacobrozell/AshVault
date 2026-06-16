# AshVault — Elemental Combat & Sigil Loadout Spec

**Status:** Shipped (June 2026)  
**Audience:** Implementers, balance, narrative, QA  
**Related:** [game-design-spec.md](game-design-spec.md) §3 · [beta-feedback-todo.md](beta-feedback-todo.md) · [progressive-unlock-spec.md](progressive-unlock-spec.md) · [pacing-spec.md](pacing-spec.md) · [future-work.md](future-work.md) · [ashvault-narrative-plan.md](ashvault-narrative-plan.md)

**Code touchpoints (today):** `Move`, `GameEngine` (`performSigil`, `resolveSigil`, `resolvePoison`, `autoAction`, `autoShop`), `SpellCatalog`, `TypeChart`, `DamagePipeline`, `Enemy` / `EnemyKind` / `Bestiary`, `CombatView`, `SigilLoadoutView`, `ShopView`, `Balance`, `Narrative`, `GameSave`, `MetaStore`

---

## 1. Executive summary

Beta testers asked for **Pokémon-style enemy weaknesses** and **more engaging magic**. This spec replaces the single **Magic Bolt** with a **sigil (spell) system**: typed enemies, typed spells, effectiveness multipliers, and **three dedicated spell buttons** in combat — like choosing moves in a monster battle.

**Player-facing promise:**  
*"Read the guardian's aspect. Slot your sigils before the crawl. Cast the right one."*

**Design contract:**

| Principle | Meaning |
|-----------|---------|
| **Read the foe** | Every enemy shows its **aspect** (element type). Spells show theirs. |
| **Three sigil slots** | Combat always exposes **three spell buttons** — your equipped loadout. |
| **Loadout is a choice** | Equip / swap sigils **before a run** and again **between layers** (shop). |
| **Start small** | **v1 ships four sigils** (Ember, Frost, Venom, Arc); players equip up to three at once. |
| **Physical stays simple** | Attack / Heavy / Dodge / Heal stay **untyped**; Venom damage is a **sigil** (Venom Lash). |
| **Weak = ×1.5 + WEAK!** | Super-effective hits use a **1.5× damage multiplier** and a distinct **WEAK!** popup (not stacked with crit). |
| **Future-ready casting** | All spell resolution goes through **`SpellCastResolver`**; v1 is instant; v2 adds rune-tracing minigame. |

**Not in v1:** Rune-tracing minigame, player resistances, dual-type enemies, type-based achievements, full 5-spell catalog.

---

## 2. Problem statement

### 2.1 Beta feedback

From [beta-feedback-todo.md](beta-feedback-todo.md):

| Item | This spec |
|------|-----------|
| **Enemy weaknesses (Pokémon-style)** | Enemy aspects + spell effectiveness chart |
| **Magic casting minigame** | Architecture only (`SpellCastResolver`); rune UI deferred to §12 |

Related:

- **Poison needs a purpose** — Poison Dagger gains **Venom typing** on direct hit; deeper poison rebalance stays separate.
- Mana moves feel samey — loadout + typing differentiates **which** spell to press.

### 2.2 Product fit

Adds a **per-encounter readable puzzle** without breaking idle flow:

- Manual play: pick the super-effective sigil (Pokémon move selection).
- Auto-battle: engine picks best affordable equipped sigil vs current enemy aspect.
- Meta: buying / unlocking sigils and curating a 3-slot loadout between layers.

### 2.3 Resolved product decisions

| # | Question | **Decision** |
|---|----------|--------------|
| 1 | Weak hit math | **×1.5 damage** + **WEAK!** popup + flavor log line. **No crit stack** on spells in v1. |
| 2 | Initial spell count | **2 spells** in catalog at launch (**Ember Bolt**, **Frost Shard**). Third combat slot **vacant** until a future sigil ships. |
| 3 | Poison Dagger typing | **Tag Venom** on direct hit; DoT remains untyped (bypasses DEF as today). |
| 4 | Combat UI | **Three separate spell buttons** (Pokémon-style), driven by **equipped loadout** — not a picker sheet mid-fight. |
| 5 | When loadout changes | **Before run** (title / pre-crawl) **and** **between layers** (shop phase). Locked during combat. |
| 6 | Resist math | **×0.5** damage, minimum 1. Neutral = ×1.0. |

---

## 3. Player experience

### 3.1 Core loop

```
Title / pre-run
    └── Sigil Loadout (pick up to 3 from mastered sigils)
            └── startGame → combat

Combat
    └── Enemy panel shows aspect badge (e.g. "Stone")
    └── Three spell buttons = equipped loadout (empty slot greyed)
    └── Player picks sigil → damage through type chart → WEAK! / normal / resist feedback
    └── Physical row unchanged (Attack, Heavy, Poison, Dodge, Heal)

Boss defeated → level-up → shop
    └── Merchant (existing items)
    └── Sigil Bench (NEW): buy sigil scrolls, rearrange loadout
    └── Continue → next layer combat (loadout locked until next shop)
```

### 3.2 v1 spell catalog & slots

| Spell | Element | Mana | Replaces | Status | Unlock (v1) |
|-------|---------|------|----------|--------|-------------|
| **Ember Bolt** | Ember | 8 | Magic Bolt | 35% burn (unchanged) | **Starter** — equipped slot 1 by default |
| **Frost Shard** | Frost | 6 | — | — | **Shop scroll** — 45g |
| **Arc Lance** | Arc | 10 | — | — | **Shop scroll** — 55g |

**Combat buttons (spell row):**

```
[ Ember Bolt ]  [ Frost Shard ]  [ Arc Lance ]
```

Unmastered sigils show as vacant slots in combat. Buy scrolls at the **Sigil Bench** in shop.

### 3.3 Loadout rules

| Rule | Detail |
|------|--------|
| Slot count | **3** fixed slots (Pokémon move bar size − 1). |
| Equip limit | Up to **3** distinct mastered sigils; duplicates **not** allowed. |
| Empty slots | Allowed — vacant button disabled in combat. |
| When editable | `Phase.title` (pre-run sheet), `Phase.shop` (Sigil Bench). **Not** in `Phase.combat`. |
| Run persistence | Loadout saved in `GameSave` for resume mid-run. |
| Meta persistence | `masteredSigils` in `MetaStore` (or `PrestigeStore` if preferred — see §4.2). |

### 3.4 Effectiveness feedback

| Result | Damage | Popup | Log example |
|--------|--------|-------|-------------|
| **Weak** (super-effective) | ×1.5 (after DEF rules) | `WEAK! −N` (gold, crit-like) | *"The sigil finds its mark — super effective!"* |
| **Neutral** | ×1.0 | `−N` | *"Your Ember Bolt sears Goblin for N!"* |
| **Resist** | ×0.5 (min 1) | `−N` (smaller emphasis) | *"The guardian shrugs off the sigil."* |

SFX: weak → reuse `.crit` or add `spellWeak` later; neutral → `.magic`; resist → `.magic` at lower gain.

### 3.5 Discovery & teaching

| Trigger | `Narrative.Beat` | Copy direction |
|---------|------------------|----------------|
| First typed enemy | `.aspectIntro` | *"This one bears the Stone aspect. Match your sigil."* |
| First weak hit | `.aspectWeak` | *"The ash remembers what burns what."* |
| First resist | `.aspectResist` | *"Wrong sigil. The guardian barely flinches."* |
| First shop sigil | `.sigilScroll` | *"A scrap of ritual. Slot it before the next ring."* |
| Pre-run loadout | `.loadoutIntro` | *"Three sigils. Choose before you descend."* |

Align with [progressive-unlock-spec.md](progressive-unlock-spec.md) when that ships: replace generic Magic Bolt unlock with **Ember Bolt**; Frost scroll appears after first boss shop.

### 3.6 Copy tone

- Player is an **ash-crawler**; spells are **sigils** or **rites**, not "MP skills."
- Enemy types are **aspects** (not "Goblin type").
- Avoid Pokémon trademark language in UI ("super effective" is fine — it's generic).

All strings in `Narrative` (`Narrative.Sigil`, `Narrative.Aspect`), not scattered in views.

---

## 4. Architecture

### 4.1 System diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Title / Shop (SigilLoadoutEditor)                                        │
│   masteredSigils (meta) + equippedLoadout[3] (run) + buy scrolls       │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ CombatView                                                               │
│   enemy aspect badge │ 3 × spell buttons (from loadout) │ physical row  │
│   [future] RuneCastView when Phase.casting                               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ GameEngine.perform(spell)                                                │
│   → SpellCastResolver.resolve → CastResult.damageMultiplier              │
│   → DamagePipeline.spellDamage → TypeChart.effectiveness                 │
│   → takeHit, popups, log, status procs, enemyRetaliates                  │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼
   Spell.swift           TypeChart.swift        EnemyKind.aspect
   Element.swift         DamagePipeline.swift   Bestiary table
```

### 4.2 Data model

#### 4.2.1 `Element` & `EnemyTag`

```swift
/// Elements used by sigils (and enemy aspects).
enum Element: String, CaseIterable, Codable {
    case ember, frost, arc, venom, stone
}

/// Extra chart keys for enemies (not used by sigils directly).
enum EnemyTag: String, Codable, Hashable {
    case wild, fey, undead, wyrm
}
```

Player-facing names: Ember, Frost, Arc, Venom, Stone. Icons: `flame.fill`, `snowflake`, `bolt.fill`, `drop.fill`, `mountain.2.fill`.

#### 4.2.2 `SpellID` & `SpellDefinition`

```swift
enum SpellID: String, CaseIterable, Codable, Identifiable {
    case emberBolt
    case frostShard
    // v1.5: arcLance
}

struct SpellDefinition {
    let id: SpellID
    let displayName: String
    let subtitle: String
    let element: Element
    let manaCost: Int
    let flatBonus: Int
    let ignoresDefense: Bool
    let burnChancePercent: Int?   // ember only
    let castingStyle: CastingStyle
    let shopScrollPrice: Int?     // nil = not sold in shop (starter)
}

enum CastingStyle: Equatable {
    case instant
    case runeTrace(RuneShape)    // future — §12
}
```

Static catalog: `SpellCatalog.all`, `SpellCatalog.definition(for:)`.

#### 4.2.3 Loadout & mastery

```swift
/// Three Pokémon-style move slots. `nil` = vacant.
struct SigilLoadout: Codable, Equatable {
    static let slotCount = 3
    var slots: [SpellID?]   // count always 3

    var equipped: [SpellID] { slots.compactMap { $0 } }
}

struct SigilMastery: Codable, Equatable {
  /// Sigils permanently learned (meta). Starter includes emberBolt.
  var mastered: Set<SpellID>
}
```

**Persistence:**

| Field | Store | Survives |
|-------|-------|----------|
| `mastered` | `MetaStore` key `meta.sigils.v1` | Death, ascension, new runs |
| `loadout` | `GameSave` run blob | App close; cleared on death |
| `loadout` (draft) | Optional: edit on title before `startGame` copies into run | — |

**v1 starter state:** `mastered = [.emberBolt]`, `loadout.slots = [.emberBolt, nil, nil]`.

#### 4.2.4 `EnemyKind` extension

```swift
struct EnemyKind {
    let name: String
    let sprite: String
    let tint: String
    let aspect: Element
    let tags: Set<EnemyTag>
}
```

`Enemy` copies `aspect` and `tags` at `init` for combat + UI.

#### 4.2.5 `Move` enum migration

**Remove:** `case magic = "Magic Bolt"`

**Physical / utility (unchanged cases):** `attack`, `heavy`, `poison`, `dodge`, `heal`

**Spells are NOT `Move` cases.** Spells are a parallel action type:

```swift
enum CombatAction: Equatable {
    case move(Move)
    case sigil(SpellID)
}
```

`GameEngine.perform(_ action: CombatAction)` — or `performSigil(_ id: SpellID)` alongside `perform(_ move: Move)`.

`CombatView` renders:
- **Sigil row:** `ForEach(loadout.slots)` → spell button or vacant placeholder
- **Move row:** existing `Move` grid minus removed `.magic`

This keeps `Move.allCases` stable for Attack/Heavy/Poison/Dodge/Heal and avoids stuffing variable spell count into `Move`.

#### 4.2.6 `TypeChart` (pure)

```swift
enum Effectiveness: Double {
    case weak = 1.5
    case neutral = 1.0
    case resist = 0.5
}

enum TypeChart {
    static func effectiveness(
        spellElement: Element,
        enemyAspect: Element,
        enemyTags: Set<EnemyTag>
    ) -> Effectiveness
}
```

Chart logic (v1):

| Spell → | Weak vs (×1.5) | Resist vs (×0.5) |
|---------|----------------|------------------|
| **Ember** | Frost aspect, Venom aspect, Undead tag | Stone aspect |
| **Frost** | Ember aspect, Wild tag | Venom aspect |
| **Arc** *(v1.5)* | Stone aspect, Undead tag | Ember aspect |
| **Venom** *(poison hit)* | Stone aspect, Fey tag | Frost aspect, Arc aspect |
| **Stone** | — | — |

Neutral when no row matches. **Wild / Fey / Undead / Wyrm** are tags that modify chart without being spell elements.

#### 4.2.7 `DamagePipeline`

```swift
struct SpellDamageRequest {
    let spell: SpellDefinition
    let attackerAttack: Int
    let targetDefense: Int
    let targetAspect: Element
    let targetTags: Set<EnemyTag>
    let castMultiplier: Double
}

struct SpellDamageResult {
    let baseDamage: Int
    let finalDamage: Int
    let effectiveness: Effectiveness
}

enum DamagePipeline {
    static func spellDamage(_ req: SpellDamageRequest) -> SpellDamageResult
}
```

Poison direct hit uses same pipeline with a synthetic `SpellDefinition` for Venom (half ATK − DEF, no `ignoresDefense`).

#### 4.2.8 `SpellCastResolver` (injection point)

```swift
enum CastQuality { case perfect, clean, partial, fumbled }

struct CastResult {
    let quality: CastQuality
    var damageMultiplier: Double { ... }
}

protocol SpellCastResolver: AnyObject {
    func resolve(spell: SpellID, engine: GameEngine) -> CastResult
}

final class InstantSpellCastResolver: SpellCastResolver {
    func resolve(spell: SpellID, engine: GameEngine) -> CastResult {
        .init(quality: .clean)  // damageMultiplier 1.0
    }
}
```

`GameEngine` holds `var castResolver: SpellCastResolver = InstantSpellCastResolver()`.

**Future:** `RuneTraceSpellCastResolver` sets `phase = .casting`, returns after minigame via `completeCast(_:)`.

### 4.3 Shop: Sigil Bench

New section in `ShopView` (or sibling `SigilBenchView` embedded in shop scroll).

| Action | Cost | Effect |
|--------|------|--------|
| **Frost Shard scroll** | 45g | Adds `frostShard` to `mastered`; auto-slots into first vacant loadout slot |
| **Arc Lance scroll** | 55g | Adds `arcLance` to `mastered`; auto-slots if a slot is vacant |

Rules:

- Cannot buy duplicate scrolls (already mastered → greyed *"Sigil already bound"*).
- Buying **auto-equips** into the first vacant slot; if all three slots are full, mastery is granted and the player swaps at the **Sigil Bench**.
- **Swapping slots is free** (tap chip → vacant slot, or clear slot).
- Shop automation (`autoShop`): permanents → mercenary → up to one scroll from `autoShopScrolls` (Frost) → auto-equip → leave.

**Not sold:** Ember Bolt (starter). Physical moves stay off the bench.

### 4.4 Pre-run loadout (title)

Entry: **"Sigils"** on title screen (same tier as Ash Gallery) **or** modal on first `startGame` each session.

- Shows 3 slots + list of mastered sigils not equipped.
- **Continue** writes `loadout` into run state and starts crawl.
- Returning players: loadout defaults to last run's loadout if still valid, else starter.

Veteran backfill: existing saves get `mastered = [.emberBolt]` on first launch after update.

### 4.5 Auto-battle

Replace `if mana >= Move.magic.manaCost { return .magic }` with:

```
1. For each spell in equippedLoadout (in slot order):
     if mana >= cost && would deal meaningful damage → score by effectiveness
2. Pick highest score (.weak > .neutral > .resist)
3. Tie-break: higher expected damage, then slot order
4. Else poison → heavy → attack (unchanged)
```

Auto-battle uses `InstantSpellCastResolver` (no minigame stall).

---

## 5. Bestiary — enemy aspects (v1)

| Enemy | Aspect | Tags |
|-------|--------|------|
| Goblin | Stone | `fey` |
| Troll | Stone | — |
| Pixie | Fey | `fey` |
| Wolf | Frost | `wild` |
| Gnoll | Frost | `wild` |
| Skeleton | Ember | `undead` |
| Giant Spider | Venom | — |
| Slime | Stone | — |
| Bat Swarm | Arc | `wild` |
| Cave Imp | Ember | `fey` |
| Blue Dragon Boss | Frost | `wyrm` |
| Giant Troll Boss | Stone | — |
| Warlord Shaman Boss | Arc | — |
| Treasure Seeker Goblin Boss | Stone | `fey` |
| Bloodthirsty Gnoll Boss | Frost | `wild` |
| Lich King Boss | Ember | `undead` |
| Minotaur Boss | Stone | — |
| Ash Dragon | Frost | `wyrm` |

**Note:** Fey is a **tag** only; aspect for Goblins/Pixies is **Stone** (weak to Arc when Arc ships; until then Ember is neutral and Frost may be weak via `fey` tag on Frost chart row).

Refine during implementation: every fodder enemy in Layer 1 should display **at least two different aspects** so both starter sigils matter.

### 5.1 Weak / resist examples (v1 two-sigil meta)

| Enemy | Ember | Frost |
|-------|-------|-------|
| Troll (Stone) | **WEAK** | neutral |
| Wolf (Frost) | **WEAK** | resist |
| Skeleton (Ember + undead) | resist | neutral |
| Slime (Stone) | **WEAK** | neutral |
| Spider (Venom) | **WEAK** | resist |

---

## 6. UI specification

### 6.1 Enemy stage (`CombatView`)

Below enemy name, before BOSS pill:

```
Goblin   [◇ Stone]   Lv 3
```

- Pill: aspect icon + name, `Theme` color per element.
- Sprite ring: subtle aspect-colored stroke (extends existing tint ring).
- Accessibility: *"Goblin, stone aspect, weak to ember sigils"* (derive from chart).

### 6.2 Spell button row (Pokémon-style)

Dedicated row **above** physical move grid:

| State | Appearance |
|-------|------------|
| Equipped + affordable | Full color, element tint, name + subtitle + mana |
| Equipped + no mana | Dimmed (0.4 opacity), disabled |
| Vacant slot | Dashed border, *"Vacant sigil"*, disabled |
| Not mastered | Hidden in combat (slot vacant) |

**Effectiveness hints:** gold solid border when `.weak`; dashed pale border when `.resist` (`CombatView.sigilEffectivenessBorder`).

### 6.3 Physical move grid

Unchanged layout minus Magic Bolt. Poison subtitle update: *"Venom strike · DoT stacks"*.

### 6.4 Sigil Loadout editor

`SigilLoadoutView` — used on title and in shop.

```
┌─────────────────────────────────────┐
│  Slot 1    [ Ember Bolt      ]  ✕   │
│  Slot 2    [ Frost Shard     ]  ✕   │
│  Slot 3    [ Vacant          ]  +   │
├─────────────────────────────────────┤
│  Mastered: (tap to assign to slot)  │
│  [ Frost Shard ]  (dim if in slot)  │
└─────────────────────────────────────┘
```

- Tap `+` on vacant slot → pick from mastered list.
- Tap ✕ → clear slot.
- Drag-and-drop between slots (optional v1.1).

### 6.5 Combat popups

Add `CombatPopup.Flavor.weak` (gold, scale animation like crit) for WEAK! hits.

---

## 7. Balance knobs (`Balance.swift`)

```swift
// MARK: - Elemental combat
static let weaknessMultiplier = 1.5
static let resistMultiplier = 0.5

// Sigils (replaces magicManaCost / magicFlatBonus)
static let emberBoltManaCost = 8
static let emberBoltFlatBonus = 5
static let emberBurnChancePercent = 35
static let frostShardManaCost = 6
static let frostShardFlatBonus = 2

// Shop
static let frostShardScrollPrice = 45

// Future casting (unused v1)
static let partialCastMultiplier = 0.5
static let fumbledCastMultiplier = 0.25
```

Deprecate after migration: `magicManaCost`, `magicFlatBonus`, `magicBurnChancePercent`.

---

## 8. Implementation phases

### Phase A — Foundation (no UI)

- [x] `Element.swift`, `EnemyTag.swift`
- [x] `TypeChart.swift` + `TypeChartTests` (full matrix)
- [x] `Spell.swift` (`SpellID`, `SpellDefinition`, `SpellCatalog`)
- [x] `SpellCasting.swift` (`CastResult`, `InstantSpellCastResolver`)
- [x] `DamagePipeline.swift` + tests
- [x] `Balance` knobs + `ProgressionKnobTests`

### Phase B — Data layer

- [x] `EnemyKind.aspect` + `tags`; fill `Bestiary`
- [x] `Enemy.aspect` / `tags` properties
- [x] `SigilLoadout`, `SigilMastery`, `MetaStore` persistence
- [x] `GameSave` includes `loadout`
- [x] Migration: grant `emberBolt` to existing players

### Phase C — Combat engine

- [x] Remove `Move.magic`; add `performSigil(_:)`
- [x] `resolveMagic()` → `resolveSigil(_:)` via pipeline + cast resolver
- [x] `resolvePoison()` direct hit through Venom pipeline
- [x] `autoAction()` sigil-aware auto-battle
- [x] Update all tests referencing `.magic`

### Phase D — UI

- [x] `CombatView`: aspect badge, spell row (3 slots), remove magic button
- [x] `WEAK!` popup + log lines
- [x] `SigilLoadoutView`
- [x] Title entry + shop Sigil Bench
- [x] `Narrative` beats

### Phase E — Shop & economy

- [x] Frost Shard scroll purchase
- [x] Arc Lance scroll purchase (v1.5)
- [x] `autoShop` buys scrolls
- [x] Pacing pass with playtest harness

### Phase F — Docs & ship

- [x] Update `game-design-spec.md` §3.1
- [x] Update `README.md` move table
- [x] Mark beta-feedback items in `beta-feedback-todo.md`
- [x] `future-work.md` progress log

---

## 9. Testing strategy

### 9.1 Unit tests

| Suite | Cases |
|-------|-------|
| `TypeChartTests` | Each spell × representative enemy; tag modifiers (undead, wyrm, fey) |
| `DamagePipelineTests` | DEF ignored for sigils; resist min 1; ×1.5 weak math |
| `SigilLoadoutTests` | Equip, vacant slots, no duplicates, Codable round-trip |
| `CombatMovesTests` | Ember burn; frost base formula; poison venom typing |
| `ShopTests` | Scroll buy, duplicate guard, mastery persistence |

### 9.2 Integration tests

| Flow | Assert |
|------|--------|
| `performSigil(.emberBolt)` vs Stone enemy | WEAK popup path, ×1.5 damage |
| Loadout only in shop/title | Combat cannot change slots |
| Save / restore mid-run | Loadout preserved |
| `autoMove` | Picks weak sigil when affordable |

### 9.3 Playtest / balance

- Layer 1 enemies expose both Ember-weak and Frost-relevant targets.
- Two-sigil runs do not trivialize bosses vs current Magic Bolt baseline.
- Run `PlaytestHarness` — clear rate delta &lt; ~3% vs pre-elemental baseline.

---

## 10. Future work (out of v1 scope)

### 10.1 Spell catalog expansion

All v1 sigils shipped (Ember, Frost, Arc). Future additions use the same `SpellCatalog` + shop scroll pattern.

### 10.2 Rune-tracing minigame (beta item — architecture ready)

| Spell | Rune shape | Partial cast |
|-------|------------|--------------|
| Ember Bolt | Triangle | 50% damage |
| Frost Shard | Circle | 50% damage |
| Arc Lance | Zigzag | 50% damage |

- `Phase.casting(spell:)` + `RuneCastView` overlay
- `RuneTraceSpellCastResolver`
- Settings: **Simplified sigils** (instant cast) for accessibility
- Auto-battle: always `.clean` cast

### 10.3 Other deferred

- Type-based achievements — **Aspect Reader** (`weakSigil`), **Second Binding** (`sigilScholar`); see `Achievements.swift`
- Player armor aspects / resist gear
- Dual-aspect enemies
- Poison rebalance (magnitude) — coordinate with Venom typing
- Investable stats (separate beta item)

---

## 11. Success metrics

| Metric | Target |
|--------|--------|
| Players who buy Frost scroll by Layer 2 | ≥60% of runs that reach shop twice |
| Manual sigil picks that are super-effective (Layer 1) | ≥40% after first weak-hit beat |
| Combat UI regression | No increase in move mis-tap rate (playtest) |
| Clear rate Layer 1–5 | Within ±3% of pre-elemental baseline |

Qualitative: playtesters describe **reading the enemy** and **choosing a sigil** without prompting.

---

## 12. Open questions

| # | Question | Default |
|---|----------|---------|
| 1 | MetaStore vs PrestigeStore for `SigilMastery` | **MetaStore** (`meta.sigils.v1`) |
| 2 | Title sigil screen vs inline on New Run only | **Both** — title entry + confirm on new run |
| 3 | Show enemy "weak to" hint on badge | **After first weak hit** only |
| 4 | Frost scroll price | **45g** — tune in Phase E |
| 5 | Progressive unlock spec alignment | Defer until [progressive-unlock-spec.md](progressive-unlock-spec.md) build |

---

## 13. Document cross-references

When implementing, also update:

| Doc | Section |
|-----|---------|
| [game-design-spec.md](game-design-spec.md) | §3.1 moves, §3.2 if crit/spell interaction noted |
| [systems-overview.md](systems-overview.md) | Combat + meta diagram |
| [beta-feedback-todo.md](beta-feedback-todo.md) | Weaknesses + magic minigame status |
| [progressive-unlock-spec.md](progressive-unlock-spec.md) | Magic Bolt → Ember Bolt unlock row |
| [future-work.md](future-work.md) | Progress log |
| [README.md](README.md) | Index row |

---

## 14. Changelog

| Date | Change |
|------|--------|
| 2026-06-16 | Initial spec: 2-spell v1, 3-slot loadout, ×1.5 WEAK!, Venom poison, shop + pre-run editing, `SpellCastResolver` stub for rune minigame |
