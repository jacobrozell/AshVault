# AshVault

AshVault is a turn-based dungeon crawler that started as a **one-night Java console game** — the three files in this repo root ([`GameDriver.java`](GameDriver.java), [`Player.java`](Player.java), [`Enemy.java`](Enemy.java)). No frameworks, no graphics: just combat logic, layer progression, and a dragon at the end.

This project is a **remake and expansion** of that original. The iOS app in [`ios/`](ios/) ports the core combat math faithfully, then builds on it with SwiftUI, idle/incremental systems, prestige, relics, and a much wider move set.

## Play the remake

See [`ios/README.md`](ios/README.md) for setup, gameplay, and documentation.

## Play the original

The Java version runs from the command line:

```bash
javac GameDriver.java Player.java Enemy.java
java GameDriver
```

Or open `GameDriver.java` in any Java IDE and run `main`.
