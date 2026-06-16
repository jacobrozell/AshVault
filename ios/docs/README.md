# AshVault — Documentation Index

Living design and implementation specs for the iOS app. When you change game
behavior, update the relevant doc **and** `Models/Balance.swift` together.

## Start here

| Doc | What it covers |
|-----|----------------|
| [**game-design-spec.md**](game-design-spec.md) | **Complete spec** — combat, run loop, prestige, mercenaries, relics, offline, persistence, UI, balance tables |
| [**systems-overview.md**](systems-overview.md) | Architecture diagram, phase machine, persistence layers, file map |
| [**pacing-spec.md**](pacing-spec.md) | **Progression tuning** — knob table, tweak workflow, sim CLI, pacing targets |
| [**idle-earnings-spec.md**](idle-earnings-spec.md) | **Idle earnings deep dive** — auto-battle tick, offline formula, tuning knobs, pacing targets, future work |
| [**long-term-idle.md**](long-term-idle.md) | Product north star, retention roadmap (Month 1–3), future work |
| [**idle-design.md**](idle-design.md) | Original hybrid-idle research study (June 2026); historical context |
| [**ashvault-narrative-plan.md**](ashvault-narrative-plan.md) | **Lore bible** + phased plan to bake story into UI and combat log |
| [**progressive-unlock-spec.md**](progressive-unlock-spec.md) | **Planned:** gated onboarding — unlock features through play (not shipped) |
| [**beta-feedback-todo.md**](beta-feedback-todo.md) | **Beta playtest backlog** — open items from tester feedback |
| [**agent-build-checklist.md**](agent-build-checklist.md) | **Engineering checklist** — 0→Ship phases, progress log, release gates |
| [**achievements-spec.md**](achievements-spec.md) | Shrine Records — lifetime trophies, caps, hook map (Phases A–D shipped; E Game Center planned) |
| [**elemental-combat-spec.md**](elemental-combat-spec.md) | Enemy aspects, sigil loadout (3 slots), type chart, shop scrolls (**shipped**) |

## By task

| I want to… | Read |
|------------|------|
| Tune progression / pacing | **[pacing-spec.md](pacing-spec.md)** → `Balance.swift` `// MARK: - Progression` |
| Simulate pacing (no device) | `python3 docs/tools/balance_sim.py --campaign-only` (or `--gold-scale 0.45` what-if) |
| Verify knob values | `xcodebuild test -scheme AshVault -only-testing:AshVaultTests/ProgressionKnobTests` |
| Add a relic or mercenary | `game-design-spec.md` § Meta progression |
| Change offline / auto-descend | [idle-earnings-spec.md](idle-earnings-spec.md) |
| Change prestige / ash tree | `game-design-spec.md` § Prestige |
| Design first-run / unlock onboarding | **[progressive-unlock-spec.md](progressive-unlock-spec.md)** (future) |
| Design achievements / Shrine Records | **[achievements-spec.md](achievements-spec.md)** |
| Design elemental weaknesses / sigils | **[elemental-combat-spec.md](elemental-combat-spec.md)** |
| Check ship readiness / engineering phases | **[agent-build-checklist.md](agent-build-checklist.md)** |
| Run the app | [`../README.md`](../README.md) |

## Persistence keys (quick reference)

| Store | Key prefix | Survives |
|-------|------------|----------|
| `SaveStore` | `save.run.v1` | App close (single in-progress run) |
| `PrestigeStore` | `prestige.shards.v1`, `prestige.tree.v1` | Death, ascension, new runs |
| `MetaStore` | `meta.mercenaries.v1`, `meta.relics.*`, `meta.lifetime.v1`, `meta.achievements.v1` (planned) | Death, ascension, new runs |
| `BestRun` | `best.layer`, `best.level`, `best.gold` | Forever |
| `AutoDescendSettings` | `autoDescend.enabled`, `autoDescend.minShards` | Forever (UserDefaults) |
| `@AppStorage` audio | `audio.sfxEnabled`, `audio.musicEnabled` | Forever |

## Test targets

Unit tests: `ios/AshVault/AshVaultTests/`. Key suites:

- `GameEngineTests` — combat flow, shop, save/restore
- `PrestigeTests` — shards, soul tree, automation
- `ProgressionKnobTests` — pacing constant regression lock
- `MetaProgressionTests` — mercenaries, relics, offline, auto-descend
- `ProgressionTests` — prestige nodes, offline cap

Run: `xcodebuild test -scheme AshVault -destination 'platform=iOS Simulator,name=iPhone 17'`
