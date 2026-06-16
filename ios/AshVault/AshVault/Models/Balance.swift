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
    // ── Economy ─────────────────────────────────────────────────────────────
    /// Global kill-gold multiplier (combat + offline). ↓ = tighter economy.
    static let goldRewardScale = 0.55
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
    /// Per completed group-of-5 (scaleLevel bump).
    static let enemyScaleHpPerGroup = 18
    static let enemyScaleAtkPerGroup = 16
    static let enemyScaleDefPerGroup = 6
    /// Boss flat bump over current fodder line.
    static let enemyBossHpBonus = 20
    static let enemyBossAtkBonus = 12
    /// Pre-dragon: layers 2–5 multiply stats by `1 + this × (layer − 1)`.
    static let campaignLayerStatGrowth = 0.06
    /// Post-dragon compounding per endless layer (HP > ATK on purpose).
    static let enemyEndlessHpGrowth = 1.10
    static let enemyEndlessAtkGrowth = 1.06

    // ── Relics ──────────────────────────────────────────────────────────────
    static let bossRelicDropChancePercent = 18
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
    /// Auto-battle heals when HP% is below this threshold.
    static let autoBattleHealThresholdPercent = 35
    /// Auto level-up / shop unlock after this many Ash Shards earned (lifetime).
    static let automationUnlockShards = 1
    static let autoDescendDefaultMinShards = 8

    // ── Mercenary milestones ────────────────────────────────────────────────
    static let mercenaryMilestones = [25, 50, 100, 200, 400]

    // MARK: - Offline (see idle-earnings-spec.md)
    static let baseOfflineHours = 4.0
    static let baseOfflineEfficiency = 0.055
    static let maxOfflineEfficiency = 1.0
    static let manualOfflineEfficiency = 0.025
    static let offlineMercenaryDpsFactor = 0.10
    static let patienceHoursPerLevel = 1
    static let patienceEfficiencyPerLevel = 0.05

    // MARK: - Combat
    static let manaRegenPerTurn = 2
    static let critMultiplier = 2.0
    static let minCritChancePercent = 5

    // MARK: - Moves
    static let heavyManaCost = 5
    static let magicManaCost = 8
    static let poisonManaCost = 4
    static let heavyDamageMultiplier = 1.8
    static let magicFlatBonus = 5
    static let heavyStunChancePercent = 20
    static let magicBurnChancePercent = 35
    static let bossPoisonChancePercent = 25

    // MARK: - Prestige (combat stats)
    static let mightAttackPerLevel = 0.05
    static let vitalityHpPerLevel = 0.06
    static let wardReductionPerLevel = 0.03
    static let maxDamageReduction = 0.60

    // MARK: - Idle tick
    static let tickSeconds = 1.0
}
