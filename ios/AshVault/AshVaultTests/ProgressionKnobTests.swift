import XCTest
@testable import AshVault

/// Regression lock for `Balance` progression knobs.
/// When retuning pacing: edit `Balance.swift`, this file, `pacing-spec.md`,
/// and `docs/tools/balance_sim.py` `PACING` together.
@MainActor
final class ProgressionKnobTests: XCTestCase {

    func testEconomyKnobs() {
        XCTAssertEqual(Balance.goldRewardScale, 0.58, accuracy: 1e-9)
        XCTAssertEqual(Balance.shopPriceGrowth, 1.7, accuracy: 1e-9)
        XCTAssertEqual(Balance.mercenaryPriceGrowth, 1.14, accuracy: 1e-9)
        XCTAssertEqual(Balance.prestigeShardDivisor, 100.0, accuracy: 1e-9)
        XCTAssertEqual(Balance.fortuneGoldPerLevel, 0.06, accuracy: 1e-9)
    }

    func testEnemyKnobs() {
        XCTAssertEqual(Balance.enemyBaseHp, 50)
        XCTAssertEqual(Balance.enemyBaseAtk, 15)
        XCTAssertEqual(Balance.enemyBaseDef, 5)
        XCTAssertEqual(Balance.enemyScaleHpPerGroup, 18)
        XCTAssertEqual(Balance.enemyScaleAtkPerGroup, 16)
        XCTAssertEqual(Balance.enemyScaleDefPerGroup, 6)
        XCTAssertEqual(Balance.enemyBossHpBonus, 20)
        XCTAssertEqual(Balance.enemyBossAtkBonus, 10)
        XCTAssertEqual(Balance.campaignLayerStatGrowth, 0.06, accuracy: 1e-9)
        XCTAssertEqual(Balance.enemyEndlessHpGrowth, 1.10, accuracy: 1e-9)
        XCTAssertEqual(Balance.enemyEndlessAtkGrowth, 1.06, accuracy: 1e-9)
    }

    func testRelicKnobs() {
        XCTAssertEqual(Balance.bossRelicDropChancePercent, 18)
        XCTAssertEqual(Balance.relicDuplicateGoldBonus, 40)
        XCTAssertEqual(Balance.maxEquippedRelics, 3)
    }

    func testAutomationKnobs() {
        XCTAssertEqual(Balance.autoShopMaxMercenariesPerVisit, 1)
        XCTAssertEqual(Balance.autoBattleHealThresholdPercent, 35)
        XCTAssertEqual(Balance.automationUnlockShards, 1)
        XCTAssertEqual(Balance.autoDescendDefaultMinShards, 8)
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
