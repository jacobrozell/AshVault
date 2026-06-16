# AshVault — Progression & Pacing Spec

**Status:** Living spec (June 2026)  
**Source of truth for numbers:** `AshVault/Models/Balance.swift` → `// MARK: - Progression`  
**Simulator:** `docs/tools/balance_sim.py` → `PACING` dict (keep in sync)  
**Regression lock:** `AshVaultTests/ProgressionKnobTests.swift`  
**Related:** [idle-earnings-spec.md](idle-earnings-spec.md) · [game-design-spec.md](game-design-spec.md)

---

## 0. How to tweak progression (quick start)

```
1. Edit Balance.swift  // MARK: - Progression
2. Mirror values in balance_sim.py PACING + ProgressionKnobTests.swift
3. python3 ios/docs/tools/balance_sim.py --campaign-only   # sanity check
4. xcodebuild test -scheme AshVault -only-testing:AshVaultTests/ProgressionKnobTests
5. Playtest layers 1–5
6. Update § Knob reference below if targets changed
```

**What-if without editing Swift** (sim only):

```bash
python3 ios/docs/tools/balance_sim.py --gold-scale 0.45 --campaign-only
python3 ios/docs/tools/balance_sim.py --layer-growth 0.10 --campaign-only
```

---

## 1. Progression loop

```
Kill enemy → gold (scaled)
     │
     ├─ Boss (5th) → level-up → shop → next layer
     │                  │         ├─ permanents (geometric prices)
     │                  │         └─ merc camp (meta, 0–N auto-buys)
     │                  └─ stat choice (+5–10 ATK/DEF, +10–20 HP)
     │
     ├─ Boss → 18% relic roll (6 in pool; duplicates → 40g)
     │
     └─ scaleLevel +1 each layer → enemies permanently stronger
              └─ layers 2–5: +7%/layer campaign multiplier
```

**Meta (persists across runs):** mercenary counts, relics, Soul Tree, best run.  
**Run-scoped:** gold, shop permanents, level, layer progress.  
**Idle/offline:** separate curve — [idle-earnings-spec.md](idle-earnings-spec.md).

---

## 2. Knob reference

Every row maps **1:1** to `Balance.swift`. Change the constant, not scattered magic numbers.

### 2.1 Economy

| `Balance` constant | Value | Effect | Turn ↓ tighter | Turn ↑ looser |
|--------------------|-------|--------|----------------|---------------|
| `goldRewardScale` | `0.55` | All kill gold × this | `0.45` | `0.65` |
| `shopPriceGrowth` | `1.7` | Permanent shop `base × r^n` | `1.8` | `1.55` |
| `mercenaryPriceGrowth` | `1.14` | Merc `baseCost × r^n` | `1.18` | `1.10` |
| `prestigeShardDivisor` | `100` | `shards = ⌊√(runGold / div)⌋` | `120` | `80` |
| `fortuneGoldPerLevel` | `0.06` | Soul Tree gold%/level | — | — |

**Gold formula** (`Enemy.generateGold`):

```
gold = round(attack × level × goldRewardScale × fortuneMult × goldToothMult)
```

**Semi-tunable** (not in `Balance`): `ShopItem.basePrice`, `Mercenary.baseCost` / `baseDPS` in their enum files.

### 2.2 Enemy difficulty

| `Balance` constant | Value | Effect |
|--------------------|-------|--------|
| `enemyBaseHp` / `Atk` / `Def` | `50` / `15` / `5` | Fodder at `scaleLevel` 0 |
| `enemyScaleHpPerGroup` | `18` | +HP per `scaleLevel` |
| `enemyScaleAtkPerGroup` | `17` | +ATK per `scaleLevel` |
| `enemyScaleDefPerGroup` | `6` | +DEF per `scaleLevel` |
| `enemyBossHpBonus` | `20` | Boss HP on top of fodder line |
| `enemyBossAtkBonus` | `12` | Boss ATK |
| `campaignLayerStatGrowth` | `0.07` | Layers 2–5: `×(1 + 0.07×(layer−1))` |
| `enemyEndlessHpGrowth` | `1.10` | Post-dragon HP/layer |
| `enemyEndlessAtkGrowth` | `1.06` | Post-dragon ATK/layer |

`scaleLevel` increments once per layer cleared (after each boss).  
Dragon (layer 5 boss) uses a **fixed** stat block — not scaled by knobs above.

**Code:** `Enemy.init` → `GameEngine.spawnNextEnemy`.

### 2.3 Relics

| `Balance` constant | Value | Effect |
|--------------------|-------|--------|
| `bossRelicDropChancePercent` | `18` | Roll on boss kill only |
| `relicDuplicateGoldBonus` | `40` | Gold when pool empty |
| `maxEquippedRelics` | `3` | Loadout cap |
| `relicGoldBonus` etc. | see `Balance` | Per-relic combat effects |

6 relics in pool → ~30+ boss kills to complete at 18% (with variance).

### 2.4 Automation pacing

| `Balance` constant | Value | Effect |
|--------------------|-------|--------|
| `autoShopMaxMercenariesPerVisit` | `1` | `0` = manual merc buys only |
| `autoBattleHealThresholdPercent` | `35` | Auto-battle heals below this HP% |
| `automationUnlockShards` | `1` | Auto level-up/shop threshold |
| `autoDescendDefaultMinShards` | `8` | Settings default for auto-prestige |

**Code:** `GameEngine.autoShop`, `GameEngine.autoMove`.

### 2.5 Offline (cross-ref)

Not in this table — see [idle-earnings-spec.md](idle-earnings-spec.md) §4.4.  
Shares `goldRewardScale` and Fortune/Gold Tooth multipliers.

---

## 3. Player growth (fixed — context only)

Not in `Balance` today; change in `Player.swift` / `ShopItem` if needed.

| Source | Gain |
|--------|------|
| Level-up | +10 primary / +5 secondary stat; +20/+10 HP; full heal |
| Whetstone / shield | +5 ATK / DEF |
| Heart vial | +15 max HP, full heal |
| Mercenary | Flat DPS (meta) |
| Relic | Passive when equipped |

---

## 4. Pacing targets

| Milestone | Target |
|-----------|--------|
| Layer 1–2 | ~20–40 turns/layer; first Goblin Slayer after careful saving |
| Layer 3–4 | Noticeable wall (~60–100 turns/layer in sim) |
| Layer 5 dragon | Winnable first run; not trivial |
| Campaign gold (L1–5) | ~3k total (sim, no prestige) |
| First relic | ~1 per 5–6 bosses |
| First Knight (12k) | Many runs / deep grind |

```bash
python3 ios/docs/tools/balance_sim.py --campaign-only
```

---

## 5. File map

| File | Role |
|------|------|
| `Models/Balance.swift` | **Edit knobs here** |
| `Models/Enemy.swift` | Applies scaling + `generateGold` |
| `Models/GameEngine.swift` | Gold grant, relic drop, auto-shop/heal |
| `Models/Mercenary.swift` | Base costs/DPS (semi-tunable) |
| `Models/ShopItem.swift` | Base prices (semi-tunable) |
| `docs/tools/balance_sim.py` | Headless pacing sim + CLI what-ifs |
| `AshVaultTests/ProgressionKnobTests.swift` | Value regression lock |
| `AshVaultTests/EnemyTests.swift` | Scaling math |
| `AshVaultTests/MetaProgressionTests.swift` | Offline + merc integration |

---

## 6. Tuning history

| Date | Summary |
|------|---------|
| 2026-06-15 | Hybrid idle ship |
| 2026-06-15 | Offline nerfs |
| 2026-06-15 | Pacing pass: gold 0.55×, tougher enemies, relics 18%, shop 1.7× |
| 2026-06-15 | Centralized knobs in `Balance` Progression section + this spec |

---

## 7. Future knobs (not implemented)

| Idea | `Balance` home (proposed) |
|------|---------------------------|
| Level-up stat % reduction | `levelUpPrimaryBonus`, `levelUpSecondaryBonus` |
| Timed boss retreat | `bossTimerSeconds` |
| Relic pity counter | `relicPityBossKills` |
| Per-layer gold dampener | `goldLayerScale` |
| Elite 6th enemy | `eliteSpawnLayer` |
