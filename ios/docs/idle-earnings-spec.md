# AshVault — Idle Earnings Spec

**Status:** Living spec (June 2026)  
**Authority:** When this doc and `game-design-spec.md` §7 disagree on idle math, **this doc wins**.  
**Code:** `Balance.swift`, `GameEngine.grantOffline`, `GameEngine.tick`, `OfflineReportView`

**Related:** [game-design-spec.md](game-design-spec.md) · [long-term-idle.md](long-term-idle.md) · [idle-design.md](idle-design.md) · [tools/balance_sim.py](tools/balance_sim.py)

---

## 1. Design goals

AshVault is a **hybrid idle RPG**. Earnings come from two related but distinct loops:

| Loop | When it runs | Player promise |
|------|----------------|----------------|
| **Active auto-battle** | App open, auto-battle on | Full combat simulation at 1 Hz; mercenaries at 100% DPS |
| **Offline accrual** | App closed or backgrounded | Reduced-rate gold estimate on return; time-capped |

**Target feel (current tuning):**

- A **few hours away** should feel rewarding (hundreds → low thousands early; mid thousands later).
- Offline must **never trivialize active play** — e.g. a 2h absence on a mid run should not fund an endgame Knight (12k) outright.
- **Time cap** works like genre-standard idle games: only the first N hours credit per return; Patience extends N.
- **Active play is king** for deep progression, relic drops, layer advancement, and prestige shards.

---

## 2. Architecture overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        GameEngine                               │
├────────────────────────────┬────────────────────────────────────┤
│   ACTIVE (tick @ 1 Hz)     │   OFFLINE (delta-time on resume)   │
│   CombatView → tick()      │   loadIfAvailable / foregrounded() │
│   Full combat + merc DPS   │   DPS estimate + efficiency + cap  │
│   Layer/shop/level-up flow │   Gold only (no layers, no relics) │
└────────────────────────────┴────────────────────────────────────┘
              │                              │
              ▼                              ▼
        player.gold                   player.gold
        runGoldEarned                 runGoldEarned
        lifetime stats                lifetime stats
```

**Shared inputs:** hero stats, mercenary counts (meta), Fortune prestige, Gold Tooth relic.  
**Not shared:** offline ignores mana, crit variance, enemy retaliation, death, status effects, and layer progression.

---

## 3. Active auto-battle (live tick)

### 3.1 Driver

| Constant | Value | Location |
|----------|-------|----------|
| `Balance.tickSeconds` | `1.0` (1 Hz) | `Balance.swift` |
| Entry point | `CombatView` `Timer.publish` → `GameEngine.tick()` | `CombatView.swift` |
| Guard | `autoBattle == true` | `GameEngine.tick()` |

### 3.2 Tick behavior by phase

| Phase | Action (auto-battle on) |
|-------|-------------------------|
| `.combat` | Auto-descend check → else `perform(autoMove())` |
| `.levelUp` | `chooseUpgrade(autoUpgrade())` — only if `automationUnlocked` |
| `.shop` | `autoShop()` — only if `automationUnlocked` |
| Other | No-op |

**`automationUnlocked`:** `totalShards >= Balance.automationUnlockShards` (currently `1`).

### 3.3 Auto-combat heuristic (`autoMove`)

1. Heal if HP &lt; 35% and not full.
2. Else magic → poison → heavy → attack (by mana affordability).

### 3.4 Auto-shop (`autoShop`)

Buys all affordable permanent shop items, then **every affordable mercenary** (in enum order), then `leaveShop()`.

> **Balance note:** Large offline gold piles + automation can cause rapid mercenary spending on the next shop visit. Offline tuning and shop AI are coupled.

### 3.5 Active DPS model

In combat, damage uses `combatAttack = player.attack + mercenaryDPS` (full merc contribution) plus move kit, crit, defense, etc. There is no separate “idle DPS” constant for active play — it is emergent from combat rules.

---

## 4. Offline accrual (current behavior)

### 4.1 Triggers

| Event | Call site | `lastSeen` source |
|-------|-----------|-------------------|
| Cold launch with save | `loadIfAvailable` → `restore` → `grantOffline` | `GameSave.lastSeen` |
| Warm foreground | `foregrounded()` → `grantOffline` | `backgroundedAt` (set in `backgrounded()`) |

`save()` stamps `lastSeen` on every persist.

### 4.2 Guards (no payout when…)

- `phase != .combat` (level-up, shop, game over, etc.)
- Elapsed ≤ 60 seconds
- Computed `gold <= 0`

### 4.3 Formula

```
elapsed          = now − lastSeen
credited         = min(elapsed, offlineCap)
rate             = autoBattle ? offlineEfficiency : manualOfflineEfficiency

heroDps          = max(1, player.attack − enemy.defense)
mercDps          = mercenaryDPS × offlineMercenaryDpsFactor
totalDps         = heroDps + mercDps

killsPerSec      = totalDps / max(1, enemy.maxHp)
goldPerSec       = killsPerSec × max(1, enemy.generateGold())

gold             = floor(goldPerSec × credited × rate × fortuneMult × goldToothMult)
estimatedKills   = max(1, floor(killsPerSec × credited))
mercenaryGold    = floor(gold × mercDps / totalDps)   // report split only
```

**Enemy snapshot:** Uses the **rebuilt enemy at the saved layer/index** (`spawnNextEnemy(advance: false)`), not the enemy instance from before close. Transient combat state is intentionally discarded.

**`enemy.generateGold()`:** `attack × level` (scales with `scaleLevel` and endless depth).

### 4.4 Balance constants (June 2026)

| Constant | Value | Notes |
|----------|-------|-------|
| `baseOfflineHours` | `4.0` | Default time cap per return |
| `baseOfflineEfficiency` | `0.055` (5.5%) | Auto-battle offline base rate |
| `manualOfflineEfficiency` | `0.025` (2.5%) | When auto-battle was off |
| `maxOfflineEfficiency` | `1.0` | Patience ceiling |
| `offlineMercenaryDpsFactor` | `0.10` | Mercs count at 10% offline |
| `patienceHoursPerLevel` | `+1h` cap per Patience level | Soul Tree |
| `patienceEfficiencyPerLevel` | `+5%` rate per Patience level | Soul Tree |
| `fortuneGoldPerLevel` | `+8%` gold per Fortune level | Applies to offline |
| `relicGoldBonus` | `+12%` | Gold Tooth equipped |

**Derived caps & rates:**

```
offlineCap(seconds)     = (baseOfflineHours + patienceHoursPerLevel × patienceLevel) × 3600
offlineEfficiency       = min(maxOfflineEfficiency, baseOfflineEfficiency + patienceEfficiencyPerLevel × patienceLevel)
```

| Patience level | Cap | Auto offline rate |
|----------------|-----|-------------------|
| 0 | 4h | 5.5% |
| 5 | 9h | 30.5% |
| 19 | 23h | 100% (capped) |

### 4.5 Auto-battle vs manual offline

| `autoBattle` at save | Rate used | UX copy |
|----------------------|-----------|---------|
| `true` | `offlineEfficiency` (Patience-scaled) | “Auto-battle kept diving…” |
| `false` | `manualOfflineEfficiency` (flat 2.5%) | “Your crawl idled at reduced rate…” |

Manual rate exists so forgetting the toggle does not zero out a long absence.

### 4.6 Side effects on grant

- `player.addGold(gold)`
- `runGoldEarned += gold` (feeds prestige shard formula)
- `lifetime.totalGoldEarned`, `lifetime.totalKills` updated
- `recordRun()` may update best-run records
- `offlineReport` set for UI sheet

### 4.7 Offline report (`OfflineReport`)

| Field | Meaning |
|-------|---------|
| `gold` | Total granted |
| `duration` | Wall-clock absence |
| `creditedDuration` | Time used in formula (`min(duration, cap)`) |
| `estimatedKills` | `killsPerSec × credited` |
| `hitCap` | `duration > offlineCap` |
| `wasAutoBattle` | Rate branch taken |
| `mercenaryGold` | Share attributed to merc DPS (display only) |

**UI:** `OfflineReportView` — shows credited time; when capped, displays e.g. `4h credited · 10h away` and Patience hint.

---

## 5. Pacing reference (sanity checks)

These are **order-of-magnitude targets**, not guarantees — enemy snapshot and build vary.

| Scenario | ~2h auto offline | ~4h (cap, Patience 0) |
|----------|------------------|------------------------|
| Early run (L1, atk 25, no mercs) | ~500–1.5k | ~1–3k |
| Mid run (L2, atk 35, 10 slayers + 5 archers) | ~8–11k | ~16–22k |
| Same mid run, auto-battle **off** | ~40% of above | ~40% of above |

**Regression tests encode minimum expectations:**

- `MetaProgressionTests.testOfflineGoldStaysBelowKnightSpamThreshold` — 2h mid run &lt; 12k (one Knight).
- `MetaProgressionTests.testOfflineTimeCapLimitsEarnings` — 6h away == 4h away (at default cap).
- `MetaProgressionTests.testOfflineWorksWithoutAutoBattle` — manual path still grants gold.
- `ProgressionTests.testPatienceNodeExtendsOfflineCap` — Patience raises cap and efficiency.

---

## 6. Simplifications vs live combat

The offline model is deliberately **optimistic in some ways, pessimistic in others**:

| Aspect | Offline model | Live combat |
|--------|---------------|-------------|
| Hero damage | Flat `attack − defense` per second | Moves, crit, miss, mana |
| Mercenaries | 10% DPS | 100% DPS |
| Enemy damage / death | Ignored | Full retaliation |
| Layer progress | Frozen at snapshot | Advances per kill |
| Relic drops | None | Boss kills only |
| Gold/kill | Current enemy `generateGold()` | Per-kill on death |

**Known skew:** High `scaleLevel` + strong merc roster can still inflate offline earnings because gold/kill rises with enemy attack while the DPS/HP ratio uses a single snapshot enemy. This was the root cause of the June 2026 “67k in 2h” playtest report.

---

## 7. Tuning knobs

All changes should update **`Balance.swift`**, this doc, and relevant tests together.

| Knob | Effect | Turn down if… | Turn up if… |
|------|--------|---------------|-------------|
| `baseOfflineHours` | Hard time ceiling | Returns feel too generous | Players want longer away payouts |
| `baseOfflineEfficiency` | Auto offline rate | Idle skips merc tiers | Returns feel stingy |
| `manualOfflineEfficiency` | Non-auto away rate | — | Players punished for forgetting toggle |
| `offlineMercenaryDpsFactor` | Merc snowball offline | Meta roster dominates returns | Merc camp feels irrelevant offline |
| `patienceHoursPerLevel` | Cap extension per level | Patience too strong | Patience node weak |
| `patienceEfficiencyPerLevel` | Rate extension per level | Late prestige breaks cap | Patience not worth buying |
| `fortuneGoldPerLevel` | All gold (incl. offline) | Global economy inflates | Gold always tight |

### 7.1 Potential tweaks (not implemented)

| Idea | Rationale |
|------|-----------|
| **Hard gold cap per return** | `min(computedGold, layerBasedCap)` — second safety rail beyond time cap |
| **Layer-averaged enemy** | Use mean gold/kill & HP for current layer instead of snapshot fodder — reduces exploit of saving on weak enemy |
| **Simulated layer drift** | Advance virtual layer during offline at reduced rate — more accurate but harder to explain |
| **Defense-aware merc DPS** | Apply `max(1, mercDps − defense)` — further lowers early offline |
| **Decay after cap** | Some idle games show “full bar” collection; we currently stop at cap (no overflow bank) |
| **Offline-only shop** | Let players spend a fraction of offline gold on meta (controversial — blurs run/meta) |
| **Notification on cap** | Push when offline cap fills (retention; needs platform permission) |
| **balance_sim.py offline mode** | Deterministic offline payout estimator for playtests without device |

### 7.2 Recent tuning history

| Date | Change | Motivation |
|------|--------|------------|
| 2026-06-15 | Shipped offline @ 50% eff, 8h cap | Initial hybrid idle |
| 2026-06-15 | Playtest: ~67k in 2h, multiple Knights | Snowball too fast |
| 2026-06-15 | Defense-aware hero DPS, merc factor, 10% eff | First nerf pass |
| 2026-06-15 | 4h cap, 5.5% / 2.5% eff, merc 10%, credited time in UI | Conservative cap + clarity |

---

## 8. Future work

From [long-term-idle.md](long-term-idle.md) and [idle-design.md](idle-design.md) — **not shipped**:

### 8.1 Near-term (Month 2)

| Feature | Idle impact |
|---------|-------------|
| **Soul Tree: auto-buy consumables** | Auto-shop buys potions/ethers — keeps unattended runs alive deeper |
| **Achievements** | Lifetime gold/kill milestones; optional small permanent offline bonus |
| **Abyss Essence** | Second prestige currency; could gate offline cap extensions or merc slots |

### 8.2 Mid-term (Month 3+)

| Feature | Idle impact |
|---------|-------------|
| **Daily delve modifiers** | e.g. `+3× gold` day — affects offline if snapshot during event |
| **Boss enrage / phases** | Active-only difficulty; offline stays fodder estimate |
| **Classes** | Different offline/heal curves per archetype |
| **Timed boss layer** | Clicker Heroes-style retreat — would need offline failure model |

### 8.3 Aspirational

- **Overflow collection bar** — visual “bank” up to cap, tap to claim (UX polish).
- **Idle simulation replay** — log summary of virtual kills/layers for offline report.
- **Background task accrual** — iOS `BGAppRefreshTask` for partial credit without full relaunch (battery/policy tradeoff).
- **Server-side sync** — cross-device offline integrity (out of scope for solo app today).

---

## 9. File & test map

| File | Role |
|------|------|
| `Models/Balance.swift` | All tuning constants |
| `Models/GameEngine.swift` | `tick()`, `grantOffline`, `offlineCap`, `offlineEfficiency` |
| `Models/GameSave.swift` | `lastSeen`, `OfflineReport` |
| `Models/Mercenary.swift` | `mercenaryDPS` for offline |
| `Models/Enemy.swift` | `generateGold()`, HP/defense for snapshot |
| `Views/CombatView.swift` | Tick timer, auto-battle toggle |
| `Views/OfflineReportView.swift` | Return summary sheet |
| `Views/ContentView.swift` | `scenePhase` → background/foreground |
| `Tests/MetaProgressionTests.swift` | Offline regression tests |
| `Tests/ProgressionTests.swift` | Patience cap/efficiency |
| `docs/tools/balance_sim.py` | Active-run pacing sim (**no offline mode yet**) |

---

## 10. Checklist for changing idle earnings

1. Edit `Balance.swift` constants.
2. Update **this doc** §4.4 and §5 if pacing targets shift.
3. Update `game-design-spec.md` §7 summary table (one-liner + link here).
4. Add/adjust regression test in `MetaProgressionTests` or `ProgressionTests`.
5. Playtest: 2h away early run, 2h mid run with mercs, 8h+ away (cap hit).
6. Consider `balance_sim.py` offline extension if changing formulas heavily.
