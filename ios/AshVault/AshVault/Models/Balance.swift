import Foundation

/// Central tuning knobs. One place to balance the whole game.
///
/// **Progression / pacing:** every knob in `// MARK: - Progression` below is
/// documented in `ios/docs/pacing-spec.md` (knob table + tweak workflow).
/// **Idle / offline:** `ios/docs/idle-earnings-spec.md`.
/// **Full game:** `ios/docs/game-design-spec.md` §10.
///
/// After changing progression constants, run:
///   `python3 ios/docs/tools/balance_sim.py`
///   `xcodebuild test -scheme AshVault -only-testing:AshVaultTests/ProgressionKnobTests`
///
/// Keep `docs/tools/balance_sim.py` `PACING` block in sync (same names/values).
enum Balance {

    // MARK: - Progression
    //
    // ── Crawl structure (survivor crawl) ────────────────────────────────────
    /// Guardians per ring; last is the warden (boss).
    static let enemiesPerLayer = 8
    /// Vault Heart warden — campaign climax before endless descent.
    static let vaultHeartLayer = 10
    /// Legacy alias (tests/docs migrating).
    static let campaignDragonLayer = vaultHeartLayer

    // ── Run draft (kill XP) ─────────────────────────────────────────────────
    static let killsPerDraftBase = 4
    static let killsPerDraftMin = 3
    static let killsPerDraftRingStep = 2
    static let draftAttackBonus = 10
    static let draftDefenseBonus = 8
    static let draftHpBonus = 30
    static let draftManaBonus = 10
    // Delver oaths (F1 — survivor crawl classes)
    static let oathHoundAttackBonus = 3
    static let oathMastHpBonus = 15
    static let oathMastDefenseBonus = 3
    static let oathKiteLuckSteps = 1
    static let oathKiteHpPenalty = 8
    static let oathHoundWoundedDamageBonusPercent = 10
    static let oathMastCampMaxHpBonusPercent = 5
    static let sealedRoomRing = 7
    static let sealedRoomLeaveSupplyBonus = 1

    static let draftStatBaseWeight = 10
    static let draftRelicBaseWeight = 8
    static let draftInkBaseWeight = 10
    static let draftTuneBaseWeight = 9
    static let draftEvolutionUnlockWeight = 25

    // ── Manual vs auto (Camp Guard) ─────────────────────────────────────────
    static let manualDamageMultiplier = 1.20
    static let autoDamageMultiplier = 0.80
    /// Auto-battle camps when HP falls below this % before pushing deeper.
    static let autoCampHpThresholdPercent = 70
    /// Auto-battle makes camp every N rings cleared (buys upgrades / potions).
    static let autoCampEveryNRings = 1
    /// Meta mercenaries do not fight for you in Phase 1 survivor crawl.
    static let mercenaryCombatDpsFactor = 0.0

    // ── Dungeon crawl (supplies, modifiers, doors) ──────────────────────────
    /// Torch/supply budget for the run (see `dungeon-crawl-pillars.md`).
    static let startingSupplies = 32
    static let supplyCostPerRing = 1
    static let supplyCostCamp = 2
    /// Enemy ATK bonus when supplies hit 0.
    static let supplyStarvedEnemyAtkPercent = 15
    /// First ring teaches combat; door forks from ring 2.
    static let doorChoiceMinRing = 2
    static let eliteEncounterHpPercent = 40
    static let eliteEncounterAtkPercent = 40
    static let eliteBonusGoldPercent = 50
    static let shrineHealPercent = 25
    static let shrineBonusGold = 35
    static let quietRingExtraDraftKills = 2
    static let ashGreedGoldBonus = 1.35
    static let brittleSealEnemyAtkPercent = 15
    static let mirrorVaultEnemyAtkPercent = 10
    static let fungalRingEnemyHpPercent = 10
    static let hoardersTollShopDiscount = 0.75
    static let hoardersTollWardenHpPercent = 25

    // ── Economy ─────────────────────────────────────────────────────────────
    /// Global kill-gold multiplier (combat + offline). ↓ = tighter economy.
    static let goldRewardScale = 0.52
    /// Permanent shop price growth per item owned.
    static let shopPriceGrowth = 1.7
    /// Mercenary hire price growth per copy owned.
    static let mercenaryPriceGrowth = 1.14
    /// Shards on descent = floor(sqrt(runGoldEarned / this)).
    static let prestigeShardDivisor = 100.0
    static let fortuneGoldPerLevel = 0.06      // Ash Tree: +6% gold / level

    // ── Enemy difficulty ────────────────────────────────────────────────────
    /// Base fodder stats at scaleLevel 0 (Java original).
    static let enemyBaseHp = 50
    static let enemyBaseAtk = 15
    static let enemyBaseDef = 5
    /// Per completed layer (scaleLevel bump).
    static let enemyScaleHpPerGroup = 23
    static let enemyScaleAtkPerGroup = 13
    static let enemyScaleDefPerGroup = 6
    /// Boss flat bump over current fodder line.
    static let enemyBossHpBonus = 20
    static let enemyBossAtkBonus = 10
    /// Pre-dragon: layers 2–5 multiply stats by `1 + this × (layer − 1)`.
    static let campaignLayerStatGrowth = 0.05
    /// Post-dragon compounding per endless layer (HP > ATK on purpose).
    static let enemyEndlessHpGrowth = 1.10
    static let enemyEndlessAtkGrowth = 1.06

    // ── Run relics (in-crawl) ───────────────────────────────────────────────
    static let maxRunRelics = 6
    static let wardenRunRelicDropChancePercent = 55
    static let runRelicDuplicateGoldBonus = 30
    static let draftSynergyWeightBase = 12
    static let evolutionInkPerPick = 3
    static let evolutionInkThreshold = 8
    static let meteorBurnProcsNeeded = 8
    static let kindlingDraftsNeeded = 5
    static let glacierChillProcsNeeded = 10
    static let needleCritsNeeded = 15
    static let kindlingDmgPerBurnStack = 3
    static let meteorDamageBonusPercent = 50
    static let rimeShardDamageBonusPercent = 20
    static let coalTinderBurnBonusPercent = 15
    static let luckyFlintCritBonus = 5
    static let thornLatticeBonusPercent = 50
    static let greedSealGoldBonusPercent = 40
    static let ashWardReduction = 0.05
    static let frostCrownChillAtkPenalty = 4
    static let glacierHighHpThresholdPercent = 70
    static let glacierDamageBonusPercent = 35

    // ── Gallery relics (meta trophies) ──────────────────────────────────────
    static let bossRelicDropChancePercent = 8
    static let relicDuplicateGoldBonus = 40
    static let maxEquippedRelics = 3
    static let relicGoldBonus = 0.12
    static let relicHpBonus = 0.08
    static let relicCritBonus = 8
    static let relicLifestealPercent = 6
    static let relicThornsPercent = 10
    static let relicManaRegenBonus = 1

    // ── Automation pacing ───────────────────────────────────────────────────
    /// Max mercenaries auto-shop hires per shop visit (0 = manual only).
    static let autoShopMaxMercenariesPerVisit = 1
    /// Max sigil scrolls auto-shop buys per visit (frost before arc via catalog order).
    static let autoShopMaxSigilScrollsPerVisit = 1
    /// Auto-battle heals when HP% is below this threshold.
    static let autoBattleHealThresholdPercent = 35
    /// Auto level-up / shop unlock after this many Ash Shards earned (lifetime).
    static let automationUnlockShards = 6
    static let autoDescendDefaultMinShards = 8

    // ── Mercenary milestones ────────────────────────────────────────────────
    static let mercenaryMilestones = [25, 50, 100, 200, 400]

    // MARK: - Offline (see idle-earnings-spec.md)
    static let baseOfflineHours = 4.0
    static let baseOfflineEfficiency = 0.035
    static let maxOfflineEfficiency = 1.0
    static let manualOfflineEfficiency = 0.020
    static let offlineMercenaryDpsFactor = 0.04
    /// Hard gold ceiling per return: `base + perLayer × layer` (stops post-campaign snowball).
    static let offlineGoldCapBase = 2_500
    static let offlineGoldCapPerLayer = 800
    static let patienceHoursPerLevel = 1
    static let patienceEfficiencyPerLevel = 0.05

    // MARK: - Crawl rewards (survivor-style: depth pays, not gold)
    /// Shards per warden slain this run.
    static let shardsPerBossKill = 1
    /// +1 shard per two rings reached (floor(depth / 2)).
    static let shardsPerTwoRings = 1
    /// Bonus when Vault Heart falls.
    static let vaultHeartShardBonus = 5
    /// On death, the Shrine banks this fraction of `pendingShards` (rest scatters).
    static let deathShardRetention = 0.35
    /// Legacy depth bonus (superseded by depth shard formula).
    static let dragonClearShardBonus = vaultHeartShardBonus
    static let shardBonusPerLayerCleared = 0

    /// Max offline gold for a return at the given layer (before efficiency math).
    static func offlineGoldCap(layer: Int) -> Int {
        offlineGoldCapBase + offlineGoldCapPerLayer * max(1, layer)
    }

    // MARK: - Combat
    static let manaRegenPerTurn = 2
    static let critMultiplier = 2.0
    static let minCritChancePercent = 5

    // MARK: - Moves
    static let heavyManaCost = 5
    static let heavyDamageMultiplier = 1.8
    static let heavyStunChancePercent = 20
    static let bossPoisonChancePercent = 25

    // MARK: - Elemental combat (sigils)
    static let weaknessMultiplier = 1.5
    static let resistMultiplier = 0.5
    static let emberBoltManaCost = 8
    static let emberBoltFlatBonus = 5
    static let emberBurnChancePercent = 35
    static let frostShardManaCost = 6
    static let frostShardFlatBonus = 2
    static let frostShardScrollPrice = 45
    static let arcLanceManaCost = 10
    static let arcLanceFlatBonus = 8
    static let arcLanceScrollPrice = 55
    static let venomLashManaCost = 5
    static let venomLashFlatBonus = 1
    static let venomLashScrollPrice = 45
    static let partialCastMultiplier = 0.5
    static let fumbledCastMultiplier = 0.25
    /// During campaign (layers 1–5), cap a single enemy hit to this % of max HP.
    static let maxCampaignHitPercent = 50
    /// Flat shop price for the once-per-run revive consumable.
    static let phoenixAshPrice = 175
    /// HP restored when Phoenix Ash triggers (percent of max HP).
    static let phoenixAshReviveHpPercent = 35
    /// Mana floor when revived (percent of max mana).
    static let phoenixAshReviveManaPercent = 25

    // MARK: - Prestige (combat stats)
    static let mightAttackPerLevel = 0.05
    static let vitalityHpPerLevel = 0.06
    static let wardReductionPerLevel = 0.03
    static let maxDamageReduction = 0.60

    // MARK: - Idle tick
    static let tickSeconds = 1.0
}
