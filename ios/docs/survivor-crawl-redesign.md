# AshVault — Survivor Crawl Redesign

**Status:** Proposed north star (June 2026)  
**Replaces as primary vision:** Java-faithful idle RPG loop in `game-design-spec.md`  
**Keeps:** Vault lore, sigils/elements, turn-based combat (our twist on “survivor”)  
**Fun target:** *“One more run”* — the crawl is the game; meta is seasoning.

---

## 1. The pivot in one sentence

**AshVault becomes a turn-based survivor crawl:** each run is a 20–30 minute descent through procedural rings where you draft a build from sigil evolutions, run relics, and ring modifiers — then die, learn, and try a new combo.

Stop shipping an idle RPG that happens to have combat. Ship **combat that happens to have a light shrine meta**.

---

## 2. What we’re leaving behind (Java legacy)

| Legacy | Why it hurts fun | Redesign |
|--------|------------------|----------|
| Boss → shop → next layer every ring | Pacing is economic, not build-driven | Kill bar → **draft pick**; shop is optional pit stop |
| Mercenary meta DPS snowball | Skips the run; idle solves combat | **Run allies** hired with run gold OR cut mercs |
| 25-level × 5-node prestige tree | Spreadsheet endgame, not runs | **~12 total shrine upgrades**, flat bonuses |
| Offline / auto as progression engine | You don’t play; numbers solve it | Offline = small bonus; **manual clearly stronger** |
| Global `scaleLevel` bestiary | Abstract difficulty | **Ring index + modifier** = readable threat |
| Dragon at layer 5 in ~6 min | Campaign over before you care | **10–12 rings** to Vault Heart; dragon is mid-run boss |
| Permanent relics as stat sticks | Collection meta, not build | **Run relics** (stack synergies) + gallery as trophy case |

None of this requires keeping parity with the Java clone.

---

## 3. Player promise (new)

> *Descend ring by ring. Draft power every few kills. Evolve your sigils. Stack relics that combo. Survive until the vault breaks you — then spend a handful of Ash Shards so the next crawl starts a little sharper.*

**Session:** 20–30 min manual crawl (15 min once mastered).  
**Return hook:** “I want to try Frost + Thorns + Hoarder ring.”  
**Not:** “I want to check offline gold and buy goblin #47.”

---

## 4. Core loop (run-first)

```
Start crawl (pick 1 starter sigil + shrine meta)
     │
     ▼
┌─ RING ─────────────────────────────────────────────┐
│  Modifier banner (e.g. "Brittle Seal: +25% enemy ATK") │
│  8–12 guardians → warden boss                        │
│  Each kill: gold + XP toward next DRAFT              │
│  XP full → pause combat → pick 1 of 3 upgrades       │
│  Warden dead → choose: Push Deeper | Camp (shop)     │
└────────────────────────────────────────────────────┘
     │
     ├─ Push Deeper → next ring (harder, new modifier)
     │
     └─ Camp → spend gold (consumables, temp buffs, evolve mats)
     │
     ▼
Die or Retreat to Shrine
     │
     ├─ Death → bank 30% Ash Shards + unlock gallery progress
     └─ Retreat → bank 100% shards + small depth bonus (risk/reward)
```

**No mandatory shop phase after every boss.** Shopping is a **choice** when you need healing or want to roll for an evolution material.

---

## 5. Systems that make runs fun

### 5.1 Run XP + draft picks (VS level-up)

- **XP per kill** scales slightly with ring depth.
- Every **N kills** (tunable: ~4–6 early, ~8 late): combat pauses → **Draft screen** with **3 options**.
- Options drawn from pools weighted by your current build (sigils, relics, stats).

**Draft categories (mix in one screen):**

| Category | Example |
|----------|---------|
| Stat surge | +15% ATK, +20 max HP, +10% crit |
| Sigil tune | −2 Ember mana cost, +burn duration |
| Run relic | "Cinder Heart: burns spread" (see 5.3) |
| Evolution ink | Progress toward evolving a equipped sigil |
| Ring trick | Next ring modifier revealed early; or negate one penalty |

**Banish (optional, 1/run):** Remove one option forever from this run’s pools — classic survivor feel.

Implementation home: `RunDraft.swift`, `Phase.draft`, trigger in `GameEngine` on kill count — **not** on boss-only level-up.

### 5.2 Sigil evolutions (build identity)

Each base sigil has **2 evolution paths** at run level thresholds + a simple condition.

| Base | Evo A (condition) | Evo B (condition) |
|------|-------------------|-------------------|
| Ember Bolt | **Meteor** (8 burn procs) — AoE feel: +50% dmg, burn stacks ×2 | **Kindling** (5 drafts taken) — +dmg per burn on target |
| Frost Shard | **Glacier** (slow 10 enemies) — bonus vs high HP | **Needle** (15 crits) — crits shatter for ignore-def spike |
| Venom Lash | **Plague** (max poison stacks 5×) — poison ticks faster | **Leech** (evolved with Vampiric run relic) — poison heals |
| Arc Lance | **Storm Lance** (10 weakness hits) — chain bonus on WEAK | **Null Bolt** (survive 3 rings sub-30% HP) — execute sub-20% HP |

Evolutions are **run-only** — reset each crawl. Shrine can unlock *seeing* evolutions in the index (collection), not permanent power.

Implementation: extend `SpellDefinition` with `evolvedForm`, track `evolutionProgress` in `RunBuild` struct on `GameEngine`.

### 5.3 Run relics (synergies, not stat sticks)

Bosses and ward chests drop **run relics** (separate from gallery trophies).

- **Up to 6 held** per run; no equip limit — all active (VS passive items).
- **Synergy tags:** `burn`, `frost`, `poison`, `crit`, `thorns`, `greed`, `ward`.
- Examples:

| Relic | Effect | Synergy |
|-------|--------|---------|
| Cinder Heart | Burns can re-apply at 2× dmg once | burn |
| Frost Crown | First hit each fight applies chill (−ATK) | frost |
| Greed Seal | +40% gold, elites spawn in 2nd half of ring | greed |
| Thorn Lattice | Thorns +50%; when thorns proc, gain 1 draft ink | thorns |

**Gallery relics** (meta): cosmetic + tiny flat bonus (+2% gold) — **not** build-defining.

Split `Relic` → `RunRelic` (in-run) and `Trophy` (museum).

### 5.4 Ring modifiers (procedural crawl)

Each ring rolls **1 modifier** from a table (seeded per run for fairness).

Examples:

| Modifier | Effect |
|----------|--------|
| Ash Greed | +50% gold, +1 elite guardian |
| Brittle Seal | Enemies +20% ATK, you +15% crit |
| Fungal Ring | Poison lasts +2 turns; spores on boss death |
| Mirror Vault | Resisted sigils deal 75% instead of 50% |
| Hoarder’s Toll | Shop prices −30%, warden has +30% HP |
| Quiet Ring | No draft picks this ring; double XP next ring |

Show modifier **before** entering ring — lets players plan. Manual players can sometimes **scout** (spend focus — see 5.5).

Implementation: `RingModifier.swift`, stored on `GameEngine.currentRingModifier`, applied in `Enemy.init` and reward hooks.

### 5.5 Manual play rewarded

Auto-battle becomes **Camp Guard** mode — reduced rewards, intended for idle/offline snapshot only.

| | Manual | Auto (Camp Guard) |
|--|--------|-------------------|
| Damage | 100% | 70% |
| Crit / focus gain | Full | None |
| Draft quality | Normal weights | No banish; worse pools |
| Evolution progress | 100% | 50% |
| Offline gold | N/A | Capped, no drafts |

**Focus meter** (0–100): manual attacks and well-timed dodges fill it. Spend for:
- **Burst** — next sigil ×1.5 and applies element rider
- **Scout** — reveal next ring modifier + one draft preview

This gives a reason to tap without requiring frame-perfect play.

### 5.6 Meta: light shrine (12 upgrades total)

Replace 5×25 geometric tree with **3 branches × 4 ranks**:

| Branch | Ranks | Example per rank |
|--------|-------|------------------|
| **Blade** | 4 | +3% ATK, +1 starting focus |
| **Ember** | 4 | Start with 1 random run relic ink, +5% burn |
| **Depth** | 4 | +1 retreat shard, see 1 extra draft option once/run |

**Max cost:** ~40–60 total Ash Shards to max — achievable in **2–3 weeks**, not years.

**Ash Shards:** only from run end (death/retreat). Formula simplified:

```
shards = floor(ringReached / 2) + bossKillsThisRun + (vaultHeartBonus)
```

Gold during run **does not** convert to shards — gold is for **this crawl’s power**.

---

## 6. Run length & difficulty (targets)

| Milestone | Target (manual) |
|-----------|-----------------|
| Ring 1 clear | ~3 min |
| First warden | ~6 min |
| Vault Heart (ring 10 boss) | ~18–22 min first clear |
| Death after Heart (endless) | 25–35 min |
| Full death on strong build | 30+ min |

**Structure:**

- **8 guardians + warden** per ring (tunable via `Balance.enemiesPerLayer`)
- **10 rings** to Vault Heart (campaign)
- **Endless** after Heart with compounding modifiers (not just stat scale)

---

## 7. What happens to existing features

| Feature | Fate |
|---------|------|
| Mercenary camp | **Phase 2:** convert to 3–4 **run hireables** (die with run) OR remove |
| Skill tree UI | Repurpose as **Shrine** (12 nodes) |
| Ascension / withdraw | **Retreat** — mid-run only at camp between rings; risk telegraph |
| Offline | Keep capped gold; **no drafts, no evolutions** |
| Achievements | Keep; re-tag toward crawl feats (evo unlocked, synergy win) |
| Auto-shop | Remove; camp shop is player-driven |
| Phoenix Ash | Keep as rare run save — one per run |
| Type chart / sigils | **Keep — core skill expression** |

---

## 8. UI / feel changes

1. **Draft screen** — full-screen, 3 cards, tap to pick (biggest new UI)
2. **Build panel** — always visible: sigils, evo progress, run relics with synergy highlights
3. **Ring ingress** — modifier banner + “Push deeper?” / “Camp”
4. **Death screen** — build summary: evolutions hit, relics collected, rings, shards gained
5. **Tone** — less shopkeeper, more expedition log

---

## 9. Implementation phases

### Phase 1 — Run skeleton (1–2 weeks)
**Goal:** Feel different in the first 10 minutes.

- [ ] Kill-based XP + `Phase.draft` + 3-choice picks (stats only first)
- [ ] Remove forced shop-after-boss; add Camp choice
- [ ] Extend to 10 rings; move Vault Heart boss
- [ ] Manual damage bonus vs auto penalty
- [ ] Simplify shard formula; demote merc DPS in combat

**Files:** `GameEngine`, `Balance`, new `RunDraft.swift`, `DraftView.swift`, strip auto-shop on boss flow.

### Phase 2 — Build identity (1–2 weeks)
- [ ] Run relics (6 slots, drop from wardens)
- [ ] Sigil evolution tracks + 1 evo per sigil (Ember + Frost first)
- [ ] Synergy tags in draft weighting

**Files:** `RunRelic.swift`, extend `Spell.swift`, `RunBuild` state on engine.

### Phase 3 — Procedural crawl (1 week)
- [ ] Ring modifier table + UI banner
- [ ] Elite guardians (modifier-driven)
- [ ] Banish once per run

### Phase 4 — Meta trim (1 week)
- [ ] Replace skill tree with 12-node Shrine
- [ ] Gallery = trophies only (tiny passive)
- [ ] Rebalance offline to negligible progression

### Phase 5 — Polish & pacing
- [ ] `balance_sim.py` → run-focused sim (drafts, evos, ring mods)
- [ ] Playtest: “name your build” after each run
- [ ] Tune to 20–30 min Vault Heart clear

---

## 10. Success metrics (fun, not economy)

After Phase 2, a playtester should be able to answer:

1. *What build were you going for this run?* (If “I don’t know” → fail)
2. *Why did you start another run?* (Should NOT be “offline gold piled up”)
3. *Did manual play feel better than auto?* (Should be yes)
4. *Was there a moment you almost died and it was exciting?* (Should be yes)

**North star metric:** % of runs where player can name their synergy after death.

---

## 11. First concrete step

If you approve this direction, **Phase 1** is the right cut:

1. Add kill XP → draft picks (stats-only pool)
2. Boss opens **Camp or Push Deeper** instead of forced shop
3. Manual +20% damage, auto −30%
4. Freeze merc meta DPS at 0 in combat until we redesign hireables

That alone breaks the Java rhythm and tells you within a day if the crawl feels more like a game you’d replay.

---

## 12. Related docs (deprioritized)

These remain for reference but are **not** the north star after this doc:

- `game-design-spec.md` — idle hybrid (superseded for vision)
- `crawl-pacing-spec.md` — economy tuning for old model
- `idle-earnings-spec.md` — demote to appendix
- `long-term-idle.md` — contradicts survivor crawl; archive

**Living specs after pivot:** this doc + [dungeon-crawl-pillars.md](dungeon-crawl-pillars.md) + `elemental-combat-spec.md` + `ashvault-narrative-plan.md`
