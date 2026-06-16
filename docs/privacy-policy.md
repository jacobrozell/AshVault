# Privacy Policy

**AshVault** · Last updated: June 16, 2026

Jacob Rozell ("we", "us") built AshVault as a free offline game. This policy
explains what information the app handles.

Hosted copy: [privacy-policy.html](privacy-policy.html) (GitHub Pages).

## Summary

- **On your device:** display name, run progress, prestige, mercenaries, relics, settings.
- **Release builds only:** limited anonymous Firebase Analytics + Crashlytics.
- **Not collected:** accounts, ads, location, contacts, or photos.

## Information stored on your device

The app saves gameplay data using iOS local storage (UserDefaults), including:

- A display name you enter at the start of a run
- In-progress run state, prestige progress, mercenaries, relics, and settings
- Audio and automation preferences

This data stays on your device unless you delete the app or reset your device.

## Information sent to third parties (Release only)

In App Store Release builds with a valid Firebase configuration, we may send:

- **Firebase Analytics** — allowlisted events (`app_open`, `run_started`, `run_ended`, `layer_cleared`, `dragon_slayed`, `prestige_completed`, `onboarding_completed`) with non-identifying parameters (layer, level, shard counts, app version).
- **Firebase Crashlytics** — crash stack traces and device/OS context for diagnosis.

Firebase is **disabled** in Debug builds, CI, and when only the placeholder plist is bundled.

## Information we do not collect

- No advertising or ad-network SDKs
- No cross-app tracking for ads
- No in-app purchases
- No requirement to create an account

## Third-party links

Settings may link to external sites (for example, Buy Me a Coffee). Those sites
have their own privacy policies and are not operated by us.

## Children's privacy

AshVault is not directed at children under 13, and we do not knowingly collect
personal information from anyone.

## Changes

We may update this policy from time to time. The "Last updated" date above will
reflect the latest version.

## Contact

Questions about this policy: [Buy Me a Coffee](https://buymeacoffee.com/jacobrozelq)
