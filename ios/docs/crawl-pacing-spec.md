# AshVault — Crawl Pacing Spec

**Status:** Living spec (June 2026)  
**Inspiration:** Vampire Survivors / horde-survivor “one more run” loop  
**Code:** `Balance.swift` → `// MARK: - Crawl structure` + `// MARK: - Crawl rewards`  
**Simulator:** `docs/tools/balance_sim.py`  
**Related:** [pacing-spec.md](pacing-spec.md) · [idle-earnings-spec.md](idle-earnings-spec.md)

---

## 1. Design north star

AshVault should feel like a **dungeon crawl**, not a slot machine that pays out overnight.

| Vampire Survivors feel | AshVault equivalent |
|------------------------|---------------------|
| Run lasts 15–30 minutes | Longer rings (7 guardians), tougher HP curve, endless until death |
| In-run power spikes (levels, evolutions) | Boss → level-up → shop after each ring |
| Death still banks currency | **35%** of pending shards salvaged on death |
| Meta shop between runs | Ash Tree + merc camp (meta) |
| “I survived longer” = better payout | **Depth shard bonus** per ring cleared + dragon bonus |
| Idle ≠ skip the game | Offline capped in **gold** and **rate**; active crawl is king |

**Player promise:** Every completed crawl — withdraw or death — should show **what you earned and why**.

---

## 2. Crawl structure

| Constant | Value | Effect |
|----------|-------|--------|
| `enemiesPerLayer` | `7` | Guardians per ring; 7th is the warden (boss) |
| `campaignDragonLayer` | `5` | Ash Dragon warden on ring 5 |
| `enemyScaleHpPerGroup` | `22` | Slower kills → longer active sessions |
| `goldRewardScale` | `0.52` | Tighter run economy |

**Campaign:** 5 rings × 7 guardians = **35 fights** before endless (was 25).  
**Endless:** `postGameDepth = layer − campaignDragonLayer` after the dragon.

---

## 3. Crawl rewards (shard payout)

```
goldShards     = floor(√(runGoldEarned / prestigeShardDivisor))
depthBonus     = layersClearedThisRun × shardBonusPerLayerCleared
                 + (dragonClearShardBonus if dragon slain)
pendingShards  = goldShards + depthBonus
```

| Constant | Value |
|----------|-------|
| `shardBonusPerLayerCleared` | `1` |
| `dragonClearShardBonus` | `3` |
| `deathShardRetention` | `0.35` |

**Withdraw (✨):** bank full `pendingShards`.  
**Death:** bank `floor(pendingShards × deathShardRetention)`; run gold is lost.

This mirrors survivor games where a bad run still feeds meta — without removing tension from voluntary withdraw.

---

## 4. Offline (anti-snowball)

| Constant | Old | New |
|----------|-----|-----|
| `baseOfflineEfficiency` | 5.5% | **3.5%** |
| `manualOfflineEfficiency` | 2.5% | **2.0%** |
| `offlineMercenaryDpsFactor` | 10% | **4%** |
| `offlineGoldCap(layer)` | none | **2500 + 800×layer** |

**Target:** 4h away on post-dragon ring 6 → **~5–7k gold** (not 125k).

---

## 5. Automation gate

| Constant | Old | New |
|----------|-----|-----|
| `automationUnlockShards` | `1` | **`6`** |

First crawls stay **manual** at level-up and shop — players learn the loop before auto takes over.

---

## 6. Session length targets

| Milestone | Target (auto-battle) |
|-----------|----------------------|
| Ring 1 | ≤ 3 min |
| Campaign (rings 1–5) | **8–15 min** |
| Full crawl to endless death (~ring 10) | **15–25 min** |
| First meaningful withdraw | **1–2 sessions** |

Validate:

```bash
python3 ios/docs/tools/balance_sim.py --campaign-only
python3 ios/docs/tools/balance_sim.py --offline --layer 6
```

---

## 7. Optimal path (efficiency)

1. **Manual first crawl** — learn combat, clear ring 1, save gold for first Slayer.
2. **Beat dragon** — triggers +3 shard bonus; celebrate, then push endless until uncomfortable.
3. **Withdraw** when shard payout justifies reset (default auto-withdraw at 8 shards).
4. **Spend shards** — Might → Fortune → Ward (endless survival).
5. **Unlock automation** at 6 lifetime shards — use for repeat crawls, not first run.
6. **Offline** — bonus gold between sessions, not a substitute for crawling.

---

## 8. Tuning workflow

1. Edit `Balance.swift` crawl + offline + reward constants.
2. Mirror in `balance_sim.py` `PACING`.
3. Update `ProgressionKnobTests.swift`.
4. Run sim + `MetaProgressionTests` offline regressions.
5. Playtest one full crawl: withdraw summary + death salvage.

---

## 9. Tuning history

| Date | Summary |
|------|---------|
| 2026-06-16 | Crawl pacing pass: 7 guardians/ring, offline gold cap, depth shard bonuses, death salvage, automation @ 6 shards |
