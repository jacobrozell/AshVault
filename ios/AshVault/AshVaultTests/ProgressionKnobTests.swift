import XCTest
@testable import AshVault

/// Regression lock for `Balance` progression knobs.
/// When retuning pacing: edit `Balance.swift`, this file, `pacing-spec.md`,
/// `crawl-pacing-spec.md`, and `docs/tools/balance_sim.py` `PACING` together.
@MainActor
final class ProgressionKnobTests: XCTestCase {

    func testCrawlStructureKnobs() {
        XCTAssertEqual(Balance.enemiesPerLayer, 8)
        XCTAssertEqual(Balance.vaultHeartLayer, 10)
        XCTAssertEqual(Balance.campaignDragonLayer, 10)
        XCTAssertEqual(Balance.vaultHeartShardBonus, 5)
        XCTAssertEqual(Balance.shardsPerBossKill, 1)
        XCTAssertEqual(Balance.deathShardRetention, 0.35, accuracy: 1e-9)
        XCTAssertEqual(Balance.manualDamageMultiplier, 1.20, accuracy: 1e-9)
        XCTAssertEqual(Balance.autoDamageMultiplier, 0.80, accuracy: 1e-9)
        XCTAssertEqual(Balance.campaignLayerStatGrowth, 0.05, accuracy: 1e-9)
        XCTAssertEqual(Balance.draftAttackBonus, 10)
        XCTAssertEqual(Balance.mercenaryCombatDpsFactor, 0.0, accuracy: 1e-9)
    }

    func testCrawlKnobs() {
        XCTAssertEqual(Balance.startingSupplies, 32)
        XCTAssertEqual(Balance.supplyCostPerRing, 1)
        XCTAssertEqual(Balance.supplyCostCamp, 2)
        XCTAssertEqual(Balance.doorChoiceMinRing, 2)
        XCTAssertEqual(Balance.quietRingExtraDraftKills, 2)
    }

    func testDraftKnobs() {
        XCTAssertEqual(Balance.killsPerDraftBase, 4)
        XCTAssertEqual(Balance.killsPerDraftMin, 3)
        XCTAssertEqual(Balance.draftAttackBonus, 10)
        XCTAssertEqual(Balance.autoCampEveryNRings, 1)
    }

    func testEconomyKnobs() {
        XCTAssertEqual(Balance.goldRewardScale, 0.52, accuracy: 1e-9)
        XCTAssertEqual(Balance.shopPriceGrowth, 1.7, accuracy: 1e-9)
        XCTAssertEqual(Balance.mercenaryPriceGrowth, 1.14, accuracy: 1e-9)
        XCTAssertEqual(Balance.prestigeShardDivisor, 100.0, accuracy: 1e-9)
        XCTAssertEqual(Balance.fortuneGoldPerLevel, 0.06, accuracy: 1e-9)
    }

    func testEnemyKnobs() {
        XCTAssertEqual(Balance.enemyBaseHp, 50)
        XCTAssertEqual(Balance.enemyBaseAtk, 15)
        XCTAssertEqual(Balance.enemyBaseDef, 5)
        XCTAssertEqual(Balance.enemyScaleHpPerGroup, 23)
        XCTAssertEqual(Balance.enemyScaleAtkPerGroup, 13)
        XCTAssertEqual(Balance.enemyScaleDefPerGroup, 6)
        XCTAssertEqual(Balance.enemyBossHpBonus, 20)
        XCTAssertEqual(Balance.enemyBossAtkBonus, 10)
        XCTAssertEqual(Balance.campaignLayerStatGrowth, 0.05, accuracy: 1e-9)
        XCTAssertEqual(Balance.enemyEndlessHpGrowth, 1.10, accuracy: 1e-9)
        XCTAssertEqual(Balance.enemyEndlessAtkGrowth, 1.06, accuracy: 1e-9)
    }

    func testOfflineKnobs() {
        XCTAssertEqual(Balance.baseOfflineEfficiency, 0.035, accuracy: 1e-9)
        XCTAssertEqual(Balance.manualOfflineEfficiency, 0.020, accuracy: 1e-9)
        XCTAssertEqual(Balance.offlineMercenaryDpsFactor, 0.04, accuracy: 1e-9)
        XCTAssertEqual(Balance.offlineGoldCapBase, 2_500)
        XCTAssertEqual(Balance.offlineGoldCapPerLayer, 800)
        XCTAssertEqual(Balance.offlineGoldCap(layer: 6), 7_300)
    }

    func testRelicKnobs() {
        XCTAssertEqual(Balance.bossRelicDropChancePercent, 18)
        XCTAssertEqual(Balance.relicDuplicateGoldBonus, 40)
        XCTAssertEqual(Balance.maxEquippedRelics, 3)
    }

    func testAutomationKnobs() {
        XCTAssertEqual(Balance.autoShopMaxMercenariesPerVisit, 1)
        XCTAssertEqual(Balance.autoShopMaxSigilScrollsPerVisit, 1)
        XCTAssertEqual(Balance.autoBattleHealThresholdPercent, 35)
        XCTAssertEqual(Balance.automationUnlockShards, 6)
        XCTAssertEqual(Balance.autoDescendDefaultMinShards, 8)
    }

    func testCombatTuningKnobs() {
        XCTAssertEqual(Balance.maxCampaignHitPercent, 50)
        XCTAssertEqual(Balance.phoenixAshPrice, 175)
        XCTAssertEqual(Balance.phoenixAshReviveHpPercent, 35)
        XCTAssertEqual(Balance.weaknessMultiplier, 1.5)
        XCTAssertEqual(Balance.emberBoltManaCost, 8)
        XCTAssertEqual(Balance.frostShardScrollPrice, 45)
        XCTAssertEqual(Balance.arcLanceManaCost, 10)
        XCTAssertEqual(Balance.arcLanceScrollPrice, 55)
        XCTAssertEqual(Balance.venomLashManaCost, 5)
        XCTAssertEqual(Balance.venomLashScrollPrice, 45)
    }

    func testEconomyKnobsInSaneRanges() {
        XCTAssertGreaterThan(Balance.goldRewardScale, 0.2)
        XCTAssertLessThan(Balance.goldRewardScale, 1.0)
        XCTAssertGreaterThan(Balance.bossRelicDropChancePercent, 0)
        XCTAssertLessThanOrEqual(Balance.bossRelicDropChancePercent, 50)
        XCTAssertGreaterThan(Balance.campaignLayerStatGrowth, 0)
        XCTAssertLessThan(Balance.campaignLayerStatGrowth, 0.25)
    }
}
