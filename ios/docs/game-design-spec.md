# AshVault — Game Design Spec

**Status:** Living document — reflects implemented behavior as of June 2026.  
**Code truth:** When this doc and code disagree, fix the doc or file a bug — but
verify in `GameEngine.swift` and `Balance.swift` first.

**Related:** [systems-overview.md](systems-overview.md) · [long-term-idle.md](long-term-idle.md)

---

## 1. Player promise

AshVault is a **hybrid idle RPG** set in a buried imperial vault of ash-crystal and sealed rings:

- **Short sessions** — manual combat, relic hunts, shop/camp choices (2–5 min).
- **Leave it running** — auto-battle, mercenary DPS, offline gold accrual.
- **Check in later** — offline report, new relics, deeper layer records, withdraw to bank **Ash Shards**.

**Lore & copy:** [ashvault-narrative-plan.md](ashvault-narrative-plan.md) · in-app strings in `Narrative.swift`.

**North star:** Every time you open the app, at least two numbers should be going
up — and at least one should be permanent.

---

## 2. Run structure

### 2.1 Layers and enemies

- Each **layer** has **5 enemies**; the 5th is a **boss**.
- Defeating a boss → **level up** (stat choice) → **shop** (gold spend) → next layer.
- **Layers 1–5:** campaign; layer 5 boss is the **Ash Dragon** (fixed
  150 HP / 100 ATK / 0 DEF).
- After the dragon: **endless mode** — enemy stats compound per layer (`postGameDepth
  = layer − 5`). Depth is the score; every run eventually ends in death.

### 2.2 Enemy scaling

| Region | HP growth | ATK growth | Notes |
|--------|-----------|------------|-------|
| Pre-dragon (`scaleLevel`) | +15 per group of 5 | +5 per group | Faithful Java port |
| Endless (`postGameDepth`) | ×1.10^depth / layer | ×1.06^depth / layer | `Balance.enemyEndlessHpGrowth` / `AtkGrowth` |

### 2.3 Gold economy (per run)

- **Drop formula:** `enemy.attack × enemy.level` (then × prestige Fortune × relic Gold Tooth).
- **Shop:** consumables (flat price) + permanent upgrades (geometric: `base × 1.6^owned`).
- **Mercenary camp:** hire with run gold; **ownership persists in meta** (see §6).
- Run gold resets on death / ascension. `runGoldEarned` tracks gold this run for shard payout.

### 2.4 Level-up

Chosen stat +large / others +small (HP +20/+10, others +10/+5), full restore.  
Automation (post-first-prestige): round-robin HP → ATK → DEF.

---

## 3. Combat

### 3.1 Moves & sigils

**Physical / utility moves**

| Move | Mana | Effect |
|------|------|--------|
| Attack | 0 | `combatAttack − def`; hit via luck d10; can crit |
| Heavy Strike | 5 | ×1.8 damage; 20% stun |
| Dodge | 0 | avoid swing or take hit; clean dodge heals `5×level` HP + 4 mana |
| Heal (Second Wind) | 0 | `10×level` HP; enemy retaliates with +1 luck |

**Sigils** — three equipped slots (Pokémon-style bar). Chosen on the title screen and at the **Sigil Bench** in shop. See [`elemental-combat-spec.md`](elemental-combat-spec.md).

| Sigil | Element | Mana | Effect | Unlock |
|-------|---------|------|--------|--------|
| Ember Bolt | Ember | 8 | `combatAttack + 5`; ignores def; 35% burn | Starter (slot 1) |
| Frost Shard | Frost | 6 | `combatAttack + 2`; ignores def | Shop scroll (45g) |
| Venom Lash | Venom | 5 | `combatAttack + 1`; ignores def; stacks poison | Shop scroll (45g) |
| Arc Lance | Arc | 10 | `combatAttack + 8`; ignores def | Shop scroll (55g) |

**Type chart:** enemies show an **aspect** (element). Super-effective sigils deal ×1.5 (`WEAK!` popup); resisted sigils deal ×0.5 (min 1). Physical moves are untyped.

**`combatAttack`** = `player.attack + mercenaryDPS` (see §6.1).

Consumables (combat): 🧪 Potion (`15×level` heal), 🔮 Ether (full mana) — cost a turn.

### 3.2 Hit, crit, mitigation

- **Hit:** d10 roll ≥ target `luck` (`Dice.checkHit`).
- **Crit:** chance = `max(5%, (10 − luck)×3)` + focus buff + Lucky Charm (+8%); damage ×2.
- **Ward (prestige):** `%` damage reduction on direct hits, cap 60%. DoT bypasses Ward.
- **Mitigation order:** guard buff → subtract def → Ward % on remainder.

### 3.3 Status effects

| Effect | Behavior |
|--------|----------|
| Burn / Poison | DoT each round, ignores defense |
| Stun | Skips next action (consumed on attempt, not by duration tick) |
| Guard / Focus | Buff hooks (reserved for future items) |

Bosses: 25% chance to poison player on hit.

### 3.4 Death resolution

Player death during a round (including DoT) → defeat, clear `SaveStore`.  
Enemy death → gold, possible relic roll (boss only), spawn next or boss flow.

---

## 4. Shop (run-scoped)

**Phase:** `.shop` — after every level-up.

| Item | Type | Effect | Base price |
|------|------|--------|------------|
| Potion | consumable | +1 charge | 25g |
| Ether | consumable | +1 charge | 20g |
| Whetstone | permanent | +5 max ATK | 40g |
| Tower Shield | permanent | +5 max DEF | 40g |
| Heart Vial | permanent | +15 max HP, full heal | 50g |
| Lucky Coin | permanent | luck −1 (min 1) | 60g |

Permanent prices: `base × 1.6^owned` (`Balance.shopPriceGrowth`).

**Automation:** buys all affordable permanents, then all affordable mercenaries, then dives.

---

## 5. Prestige (Ash Shards)

Player-facing name: **Ash Shards** (`Narrative.Term.ashShards`). Code/persistence: `totalShards`, `PrestigeStore`.

### 5.1 Earning shards

On **ascension** (manual or auto-descend):

```
pendingShards = floor( sqrt(runGoldEarned / 100) )
```

`runGoldEarned` = total gold earned this run (combat + offline + duplicate relics).

### 5.2 Ash Tree (`SkillNode`)

Spend shards permanently. Max level **25** per node. Cost: `baseCost × 1.6^level`.

| Node | Base cost | Per-level effect |
|------|-----------|------------------|
| Might | 1 | +5% starting attack |
| Fortune | 1 | +6% gold earned |
| Vitality | 1 | +6% starting max HP |
| Ward | 4 | +3% damage reduction (cap 60%) |
| Patience | 3 | +1h offline cap, +5% offline efficiency |

Applied in `startGame` via `Player.applyPrestige(attackMult:hpMult:)`.

### 5.3 Ascension flow

- **Manual:** ✨ button in combat header → `AscensionView` → Descend or cancel.
- **Auto-descend:** see §8.3.
- On descend: bank shards, increment `lifetime.totalDescents`, `startGame` (fresh run).

### 5.4 Automation unlock

`totalShards >= 1` → `automationUnlocked`: auto-battle also clears level-up and shop.

---

## 6. Meta progression (permanent)

Stored in `MetaStore` — survives death, ascension, and new runs.

### 6.1 Mercenary Camp

**UI:** `MercenaryCampView` embedded in `ShopView`.  
**Payment:** run gold during shop phase only (`hireMercenary` guards `phase == .shop`).

#### Tiers

| Mercenary | Base cost | Base DPS | Role |
|-----------|-----------|----------|------|
| Goblin Slayer | 50 | 2 | Entry generator |
| Archer | 200 | 8 | Mid-tier |
| Mage | 800 | 35 | Strong |
| Cleric | 3,000 | 120 | Late |
| Knight | 12,000 | 500 | Endgame |

#### Cost formula

```
cost(n) = floor(baseCost × 1.14^n)    // n = already owned
```

`Balance.mercenaryPriceGrowth = 1.14`

#### DPS formula

```
dps(count) = floor(baseDPS × count × milestoneMult(count))

milestoneMult: ×2 for each threshold in {25, 50, 100, 200, 400} where count >= threshold
```

**Total party DPS** = sum of `dps(count)` across all tiers.

#### Integration

- Added to `combatAttack` for all player damage formulas.
- Added to offline DPS estimate (§7.2).
- Persisted: `MetaStore.loadMercenaryCounts()` → `[Mercenary.rawValue: Int]`.

### 6.2 Relics

**UI:** `RelicMuseumView` (title screen), `RelicFoundView` (sheet on new drop).

#### Drop rules

- **When:** boss killed (`enemyIndex == 5` at death resolution).
- **Chance:** 18% (`Balance.bossRelicDropChancePercent`).
- **New relic:** uniform pick from undiscovered pool; auto-equip if slot available.
- **All discovered:** +40 gold (`Balance.relicDuplicateGoldBonus`).

#### Relic catalog

| Relic | Passive | Constant |
|-------|---------|----------|
| Lucky Charm | +8% crit chance (flat %) | `relicCritBonus` |
| Gold Tooth | +12% gold | `relicGoldBonus` |
| Vampiric Fang | Heal 6% of damage dealt | `relicLifestealPercent` |
| Thorn Mail | Reflect 10% damage taken | `relicThornsPercent` |
| Mana Stone | +1 mana regen / turn | `relicManaRegenBonus` |
| Iron Heart | +8% starting max HP | `relicHpBonus` |

**Equip limit:** 3 (`Balance.maxEquippedRelics`). Toggle in museum.  
**Stacking:** one copy each; effects do not stack duplicates (only one of each type exists).

#### Integration points

| Relic | Hook in `GameEngine` |
|-------|------------------------|
| Lucky Charm | `rollCrit()` |
| Gold Tooth | kill gold, `grantOffline` |
| Vampiric Fang | after player damage dealt |
| Thorn Mail | after `player.takeHit` |
| Mana Stone | `endRound()` mana regen |
| Iron Heart | `startGame` hp multiplier |

Persisted: `discoveredRelics: Set<String>`, `equippedRelics: [String]` (max 3).

### 6.3 Lifetime stats

`LifetimeStats` (JSON in `MetaStore`):

| Field | Incremented when |
|-------|----------------|
| `totalGoldEarned` | kill gold, offline gold, duplicate relic |
| `totalKills` | enemy kill, offline estimate |
| `totalBossKills` | boss kill |
| `totalDescents` | ascension (manual or auto) |
| `relicsFound` | new relic discovered |

Displayed in `RelicMuseumView`. Future: achievements screen (Month 2).

---

## 7. Idle & offline

### 7.1 Auto-battle tick

- **Rate:** 1 Hz (`Balance.tickSeconds`).
- **Driver:** `Timer.publish` in `CombatView` → `GameEngine.tick()`.
- **Guard:** `autoBattle` must be true.

**`tick()` behavior:**

| Phase | Action (auto-battle on) |
|-------|-------------------------|
| `.combat` | Auto-descend check → else `autoAction()` (sigil or physical move) |
| `.levelUp` | `chooseUpgrade` (if automation unlocked) |
| `.shop` | `autoShop` (if automation unlocked) |

**`autoAction()` heuristic:** heal/dodge if HP &lt; 35%; else super-effective sigil → neutral sigil → primary-slot sigil → resisted sigil → heavy → attack. See [`elemental-combat-spec.md`](elemental-combat-spec.md) §4.3.

### 7.2 Offline progress

> **Full spec:** [idle-earnings-spec.md](idle-earnings-spec.md) — formulas, tuning history, future work.

**Trigger:** app launch (`loadIfAvailable`) or foreground (`foregrounded()`).  
**Minimum absence:** 60 seconds.

```
elapsed     = now − lastSeen
credited    = min(elapsed, offlineCap)        // Patience extends cap (base 4h)
rate        = autoBattle ? offlineEfficiency : manualOfflineEfficiency
heroDps     = max(1, player.attack − enemy.defense)
mercDps     = mercenaryDPS × offlineMercenaryDpsFactor
totalDps    = heroDps + mercDps
killsPerSec = totalDPS / enemy.maxHp
goldPerSec  = killsPerSec × enemy.generateGold()
gold        = floor(goldPerSec × credited × rate × fortuneMult × goldToothMult)
```

| Mode | Efficiency (base) | Cap base |
|------|-------------------|----------|
| Auto-battle on | 5.5% + Patience (max 100%) | 4h + Patience |
| Auto-battle off | 2.5% (`manualOfflineEfficiency`) | same cap |

Mercenaries count at **10%** DPS offline (`offlineMercenaryDpsFactor`).

**Offline report** (`OfflineReport`): gold, wall-clock duration, credited duration,
estimated kills, hitCap flag, wasAutoBattle, mercenaryGold share.

### 7.3 Run save (`SaveStore`)

Saved phases: `.combat`, `.levelUp`, `.shop` only.  
Not saved: enemy instance, statuses, log (rebuilt on resume).  
Cleared on: death, ascension, explicit new game.

---

## 8. Auto-descend

**Settings:** `SettingsView` → Automation section.  
**Storage:** `AutoDescendSettings` (`UserDefaults`).

| Setting | Key | Default |
|---------|-----|---------|
| Enabled | `autoDescend.enabled` | false |
| Min shards | `autoDescend.minShards` | 8 |

**Requirements:**

1. `automationUnlocked` (`totalShards >= 1`)
2. `autoBattle` on
3. `AutoDescendSettings.enabled`
4. `pendingShards >= minShards`
5. Phase `.combat`

**Action:** `performAscension()` — same as manual descend (bank shards, new run).

---

## 9. UI surfaces

| Screen | Entry | Purpose |
|--------|-------|---------|
| Title | Launch (no save) | Name, begin, best run, soul tree, museum, settings |
| Combat | Run | Fight, auto-toggle, ascend, merc DPS chip |
| Level-up | Boss kill | Stat choice |
| Shop | After level-up | Items + mercenary camp |
| Ascension | ✨ combat button | Preview shards, descend, soul tree |
| Ash Tree | Title / ascension | Spend shards |
| Relic Museum | Title | Collection, equip, lifetime stats |
| Relic Found | Sheet | New drop celebration |
| Offline Report | Sheet on resume | Away earnings |
| Settings | ⚙️ title | Audio, auto-descend |
| Game Over | Death / victory | Summary, new run |

---

## 10. Balance constants reference

All values in `AshVault/Models/Balance.swift`. Summary:

| Category | Key constants |
|----------|---------------|
| Combat | `manaRegenPerTurn`, `critMultiplier`, move costs/procs |
| Economy | `goldRewardScale` 0.55 |
| Enemy scale | `enemyScaleHp/Atk/DefPerGroup`, `campaignLayerStatGrowth` 0.07 |
| Endless | `enemyEndlessHpGrowth` 1.10, `enemyEndlessAtkGrowth` 1.06 |
| Shop | `shopPriceGrowth` 1.7 |
| Prestige | `prestigeShardDivisor` 100, node %/level, `automationUnlockShards` 1 |
| Offline | see [idle-earnings-spec.md](idle-earnings-spec.md) |
| Mercenaries | `mercenaryPriceGrowth` 1.14, milestones [25,50,100,200,400] |
| Relics | drop 18%, duplicate 40g, max equip 3, effect %/values |
| Auto-descend | `autoDescendDefaultMinShards` 8 |
| Tick | `tickSeconds` 1.0 |

**Pacing deep dive:** [pacing-spec.md](pacing-spec.md)

**Tuning workflow:** playtest → adjust `Balance.swift` → optionally sync
`docs/tools/balance_sim.py` → run `MetaProgressionTests` + `GameEngineTests`.

---

## 11. Testing

| Suite | Covers |
|-------|--------|
| `DiceTests`, `PlayerTests`, `EnemyTests` | Core math |
| `GameEngineTests` | Combat, shop, save/restore |
| `PrestigeTests` | Shards, tree, automation, Ward |
| `MetaProgressionTests` | Mercenaries, relics, offline, auto-descend |
| `ProgressionTests` | Node effects, offline cap |

`TestSupport.clearPersistence()` clears `SaveStore`, `PrestigeStore`, `MetaStore`, `BestRun`.

---

## 12. Future (not implemented)

See [long-term-idle.md](long-term-idle.md):

- **Month 2:** Abyss Essence (second prestige), achievements, more soul tree nodes
- **Month 3:** Daily delve, boss phases, playable classes

Unscoped backlog: [future-work.md](future-work.md) § Ideas backlog.
