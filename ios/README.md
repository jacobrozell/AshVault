# AshVault — iOS

A SwiftUI iOS remake of the original one-night Java console game
([`GameDriver.java`](../GameDriver.java), [`Player.java`](../Player.java),
[`Enemy.java`](../Enemy.java)). The turn-based combat math is ported faithfully,
then dressed up with graphics, animation, and a wider move set / bestiary.

## Running it

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
2. Generate the Xcode project:
   ```bash
   cd ios/AshVault && xcodegen generate
   ```
3. Open `ios/AshVault/AshVault.xcodeproj` in Xcode 15+.
4. Pick an iPhone simulator (iOS 16+) and press **Run** (⌘R).

The project is defined in `ios/AshVault/project.yml` (app + unit-test targets).
Regenerate after changing targets, sources, or build settings.

No third-party dependencies — pure SwiftUI.

## How to play

- Enter your name, then **Begin the Crawl**.
- Each layer has **5 enemies**; the 5th is a **boss**.
- Clear a boss to advance a layer and **level up** (pick a stat to boost).
- Reach **Layer 5** and slay the **Ash Dragon** to win.
- Winning unlocks **endless mode**: a "how deep can you go?" score chase where
  enemy stats **compound** each layer. No build keeps up forever — every run
  eventually ends, and your deepest layer is the score.
- You lose when your HP hits 0.

## Moves

| Move | Origin | Effect |
|------|--------|--------|
| **Attack** | original | Standard hit (`ATK − enemy DEF`), can miss via the d10 luck roll; can **crit** for 2× (chance scales with luck). |
| **Heavy Strike** | new | ~1.8× damage, costs 5 mana, 20% chance to **stun**. |
| **Magic Bolt** | new | Ignores enemy defense, always lands, costs 8 mana, 35% chance to **burn**. |
| **Poison Dagger** | new | Light hit that stacks **poison** DoT (up to ×5), costs 4 mana. |
| **Dodge** | original | Try to avoid the next hit; a clean dodge restores HP + mana. |
| **Heal** | original | Restore `10 × level` HP; enemy gets a slightly better swing. |

Plus **consumables** when carried: 🧪 Potion (instant heal) and 🔮 Ether (refill mana).

A lethal blow skips the enemy's retaliation — just like the original's
`break` out of the combat switch.

## Faithful combat math

- **Hit check** (`Dice.checkHit`): roll a d10 (0–9); the hit lands when the
  roll ≥ the target's `luck`. Higher luck = harder to hit. (Ported verbatim
  from the Java `checkHit`.)
- **Player base stats**: HP 60 / ATK 25 / DEF 10 / luck 3.
- **Enemy base stats**: HP 50 / ATK 15 / DEF 5 / luck 5.
- **Level-up**: the chosen stat rises by the larger amount (HP +20, others
  +10) and every other stat by the smaller amount (HP +10, others +5), then
  the hero is fully restored.
- **Ash Dragon**: fixed HP 150 / ATK 100 / DEF 0.
- **Gold reward**: `enemy attack × enemy level`.
- **Escalating difficulty**: the Java original used `static` enemy maxes, so
  every group of five permanently strengthened the whole bestiary. The clone
  reproduces that with a cumulative `scaleLevel` in `GameEngine` instead of
  globals.

## Idle / incremental layer (hybrid)

AshVault is a **hybrid active + idle** game. Full spec:
[`docs/game-design-spec.md`](docs/game-design-spec.md).

- **Auto-battle** — ~1 Hz tick; pauses for level-up / shop / ascension unless automation unlocked.
- **Offline progress** — capped gold on resume; 50% rate with auto-battle, **25% without** (Patience extends cap/rate).
- **Prestige (Soul Shards)** — `floor(√(runGold/100))` shards; Soul Tree (Might / Fortune / Vitality / Ward / Patience).
- **Automation** — after first prestige: auto level-up, shop, and optional **auto-descend** (Settings).
- **Mercenary camp** — meta generators at shop; persist forever; DPS → combat + offline.
- **Relics** — boss drops; equip 3 passives; Relic Museum on title screen.
- **Big-number formatting** (K/M/B/T/aa…).

## Systems & progression

- **Gold shop** between layers — consumables + run-scoped permanents (geometric prices).
- **Mercenary camp** — see [`game-design-spec.md`](docs/game-design-spec.md) §6.1.
- **Relics** — see §6.2.
- **Status effects** — burn, poison, stun; badges under combatants.
- **Sound & music** — `SoundManager` hooks; assets pending (`Audio/CREDITS.md`).
- **Deterministic combat** — injectable `RandomSource`; tests in `AshVaultTests/`.
- **Balance** — all knobs in `Models/Balance.swift` (documented in spec §10).

## Documentation

| Doc | Purpose |
|-----|---------|
| [`docs/README.md`](docs/README.md) | Index — start here |
| [`docs/game-design-spec.md`](docs/game-design-spec.md) | Complete living spec |
| [`docs/systems-overview.md`](docs/systems-overview.md) | Architecture & file map |
| [`docs/long-term-idle.md`](docs/long-term-idle.md) | Retention roadmap |
| [`docs/future-work.md`](docs/future-work.md) | Contributor progress log |

Remaining unscoped ideas are in [`docs/future-work.md`](docs/future-work.md) § backlog.

## Project layout

```
ios/AshVault/
├── project.yml                      // XcodeGen spec (app + unit tests)
├── AshVault.xcodeproj               // generated — run `xcodegen generate`
├── AshVault/
│   ├── AshVaultApp.swift           // @main entry
│   ├── Models/
│   │   ├── Combatant.swift          // shared protocol + status helpers
│   │   ├── Player.swift             // hero stats / level-up / economy
│   │   ├── Enemy.swift              // bestiary + scaling
│   │   ├── GameEngine.swift         // State machine + combat + idle
│   │   ├── Balance.swift            // All tuning (see docs/game-design-spec.md §10)
│   │   ├── GameSave.swift           // Run save + PrestigeStore
│   │   ├── MetaStore.swift          // Mercenaries, relics, lifetime, auto-descend
│   │   ├── Mercenary.swift          // Generator tiers
│   │   ├── Relic.swift              // Collectible passives
│   │   ├── SkillNode.swift          // Soul Tree
│   │   ├── RandomSource.swift       // injectable RNG (testable)
│   │   ├── StatusEffect.swift       // burn / poison / stun / buffs
│   │   ├── ShopItem.swift           // shop catalogue + pricing
│   │   └── SoundManager.swift       // AVFoundation audio (graceful no-op)
│   ├── Views/
│   │   ├── Theme.swift              // palette, panels, animated stat bars
│   │   ├── ContentView.swift        // phase router + title + music
│   │   ├── CombatView.swift         // sprites, bars, moves, log, badges
│   │   ├── LevelUpView.swift         // stat-choice screen
│   │   ├── ShopView.swift            // Between-layers shop
│   │   ├── MercenaryCampView.swift   // Meta generators (in shop)
│   │   ├── RelicMuseumView.swift     // Collection + lifetime stats
│   │   ├── OfflineReportView.swift   // Away earnings summary
│   │   ├── SkillTreeView.swift       // Soul Tree
│   │   ├── AscensionView.swift       // Prestige screen
│   │   ├── SettingsView.swift        // audio toggles
│   │   └── GameOverView.swift        // victory / defeat + run summary
│   └── Audio/CREDITS.md             // where to drop sound/music assets
└── AshVaultTests/              // unit tests (AshVaultTests target via project.yml)
```

## What's new vs. the Java version

- Graphical UI: emoji sprites, animated HP/mana bars, hit flashes, scrolling
  combat log.
- **Mana** resource powering the two new moves (Heavy Strike, Magic Bolt).
- Larger **bestiary** (10 fodder types, 7 mid-bosses) with per-enemy sprites
  and colours.
- Dodge now also restores a little mana on success.
- **Critical hits** (2× damage, luck-driven) with floating combat numbers.
- **Status effects** (burn / poison / stun) plus a Poison Dagger move.
- A **gold shop** + consumables that turn gold into a real economy.
- **Audio**: SFX/music hooks (`SoundManager`) with a settings sheet.
- Endless mode after the dragon, plus a run-summary screen.
- **Best-run persistence** (layer / level / gold) via `UserDefaults`, shown on
  the title screen and flagged with a "New best run!" badge on game over.

## Presentation

- **Light & Dark mode** — follows the system setting. Dark Mode is a moody
  dungeon; Light Mode switches to a readable "stone tablet" palette. Text uses
  `.primary`/`.secondary` and surface/accent colours adapt via a dynamic
  `UIColor` provider in `Theme`.
- **Portrait & landscape** — combat reflows into a side-by-side layout when the
  height is compact (iPhone landscape); the title, level-up and game-over
  screens scroll-fit so nothing clips on short screens.
- **Safe, lightweight animations** (no extra dependencies):
  - Enemy sprite idle-bob, a spring scale-in when each enemy spawns, and a
    flash + screen shake on every hit.
  - Numeric roll-ups (`contentTransition(.numericText())`) on gold and stats.
  - Floating combat numbers that rise and fade (damage, **CRIT!**, heals, misses).
  - Tactile button presses (`PressableButtonStyle`), a pulsing title crest,
    and spring entrances on the level-up / victory screens.
  - Haptic feedback on hits, kills and death.
  - **Reduce Motion** is honoured throughout: the shake, idle-bob, pulsing,
    spring entrances and floating travel all fall back to still / fade-only.
