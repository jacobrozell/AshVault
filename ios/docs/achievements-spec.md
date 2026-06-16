# AshVault — Achievements Spec

**Status:** Planned (not shipped) — design authority for Month 2 meta layer  
**Audience:** Implementers, balance, narrative, QA  
**Related:** [game-design-spec.md](game-design-spec.md) §6.3 · [long-term-idle.md](long-term-idle.md) Month 2 · [beta-feedback-todo.md](beta-feedback-todo.md) · [ashvault-narrative-plan.md](ashvault-narrative-plan.md) · [progressive-unlock-spec.md](progressive-unlock-spec.md)

**Code touchpoints (today):** `LifetimeStats`, `MetaStore`, `BestRun`, `RelicMuseumView`, `GameEngine`, `Narrative`, `GameAnalytics`

---

## 1. Executive summary

Achievements are a **long-term goal layer** that sits on top of systems already in the game: combat, prestige, mercenaries, relics, offline earnings, and lifetime counters. They answer the question beta testers implicitly asked — *"What am I working toward after I beat the dragon?"* — without replacing the Ash Tree, mercenary camp, or endless ladder.

**Player-facing promise:**  
*"The Shrine remembers what you've done in the Vault. Trophies don't make you immortal — but they mark the crawlers who kept going."*

**Design contract:**

| Principle | Meaning |
|-----------|---------|
| **Celebrate, don't gate** | Achievements never block core loops (combat, shop, withdraw, endless). |
| **Mostly memory** | The primary reward is recognition — title, gallery entry, combat-log beat. |
| **Tiny power, hard cap** | Optional account-wide bonuses exist but are **small** and **capped** so they cannot outscale the Ash Tree or relics. |
| **Build on truth** | Prefer counters and flags the engine already maintains; avoid shadow bookkeeping. |
| **One-time pop, quiet after** | First unlock gets a moment; the trophy room is for browsing. |

Achievements are **not** a second prestige currency (that is [Abyss Essence](long-term-idle.md), planned separately). They are **not** a battle pass, daily quest list, or FOMO timer.

---

## 2. Problem statement (beta + roadmap)

### 2.1 Beta feedback

From [beta-feedback-todo.md](beta-feedback-todo.md):

> **Achievements** — meta progression layer building on `LifetimeStats` (also listed in `future-work.md`).

Related tester pain (already partially addressed elsewhere):

- Beat the lich / dragon but unclear what long-term progression means → achievements give **named milestones** beyond raw numbers.
- Level and mercenary clarity → achievement copy can **reinforce** those systems without more tutorial UI.

### 2.2 Product fit (Month 2)

[long-term-idle.md](long-term-idle.md) lists achievements under **Month 2 — Depth**:

> Goals tied to lifetime stats; small permanent bonuses.

North star alignment:

> Every time you open the app, at least two numbers should be going up — and at least one of them should be permanent.

Achievements add a **third** permanent vector: **completed trophies** (and optionally a small capped bonus layer), visible on the title screen and in the Ash Gallery.

### 2.3 What achievements must not do

| Anti-goal | Reason |
|-----------|--------|
| Replace Ash Shards / Ash Tree | Prestige remains the main permanent power ramp. |
| Replace relic hunt | Boss drops stay the chase item for build variety. |
| Replace mercenary milestones | Generator ×2 thresholds are the idle spine. |
| Punish death | Death achievements are observational ("first fall"), not fail states. |
| Require IAP | None in v1. |
| Require cloud / account | Local-only like all other meta. |

---

## 3. Player experience

### 3.1 Discovery flow

```
Title screen
    └── "Trophies" / "Shrine Records" entry (near Ash Gallery)
            └── AchievementsView (grid + categories + progress)
                    ├── Locked: silhouette + hint + progress bar
                    └── Unlocked: icon + name + lore + date unlocked

In-run unlock (first time only)
    └── Toast or compact sheet: "Trophy earned: {name}"
    └── Optional one-line combat log beat (Narrative.Beat)
    └── Haptic .success + SFX purchase-style sting
```

**Entry point (v1):** Title screen, same tier as Ash Gallery and Ash Tree — not buried in Settings.

**In-run intrusion:** Minimal. At most one toast per session tick batch; queue if multiple unlock same frame.

### 3.2 Copy tone

Follow [ashvault-narrative-plan.md](ashvault-narrative-plan.md):

- Player is an **ash-crawler**; achievements are **Shrine records** or **vault testimony**.
- Avoid modern gaming slang ("achievement unlocked!!!"). Prefer short, dry, slightly ominous pride.
- Examples:
  - *"The Shrine records your first withdrawal."* (first prestige)
  - *"You laughed. The Vault did not."* (first death — pairs with existing `FirstDeathBeat`)
  - *"Seal-breaker. The crown ring is behind you now."* (campaign clear)

All strings live in `Narrative` (new `Achievement` enum or nested struct), not scattered in views.

### 3.3 Relationship to Ash Gallery

| Surface | Purpose |
|---------|---------|
| **Ash Gallery** (`RelicMuseumView`) | Equippable boss trophies + lifetime stat **numbers** |
| **Shrine Records** (new `AchievementsView`) | **Goals** and **stories** — what those numbers meant |

**v1:** Keep lifetime stat rows in the museum **and** mirror key thresholds as achievements (intentional overlap — museum = dashboard, achievements = trophy case).

**v2 (optional):** Move lifetime summary entirely into Achievements; museum focuses on relics only.

---

## 4. Architecture

### 4.1 System diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                         GameEngine                                    │
│  Combat · shop · prestige · offline · death · relic drop · …         │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ events (thin hooks)
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    AchievementEvaluator                               │
│  evaluate(event, engine snapshot) → [AchievementID] newly unlocked    │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼
   LifetimeStats          BestRun / run          AchievementState
   (cumulative)          snapshots              (unlocked IDs + dates)
          │                     │                     │
          └─────────────────────┴─────────────────────┘
                                ▼
                          MetaStore persistence
                                ▼
                    AchievementsView · toasts · analytics
```

**Rule:** `GameEngine` does not embed achievement logic inline beyond **one** call site:

```swift
AchievementEvaluator.shared.evaluate(event, context: engine.achievementContext())
```

Evaluator is pure-ish: given event + context → returns IDs to unlock. Engine applies unlocks, persists, surfaces UI.

### 4.2 Data model

#### 4.2.1 `AchievementID` (stable string keys)

```swift
enum AchievementID: String, CaseIterable, Codable {
    case firstKill
    case firstBoss
    case firstDeath
    case firstWithdrawal
    case dragonSlain
    case deepLayer10
    // … see §6 catalog
}
```

**Persistence key:** raw string (`"dragonSlain"`). Never rename without migration.

#### 4.2.2 `AchievementDefinition` (static catalog)

Not persisted — compiled from code (or single JSON bundled in app):

| Field | Type | Purpose |
|-------|------|---------|
| `id` | `AchievementID` | Key |
| `category` | `AchievementCategory` | UI grouping |
| `name` | `String` | Player-facing title |
| `description` | `String` | How to earn (spoiler-safe when locked) |
| `lore` | `String` | Flavor when unlocked |
| `icon` | `String` | SF Symbol or emoji |
| `secret` | `Bool` | Hide description until unlock |
| `condition` | `AchievementCondition` | Evaluator input |
| `reward` | `AchievementReward?` | Optional bonus — see §5 |

#### 4.2.3 `AchievementState` (persisted)

```swift
struct AchievementState: Codable, Equatable {
    /// Unlocked trophy IDs.
    var unlocked: Set<String>
    /// ISO8601 or Unix timestamp per ID (for "earned on …" UI).
    var unlockedAt: [String: Date]
    /// Sum of claimed account bonuses applied (for cap enforcement).
    var bonusGoldPercent: Int      // 0…AchievementCaps.maxBonusGoldPercent
    var bonusStartingHpPercent: Int
}
```

**Storage:** `MetaStore` new key `meta.achievements.v1` (JSON), alongside `meta.lifetime.v1`.

**Survives:** death, ascension, app restart. **Cleared:** only on explicit debug / `MetaStore.clearAll()`.

#### 4.2.4 Extensions to `LifetimeStats`

Current fields ([`MetaStore.swift`](../AshVault/AshVault/Models/MetaStore.swift)):

| Field | Incremented when |
|-------|------------------|
| `totalGoldEarned` | kill gold, offline gold, duplicate relic gold |
| `totalKills` | enemy kill, offline kill estimate |
| `totalBossKills` | boss kill (`enemyIndex == 5`) |
| `totalDescents` | ascension (manual or auto) |
| `relicsFound` | new relic discovered |

**Proposed additions (v1):**

| Field | Increment when | Used for |
|-------|----------------|----------|
| `totalDeaths` | `phase → .defeat` | Death-related trophies |
| `totalRevives` | Phoenix Ash consumed | Safety-net trophy |
| `totalRunsStarted` | `startGame` | Engagement |
| `deepestLayer` | `max(deepestLayer, layer)` on layer clear / endless | Depth trophies |
| `highestRunGold` | `max` on run end / ascension | Economy trophies |
| `phoenixAshesBought` | shop buy | Economy sink trophy |

**Codable migration:** new fields default to `0` on decode (optional properties or custom `init(from:)`).

#### 4.2.5 Run-scoped stats (`RunStats` — not persisted across death)

For "this run only" challenges (phase 2). Held on `GameEngine`, reset in `startGame`:

```swift
struct RunStats {
    var healsUsed: Int
    var phoenixAshUsed: Bool
    var layersClearedThisRun: Int
    var damageTaken: Int
    var manualMoves: Int  // non-auto-battle
}
```

Not required for v1 catalog except optionally `phoenixAshUsed` if we add a hidden trophy.

#### 4.2.6 One-shot flags (existing patterns)

Reuse the `FirstDeathBeat` / `OnboardingSettings` pattern for achievements that must fire **exactly once** even if stats regress (shouldn't happen):

| Flag | Exists today? | Trophy |
|------|---------------|--------|
| `FirstDeathBeat.hasShown` | Yes | Map to `firstDeath` achievement |
| Onboarding completed | Yes (`OnboardingSettings`) | Optional `completedOnboarding` |

**Recommendation:** On unlock, write to `AchievementState.unlocked` **and** keep existing flags; evaluator checks both to avoid double-award during migration.

### 4.3 Evaluation model

#### 4.3.1 Event types

```swift
enum AchievementEvent {
    case runStarted
    case enemyKilled(wasBoss: Bool)
    case playerDied
    case phoenixAshRevived
    case layerCleared(layer: Int)
    case dragonSlain
    case prestige(shardsGained: Int, totalShards: Int)
    case relicDiscovered(count: Int)
    case mercenaryHired(merc: Mercenary, totalOwned: Int)
    case offlineGold(gold: Int, hitCap: Bool)
    case shopPurchase(ShopItem)
    case runEnded(reason: String, layer: Int, level: Int, gold: Int)
    case appForegrounded  // for session-count achievements (phase 2)
}
```

Emit from existing `GameEngine` hooks — same places as `GameAnalytics.track` today.

#### 4.3.2 Condition types

```swift
enum AchievementCondition {
    case lifetimeStat(LifetimeStatKey, >=, Int)
    case bestRun(BestRunKey, >=, Int)
    case flag(AchievementID)  // manual / narrative
    case allInCategory(AchievementCategory)  // meta-collection
    case and([AchievementCondition])
    case or([AchievementCondition])
}
```

**Evaluation frequency:**

| Trigger | Re-evaluate |
|---------|-------------|
| After each `AchievementEvent` | All achievements whose `condition` depends on changed stats |
| On app launch (title) | Full scan once (cheap — &lt;50 definitions) |

**Idempotence:** Unlocking is idempotent; `unlocked` set dedupes.

### 4.4 Rewards (account bonuses)

From roadmap: *small permanent bonuses*. **Strict cap** to protect pacing ([pacing-spec.md](pacing-spec.md), [idle-earnings-spec.md](idle-earnings-spec.md)).

#### 4.4.1 `AchievementReward`

```swift
enum AchievementReward {
    case accountGoldPercent(Int)       // stacks into bonusGoldPercent
    case accountStartingHpPercent(Int) // stacks into bonusStartingHpPercent
    case cosmeticTitle(String)         // display under crawler name (phase 2)
    case none                          // lore-only trophy
}
```

#### 4.4.2 Global caps (`AchievementCaps`)

| Bonus type | Per-trophy max | Account cap | Applied in |
|------------|----------------|-------------|------------|
| Gold earned | +1% | **+5% total** | `goldMultiplier` chain |
| Starting max HP | +1% | **+5% total** | `startGame` / `applyPrestige` |
| Offline efficiency | — | **0% in v1** | Defer — Patience node owns this |
| Damage reduction | — | **0% in v1** | Ward node owns this |

**Implementation sketch:** `GameEngine` reads `AchievementState.bonusGoldPercent` and multiplies alongside Fortune / Gold Tooth with a hard `min(cap, sum)`.

**Balance rule:** Sum of all achievement combat power ≈ **less than one** low-level Ash Tree node. Trophies are flavor-first.

#### 4.4.3 What achievements do NOT grant

- Ash Shards directly (would skip prestige loop)
- Relics or mercenaries (would skip gold sinks)
- Extra Phoenix Ash charges
- Automation unlock (stays `totalShards >= 1`)

---

## 5. UI specification

### 5.1 `AchievementsView`

**Layout:**

- Navigation title: **Shrine Records** (or `Narrative.Term.shrineRecords`)
- Header panel: `unlocked.count / total.count` + optional account bonus summary ("+3% gold from trophies")
- Category picker or sections:
  1. **The Crawl** — runs, layers, deaths
  2. **The Shrine** — prestige, Ash Tree, withdrawals
  3. **The Camp** — mercenaries, gold, shop
  4. **The Gallery** — relics, bosses
  5. **Secrets** — hidden until unlocked

**Card (locked):**

- Silhouette icon (SF Symbol `lock.fill` overlay)
- Name: "???" or hinted name for non-secret
- Progress: `47 / 100 bosses` when `lifetimeStat` condition
- Accessibility: "Locked achievement. Progress 47 of 100 bosses slain."

**Card (unlocked):**

- Full icon + gold border (match relic equipped styling)
- Name + lore paragraph
- Footnote: unlocked date (relative: "3 days ago")
- If reward: small badge "+1% gold"

**Adaptive layout:** Reuse `AccessibilityLayout.metaGridColumnCount` patterns from `RelicMuseumView` / `MercenaryCampView`.

### 5.2 Unlock toast / sheet

**Trigger:** First unlock in a session or any unlock (config flag).

**Content:**

- Trophy icon + name
- One-line lore
- Dismiss: tap or 3s auto-dismiss (respect Reduce Motion)

**Do not** block combat input longer than relic-found sheet.

### 5.3 Title screen entry

In `TitleView`, below Ash Gallery link:

```swift
Label("Shrine Records \(unlocked)/\(total)", systemImage: "rosette")
```

Show **pulse** when new unlock since last visit (`AchievementState.hasUnread`).

### 5.4 Combat log beats

Optional `Narrative.Beat` for **milestone** trophies only (dragon, first prestige, deepest layer record) — same policy as `milestoneFirstShard`.

---

## 6. Achievement catalog (v1)

**Legend:**

- **Cat:** category
- **Cond:** condition shorthand
- **Reward:** `—` = none, `G1` = +1% gold (account), `H1` = +1% starting HP

### 6.1 The Crawl — runs & survival

| ID | Name | Cond | Reward | Notes |
|----|------|------|--------|-------|
| `firstBlood` | First Blood | `totalKills >= 1` | — | Tutorial-adjacent |
| `firstFall` | First Fall | `FirstDeathBeat` or `totalDeaths >= 1` | — | Sync with narrative beat |
| `tenDeaths` | Familiar Scattering | `totalDeaths >= 10` | — | Long-term |
| `layer3Reach` | Ring Three | `deepestLayer >= 3` | — | Campaign progress |
| `dragonSlain` | Seal-Breaker | `clearedFinalBoss` on any run end | G1 | Campaign climax |
| `deep10` | Deep AshVault X | `deepestLayer >= 10` | — | Endless |
| `deep25` | Deep AshVault XXV | `deepestLayer >= 25` | G1 | Endless grind |
| `deep50` | Below the Map | `deepestLayer >= 50` | H1 | Whale target |
| `newBestLayer` | Deeper Still | `BestRun.layer` improved | — | Repeatable? **No** — fire once per account when first setting `best.layer >= 6` |
| `phoenixRise` | Ashen Resurrection | `totalRevives >= 1` | — | Phoenix Ash |
| `noPhoenixClear` | True Death | Campaign clear **without** `phoenixAshUsed` this run | G1 | Phase 2 / needs `RunStats` |
| `weakSigil` | Aspect Reader | first super-effective sigil or Venom weak hit | — | `sigilWeakHit` event; backfill via teaching flag |
| `sigilScholar` | Second Binding | `masteredSigilCount >= 2` | — | Frost/Arc scroll purchase |

### 6.2 The Shrine — prestige & Ash Tree

| ID | Name | Cond | Reward | Notes |
|----|------|------|--------|-------|
| `firstWithdrawal` | First Withdrawal | `totalDescents >= 1` | — | Pairs with milestone shard beat |
| `tenWithdrawals` | Habitual Pilgrim | `totalDescents >= 10` | — | |
| `shardHoarder` | Shard Hoarder | `totalShards >= 50` | — | Read from `PrestigeStore` at eval |
| `might5` | Blade Remembered | `SkillNode.might` level >= 5 | — | |
| `ward10` | Warded Crawler | `SkillNode.ward` level >= 10 | H1 | Endless survival |
| `treeMaxOne` | One Branch Mastered | any `SkillNode` level >= 25 | G1 | Max one node |

### 6.3 The Camp — economy & mercenaries

| ID | Name | Cond | Reward | Notes |
|----|------|------|--------|-------|
| `gold1k` | Pocket of Ash | `totalGoldEarned >= 1_000` | — | |
| `gold100k` | Treasury Taster | `totalGoldEarned >= 100_000` | G1 | |
| `gold1m` | Vault's Accountant | `totalGoldEarned >= 1_000_000` | — | Late idle |
| `hireFirstMerc` | Signed at the Mouth | any merc count >= 1 | — | |
| `milestone25` | Camp Chorus | any merc count >= 25 | — | Matches ×2 milestone |
| `fullRoster` | Full Camp | each mercenary `count >= 1` | — | 5 tiers |
| `knightOwner` | Knight's Patron | `knight count >= 1` | — | 12k gold sink |
| `phoenixBuyer` | Bought Insurance | `phoenixAshesBought >= 1` | — | Economy sink |

### 6.4 The Gallery — relics & bosses

| ID | Name | Cond | Reward | Notes |
|----|------|------|--------|-------|
| `firstRelic` | First Trophy | `relicsFound >= 1` | — | |
| `fullGallery` | Gallery Complete | `discoveredRelics.count == Relic.allCases.count` | H1 | 6 relics |
| `boss10` | Warden Hunter | `totalBossKills >= 10` | — | |
| `boss100` | Seal Killer | `totalBossKills >= 100` | G1 | |
| `equipThree` | Triad Bound | 3 relics equipped simultaneously | — | Snapshot at equip time |

### 6.5 Secrets (hidden description until unlock)

| ID | Name | Cond | Reward |
|----|------|------|--------|
| `idleCap` | Time's Ceiling | offline report `hitCap == true` once | — |
| `autoWithdraw` | Hands Off | auto-descend triggers ascension once | — |
| `firstCrit` | Lucky Strike | log contains crit (one-shot flag) | — |
| `surviveOneshot` | Still Standing | survive a hit that dealt >= 45% max HP | — | Needs damage event |

**Total v1:** ~37 trophies.

---

## 7. Hook map (`GameEngine` → events)

| Location | Event |
|----------|-------|
| `startGame(named:)` | `runStarted`; increment `totalRunsStarted` |
| `resolveDeaths` enemy branch | `enemyKilled(wasBoss:)` |
| `resolveDeaths` player defeat | `playerDied` |
| `tryPhoenixAshRevive()` | `phoenixAshRevived` |
| `handleBossDefeated` | `layerCleared`; if final `dragonSlain` |
| `performAscension` / auto-descend | `prestige` |
| `tryRelicDrop` new relic | `relicDiscovered` |
| `hireMercenary` | `mercenaryHired` |
| `grantOffline` | `offlineGold` |
| `buy(.phoenixAsh)` | `shopPurchase` |
| `recordRun` + defeat/victory | `runEnded` |
| `chooseUpgrade` / `upgradeNode` | re-eval Ash Tree conditions |
| `surfaceSigilHit` / Venom Lash poison (weak) | `sigilWeakHit` |
| `buySigilScroll` | `sigilMasteryUpdated(count:)` |

**Analytics:** Add `achievement_unlocked` to `GameAnalyticsEvent` with params `id`, `category` (allowlist).

---

## 8. Persistence & migration

### 8.1 Keys

| Key | Content |
|-----|---------|
| `meta.achievements.v1` | `AchievementState` JSON |
| `meta.lifetime.v1` | Extended `LifetimeStats` |

### 8.2 Upgrade path

1. Ship evaluator + state with **no UI** — backfill unlocks from lifetime on first launch.
2. Ship `AchievementsView` + title link.
3. Ship toasts + bonuses.

**Backfill algorithm (first launch after update):**

```swift
for def in AchievementDefinition.all {
    if evaluator.isMet(def.condition, lifetime, best, relics, tree) {
        state.unlock(def.id)
    }
}
```

Existing veterans get a burst of unlocks — **acceptable**; show summary sheet once: *"The Shrine remembers your past crawls."*

### 8.3 Debug

- `MetaStore.clearAll()` clears achievements (already clears lifetime).
- Hidden debug menu (future): unlock one / reset / print eval context.

---

## 9. Implementation phases

### Phase A — Data & backfill (1 PR)

- [ ] `AchievementID`, `AchievementDefinition`, `AchievementState`
- [ ] `MetaStore` load/save achievements
- [ ] Extend `LifetimeStats` + migration-safe decode
- [ ] `AchievementEvaluator` + unit tests (pure conditions)
- [ ] Backfill on `GameEngine.init` after meta load
- [ ] No UI

### Phase B — Shrine Records UI (1 PR)

- [x] `AchievementsView` + title entry
- [x] `Narrative` strings for all v1 trophies
- [x] Accessibility labels, Dynamic Type, landscape

### Phase C — Moments & bonuses (1 PR)

- [x] Unlock toast
- [x] `AchievementCaps` bonuses wired in `startGame` / gold
- [x] `GameAnalytics.achievementUnlocked`
- [x] Selected `Narrative.Beat` on key trophies

### Phase D — Secrets, run-scoped & full catalog (done)

- [x] `RunStats` on `GameEngine` (reset in `startGame`)
- [x] Full v1 catalog (~35 trophies) per §6
- [x] Secrets category + witness flags in `AchievementState`
- [x] Run-scoped: `noPhoenixClear`, damage/crit/offline-cap hooks
- [x] `upgradeNode` / `toggleEquipRelic` re-eval hooks

### Phase E — Game Center (planned)

**Principle:** Local `AchievementState` remains canonical; Game Center is a **reporting layer**.

| Step | Work |
|------|------|
| 1 | App Store Connect: create achievements with IDs matching `AchievementID.rawValue` |
| 2 | `GameCenterService` protocol + `GKAchievement` report on `deliverAchievementUnlocks()` |
| 3 | Backfill report on first GC auth (mirror veteran backfill sheet) |
| 4 | Optional: leaderboards for deepest layer / best run (separate from trophies) |

**Out of scope until Phase E:** GC UI entry, friend leaderboards, cross-device sync.

---

## 10. Testing strategy

### 10.1 Unit tests (`AchievementEvaluatorTests`)

- Each condition type in isolation with stub context
- Cap enforcement: 6× `G1` rewards → only +5% applied
- Backfill: given `LifetimeStats` fixture → expected unlock set
- Idempotence: double event → single unlock

### 10.2 Integration tests (`AchievementIntegrationTests`)

- Kill enemy → `firstBlood`
- Full prestige flow → `firstWithdrawal`
- Phoenix revive → `phoenixRise`
- Codable round-trip `AchievementState`

### 10.3 Playtest / balance

- Run `PlaytestHarness` campaign seeds — confirm achievement bonuses do not change clear rate by more than **~2%** (same bar as knob changes in [pacing-spec.md](pacing-spec.md))
- Verify backfill does not block title screen (&lt;100ms on main thread — evaluate in background if needed)

---

## 11. Success metrics

| Metric | Target |
|--------|--------|
| Title screen trophy entry tap rate | ≥15% of DAU after week 1 |
| Players with ≥3 trophies after 3 runs | ≥70% |
| Achievement bonus correlated with deeper `BestRun.layer` | Positive but &lt; Ash Tree correlation |
| Support burden | No "how do I earn X" confusion in playtest — every locked card shows progress |

Qualitative: players can articulate a **long-term goal** beyond "go deeper."

---

## 12. Out of scope (v1)

- Game Center / Google Play achievements
- Cloud sync / cross-device
- Leaderboards
- Daily / weekly rotating achievements
- Achievement points currency
- Gating features (see [progressive-unlock-spec.md](progressive-unlock-spec.md) — separate system)
- Replacing `FirstDeathBeat` with achievement-only logic (keep both)
- Per-class achievements (Month 3 classes)

---

## 13. Open questions

| # | Question | Default if unresolved |
|---|----------|------------------------|
| 1 | Account bonuses vs pure cosmetic? | **Small capped bonuses** per roadmap |
| 2 | Separate screen vs tab inside museum? | **Separate** `AchievementsView` |
| 3 | Repeatable achievements (weekly layer race)? | **No** — v1 all permanent |
| 4 | Show locked secret names? | **No** — show "???" |
| 5 | Notify for backfilled unlocks? | **One summary sheet**, not 20 toasts |
| 6 | Tie to Abyss Essence? | **Independent** — essence ships separately |
| 7 | Game Center? | **Phase E** — local state canonical; GC reports on unlock |

---

## 14. Document cross-references

When implementing, also update:

| Doc | Section |
|-----|---------|
| [game-design-spec.md](game-design-spec.md) | §6.3 lifetime stats, §9 UI surfaces |
| [systems-overview.md](systems-overview.md) | Meta layer diagram |
| [beta-feedback-todo.md](beta-feedback-todo.md) | Mark achievements done |
| [future-work.md](future-work.md) | Progress log entry |
| [README.md](README.md) | Index row |

---

## 15. Changelog

| Date | Change |
|------|--------|
| 2026-06-16 | Phase B/C shipped — Shrine Records UI, toasts, analytics |
| 2026-06-16 | Phase D/E roadmap — full catalog, secrets, Game Center reporting layer |
