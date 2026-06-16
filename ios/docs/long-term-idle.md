# AshVault — Long-Term Idle Design

**North star:** Every time you open the app, at least two numbers should be going
up — and at least one of them should be permanent.

**Player promise:** Fun in short doses (manual combat, relic hunts, shop choices),
rewarding to leave running (auto-battle + offline + mercenary income), and
rewarding to open periodically (offline report, new relics, deeper records).

**Full implementation spec:** [`game-design-spec.md`](game-design-spec.md) §6–8.

---

## Foundation (pre–Month 1)

- Hybrid idle: auto-battle tick, offline gold, prestige Soul Shards, Soul Tree
- Automation after first prestige (auto level-up / shop)
- Endless score chase (deepest layer)
- Ward prestige node for survival scaling

---

## Roadmap

### Month 1 — Hook ✅ DONE

| Feature | Spec | Status |
|---------|------|--------|
| Mercenary camp | [§6.1](game-design-spec.md#61-mercenary-camp) | Shipped |
| Relics + museum | [§6.2](game-design-spec.md#62-relics) | Shipped |
| Auto-descend | [§8](game-design-spec.md#8-auto-descend) | Shipped |
| Richer offline | [§7.2](game-design-spec.md#72-offline-progress) | Shipped |
| Lifetime stats | [§6.3](game-design-spec.md#63-lifetime-stats) | Shipped (museum UI) |

### Month 2 — Depth (planned)

| Feature | Intent |
|---------|--------|
| **Abyss Essence** | Second prestige currency for automation unlocks, extra merc slots |
| **Achievements** | Goals tied to lifetime stats; small permanent bonuses |
| **Soul Tree expansion** | Crit %, starting potions, auto-buy consumables nodes |

### Month 3 — Retention (planned)

| Feature | Intent |
|---------|--------|
| **Daily delve** | Seeded modifier run (e.g. +3× gold, faster burn) |
| **Boss mechanics** | Phases, enrage timers in endless |
| **Classes** | Warrior / rogue / mage build identity |

---

## Design principles

- **Short sessions:** Manual combat stays sharp; relic drops and shop choices give active players something to do in 2–5 minutes.
- **Background play:** Auto-battle + mercenary DPS + offline accrual should always feel like progress happened.
- **Return visits:** Offline report, new relic sparkle, "new deepest layer" badge, milestone pops.
- **Infinite treadmills:** Mercenary counts, relic collection, future essence layer — never fully "done."

---

## Quick math reference

See [`game-design-spec.md`](game-design-spec.md) for full formulas. Summary:

| System | Formula |
|--------|---------|
| Mercenary cost | `base × 1.12^owned` |
| Mercenary DPS | `baseDPS × count × milestoneMult` (×2 at 25/50/100/200/400) |
| Relic drop | 18% on boss kill; duplicate → 40g |
| Shards | `floor(√(runGold/100))` |
| Offline gold | `DPS/enemyHP × gold/kill × creditedTime × rate × multipliers` — see [idle-earnings-spec.md](idle-earnings-spec.md) |

---

## Lineage

- Research study: [`idle-design.md`](idle-design.md) (hybrid Level B — chosen & built)
- Progress log: [`future-work.md`](future-work.md)
- Architecture: [`systems-overview.md`](systems-overview.md)
