# AshVault — Dungeon Crawl Pillars

**Status:** Living north star (June 2026)  
**Extends:** [survivor-crawl-redesign.md](survivor-crawl-redesign.md)  
**Code truth:** `RingCrawl.swift`, `Balance.swift` (crawl section), `GameEngine.swift`

AshVault is a **turn-based dungeon crawler** on mobile: descent under scarcity, meaningful forks, and build-driven runs — not an idle RPG with combat attached.

---

## 1. Genre promise

> *Descend ring by ring into a sealed vault. Every door is a gamble. Supplies run low. Draft power from kills, camp when you must, and reach the Vault Heart — or retreat to the Shrine with your shards.*

**Session:** 20–30 min manual (15 min mastered).  
**Return hook:** “I want to try Frost + Hoarder’s Toll + elite route.”  
**References:** [Skeleton Code Machine — dungeon crawl essentials](https://www.skeletoncodemachine.com/p/what-makes-a-dungeon-crawl-good), Hades room forks, Slay the Spire path choice, OSR supply/time tension.

---

## 2. Three pillars (every feature must serve one)

| Pillar | Player feeling | AshVault expression |
|--------|----------------|---------------------|
| **Discovery** | “What’s next?” | Ring modifiers, door forks, hidden elite/shrine routes |
| **Risk & agency** | “I chose this danger.” | Supplies, camp cost, push vs. heal, manual > auto |
| **Progression arc** | “This run had a story.” | Drafts, wardens, depth shards, death summary |

---

## 3. Run structure (ring graph)

No tile map. Each ring is a **small graph** of nodes:

```
Shrine → [Ring ingress: modifier + door fork] → combat nodes (8 guardians + warden)
              ↓                                        ↓
         Push Deeper ←——————————————————————— Camp (supplies + gold)
              ↓
         Next ring … → Vault Heart (ring 10) → endless
```

### Node types (implemented / planned)

| Node | Phase | Supplies | Reward |
|------|-------|----------|--------|
| **Guard** | Combat | −1 on ring entry | Gold + draft XP |
| **Elite** | Combat (buffed) | −1 per kill | +50% gold, faster draft |
| **Shrine** | Instant | 0 | Heal 25% max HP, small gold |
| **Sealed** | Puzzle combat | −1 | Evolution ink (Phase 5) |
| **Warden** | Boss | 0 | Relic roll, ring clear |

Ring 1 skips door choice (tutorial). Door forks from ring 2 onward.

---

## 4. Supplies (risk economy)

Supplies are the crawl’s **soft timer** — like torches in OSR dungeons.

| Knob | Default | Role |
|------|---------|------|
| `startingSupplies` | 32 | ~10 rings + auto-camp budget |
| `supplyCostPerRing` | 1 | Charged at ring ingress |
| `supplyCostCamp` | 2 | Retreat has cost |
| `supplyStarvedEnemyAtkPercent` | 15 | Punish pushing at 0 |

At **0 supplies**, enemies gain +15% ATK (“delirious descent”). Camp restores HP but burns supplies — never free.

---

## 5. Ring modifiers (biomes)

One modifier per ring, rolled at ingress, shown before doors.

| Modifier | Effect |
|----------|--------|
| **Ash Greed** | +35% gold this ring |
| **Brittle Seal** | Enemy ATK +15% |
| **Hoarder’s Toll** | Camp prices −25%; warden HP +25% |
| **Quiet Ring** | +2 kills per draft this ring |
| **Fungal Ring** | Enemy HP +10% |

Future: synergize with sigils (burn/poison tags), elites per modifier.

---

## 6. Door fork (path choice)

At ring ingress (ring ≥ 2), player picks **one of two doors**:

| Door | Risk | Payoff |
|------|------|--------|
| ⚔️ **Guard** | Standard | Predictable |
| 💀 **Elite** | +40% HP/ATK first fight | Bonus gold on that kill |
| 🕯️ **Shrine** | None | Heal 25% HP, skip one fight |

Auto-battle (Camp Guard) picks **Guard** unless HP < 50% (then Shrine if offered).

---

## 7. Camp vs. push

| | Push Deeper | Make Camp |
|--|-------------|-----------|
| Supplies | No cost | −2 |
| HP | Carry wounds | Shop + restock |
| Depth | Progress | Pause only |

**Retreat to Shrine** (planned): at camp only — bank 100% shards, forfeit run relics/gold.

---

## 8. Tension waves (rings 1–10)

| Band | Rings | Feel |
|------|-------|------|
| Teach | 1–2 | Learn drafts, first fork |
| Pinch | 3–4 | Supplies matter |
| Mid | 5–6 | Build online |
| Peak | 7–8 | “Almost busted” combos |
| Attrition | 9–10 | Vault Heart marathon |

---

## 9. Meta (horizontal only)

See survivor-crawl redesign §5.6. Max ~12 shrine nodes. Unlocks expand **options**, not 10× power.

---

## 10. Implementation phases

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 | Drafts, camp choice, 10 rings | ✅ |
| 3a | Supplies + modifiers + door fork | ✅ this doc |
| 2 | Run relics + synergy UI | Planned |
| 3b | Elite/shrine polish, banish | Planned |
| 4 | 12-node Shrine | Planned |
| 5 | Sealed rooms, micro-quests | Planned |

---

## 11. Success tests

1. *Why did you camp?* → supplies or HP, not “always.”
2. *What door did you skip?* → fork mattered.
3. *Name your build* → draft identity.
4. *Scared at 1 supply?* → tension landed.

---

## 12. Tuning workflow

```bash
cd ios/AshVault
xcodebuild test -only-testing:AshVaultTests/RingCrawlTests
xcodebuild test -only-testing:AshVaultTests/PlaytestTests/testPrintCampaignDiagnostics
python3 ios/docs/tools/survivor_tune.py
```

Edit `Balance.swift` crawl knobs + `ProgressionKnobTests` together.
