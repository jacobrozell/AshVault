# AshVault — Narrative Integration Plan

**Status:** Shipped June 2026 (Phases A–E complete).  
**Goal:** Bake the AshVault story into UI copy, combat log beats, and system labels without changing core mechanics.

**Related:** [game-design-spec.md](game-design-spec.md) · [systems-overview.md](systems-overview.md)

---

## 1. Lore bible (canonical)

### What AshVault is

AshVault is a buried treasury of the **Red Empire** — a catacomb built to hoard the essence of the dead as **ash-crystal**, ring by ring, seal by seal. The empire fell. The **Ash Dragon** still guards the crown ring. Everything below Layer 5 is uncharted: the **Deep AshVault**.

### The three spaces

| Space | Player-facing name | Maps to |
|-------|-------------------|---------|
| Shrine | **The Shrine** | Title screen, Ash Tree, Ash Gallery |
| Vault | **The Vault** | Run (layers 1–5 campaign) |
| Deep AshVault | **The Deep AshVault** | Endless mode (layer 6+) |

### Player identity

You are an **ash-crawler** — someone the vault keeps calling back. Each run is a descent; only a **withdrawal to the Shrine** banks permanent ash.

### Mechanical ↔ narrative alignment

| Mechanic | Story |
|----------|-------|
| Run gold | Loot stripped from the crypt; lost on death or withdrawal |
| Death | Body fails; ash scatters. No banking ritual |
| Ascension | Retreat to Shrine; run essence **distilled into Ash Shards** |
| Ash Shards | Crystallized memory of a run — permanent |
| Ash Tree | Shards planted in the Shrine; grow permanent power |
| Relics | Anchors of power carved from boss-ash |
| Mercenary Camp | Sellswords bivouacked at the vault mouth |
| Offline gold | Camp keeps working upper rings while you're away |
| Layer / boss | A sealed ring; warden holds the door to the next |
| Dragon (L5) | Crown seal; breaking it opens the Deep AshVault |

---

## 2. Terminology migration

Rename in UI and combat log first; keep **code identifiers** (`totalShards`, `SkillNode`, `Relic`) until a dedicated refactor pass.

| Current UI | AshVault UI | Notes |
|------------|-------------|-------|
| Soul Shards | **Ash Shards** | Header, ascension, settings, offline |
| Soul Tree | **Ash Tree** | `SkillTreeView`, title links |
| Relic Museum | **Ash Gallery** | Or **Vault Relics** — pick one |
| Descend into the Abyss | **Withdraw to the Shrine** | Ascension hero |
| Descend (ascension btn) | **Bank your ash** / **Withdraw** | Button copy |
| Keep diving (cancel) | **Keep crawling** | Ascension cancel |
| Descend to Layer N (shop) | **Break the seal — Layer N** | Shop CTA |
| Descend Deeper (Endless) | **Enter the Deep AshVault** | Victory CTA |

**Persistence keys** (`PrestigeStore`, `MetaStore`) stay unchanged — player-facing strings only.

---

## 3. Story beats (trigger → copy)

One line per milestone in the combat log unless noted. Store strings in a single module (see §4).

### First run / tutorial (`GameEngine.startGame`)

Replace the three-line tutorial with:

1. *"AshVault sleeps beneath the old empire — seals, wardens, and ash that never cools."*
2. *"Clear five guardians per ring. Every fifth is a warden who holds the next seal."*
3. *"Break the crown seal on the Ash Dragon. Then keep going."*

### Layer entry (`spawnEnemy`, layer change)

| Trigger | Copy |
|---------|------|
| Layer 1, first enemy | *"The air tastes of old incense and burnt gold."* |
| Layer 2+ | *"Ring \(layer) — the stone grows warmer."* (optional, layer ≥ 3) |
| Layer 5, first enemy | *"The crown vault. Something vast stirs ahead."* |
| Layer 6+, first enemy | *"No architect planned this deep."* |
| Layer 10+ | *"The ash here is older than the empire."* |

### Boss

| Trigger | Copy |
|---------|------|
| Boss spawn (non-dragon) | *"A warden rises to hold the seal."* |
| Ash Dragon spawn | *"The Ash Dragon — last warden of the crown seal."* |
| Boss killed + relic drop | *"A sliver of the warden's ash. The vault lets you keep this."* |
| Boss killed, duplicate relic | *"More ash-dust — \(gold)g scraped from the seal."* |

### Prestige (`performAscend`)

| Trigger | Copy |
|---------|------|
| Gained shards > 0 | *"You climb back to the Shrine. \(n) Ash Shards harden in your grasp."* |
| Gained 0 | *"You withdraw, but this run left little to distill."* |
| Follow-up | *"Plant them in the Ash Tree before you crawl again."* |

### Victory / defeat

| Trigger | Copy |
|---------|------|
| Dragon killed (log) | *"The crown seal shatters. The Vault exhales. The map ends. The descent does not."* |
| Victory screen | *(already updated — crown seal / Deep AshVault)* |
| Defeat | *"The vault claims another crawler. Your ash scatters."* |

### Meta milestones (one-time, `MetaStore` flags)

| Trigger | Copy |
|---------|------|
| First Ash Shard ever | *"The Shrine remembers you now."* |
| First relic discovered | *"The Ash Gallery gains its first trophy."* |
| First mercenary hired | *"A sellsword signs on at the vault mouth."* |
| Automation unlock | *"The crawl can continue without your hand — the camp takes over."* |

---

## 4. Implementation architecture

### Phase A — `Narrative.swift` (foundation)

Add `AshVault/Models/Narrative.swift`:

```swift
enum Narrative {
    enum Term { /* ashShard, ashTree, ashGallery, ... */ }
    enum Beat { /* firstRun, layerEntry(layer:), bossSpawn(...), ... */ }
    static func text(for beat: Beat) -> String
}
```

- All player-facing AshVault strings live here.
- Views and `GameEngine` call `Narrative.text(for:)` — no scattered literals.
- Unit tests: snapshot key beats; no gameplay logic in `Narrative`.

### Phase B — UI pass (labels only)

| File | Changes |
|------|---------|
| `ContentView.swift` | Subtitle, Ash Tree / Ash Gallery links |
| `AscensionView.swift` | Hero title, body, buttons |
| `SkillTreeView.swift` | Nav title, shard label |
| `RelicMuseumView.swift` | Nav title, header blurb |
| `MercenaryCampView.swift` | One-line camp flavor |
| `ShopView.swift` | Seal-break CTA |
| `GameOverView.swift` | Defeat line, endless CTA |
| `CombatView.swift` | Shard button accessibility label |
| `OfflineReportView.swift` | Ash Tree reference |
| `SettingsView.swift` | Automation hint |

### Phase C — `GameEngine` beat hooks

| Hook | Beat |
|------|------|
| `startGame` | Tutorial lines |
| `spawnEnemy` | Layer / boss / deep thresholds |
| `onEnemyKilled` + relic | Relic drop lines |
| `performAscend` | Withdrawal lines |
| `onVictory` / `onDefeat` | Crown seal / scatter |
| `hireMercenary` (first) | Camp milestone |

Use `MetaStore` one-shot flags (`hasSeenShrineWelcome`, `hasSeenFirstShard`, …) for milestones.

### Phase D — Relic & mercenary flavor (optional)

Extend `Relic.blurb` and `Mercenary` with a `lore: String` one-liner each (display in gallery / camp, not combat).

### Phase E — Docs & tests

- Update `game-design-spec.md` §1 player promise and terminology.
- Add `NarrativeTests.swift`: beat triggers return non-empty strings; tutorial count unchanged.
- Grep tests for legacy terms (`"Soul Shard"`, `"Diver"`) — update assertions.

---

## 5. Suggested rollout order

```
Phase A (Narrative.swift + terms)     ← 1 PR, no behavior change
Phase B (UI labels)                   ← 1 PR, visual only
Phase C (combat log beats)            ← 1 PR, highest player impact
Phase D (relic/merc lore)             ← optional polish
Phase E (docs + tests)                ← with each PR or final sweep
```

**Do not** rename persistence keys or `SkillNode` in code until after UI ship — avoids save migration.

---

## 6. Out of scope (later)

- Cutscenes, character art, voiced lines
- Quest NPCs or branching story
- Renaming `SkillNode` / `Relic` types in code
- App Store description / screenshots (separate marketing pass)
- Icon rebrand (monogram **AV**, ember/ash palette)

---

## 7. Acceptance criteria

- [x] No user-visible "Soul Shard", "Soul Tree", "Relic Museum", or "Abyss"
- [x] First-run tutorial reflects AshVault lore
- [x] Ascension reads as **withdrawal / banking ash**, not generic prestige
- [x] Layer 5 and layer 6+ have distinct tone in log
- [x] All strings centralized in `Narrative.swift`
- [x] Existing saves load; shard counts unchanged
