# AshVault — Beta Tester Feedback (TODO)

> Source: beta playtest notes, June 2026.  
> Living spec: [`game-design-spec.md`](game-design-spec.md) · Backlog: [`future-work.md`](future-work.md) · Sigils: [`elemental-combat-spec.md`](elemental-combat-spec.md)

Unscoped items — spec and prioritize before building.

---

## Combat & moves

- [x] **Rethink Dodge vs Heal** — Heal renamed "Second Wind" with subtitles; Dodge = evade + HP/mana, Heal = big heal + enemy retaliation.
- [ ] **Investable stats** — let players spend on hit chance, block chance, and other secondary stats (not just ATK/DEF/HP).
- [x] **Enemy weaknesses (Pokémon-style)** — shipped: aspects, 3-slot sigil loadout, ×1.5 WEAK! hits; Ember, Frost, and Arc sigils ([`elemental-combat-spec.md`](elemental-combat-spec.md)).
- [x] **Poison needs a purpose** — **Venom Lash** shop sigil replaces Poison Dagger move; typed burst + poison stacks ([`elemental-combat-spec.md`](elemental-combat-spec.md)).
- [x] **No unfair one-shots** — campaign hits (layers 1–5) capped to 50% max HP per swing; endless uncapped.
- [~] **Magic casting minigame** — `SpellCastResolver` architecture in [`elemental-combat-spec.md`](elemental-combat-spec.md) §4.2.8 / §12; rune-tracing UI deferred.

## Progression & meta

- [x] **Progression clarity** — post-dragon combat log beat, victory screen hint, ascension shard formula copy.
- [x] **Level visibility** — level in combat header + gold badge on player panel; level-up shows N → N+1.
- [x] **Achievements** — Shrine Records UI, unlock toasts, analytics; spec in [`achievements-spec.md`](achievements-spec.md).
- [x] **Mercenary clarity** — permanent-hire copy, per-merc DPS blurb, milestone footer.
- [x] **Auto-recover from death** — **Phoenix Ash** shop item (175g, once per run): auto-revive at 35% HP, clears statuses, no second buy.

## Copy & onboarding

- [x] **Heal text fix** — combat log no longer says "quaff a potion" on the Heal move (reserved for consumable potions).
- [x] **First-death moment** — on first death, combat log delivers the twist: *"Ha. You thought this was a little idle game?"*

## UI & layout

- [x] **Landscape Home Screen** — tightened hero spacing, top padding for settings gear, top-aligned scroll, visible scroll indicators in landscape.
- [x] **Combat log spacing** — extra padding before layer headers; log trims to recent lines when a new layer begins.
- [x] **Combat log scroll** — scroll indicators visible; auto-scrolls to latest line on every new entry (not just count changes).

## Polish & settings

- [x] **Custom enemy icons** — tint-ring frames per enemy colour (distinct emoji sprites were already per-type; art pass still possible).
- [x] **Haptics toggle** — Settings → Audio & feedback → Haptics (persists via `haptics.enabled`).

## Done this pass (June 2026)

| Item | Where |
|------|-------|
| Heal move copy | `GameEngine.resolveHeal()` |
| First-death beat | `Narrative.Beat.firstDeathTwist`, `FirstDeathBeat` |
| Haptics toggle | `SettingsView`, `Haptics.enabled` |
| Combat log UX | `LogLine.spacedAbove`, `CombatLogView`, `trimLogForNewLayer()` |
| Landscape title | `TitleView`, `ScrollFit` top alignment |
| Dodge vs Heal | `Move.displayName` / `subtitle`, CombatView buttons |
| Poison clarity | `Move.subtitle`, poison DoT log line |
| Campaign hit cap | `damageToPlayer()`, `Balance.maxCampaignHitPercent` |
| Level visibility | Combat header + player badge, `LevelUpView` |
| Progression clarity | `progressionAfterDragon`, `GameOverView`, `AscensionView` |
| Mercenary clarity | `Narrative.Term`, `Mercenary.blurb`, camp footer |
| Enemy visual polish | Tinted sprite ring in `CombatView` |
| Phoenix Ash revive | `ShopItem.phoenixAsh`, `tryPhoenixAshRevive()` |
| Elemental sigils | `Element`, `TypeChart`, `SpellCatalog`, `SigilLoadoutView`, `performSigil` |
