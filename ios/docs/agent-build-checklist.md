# Agent Build Checklist — AshVault iOS (0 → Ship)

Ordered checklist for building and shipping the AshVault iOS app. Focuses on
engineering concepts, release discipline, and agent tooling — not individual
game features (those live in feature specs).

**Status:** Living document — check boxes, add dates and commit hashes as phases
complete.

**Product specs:** [`game-design-spec.md`](game-design-spec.md) · **Contributor
log:** [`future-work.md`](future-work.md)

---

## Agent query template (paste to start a new session)

```text
You are building AshVault iOS. Follow ios/docs/agent-build-checklist.md.

Rules:
1. Spec-first: no user-visible behavior without an authoritative spec. One source of truth per concern.
2. Test-first for domain: pure logic and ViewModels get unit tests before UI polish.
3. Layered architecture: Views → Models (domain) → Persistence stores. Models/ never imports SwiftUI.
4. XcodeGen — regenerate the Xcode project from ios/AshVault/project.yml.
5. Accessibility is a release gate (target WCAG 2.1 AA): VoiceOver, 44pt targets, Dynamic Type, contrast, supported orientations.
6. Use XcodeBuildMCP (or xcodebuild) for build/test; read .cursor/mcp.json for agent tooling.
7. Ship lean: gate unfinished UI via a single ReleaseSurface module — hide, don't delete.
8. Update this checklist and spec Verification blocks as phases complete.

Brainstorm spec: ios/docs/game-design-spec.md
App name / bundle ID: AshVault / com.jacobrozell.ashvault
MVP scope (what v1.0 exposes): **Full surface** — crawl, prestige, mercenaries, relics, achievements (local), elemental sigils (see § v1.0.0 scope below)
Owner decisions: **en-only** · tip link on · VoiceOver audit soon · telemetry TBD · iOS 16+ · `com.jacobrozell.ashvault`
```

---

## Living document rules

| When | Update |
|------|--------|
| Phase completes | Check box + date + commit in **Progress log** |
| New screen ships | Feature spec Verification block + accessibility screen tracker entry |
| Ship status changes | This checklist + [`future-work.md`](future-work.md) |
| Release scope changes | `ReleaseSurface` module + lean v1 doc (Phase 13) |
| New user-facing string | All bundled locale files + parity test (Phase 10) |
| New analytics/crash event | Telemetry catalog + allowlist + `GameAnalyticsTests` |
| Pre-spec idea | [`future-work.md`](future-work.md) backlog — promote to `ios/docs/*-spec.md` when rules lock |

**Source-of-truth hierarchy:** this checklist → system specs → feature specs →
[`future-work.md`](future-work.md) progress log → backlog ideas (not authoritative).

### Progress log

| Phase | Completed | Commit | Notes |
|-------|-----------|--------|-------|
| 0 | 2026-06-15 | `f965931` | XcodeGen, README, CONTRIBUTING, SwiftLint, `.cursor/mcp.json` |
| 0 | 2026-06-16 | local | GHA CI (`AshVaultCI`), Firebase plist example + CI secret block |
| 1 | 2026-06-15 | local | `docs/README.md` index, `game-design-spec.md`, `systems-overview.md` |
| 2 | 2026-06-16 | local | Dynamic Type AX1–AX5, `AccessibilityHelpersTests`, `docs/accessibility.md` |
| 3 | 2026-06-15–16 | local | 31 unit test files; domain in `Models/` (no SwiftUI) |
| 4 | 2026-06-15 | `f965931` | `SaveStore` / `PrestigeStore` / `MetaStore`, `SerializationTests` |
| 5 | 2026-06-15 | `4a79160` | Phase router, Settings, first-run onboarding walkthrough |
| 6 | 2026-06-15 | `f965931` | Full crawl loop: title → combat → level-up → shop → ascension |
| 7 | 2026-06-15–16 | local | `Theme`, `ScrollFit`, landscape combat, Reduce Motion |
| 8 | 2026-06-16 | local | Settings (audio, haptics, auto-descend), legal links in Settings |
| 9 | 2026-06-16 | local | Relic Museum, achievements Shrine Records, mercenary camp |
| 10 | — | — | Not started — strings inline |
| 11 | — | — | Engineering pass done; manual audit + UI a11y tests pending |
| 12 | 2026-06-16 | local | PR CI: lint + `AshVaultCI` unit tests; no UI test targets |
| 13 | — | — | Not started — no `ReleaseSurface` / lean v1 scope |
| 14 | 2026-06-16 | local | Firebase Analytics + Crashlytics scaffold, `GameAnalytics` allowlist |
| 15 | 2026-06-16 | local | GitHub Pages legal HTML; Settings links wired |
| 16 | — | — | Not started |
| 17 | 2026-06-16 | local | Achievements A–D, elemental sigils, beta-feedback pass (see `future-work.md`) |

> **Note:** Most June 2026 feature work is in the working tree ahead of `4a79160`.
> Land a commit before tagging a release.

---

## Phase 0 — Repo & agent infrastructure

- [x] **0.1** Create repo; `README.md` = build/run entry only (link to specs for product detail) — `2026-06-15` `f965931`
- [x] **0.2** **Project codegen:** XcodeGen `ios/AshVault/project.yml` — `2026-06-15` `f965931`
- [~] **0.3** **Layered folders** — pragmatic layout (not full checklist tree):
  - [x] `AshVault/AshVaultApp.swift` — entry
  - [x] `Models/` — pure game logic (no SwiftUI)
  - [x] `Views/` — SwiftUI screens
  - [x] `Support/` — Firebase, analytics
  - [x] `Resources/` — assets, plist templates
  - [x] `AshVaultTests/` — unit tests
  - [ ] `Features/` / `Domain/` / `Data/` / `Persistence/` / `DesignSystem/` split (optional refactor)
- [x] **0.4** Pin: iOS 16+, `com.jacobrozell.ashvault`, Swift 5 in `project.yml` — `2026-06-15`
- [~] **0.5** `.gitignore`: DerivedData, secrets (`GoogleService-Info.plist`) — **`.xcodeproj` is committed** (CI depends on it; consider gitignoring + generate-only policy later)
- [~] **0.6** **Git hooks** — CI blocks tracked Firebase plists; no local pre-commit script yet
- [x] **0.7** **`.cursor/mcp.json`** — XcodeBuildMCP + ios-simulator — `2026-06-15`
- [ ] **0.8** **Cursor rules** (`.cursor/rules/`) — accessibility, layout, migration policy
- [x] **0.9** **SwiftLint** + CI lint job — `2026-06-16`
- [x] **0.10** **`CONTRIBUTING.md`** — architecture, style, test expectations — `2026-06-15`
- [x] **0.11** Verify: `xcodegen generate && xcodebuild test -scheme AshVaultCI` — `2026-06-16`

---

## Phase 1 — Spec system from brainstorm

- [x] **1.1** Brainstorm / backlog in [`future-work.md`](future-work.md) — explicitly **non-authoritative**
- [~] **1.2** **System specs** (write before implementation):
  - [x] Architecture — [`systems-overview.md`](systems-overview.md)
  - [x] Tech stack — `project.yml`, Firebase, iOS 16+ in [`../README.md`](../README.md)
  - [x] Design system — `Views/Theme.swift`, light/dark in README
  - [x] Data schema — `game-design-spec.md` persistence §, `GameSave.swift` keys
  - [x] Accessibility — [`../../docs/accessibility.md`](../../docs/accessibility.md)
  - [ ] Localization policy
  - [~] Test plan + CI gates — CONTRIBUTING + this checklist; no standalone test-plan spec
  - [ ] Feature flags / environment config spec
  - [ ] Spec governance (conflict resolution, PR rules)
- [x] **1.3** **Promotion pipeline:** backlog → `*-spec.md` when behavior locks (informal via `docs/README.md`)
- [~] **1.4** Feature specs with **Verification** blocks — partial (`achievements-spec.md`, `elemental-combat-spec.md`)
- [~] **1.5** [`docs/README.md`](README.md) index — no separate `feature-inventory.md` yet
- [x] **1.6** Multi-variant catalog — relics, mercenaries, sigils, achievements in code + specs

---

## Phase 2 — Design system & accessibility foundations

- [x] **2.1** **Token layers** — `Theme.swift` palette, semantic surfaces — `2026-06-15`
- [~] **2.2** Semantic colors light + dark — [`docs/accessibility.md`](../../docs/accessibility.md); no contrast evidence folder
- [x] **2.3** **Dynamic Type** — AX1–AX5, `ScrollFit`, `ScaledEmoji` — `2026-06-16`
- [~] **2.4** **Touch targets** — 44pt on primary controls; not audited per-screen
- [x] **2.5** Reusable components with `accessibilityLabel` / hints — combat, shop, settings — `2026-06-16`
- [~] **2.6** **WCAG tracker** — `docs/accessibility.md`; no `accessibility/audits/` evidence folder
- [~] **2.7** `AccessibilityHelpersTests` — token/helper contracts; no dedicated `Tests/Accessibility/` target
- [x] **2.8** Supported orientations — portrait + landscape (phone combat reflow); documented in README — `2026-06-15`

---

## Phase 3 — Domain layer (test-first)

- [x] **3.1** Domain types and rule engines in `Models/` — zero UI imports — `f965931`
- [~] **3.2** **Typed errors** — some validation; not a formal domain error enum everywhere
- [x] **3.3** **State machines** — `GameEngine.phase` routes `ContentView` — `f965931`
- [x] **3.4** Deterministic services — `Balance.swift`, `DamagePipeline`, `TypeChart`, injectable `RandomSource`
- [x] **3.5** Unit tests per branch — 31 test files (`GameEngineTests`, `CombatMovesTests`, etc.)
- [x] **3.6** Long-run simulation — `PlaytestHarness`, `balance_sim.py`
- [~] **3.7** **Command pattern** — moves/sigils as enums; not a unified command bus

---

## Phase 4 — Persistence & repositories

- [~] **4.1** Versioned schema — `save.run.v1`, `prestige.*.v1`, `meta.*.v1` keys; no `SchemaV2` types
- [~] **4.2** **Repository protocols** — concrete `SaveStore` / `PrestigeStore` / `MetaStore` enums (no `any FooRepository`)
- [~] **4.3** **Dependency container** — `GameEngine.init` loads stores directly
- [x] **4.4** Migration / serialization tests — `SerializationTests`, achievement decode defaults
- [ ] **4.5** Container bootstrap failure policy — not documented
- [ ] **4.6** Features depend on repository protocols — stores are concrete

---

## Phase 5 — App shell & navigation

- [x] **5.1** `@main` `AshVaultApp.swift` + bootstrap — `f965931`
- [x] **5.2** Root navigation — `ContentView` phase machine — [`systems-overview.md`](systems-overview.md)
- [ ] **5.3** **Router** for deep links and push notifications
- [x] **5.4** First-run **onboarding** — `OnboardingView` walkthrough — `4a79160`
- [~] **5.5** Central **feature flags** — automation unlock, achievements in engine; no single provider
- [ ] **5.6** **Release surface gate** — see Phase 13

---

## Phase 6 — First vertical slice (MVP core journey)

AshVault vertical slice: **title → combat → level-up → shop → ascension → persist**

- [x] **6.1** Entry screen + state resume — `ContentView` / title — `f965931`
- [x] **6.2** Configuration — name entry, sigil loadout — `f965931` / `2026-06-16`
- [x] **6.3** Primary interaction UI — `CombatView` with a11y labels — `2026-06-16`
- [x] **6.4** Domain wired through `GameEngine` — no business rules in `View.body`
- [x] **6.5** Completion screens + persistence — `GameOverView`, `AscensionView`, stores
- [~] **6.6** Integration test — unit tests cover save/restore; no dedicated relaunch UI test
- [~] **6.7** UI test identifiers — some `accessibilityIdentifier` usage; no UI test suite

---

## Phase 7 — Shared chrome & adaptive layout

- [x] **7.1** Shared headers, toolbars, empty states — `Theme`, `PressableButtonStyle`
- [x] **7.2** **Non-color state indicators** — status badges, combat log text
- [x] **7.3** Loading, disabled, destructive patterns — shop affordances, abandon-run confirm
- [x] **7.4** **Orientation support** — landscape combat via compact height; `ScrollFit` on meta screens
- [~] **7.5** iPad predicates — universal target; not unit-tested layout predicates
- [x] **7.6** Secondary journeys — prestige, mercenaries, relics, achievements prove architecture

---

## Phase 8 — Entity management & settings

- [x] **8.1** CRUD for primary entities — shop, relic equip, mercenary hire, soul tree
- [x] **8.2** Identity presentation — player name, enemy sprites, relic icons
- [x] **8.3** **Settings screen** — audio, haptics, auto-descend, onboarding replay
- [~] **8.4** Settings persistence tests — via `GameEngine` / `@AppStorage`; no dedicated VM tests
- [~] **8.5** **AppLinks** — URLs in `SettingsView` static lets; not a shared `AppLinks` enum
- [x] **8.6** Tip/donate row — Buy Me a Coffee `Link` with a11y hint
- [x] **8.7** **Abandon run** — confirmed destructive action in Settings

---

## Phase 9 — Lists, history & derived views

- [x] **9.1** List + detail — Relic Museum, achievements categories, mercenary camp
- [x] **9.2** Filters — achievement categories; full product exposed (no release gate yet)
- [x] **9.3** Aggregations — lifetime stats, achievement bonuses, offline report
- [~] **9.4** Batch fetching — N/A at current scale; single JSON stores
- [x] **9.5** Tab/segment lean IA — phase machine instead of many tabs

---

## Phase 10 — Localization & text coverage

**Owner decision (2026-06-16):** **English only for v1.0.0** — inline strings acceptable; no `.lproj` bundle for launch.

- [~] **10.1** String catalog wrapper — strings inline in `Narrative` / views (OK for en-only v1)
- [x] **10.2** `en` as sole ship locale — implicit; no translation files required for 1.0.0
- [ ] **10.3** PR rule: all locales simultaneously — defer until post-v1 localization
- [ ] **10.4** Parity test across `.lproj` files — defer
- [ ] **10.5** Locale smoke UI tests — defer
- [x] **10.6** Lean ship: MVP locale only in release bundle — **en-only locked**
- [ ] **10.7** Translation sync scripts — defer

---

## Phase 11 — Accessibility hardening (release gate)

**Owner decision (2026-06-16):** Manual **VoiceOver audit scheduled soon** (pre-submit); engineering pass (Dynamic Type, labels, Reduce Motion) already landed.

- [ ] **11.1** Automated UI accessibility audits (`performAccessibilityAudit`)
- [ ] **11.2** Manual **VoiceOver** pass — dated audit in `accessibility/audits/` — **scheduled soon**
- [~] **11.3** **Large text (AXXXL+)** — AX1–AX5 engineering done; ship sign-off pending
- [ ] **11.4** **Contrast evidence** — light/dark samples on file
- [ ] **11.5** **Orientation matrix** — portrait/landscape × phone/pad documented with evidence
- [x] **11.6** **Reduce Motion** — honored in combat animations — `2026-06-15`
- [x] **11.7** Hide decorative elements from VoiceOver — `accessibilityDecorative()` / `accessibilityHidden`
- [x] **11.8** Accessibility statement link — Settings → GitHub Pages
- [ ] **11.9** Rollup doc with per-screen status — **no launch with open critical failures**

---

## Phase 12 — Test matrix & CI

- [x] **12.1** **PR CI scheme** — `AshVaultCI`: unit tests + coverage — `2026-06-16`
- [ ] **12.2** **Split UI tests** — no `*UISmoke`, `*UIAccessibility`, etc.
- [ ] **12.3** Nightly full UI matrix
- [ ] **12.4** Launch arguments for tests — full surface, reset state, seed fixtures
- [x] **12.5** Shared **test doubles** — `TestSupport.swift`, injectable `RandomSource`
- [x] **12.6** Documentation summary in CI — `Scripts/ci/documentation-summary.sh`
- [x] **12.7** Block tracked secrets in CI — Firebase plist check

---

## Phase 13 — Release surface & lean ship strategy

**Owner decision (2026-06-16):** **v1.0.0 ships full surface** — most built features go out; no `ReleaseSurface` gating for first App Store release. Post-v1 slices use flags for *new* work only.

- [ ] **13.1** `ReleaseSurface` module — **deferred** (not needed for 1.0.0 full ship)
- [ ] **13.2** One place controls experimental features — defer to v1.x
- [ ] **13.3** Launch argument `-enable_full_product_surface` — N/A for 1.0.0 (always full)
- [x] **13.4** **v1.0.0 scope locked** — see table below — `2026-06-16`
- [ ] **13.5** **Test-confidence matrix** for ship order
- [ ] **13.6** Branch model: `dev` vs `release/*`
- [ ] **13.7** Per-feature estimated release tags in specs

### v1.0.0 scope (locked 2026-06-16)

| Area | Ship in v1.0.0? | Notes |
|------|-----------------|-------|
| Core crawl + prestige | **Yes** | MVP |
| Mercenaries + relics | **Yes** | Meta Month 1 |
| Achievements (local Shrine Records) | **Yes** | Toasts, museum, bonuses |
| Elemental sigils + aspects | **Yes** | Ember/Frost/Arc/Venom |
| Auto-battle + offline + auto-descend | **Yes** | |
| First-run onboarding walkthrough | **Yes** | `4a79160` |
| Progressive unlock onboarding | **No** | Spec only — future update |
| Magic rune minigame | **No** | `SpellCastResolver` stub only |
| Game Center / leaderboards | **No** | `achievements-spec.md` Phase E |
| Real audio assets | **No** | Hooks only; graceful no-op |
| Localization beyond English | **No** | en-only for 1.0.0 |

---

## Phase 14 — Telemetry, deep links & platform extensions

- [x] **14.1** Secrets template — `GoogleService-Info.plist.example`; real file gitignored
- [x] **14.2** **Allowlisted analytics** — `GameAnalytics` + `GameAnalyticsTests`
- [~] **14.3** Crash reporting — Crashlytics in `project.yml`; dSYM upload not in CI
- [x] **14.4** Structured logging facade — `GameAnalytics` → Firebase (swappable)
- [ ] **14.5** **Deep links** — parser, router, gated fallback
- [ ] **14.6** App Intents / Shortcuts
- [ ] **14.7** Widgets, Live Activities, Watch — stub boundaries only

---

## Phase 15 — Legal pages, GitHub Pages & store URLs

- [x] **15.1** Static HTML — `docs/privacy-policy.html`, `accessibility.html`, `support.html`, `index.html`
- [x] **15.2** **GitHub Pages** — deploy from `/docs`
- [~] **15.3** Canonical URLs in shared `AppLinks` — wired in `SettingsView` directly
- [ ] **15.4** App Store Connect URLs — not submitted yet
- [x] **15.5** "Last updated" on accessibility page — June 2026
- [ ] **15.6** App Store metadata spec
- [ ] **15.7** Marketing screenshots + snapshot automation
- [x] **15.8** Launch screen — `LaunchBackground` + `LaunchLogo` in asset catalog
- [ ] **15.9** CI/CD for TestFlight

---

## Phase 16 — Release QA & ship

- [ ] **16.1** Device matrix scoped to lean v1.0 surface
- [ ] **16.2** RC sign-off doc with Go/No-Go
- [ ] **16.3** Owner decisions closed:
  - [x] Tip/donate link — Buy Me a Coffee shown
  - [x] Locales — **English only** for v1.0.0 (store + bundle)
  - [ ] Telemetry on/off in Release
  - [x] Bundle ID — new listing `com.jacobrozell.ashvault`
  - [x] v1.0.0 surface — **full** (see Phase 13 table)
- [ ] **16.4** Lean-surface UI smoke green on `release/*`
- [ ] **16.5** Persistence recovery smoke on physical device
- [ ] **16.6** Pre-tag gate checklist (~10 min)
- [ ] **16.7** Post-submit monitoring plan

---

## Phase 17 — Expand surface (post-v1)

| Slice | Status | Spec |
|-------|--------|------|
| Achievements A–D (local) | **Done** June 2026 | [`achievements-spec.md`](achievements-spec.md) |
| Achievements E (Game Center) | Planned | [`achievements-spec.md`](achievements-spec.md) § Phase E |
| Elemental sigils | **Done** June 2026 | [`elemental-combat-spec.md`](elemental-combat-spec.md) |
| Progressive unlock onboarding | Planned | [`progressive-unlock-spec.md`](progressive-unlock-spec.md) |
| Magic rune minigame | Deferred | [`elemental-combat-spec.md`](elemental-combat-spec.md) §12 |
| Real audio assets | Backlog | [`future-work.md`](future-work.md) |
| Localization | Backlog | Phase 10 |

---

## Phase 18 — Documentation hygiene (ongoing)

- [~] **18.1** Behavior PR → matching spec + Verification block
- [~] **18.2** Shipped reality tracked — `future-work.md` log; no `feature-inventory.md`
- [ ] **18.3** Spec/code drift report in CI
- [ ] **18.4** Engineering audit after large refactors
- [ ] **18.5** Document extractions before splitting god ViewModels
- [ ] **18.6** Release automation runbooks

---

## Quick reference for agents

| Question | Where to look |
|----------|----------------|
| What should the product do? | [`game-design-spec.md`](game-design-spec.md) + feature `*-spec.md` |
| What exists in the build today? | [`future-work.md`](future-work.md) progress log + this checklist |
| How is code organized? | [`systems-overview.md`](systems-overview.md) + [`CONTRIBUTING.md`](../../CONTRIBUTING.md) |
| How do I build and test? | [`../README.md`](../README.md), `.cursor/mcp.json` |
| What ships this sprint? | [`beta-feedback-todo.md`](beta-feedback-todo.md), [`future-work.md`](future-work.md) |
| Accessibility requirements? | [`../../docs/accessibility.md`](../../docs/accessibility.md) |
| Lean vs full UI? | Phase 13 — **v1.0.0 = full surface** (locked) |
| Legal / support URLs? | `docs/*.html` + `SettingsView` |
| Optional tip link? | Buy Me a Coffee in Settings |
| Ideas not yet spec'd? | [`future-work.md`](future-work.md) backlog |
| This checklist | **this file** |

---

## Current position (last audited 2026-06-16)

**Product:** Feature-rich hybrid idle/combat game — past MVP (Phases 6–9 largely complete).

**Engineering:** Strong domain tests and CI; pragmatic `Models/` / `Views/` layout instead of strict layered modules.

**Owner decisions locked:** v1.0.0 = **full surface**, **en-only**, VoiceOver audit **soon**, tip link **on**.

**Blocks ship (checklist):** Phase **11** (VoiceOver sign-off), Phase **16** (device QA + RC). Phase 10 closed for en-only. Phase 13 scope locked.

**Recommended next session:**

1. Manual VoiceOver pass → dated audit in `accessibility/audits/`.
2. Device matrix + RC sign-off (Phase 16).
3. Decide telemetry on/off in Release builds.
4. TestFlight / App Store submit.
