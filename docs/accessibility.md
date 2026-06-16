# Accessibility

**AshVault** · Last updated: June 16, 2026

AshVault is designed to be playable with iOS system accessibility features.
This page describes what works today and our plan for **Large Text** (Dynamic
Type) support.

## Using accessibility features

Open **Settings → Accessibility** on your iPhone or iPad:

| Feature | Where to enable | In AshVault |
|---------|-----------------|-------------|
| **VoiceOver** | Accessibility → VoiceOver | Combat log, moves, shop, and meta screens expose labels and hints. Decorative emoji are hidden from VoiceOver. |
| **Larger Text** | Accessibility → Display & Text Size → Larger Text | Supported at AX1–AX5 — see [Large Text plan](#large-text-dynamic-type) |
| **Reduce Motion** | Accessibility → Motion → Reduce Motion | Honored — shake, bob, pulse, spring entrances, and floating combat numbers fall back to still or fade-only. |
| **Bold Text** | Accessibility → Display & Text Size → Bold Text | Supported via semantic SwiftUI text styles. |
| **Increase Contrast** | Accessibility → Display & Text Size → Increase Contrast | Adaptive light/dark palette uses high-contrast surfaces for panels and inputs. |

The game is fully playable **muted** — every audio cue has a visual and combat-log counterpart.

## VoiceOver (current)

Screens with explicit accessibility support:

- **Combat** — player/enemy status, moves, consumables, auto-battle, withdraw button, scrolling combat log (`updatesFrequently`).
- **Shop / Level up / Ascension / Game over** — actionable rows with labels and hints.
- **Ash Tree, Relic Gallery, Mercenary Camp** — upgrade/buy rows with shard/gold context.
- **Settings** — toggles, abandon-run confirmation, external links.
- **Onboarding** — page content grouped; decorative icons hidden.

Gaps to close (tracked in spec):

- Locked moves / progressive unlock states (see `ios/docs/progressive-unlock-spec.md`).
- Floating combat numbers are visual-only (log carries the same information).

## Large Text (Dynamic Type)

### Goal

Support **Accessibility sizes** (AX1–AX5) without clipping, overlap, or loss of
core gameplay. A player who enables Larger Text should be able to:

1. Read all UI copy and combat log entries.
2. Reach every button (moves, shop, withdraw, settings).
3. See HP/mana bars and numeric stats (or hear them via VoiceOver).

### What works today

| Pattern | Location | Notes |
|---------|----------|-------|
| Semantic text styles | Most views (`.headline`, `.caption`, `.subheadline`, etc.) | Scales with Dynamic Type by default. |
| `Font.gameDisplay` / `gameSubtitle` | Title, level-up, game over | Built on `.largeTitle` / `.title` / `.subheadline`. |
| `ScaledEmoji` | Level-up, splash | Emoji tied to a `Font.TextStyle`. |
| `ScrollFit` | Title, shop, level-up, ascension, game over; combat **landscape** | Scrolls when content exceeds viewport height. |
| `minimumScaleFactor` | Title, shop cards (default sizes only) | Disabled at AX1+; layouts reflow instead |
| `StatBar` accessibility | Combat, player panel | VoiceOver reads value even when bar is visually compact. |

### Known gaps

Remaining items (not Dynamic Type):

- Locked moves / progressive unlock states (see `ios/docs/progressive-unlock-spec.md`).
- Floating combat numbers are visual-only (log carries the same information).

#### P0 — Layout overflow at large sizes

| Screen | Issue | Fix |
|--------|-------|-----|
| **Combat (portrait)** | Fixed `VStack`; no outer scroll | **Done** — `ScrollFit` at AX1+; two-row header |
| **Combat moves grid** | Fixed row/column grid may clip tall buttons | **Done** — vertical stack at AX1+ |
| **Combat log** | `maxHeight` in landscape | **Done** — cap removed at AX1+ |
| **Onboarding** | Fixed `.font(.system(size: 52))` hero icon | **Done** — `ScaledSymbol` + scaled bullet rows |
| **Relic detail** | Fixed 48/64 pt emoji | **Done** — `ScaledEmoji`; scroll at AX1+ portrait |

#### P1 — Touch targets and spacing

| Component | Issue | Fix |
|-----------|-------|-----|
| `AccessibleNameField` | Fixed 44 pt height | **Done** — `@ScaledMetric` min height (floor 44) |
| Shop / skill cards | Fixed `minHeight` | **Done** — `@ScaledMetric` padding; single-column grids at AX1+ |
| Header bar (combat) | Dense `HStack` at AX sizes | **Done** — two-row header at AX1+ portrait |

#### P2 — Typography hygiene

- **Done** — fixed-size fonts replaced with semantic styles / `ScaledEmoji` / `ScaledSymbol` / `@ScaledMetric`.
- **Done** — blurbs shown at accessibility sizes even in landscape (`showsExpandedCardCopy`).
- **Done** — `minimumScaleFactor` disabled at AX1+ via `adaptiveMinimumScaleFactor`.

### Implementation conventions

New UI should follow these rules (align with `Theme.swift` and `Accessibility.swift`):

```swift
// Prefer semantic styles
Text("Level Up!")
    .font(.gameDisplay(compactHeight: isLandscape))

// Scale decorative icons
ScaledEmoji("⬆️", style: .largeTitle)

// Scale layout constants
@ScaledMetric(relativeTo: .body) private var rowSpacing: CGFloat = 12

// Branch layout at large sizes
@Environment(\.dynamicTypeSize) private var dynamicTypeSize
private var usesCompactLayout: Bool {
    isLandscape || dynamicTypeSize.ashvaultUsesAccessibilityLayout
}

// Scroll when content might overflow
ScrollFit { … }

// VoiceOver
.accessibilityLabel("…")
.accessibilityHint("…")
Text(icon).accessibilityDecorative()
```

Add helpers to `Accessibility.swift` as needed, e.g.:

```swift
extension DynamicTypeSize {
    var ashvaultUsesAccessibilityLayout: Bool {
        self >= .accessibility1
    }
}
```

### Testing checklist

Run on **iPhone simulator or device** at these settings:

1. **Settings → Accessibility → Display & Text Size → Larger Text** — drag to largest (AX5).
2. Repeat in **portrait and landscape** on: Title → Combat → Shop → Level up → Ash Tree → Settings.
3. Enable **VoiceOver** and complete one combat turn + one shop purchase.
4. Enable **Reduce Motion** — confirm animations are reduced, gameplay unchanged.
5. **Xcode → Accessibility Inspector** — audit each screen for clipped elements and missing labels.

Optional automation (future): snapshot tests at `.accessibility3` using `View.dynamicTypeSize(_:)`.

### Rollout phases

| Phase | Scope | Exit criteria |
|-------|-------|---------------|
| **1** | Combat portrait scroll + move button reflow | No clipped controls at AX3 portrait | **Done** (June 2026) |
| **2** | Onboarding, relic detail, name field | Fixed-size fonts eliminated | **Done** (June 2026) |
| **3** | Shop/skill/meta card heights | Cards grow with text; grids reflow | **Done** (June 2026) |
| **4** | Full AX5 pass + Accessibility Inspector clean | All screens in checklist pass | **Done** (June 2026) |

Track progress in `ios/docs/future-work.md` when phases land.

## Feedback

Accessibility issues or suggestions: [Buy Me a Coffee](https://buymeacoffee.com/jacobrozelq)

Related: [Privacy Policy](privacy-policy.html)
