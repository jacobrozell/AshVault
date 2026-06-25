# AshVault

AshVault is a turn-based dungeon crawler that started as a **one-night Java console game** — the three files in this repo root ([`GameDriver.java`](GameDriver.java), [`Player.java`](Player.java), [`Enemy.java`](Enemy.java)). No frameworks, no graphics: just combat logic, layer progression, and a dragon at the end.

This project is a **remake and expansion** of that original. The iOS app in [`ios/`](ios/) ports the core combat math faithfully, then builds on it with SwiftUI, idle/incremental systems, prestige, relics, and a much wider move set.

**Status:** Active development · v1.0.0 (1–2) · **Branch:** `main` · App Store not submitted

---
## Play the remake

See [`ios/README.md`](ios/README.md) for setup, gameplay, and documentation.

## Engineering

AshVault follows the same meta patterns as [Dart Buddy](https://github.com/jacobrozell/Dart-Buddy): test-backed game logic, CI on every push, hosted legal pages, and privacy-conscious Firebase telemetry in Release.

| Area | What we have |
|------|----------------|
| **Tests** | 25+ unit test files covering combat, prestige, economy, serialization, pacing knobs |
| **CI** | GitHub Actions — SwiftLint, XcodeGen, `AshVaultCI` scheme on dedicated **AshVault** simulator (`.github/workflows/ci.yml`) |
| **Docs** | Living game specs in [`ios/docs/`](ios/docs/); GitHub Pages for privacy, support, accessibility ([`docs/`](docs/)) |
| **Analytics** | Allowlisted Firebase events in Release only (`Support/GameAnalytics.swift`) |
| **Accessibility** | VoiceOver labels, Reduce Motion, Dynamic Type rollout plan ([`docs/accessibility.md`](docs/accessibility.md)) |

```bash
cd ios/AshVault && xcodegen generate
cd ios/AshVault && xcodegen generate && ./Scripts/test.sh AshVaultCI
```

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for conventions and workflow.

## Documentation map

| Doc | Purpose |
|-----|---------|
| [`ios/README.md`](ios/README.md) | iOS setup, gameplay, architecture |
| [`ios/docs/future-work.md`](ios/docs/future-work.md) | Near-term backlog |
| [`docs/accessibility.md`](docs/accessibility.md) | VoiceOver, Reduce Motion, Dynamic Type plan |
| [`docs/privacy.html`](docs/privacy.html) | Hosted privacy policy |

## Play the original

The Java version runs from the command line:

```bash
javac GameDriver.java Player.java Enemy.java
java GameDriver
```

Or open `GameDriver.java` in any Java IDE and run `main`.
