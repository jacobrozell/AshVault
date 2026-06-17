# Avasia: Ash Vault — Integration & Prequel Spec

**Status:** Design north star (June 2026)  
**Product:** Standalone iOS dungeon crawler set in the [Avasia](https://github.com/jacobrozell/Avasia-iOS) universe  
**Code base:** AshVault (`GameEngine`, survivor crawl, sigil combat)  
**Fiction source of truth:** [Avasia-iOS `docs/SAGA.md`](../../../Avasia-iOS/docs/SAGA.md) §0 · [`STORY.md`](../../../Avasia-iOS/docs/STORY.md) · [`LORE_ARCHIVE.md`](../../../Avasia-iOS/docs/LORE_ARCHIVE.md) §1.4 · fiction **I-M11** / **W-07**

**Related AshVault docs:** [survivor-crawl-redesign.md](survivor-crawl-redesign.md) · [dungeon-crawl-pillars.md](dungeon-crawl-pillars.md) · [elemental-combat-spec.md](elemental-combat-spec.md) · [ashvault-narrative-plan.md](ashvault-narrative-plan.md)

**Out of scope:** Chronicler / saga hub integration · save import · Game 3 (2D Commodity Era)

---

## 1. Vision

### 1.1 One sentence

**Avasia: Ash Vault** is a turn-based dungeon crawler prequel set in the NW mountain prison-caves — the last descent before Kaefden sealed them, and the origin of the ash, pink crystal, and punitive trials that KoN players explore decades later.

### 1.2 Player promise

> *You are a nameless delver sent into the rings below the forge. Supplies dwindle. Anchors fail. Reach the Vault Heart and break the Sinter — or retreat to the surface camp with what ash you can carry.*

**Session:** 20–30 min manual crawl.  
**Return hook:** Build combos (class + sigils + run relics + ring modifiers).  
**Tone:** Earnest horror-adventure (prison, schism guilt, anchor catastrophe) with occasional meta wink on failure — same two-register voice as KoN ([`STORY.md`](../../../Avasia-iOS/docs/STORY.md) §1).

### 1.3 Product stance

| Decision | Choice |
|----------|--------|
| Distribution | **Standalone app** (separate from Avasia-iOS saga picker) |
| Canon | **Adds** one abandonment event; does not retcon KoN / SoC |
| Meta cross-link | Easter eggs + shared vocabulary only — **no Chronicler XP** |
| Mechanics | Keep survivor crawl + sigil type chart; extend with **delver classes** |
| Big bad | **New** — not Vashirr, not Ash Dragon, not Kaefden IV |

---

## 2. Timeline placement (prequel)

### 2.1 Where this sits

```text
[Ancient schism] ──► [Jal prison era, W-07] ──► [ASH VAULT GAME] ──► [Venn seals trials, I-M11]
        │                    │                         │                      │
   Agroman born          chains + pink ore         THE ABANDONMENT          "only the worthy"
                                                                              │
                                                                              ▼
                                                                    [KoN — Inflame trial]
                                                                              │
                                                                              ▼
                                                                    [SoC — 7 years later]
```

| Era | Approx. offset | What happens |
|-----|----------------|--------------|
| Schism fable | Centuries before | Younger prince → Agroman; anchor law unnamed but lived |
| Jal prison | Pre–Old Mage | NW cave = chain-mine for convicts ([`WORLD_BUILDING.md`](../../../Avasia-iOS/docs/fiction/WORLD_BUILDING.md) W-07) |
| **Ash Vault game** | **~70 years before KoN** | Active Kaefden penitentiary; catastrophe; emergency seal; maps redacted |
| Venn trio | ~40 years before KoN | Ruined vault repurposed for spell trials; murder; worthy lie ([`volume-i.md`](../../../Avasia-iOS/docs/fiction/specs/volume-i.md) I-M11) |
| KoN | Game 1 | Amnesiac mage; lantern; Inflame puzzle; corpses in branches |
| Cave Record (anthology) | Parallel vignette | Scout finds **already abandoned** archive — consistent with our seal |
| SoC | +7 years after KoN end | Paladins; flesh-anchor at scale |

**Player knowledge:** The delver does not know Venn, KoN, or Vashirr by name. They know Kaefden law, schism graffiti, and that the deep rings are wrong.

### 2.2 Sacred pillar compliance ([`SAGA.md`](../../../Avasia-iOS/docs/SAGA.md) §0)

| Pillar | This game |
|--------|-----------|
| Anchor law | Core mechanic + story — every spell/relic binds to sky, earth, flesh, or civic |
| Duology argument | **Planted**, not resolved — Malvek is Restoration extremism; graffiti voices Agroman sympathy |
| Survivor's legend | N/A (pre-dates SoC PC) |
| Trilogy question | Foreshadows Era 1 question (*where may magic live?*) via prison policy |
| Flesh magic | **Proto-horror** — Sinter is unregulated binding; not Paladins yet |
| Royal continuity | Kaefden throne exists; **no** crown protagonist |
| Never do | No Vashirr redemption; no third text game; no replacing anchor law |

---

## 3. The abandonment story (canonical addition)

### 3.1 Logline

Kaefden's **NW Mountain Penitentiary** — a sky-warded prison where convicts mine **pink crystal** (raw Anula bleed) under civic sentence — collapses from within when the warden-magister tries to bind the prisoners' suffering into a single **deterrence reliquary**. The reliquary wakes as **the Sinter**. The delver's run is the crown's last attempt to reach the Heart and sever the anchor before the surface camp seals the gates forever.

### 3.2 Facility history (player-facing codex)

1. **Forge era** — Dwarven-adjacent mine (human and mage labor); pink veins discovered.
2. **Prison era** — Kaefden converts it to penitentiary for oathbreakers, murderers, and schism agitators. Civic anchor: *law sentences, earth suffers.*
3. **Warden-Magister Malvek's tenure** — Sky mage loyalist; believes visible punishment will deter Agroman recruitment. Expands rings downward.
4. **The Binding** — Malvek anchors pain, ash, and crystal bleed into a **Vault Heart reliquary** without consent — violates anchor law (flesh + earth without vessel or oath).
5. **The Sinter** — Reliquary becomes hungry; consumes turnkeys, prisoners, Malvek's lower body; spreads through rings as ash-fog and crystal growth.
6. **The Seal** — Surface camp detonates civic oaths + emergency Stonebend on upper gates. Survivors redact maps. Folk name: **Ash Vault** (curse, not official ledger).
7. **Aftermath (off-screen)** — Decades pass. Venn's trio finds the sealed ruin and installs spell trials atop the horror — the lie that only the worthy may pass ([I-M11](../../../Avasia-iOS/docs/fiction/specs/volume-i.md)).

### 3.3 Why the prison is abandoned (answer for the saga)

| Question | Answer |
|----------|--------|
| Why empty in KoN? | Sealed ~70 years prior; later trials added; still deadly |
| Why corpses in branches? | Sinter consumption + failed delver runs + Venn-era competitors |
| Why pink crystal? | Anula bleed in ore — earth anchor leaking into prison stone |
| Why punitive puzzles later? | Venn repurposed Malvek's rings as ego trials |
| Why "both. always both." graffiti? | Schism prisoners — neither faction innocent ([Cave Record](../../../Avasia-iOS/docs/anthology/stories/STORY_CAVE_RECORD.md)) |

### 3.4 Campaign outcome (this game)

| End state | Fiction |
|-----------|---------|
| **Vault Heart cleared** | Sinter severed; upper seal holds; delver dies on surface or vanishes — camp records "ring ten breached, anchor cut." History forgets the name. |
| **Retreat** | Camp seals early; partial victory; more ash banked at shrine |
| **Death** | Body adds to branch corpses KoN will find |
| **Endless (post–Heart)** | Deeper pink veins — pre-commodity Anula horror, not charted |

This **sets up** KoN without requiring players to have beaten Ash Vault.

---

## 4. Antagonist — the Sinter & Malvek

### 4.1 Design goals

- Embodies **anchor law violation** (power without proper vessel or consent)
- Foreshadows **Vashirr's critique** (mages hoarding / binding others) without being Vashirr
- Foreshadows **Paladin horror** (flesh binding) and **Red Litany** (unregulated stacking) for saga veterans
- Replaces generic **Ash Dragon** as Vault Heart boss

### 4.2 The Sinter (entity)

| Field | Value |
|-------|-------|
| **Nature** | Accidental flesh–earth hybrid; crystallized ash + prisoner echo |
| **Voice** | Composite whispers — names of the condemned, Malvek's sermons, grinding crystal |
| **Motif** | Heat without flame (pre-Inflame); pink light; manacles fused to bone |
| **Arena** | Vault Heart — reliquary chamber, half-melted forge |

**Combat fantasy:** Phase 1 — ash fog, crystal shards; Phase 2 (future) — echo adds spawn; enrage at low HP = "anchor snap" (Brittle Seal modifier globally).

### 4.3 Warden-Magister **Malvek** (human)

| Field | Value |
|-------|-------|
| **Role** | Tragic architect; not final boss alone — merged into Sinter |
| **Philosophy** | *"Let them see what law costs."* — Restoration taken to cruelty |
| **Reveal** | Ring 8 codex / boss VO: he ordered the Binding knowing it was forbidden |
| **Fate** | Consumed; skull in Heart chamber — KoN dead mage energy |

Do **not** redeem Malvek. Do **not** mirror Vashirr's Many Hands sermon — Malvek is **civic punishment**, not populist army-building.

### 4.4 Warden roster (rings 1–9)

Replace generic wardens with ring-appropriate foes:

| Ring | Warden name | Identity |
|------|-------------|----------|
| 2 | Turnkey **Hess** | Corrupt guard; Brittle Seal ring |
| 4 | **Pink Bloom** | Crystal parasite (earth aspect) |
| 6 | **Echo Sergeant** | Flesh-bound turnkey remnant |
| 8 | **Malvek's Shade** | Sky aspect; pre-boss |
| 10 | **The Sinter** | Vault Heart |

Rings 1, 3, 5, 7, 9 may use elite guardians + mini-wardens until content pass fills all ten.

---

## 5. Geography & spaces

### 5.1 Real-world anchor

**NW mountain** west of KoN's Splitpath — same site as KoN mountain cave, Silvarium foothills, Cave Record trail ([`LORE_ARCHIVE.md`](../../../Avasia-iOS/docs/LORE_ARCHIVE.md) §1.4).

### 5.2 Three spaces (retain crawl structure)

| Crawl space | Avasia name | Fiction |
|-------------|-------------|---------|
| Meta hub | **Surface Camp** (keep code: Shrine) | Kaefden penal detachment; tents at cave mouth |
| Run | **The Ash Vault** (rings 1–10+) | Sealed penitentiary descent |
| Post-campaign | **Below the Seal** | Uncharted Anula bleed — endless |

### 5.3 Ring names (campaign)

| Ring | Name | Modifier (default pool) | Entry beat |
|------|------|-------------------------|------------|
| 1 | **Mouth** | — | *Lantern smoke. Pink crystal in wet stone.* |
| 2 | **Graffiti Gallery** | Brittle Seal | *"Both. Always both."* |
| 3 | **Manacle Hall** | Quiet Ring | *Iron that outlived its prisoners.* |
| 4 | **Branching Dark** | Mirror Vault | *The lanterns were not meant for this depth.* |
| 5 | **Forge Descent** | Ash Greed | *Ore dust and old sermons.* |
| 6 | **Pink Saturation** | Fungal Ring | *Blue crystal weeps into the rock.* |
| 7 | **Reliquary Approach** | Hoarder's Toll | *Malvek called this deterrence.* |
| 8 | **Binding Gallery** | Brittle Seal | *Chains that bind the binder.* |
| 9 | **Ash Choir** | Quiet Ring | *You hear your own footsteps twice.* |
| 10 | **Vault Heart** | — | *Something hot without flame.* |
| 11+ | **Below the Seal** | Compounding | *No surveyor planned this.* |

---

## 6. Player identity

### 6.1 Now

- **Nameless delver** — penal legionnaire, conscript, or condemned volunteer (text intentionally vague).
- No dialogue trees; identity expressed through **class oath** and **death log**.
- Future: named character in fiction (`CHARACTERS.md` cross-link) if a short story or KoN optional codex warrants it.

### 6.2 Future hook

Delver becomes **the unnamed entry** in Surface Camp ledger: *"Delver 7 — ring ten breached."* KoN Old Mage or Cave Record archivist may reference "the last descent" as rumor.

---

## 7. Delver classes (SoC-inspired)

Mirror **Blade of Courage** spirit-animal classes ([`sequel/STORY.md`](../../../Avasia-iOS/docs/sequel/STORY.md) §3.2) without druid enlistment fiction — penal **blood oaths** borrowed from Cataractan practice (Kaefden hired druid auxiliaries to train delvers).

### 7.1 Class select

- **When:** First run after tutorial; changeable at Surface Camp between runs (meta unlock).
- **UI:** Full-screen oath picker (same weight as `DraftView`).

| Oath | SoC parallel | Role | Stat bias | Run perk |
|------|--------------|------|-----------|----------|
| **Hound** | Wolf / hunter | Aggression | +ATK, medium HP | +10% damage vs wounded foes |
| **Mast** | Bear / guardian | Survival | +HP, +DEF | Camp rest +5% max HP |
| **Kite** | Fox / scout | Expedition | +crit, −max HP | Door fork reveals modifier one ring early |

### 7.2 Class-flavored draft pools

Draft offers skew by oath (weight, not exclusivity):

| Oath | Draft bias |
|------|------------|
| Hound | ATK surges, Ember, crit |
| Mast | HP, Ward, thorns, civic relics |
| Kite | Supply tricks, scout ink, gold |

### 7.3 Future fourth oath (post-launch)

**Ash-Touched** — unlock after first Vault Heart clear; flesh-rite sigils; high risk (supply drain, sanity debuff). Foreshadows Paladin / Red Litany without naming them.

---

## 8. Magic & anchor system

### 8.1 Keep (code)

- Four sigils: **Ember**, **Frost**, **Venom**, **Arc**
- `TypeChart`, aspects, 3-slot loadout, evolutions, run relics
- Physical moves: Attack, Heavy, Dodge, Heal

### 8.2 Player-facing rename (UI only — defer code identifiers)

| Code ID | Avasia name | Anchor | KoN / saga tie |
|---------|-------------|--------|----------------|
| Ember | **Inflame** (or *Ember Rite*) | Sky | KoN fire spell |
| Frost | **Stonechill** | Earth | Anula cold bleed |
| Venom | **Rot Oath** | Earth / flesh edge | Prison disease |
| Arc | **Chainbolt** | Sky | Mage warding lightning |

Rename gradually in `Narrative.swift`; keep `SpellID` stable.

### 8.3 Anchor tags (synergy layer)

Extend run relic + draft tags to match [`SAGA.md`](../../../Avasia-iOS/docs/SAGA.md) §8.2:

| Anchor | Tags | Example relic |
|--------|------|----------------|
| Sky | `ember`, `arc`, `sky` | Warden's Lens — crit vs earth foes |
| Earth | `frost`, `venom`, `earth` | Pink Shard — poison lasts +1 |
| Flesh | `thorn`, `leech`, `flesh` | Manacle Link — thorns heal 1% |
| Civic | `ward`, `greed`, `oath` | Ledger Stone — +gold, +shop cost |

### 8.4 Sigil evolutions (fiction)

| Base | Evo A | Evo B | Fiction |
|------|-------|-------|---------|
| Ember | **Meteor** | **Kindling** | Malvek forge rite / prisoner kindling |
| Frost | **Glacier** | **Needle** | Anula freeze / pickaxe shard |
| Venom | **Plague** | **Leech** | Prison rot / blood price |
| Arc | **Storm Lance** | **Null Bolt** | Sky warden / sever anchor |

### 8.5 Supplies = **lamp oil**

Replace torch abstraction with KoN-aligned **lantern oil**:

| Knob | Fiction |
|------|---------|
| `startingSupplies` | Oil flasks from Surface Camp |
| `supplyCostPerRing` | One flask per ring ingress |
| `supplyStarved` | *Delirious descent* — Sinter whispers |

---

## 9. Core loop mapping

Unchanged from [dungeon-crawl-pillars.md](dungeon-crawl-pillars.md) — re-skin only:

```
Surface Camp → pick oath + sigils + shrine meta
     → Ring ingress (modifier + door fork)
     → guardians + draft XP
     → warden
     → Camp (oil, gold, shop) or Push Deeper
     → Vault Heart (ring 10) → endless
     → Death or Retreat → bank Trial Ash (Ash Shards)
```

### 9.1 Terminology migration

| Current (AshVault) | Avasia UI | Notes |
|--------------------|-----------|-------|
| Ash Shards | **Trial Ash** or keep Ash Shards | Crystallized ring residue |
| Ash Tree | **Survivor's Pyre** or **Camp Memorial** | Plant ash for permanent perks |
| Ash Gallery | **Reliquary** | Trophies from wardens |
| Withdraw to Shrine | **Surface Withdrawal** | Climb to camp |
| Ash Dragon | **The Sinter** | Remove dragon copy |
| Deep AshVault | **Below the Seal** | Endless |

Persistence keys unchanged until dedicated migration.

### 9.2 Door fork (fiction)

| Door | Avasia copy |
|------|-------------|
| Guard | Standard patrol tunnel |
| Elite | *Malvek's punishment detail* — harder fight, bonus gold |
| Shrine | *Suformin niche* — druid auxiliaries left ward stones |

---

## 10. Meta progression

### 10.1 Keep light shrine (~12 nodes)

Branches re-themed:

| Branch | Was | Avasia |
|--------|-----|--------|
| Blade | ATK | **Hound's Mark** |
| Ember | burn | **Sky-Binder's Ember** |
| Depth | shards / draft | **Kite's Depth** |

No Chronicler. Optional: **Codex** entries unlocked by depth (local only).

### 10.2 Achievements → **Camp Records**

Re-flavor `Narrative.Achievement` strings toward abandonment story (seal-breaker → Sinter-slayer, etc.).

---

## 11. Foreshadowing payoff map

What saga players recognize after playing Ash Vault:

| This game | Pays off in |
|-----------|-------------|
| Pink crystal / Anula bleed | KoN cave, SoC fountain, Commodity Era |
| Prison manacles | KoN HISTORY, Cave Record |
| Malvek's binding | Vashirr's Many Hands argument ([`VASHIRR.md`](../../../Avasia-iOS/docs/VASHIRR.md)) |
| Sinter flesh horror | SoC Paladin echo, courtyard ash |
| "Both. Always both." | Cave Record graffiti |
| Worthy-blood lie (epilogue text) | KoN Inflame trial arrogance (I-M11) |
| Dead delvers in branches | KoN burnt mage, Story 7 |
| Emergency Stonebend seal | Silvarium blood seal culture |

See **§18–§26** for the earned-prequel craft layer (myth ladder, suppression arc, reverse seeds).

---

## 12. Story beats (`Narrative.swift` targets)

### 12.1 Tutorial (replace current three lines)

1. *"The NW penitentiary still breathes below the mountain — pink stone, iron, and sentences that outlive the judged."*
2. *"You descend ring by ring. Oil runs low. Wardens do not negotiate."*
3. *"Reach the Vault Heart. Sever the Sinter. Or climb back before the camp seals the mouth."*

### 12.2 Milestones

| Trigger | Beat |
|---------|------|
| First Trial Ash | *"The surface camp remembers your ash."* |
| Ring 5 | *"Malvek's sermons are carved in the stone."* |
| Malvek Shade defeated | *"He wanted deterrence. He bred appetite."* |
| Sinter slain | *"The Heart goes cold. The seal will hold — for now."* |
| First death | *"Another delver for the branches. The vault is hungry."* |
| First withdrawal | *"You climb into gray air. The camp counts what you carried."* |

### 12.3 Epilogue scroll (Vault Heart clear — one-time)

> *Kaefden's surveyors strike the penitentiary from the maps. The mouth is warded. In the years to come, three old mages will hide their quarrels behind "worthiness." You will not be named. The ash will remember.*

---

## 13. Content phases (fiction + mechanics)

| Phase | Deliverable |
|-------|-------------|
- [x] F0 `Narrative.swift` — Avasia prequel copy (June 2026)
| **F1** | Class oath select UI; oath stat modifiers |
| **F2** | Warden rename pass; Sinter boss stats; remove dragon copy |
| **F3** | Relic blurbs + anchor tags; modifier rename |
| **F4** | Codex entries (20–30); death screen expedition log |
| **F5** | Sealed rooms — COPY / LEAVE micro-choice (Cave Record echo) |

Mechanics phases remain per [survivor-crawl-redesign.md](survivor-crawl-redesign.md) §9.

---

## 14. Glossary

| Term | Definition |
|------|------------|
| **Anchor law** | Power must bind to sky, earth, flesh, or civic faith |
| **Ash Vault** | Folk curse-name for sealed NW penitentiary |
| **Anula** | Blue crystal; pink bleed in deep ore |
| **Kaefden** | Royal loyalist faction; operates the prison |
| **Agroman** | Western schism faction; graffiti sympathy in prison |
| **Malvek** | Warden-Magister who caused the Binding |
| **The Sinter** | Reliquary horror; Vault Heart boss |
| **Trial Ash** | Meta currency from runs |
| **Surface Camp** | Meta hub between delves |
| **Delver** | Player role — nameless |
| **Bera** | Neutral clerk; copies bark sheets during seal; truth survives suppression |
| **Commander Pell** | Surface Camp captain; orders descent and mouth seal |
| **Delver 7** | Ledger myth — ring ten breached, name lost |

---

## 15. Open author decisions

| # | Question | Default in this spec |
|---|----------|----------------------|
| 1 | App title | **Avasia: Ash Vault** |
| 2 | Exact year offset | ~70 years before KoN |
| 3 | Malvek visible in camp ledger? | Yes — as historical warden |
| 4 | Fourth Ash-Touched class timing | Post–Heart clear |
| 5 | Inflame name on nose in UI | Stage rename — start with "Ember Rite" |
| 6 | Cross-promo in Avasia-iOS | Optional codex link in anthology hub — no Chronicler |

---

## 16. Acceptance criteria

See **§27** for the full checklist. Minimum bar:

- [ ] Standalone app; no Chronicler dependency
- [ ] Prequel explains abandonment without breaking I-M11 / KoN cave
- [ ] Myth ladder + suppression arc (§18–§19)
- [ ] Sinter replaces Ash Dragon; three delver oaths
- [ ] COPY/LEAVE + "Both. Always both." braid with Cave Record
- [ ] All strings centralized in `Narrative.swift`

---

## 17. References

- [Avasia-iOS](https://github.com/jacobrozell/Avasia-iOS) — saga repo on Desktop (`../Avasia-iOS`)
- [`SAGA.md`](../../../Avasia-iOS/docs/SAGA.md) · [`STORY.md`](../../../Avasia-iOS/docs/STORY.md) · [`sequel/STORY.md`](../../../Avasia-iOS/docs/sequel/STORY.md)
- [`LORE_ARCHIVE.md`](../../../Avasia-iOS/docs/LORE_ARCHIVE.md) §1.4 · [`FORESHADOWING.md`](../../../Avasia-iOS/docs/FORESHADOWING.md)
- Fiction: [`volume-i.md`](../../../Avasia-iOS/docs/fiction/specs/volume-i.md) I-M11 · [`WORLD_BUILDING.md`](../../../Avasia-iOS/docs/fiction/WORLD_BUILDING.md) W-07
- Anthology: [`STORY_CAVE_RECORD.md`](../../../Avasia-iOS/docs/anthology/stories/STORY_CAVE_RECORD.md)

---

## 18. Earned prequel craft (myth ladder)

> **Model:** Michael J. Sullivan — *Age of Myth* enriches *Riyria* by making literal what the later books only **hinted at**. Ash Vault should answer questions KoN already asks, not introduce homework for the text games.

### 18.1 Four layers, one mountain

Each era **misremembers** the layer below:

| Layer | When | Who | What they believe |
|-------|------|-----|-------------------|
| **L1 — Chain mine** | Pre–Old Mage | Jal's generation | Law sentences; earth bleeds pink ore |
| **L2 — Ash Vault** | ~70 yr pre-KoN | Malvek, delvers, **Bera** | Deterrence reliquary; crown seals the mouth |
| **L3 — Old Mage trials** | ~40 yr pre-KoN | Venn + rivals | "Only the worthy" — ego over horror |
| **L4 — KoN crawl** | Game 1 | Amnesiac mage | Punitive puzzles; competitors in ash |

**Design rule:** Ash Vault explains **L2**. It does **not** explain Venn's symbol puzzle (L3) or KoN's plot (L4). Veterans connect **method** (ash-shaped binding), not **plot**.

### 18.2 Empty chairs (already in shipped text)

These lines are the prequel's assignment — do not contradict them:

| Source | Verbatim / paraphrase | Prequel answers |
|--------|----------------------|-----------------|
| KoN `CaveEntranceRoom` | *"prison long before the mages hid their secrets"* | Kaefden penitentiary → seal |
| KoN `FireballRoom` | Dead mage *"black ash in the shape of what he once was"* | Sinter binding method |
| KoN `NorthwestCaveRoom` | Miner speared mining pink shards | Seal-fight trap or Sinter tendril |
| KoN `NortheastCaveRoom` | Iron cages, skeleton overhead | Manacle Hall / Binding Gallery |
| KoN `DruidTalkRoom` | Dentros: *"secret of the Old Mages"* + **lantern** | Camp oil tradition; mouth warded later |
| Cave Record entrance | *"Both. Always both."* | Ring 2 graffiti — **same carving** |
| Cave Record archive | Neutral copy of trials court burned | Bera's bark sheets → later archivist |
| I-M11 | *"We told the world only the worthy"* | Epilogue: three mages wallpaper the ruin |

### 18.3 What each game thinks the mountain is

| Game | Mountain is… |
|------|----------------|
| **Ash Vault** | A failing prison becoming a reliquary of pain |
| **Venn era** | A trophy case for spell legacies |
| **KoN** | A mage exam with corpses as warnings |
| **Cave Record** | Evidence both factions lie |
| **SoC** | (off-map) Echo of binding horror in Paladin plate |

### 18.4 Play order & dramatic irony

| Order | Player experience |
|-------|-------------------|
| KoN → Ash Vault | *"So that's what the iron rings were."* Institutional dread. |
| Ash Vault → KoN | Every branch corpse is **genre foreshadowing**. |
| Ash Vault → Cave Record | Graffiti and archive **click** — same wound, later century. |
| Ash Vault → SoC | Paladins feel like **scaled-up Sinter** — thematic rhyme. |

Standalone Ash Vault must work with zero prior Avasia. Earnedness is for **returners**.

---

## 19. The suppression arc (Malvek & the crown)

Malvek is not the only villain. **Kaefden buries the story** — that is the saga tie-in Vashirr later exploits.

### 19.1 Act structure (in-run fiction)

| Act | Rings | Story |
|-----|-------|-------|
| **I — Sentence** | 1–3 | Active prison; oil, manacles, schism graffiti; delver is expendable |
| **II — Appetite** | 4–6 | Pink saturation; miners' ghosts; Hess's corruption; first ash-fog |
| **III — Binding** | 7–8 | Malvek's sermons; reliquary approach; shade boss; truth in codex |
| **IV — Sever** | 9–10 | Ash Choir; Vault Heart; Sinter; surface seal begins |
| **V — Myth** | Epilogue | Maps redacted; Delver 7 ledger; Venn era foreshadowed |

### 19.2 Malvek — character bible

| Field | Detail |
|-------|--------|
| **Title** | Warden-Magister of the NW Penitentiary |
| **Anchor** | Sky + civic — law as visible spectacle |
| **Belief** | Agroman recruits because peasants think Kaefden is soft; **show the cost** |
| **Crime** | Ordered the Binding: prisoner suffering → reliquary without oath or consent |
| **Voice** | Sermon cadence; never jokes; quotes civic statutes |
| **Key line** | *"Let them see what law costs."* |
| **Fate** | Lower body consumed; mind merged into Sinter; skull in Heart |

**Contrast Vashirr** (do not blur):

| | Malvek | Vashirr (later) |
|--|--------|-----------------|
| Audience | Convicts | Soldiers |
| Pitch | Fear the crown | Empower the shield |
| Faction | Kaefden extremist | Many Hands ideologue |
| Outcome | Buried by Kaefden | Defeated but argued |

### 19.3 The Binding (canonical detail)

1. Pink ore yields **Anula bleed** — earth anchor leaking through stone.
2. Malvek theorizes a **civic reliquary**: pain stored in crystal so any would-be oathbreaker *feels* sentence before crime.
3. Sky mages bind the ritual; turnkeys chant oaths; prisoners are **not** asked.
4. Reliquary wakes hungry — consumes vessels without stabilizing anchor.
5. **The Sinter** spreads: ash-fog, crystal growth, ash-shaped corpses (same silhouette KoN will show).

### 19.4 The Seal & suppression

**Surface Camp** officers (names for codex / future fiction):

| Name | Role | Beat |
|------|------|------|
| **Commander Pell** | Kaefden penal captain | Orders Delver 7 descent; orders seal on retreat |
| **Binder Sorin** | Emergency Stonebend mage | Closes upper gates; dies exhausted or survives maimed |
| **Clerk Bera** | Neutral Ofelos registry attaché | Copies trial bark sheets **during** seal; ancestor of Cave Record trail |

**Suppression checklist** (what history loses):

- [ ] Official ledgers reclassified *"mine collapse"*
- [ ] Malvek recorded *"died in riot"* not Binding
- [ ] NW survey maps omit cave mouth
- [ ] Folk curse **Ash Vault** replaces ledger name
- [ ] Bera's sheets survive off-book → Cave Record lineage

**Why this earns SoC/KoN:** Kaefden IV inherits a faction that **already hid one binding atrocity**. Thekia and gate-guard speak Restoration honor; the mountain keeps receipts Bera copied.

### 19.5 Delver 7 (nameless myth)

- Surface Camp ledger uses **numbers**, not names — convicts and conscripts alike.
- On Vault Heart clear, camp scribe writes: *"Delver 7 — ring ten breached, anchor cut. Mouth sealed at dusk."*
- Player may **never** see their number; optional death screen on first Heart clear: *"The ledger assigns you a number. You do not read it."*
- Cave Record (future anthology patch): margin note *"Delver 7?"* in Suformin's map hand — optional LOOK, not required.

---

## 20. Reverse seed catalog (Avasia-iOS patches)

> **Status:** Proposed text-only additions to [Avasia-iOS](https://github.com/jacobrozell/Avasia-iOS). Optional LOOK / second LOOK — never critical path. Players without Ash Vault still get atmosphere.

### 20.1 KoN — `MountainCaveRooms.swift`

| Room | Trigger | Proposed line |
|------|---------|---------------|
| `CaveEntranceRoom` | Second `LOOK` / `HISTORY` | *"The iron rings are newer than the scorch marks. Someone closed this place in a hurry."* |
| `CaveEntranceRoom` | `HISTORY` (extend) | *"Camp legend calls it the Ash Vault. Survey maps do not."* |
| `MainCaveRoom` | `LOOK` (new) | *"Pink light pulses like a slow heartbeat. The stone is warm when it should be cold."* |
| `FireballRoom` | `LOOK` dead mage | *"The ash holds his shape too carefully to be ordinary fire — as if something wanted a warning."* |
| `NorthwestCaveRoom` | `LOOK` miner | *"Spear from behind. Discipline, not monster — or something wearing a turnkey's stride."* |
| `DruidTalkRoom` | `TALK` after lantern | *"We leave oil at mountain mouths. Old habit. The penal camps are gone, but the dark isn't."* |

### 20.2 Anthology — `CaveRecordRooms.swift`

| Room | Trigger | Proposed line |
|------|---------|---------------|
| `CaveRecordTrailRoom` | `READ` map (extend) | *"A faded camp notation: Delver 7 — ring ten. The ink is older than the scholar's copy."* |
| `CaveRecordEntranceRoom` | `LOOK` graffiti (extend) | *"Beneath Both. Always both., a tally: VII."* |
| `CaveRecordCavernRoom` | `LOOK` cages | *"A reliquary niche is chiseled shut with civic seal-marks — cracked from inside."* |
| `CaveRecordArchiveRoom` | `READ` (extend) | *"One sheet names Warden-Magister Malvek. The court ledger says he died in a riot. The bark disagrees."* |

### 20.3 SoC — optional (low priority)

| Location | Proposed beat |
|----------|---------------|
| Library pamphlet LOOK | *"…binding pain into stone for deterrence. Struck from NW maps."* |
| Doran pier requisition crate | *"Pink ore — penal grade. No ledger trail."* |

### 20.4 Voice rules ([`FORESHADOWING.md`](../../../Avasia-iOS/docs/FORESHADOWING.md))

- KoN: prophetic, not preachy — **no** "Sinter" or "Malvek" on critical path.
- Use *bound*, *ash*, *seal*, *ledger*, *both hands* — not system jargon.
- Ash Vault game **may** name Malvek; text games keep myth distance.

---

## 21. COPY / LEAVE — saga moral spine

One question repeated across formats: **who owns truth when both factions lie?**

| Product | Choice | Fiction |
|---------|--------|---------|
| **Ash Vault** (ring 7 sealed room) | **Copy** bark sheet / **Leave** it | Risk camp discovery vs moral memory |
| **Cave Record** | COPY for Silvarium / LEAVE hidden | Same |
| **Two Hands Market** | Sell record to one side / broker | Commodity pressure |
| **Open Ledger** (anthology finale) | Publish / seal archive | Capstone |

**Ash Vault sealed room (F5):**

- **Trigger:** Ring 7 Reliquary Approach — side door after warden.
- **Copy:** +codex unlock; camp suspicion flag (flavor); *"Truth travels — and so does blame."* (mirror Cave Record)
- **Leave:** +1 supply from hidden oil stash; *"Memory is an archive that dies with you."*

No stat swing large enough to force pick — **identity** choice.

---

## 22. Ring script (expanded beats)

Combat log + codex unlock per ring. One **guardian flavor** line per ring.

| Ring | Beat (ingress) | Guardian flavor | Codex title |
|------|----------------|-----------------|-------------|
| 1 Mouth | *Lantern smoke. Pink crystal in wet stone.* | *A turnkey's whistle — but the shifts ended years ago.* | *The Mouth* |
| 2 Graffiti | *"Both. Always both."* | *Schism ink. Agroman numerals beside Kaefden oaths.* | *Two Hands on One Wrist* |
| 3 Manacle | *Iron that outlived its prisoners.* | *Wrist rings at kneeling height. Jal's generation.* | *Chains Below the Forge* |
| 4 Branching | *Lanterns weren't meant for this depth.* | *A pickaxe rusts beside colorless shards.* | *The Miner's Warning* |
| 5 Forge | *Ore dust and old sermons.* | *Malvek's words carved over forge slag.* | *Let Them See* |
| 6 Pink Saturation | *Blue crystal weeps into the rock.* | *Heat without flame. Pre-Inflame dread.* | *Anula Bleed* |
| 7 Reliquary | *Malvek called this deterrence.* | *COPY / LEAVE room.* | *The Clerk's Nook* |
| 8 Binding | *Chains that bind the binder.* | *Malvek's Shade: "I only wanted order."* | *Warden-Magister* |
| 9 Ash Choir | *You hear your own footsteps twice.* | *Whispers in condemned names.* | *The Sinter Stirs* |
| 10 Heart | *Something hot without flame.* | *Sinter composite VO.* | *Vault Heart* |

**Warden kill lines:**

- **Hess:** *"The crown pays me either way."*
- **Pink Bloom:** *(nonverbal crystal scream)*
- **Echo Sergeant:** *"Still… on… shift…"*
- **Malvek's Shade:** *"I only wanted them to **see**."*
- **The Sinter:** *"You are late. You are always late."* (composite)

---

## 23. Institution & object continuity

| Object | Ash Vault | Later games |
|--------|-----------|-------------|
| Iron manacle rings | Rings 2–3 | KoN entrance; Cave Record entrance |
| Lantern oil | Supplies | Dentros gift |
| Pink / blue crystal | Rings 6+ | KoN main cave; SoC Anula |
| Ash-shaped corpse | Sinter victims | KoN fireball room |
| Bark sheets | Bera / COPY choice | Cave Record archive |
| Civic seal-marks | Surface seal | Silvarium blood seal rhyme |
| Delver ledger numbers | Camp | Cave Record map margin |

**Dentros thread:** Cataracta druids contracted as **scout trainers** after the seal — fox-form scouts teach Kite oath delvers oil discipline. KoN Dentros is centuries later; he doesn't know Malvek, but he knows *"leave oil at the mouth."*

---

## 24. Local codex (Ash Vault app)

Unlock by depth / bosses / COPY choice. 24 entries — sample set:

| ID | Title | Unlock | Body (summary) |
|----|-------|--------|----------------|
| C01 | NW Penitentiary | Ring 1 | Kaefden civic prison; pink ore sentence |
| C02 | Two Hands | Ring 2 | Schism graffiti origin |
| C03 | Jal | Ring 3 | Chain-mine era ([W-07](../../../Avasia-iOS/docs/fiction/WORLD_BUILDING.md)) |
| C04 | The Miner | Ring 4 | Spear trap; ore greed |
| C05 | Malvek | Ring 5 | Warden-Magister sermons |
| C06 | Anula Bleed | Ring 6 | Earth anchor in ore |
| C07 | Clerk Bera | COPY | Neutral archive; Ofelos attaché |
| C08 | The Binding | Ring 8 | Reliquary crime |
| C09 | Commander Pell | Ring 8 | Ordered seal |
| C10 | Delver 7 | Heart clear | Ledger myth |
| C11 | The Sinter | Sinter slain | Entity nature |
| C12 | Suppression | Epilogue | Maps struck; riot lie |
| C13 | Three Mages | Epilogue | Venn era foreshadow |
| C14 | Ash Shape | Fireball echo | Why corpses hold form |
| C15 | Lantern Habit | Kite oath | Druid oil tradition |

Entries C16–C24: faction graffiti, Hess, Echo Sergeant, endless depth, class oaths, relic blurbs.

---

## 25. Thematic chain (saga argument)

Each antagonist **misapplies** anchor law differently — Ash Vault is the first proof:

```text
Malvek   → bind pain to stone (civic cruelty)     → buried
Venn     → bind worth to ego (sky hoarding)         → lied
Vashirr  → bind magic to plate (Many Hands)        → defeated, argued
Coalition→ bind flesh to garrison (SoC epilogue)   → inherited
Cults    → bind without order (Red Litany)         → Era 3
```

Ash Vault players who later read [`VASHIRR.md`](../../../Avasia-iOS/docs/VASHIRR.md) should think: *Kaefden had this coming in the argument — not in the war.*

---

## 26. Fiction backlog (author queue)

| Piece | Location | Status |
|-------|----------|--------|
| **AV-01 *Delver Seven*** | [Avasia-iOS `fiction/ASH_VAULT/STORY_AV-01_DELVER_SEVEN.md`](../../../Avasia-iOS/docs/fiction/ASH_VAULT/STORY_AV-01_DELVER_SEVEN.md) | ✅ Prose draft |
| **AV-02 *The Clerk's COPY*** | [STORY_AV-02_BERA_COPY.md`](../../../Avasia-iOS/docs/fiction/ASH_VAULT/STORY_AV-02_BERA_COPY.md) | ✅ Prose draft |
| **AV-03 *Last Oil*** | [STORY_AV-03_LAST_OIL.md`](../../../Avasia-iOS/docs/fiction/ASH_VAULT/STORY_AV-03_LAST_OIL.md) | ✅ Prose draft |
| **Malvek sermons** | [MALVEK_SERMONS.md](../../../Avasia-iOS/docs/fiction/ASH_VAULT/MALVEK_SERMONS.md) | ✅ Fragments |
| **I-M11 revision** | [I-M11_REVISION_NOTE.md](../../../Avasia-iOS/docs/fiction/ASH_VAULT/I-M11_REVISION_NOTE.md) | ✅ Author note |
| **Cross-promo copy** | [MARKETING_CROSSPROMO.md](../../../Avasia-iOS/docs/fiction/ASH_VAULT/MARKETING_CROSSPROMO.md) | ✅ Draft |
| **Anthology engine** | `ashVaultDelverSeven` story ID | Planned |
| **Reverse seeds** | Avasia-iOS §20 patches | Planned |

Ash Vault index: [`ios/docs/fiction/README.md`](fiction/README.md)

---

## 27. Updated acceptance criteria

- [ ] Myth ladder documented; no KoN plot retcon
- [ ] Suppression arc: crown erases Malvek; Bera preserves truth
- [ ] "Both. Always both." identical in Ash Vault ring 2 and Cave Record
- [ ] COPY/LEAVE sealed room mirrors Cave Record
- [ ] Delver 7 ledger myth on Heart clear
- [ ] Reverse seed list filed for Avasia-iOS (optional ship)
- [ ] §11 payoff map + §18–§26 braid for implementers
