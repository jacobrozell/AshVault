import XCTest
@testable import AshVault

@MainActor
final class AchievementEvaluatorTests: XCTestCase {
    func testBackfillFromLifetimeStatsUnlocksExpectedCoreTrophies() {
        var lifetime = LifetimeStats.empty
        lifetime.totalGoldEarned = 120_000
        lifetime.totalKills = 5
        lifetime.totalDeaths = 12
        lifetime.totalDescents = 3
        lifetime.relicsFound = 2
        lifetime.deepestLayer = 8
        lifetime.totalRevives = 1
        lifetime.phoenixAshesBought = 1

        let ctx = AchievementContext(
            lifetime: lifetime,
            best: .empty,
            totalShards: 60,
            treeLevels: [:],
            discoveredRelics: [],
            mercenaryCounts: [.goblinSlayer: 1],
            equippedRelicCount: 0,
            clearedFinalBoss: true,
            firstDeathBeatShown: true,
            onboardingCompleted: true,
            runStats: .empty,
            witness: AchievementWitnessFlags(),
            masteredSigilCount: 1,
            weakSigilWitnessed: false
        )

        let (state, unlocked) = AchievementEvaluator.shared.backfill(
            context: ctx,
            from: .empty,
            now: Date(timeIntervalSince1970: 1234)
        )

        let ids = Set(unlocked)
        XCTAssertTrue(ids.contains(.firstBlood))
        XCTAssertTrue(ids.contains(.firstFall))
        XCTAssertTrue(ids.contains(.tenDeaths))
        XCTAssertTrue(ids.contains(.gold1k))
        XCTAssertTrue(ids.contains(.gold100k))
        XCTAssertTrue(ids.contains(.firstWithdrawal))
        XCTAssertTrue(ids.contains(.shardHoarder))
        XCTAssertTrue(ids.contains(.phoenixRise))
        XCTAssertTrue(ids.contains(.phoenixBuyer))
        XCTAssertTrue(ids.contains(.firstRelic))
        XCTAssertTrue(ids.contains(.dragonSlain))

        // Bonus caps should not exceed global limits even if many rewards apply.
        XCTAssertLessThanOrEqual(state.bonusGoldPercent, AchievementCaps.maxBonusGoldPercent)
        XCTAssertLessThanOrEqual(state.bonusStartingHpPercent, AchievementCaps.maxBonusStartingHpPercent)
        XCTAssertEqual(AchievementID.allCases.count, AchievementEvaluator.shared.catalog.count)
    }

    func testSecretWitnessFlagsUnlockViaBackfill() {
        var witness = AchievementWitnessFlags()
        witness.idleCapHit = true
        witness.firstCritLanded = true

        let ctx = AchievementContext(
            lifetime: .empty,
            best: .empty,
            totalShards: 0,
            treeLevels: [:],
            discoveredRelics: [],
            mercenaryCounts: [:],
            equippedRelicCount: 0,
            clearedFinalBoss: false,
            firstDeathBeatShown: false,
            onboardingCompleted: true,
            runStats: .empty,
            witness: witness,
            masteredSigilCount: 1,
            weakSigilWitnessed: false
        )

        let (_, unlocked) = AchievementEvaluator.shared.backfill(context: ctx, from: .empty)
        let ids = Set(unlocked)
        XCTAssertTrue(ids.contains(.idleCap))
        XCTAssertTrue(ids.contains(.firstCrit))
        XCTAssertFalse(ids.contains(.surviveOneshot))
    }

    func testTreeAndRelicProgressAchievements() {
        var tree: [SkillNode: Int] = [.might: 5, .ward: 10]
        tree[.fortune] = 25

        let ctx = AchievementContext(
            lifetime: .empty,
            best: BestRun(layer: 6, level: 1, gold: 0),
            totalShards: 0,
            treeLevels: tree,
            discoveredRelics: Set(Relic.allCases.map(\.rawValue)),
            mercenaryCounts: [.knight: 1],
            equippedRelicCount: 3,
            clearedFinalBoss: false,
            firstDeathBeatShown: false,
            onboardingCompleted: true,
            runStats: .empty,
            witness: AchievementWitnessFlags(),
            masteredSigilCount: 1,
            weakSigilWitnessed: false
        )

        let (_, unlocked) = AchievementEvaluator.shared.backfill(context: ctx, from: .empty)
        let ids = Set(unlocked)
        XCTAssertTrue(ids.contains(.might5))
        XCTAssertTrue(ids.contains(.ward10))
        XCTAssertTrue(ids.contains(.treeMaxOne))
        XCTAssertTrue(ids.contains(.newBestLayer))
        XCTAssertTrue(ids.contains(.fullGallery))
        XCTAssertTrue(ids.contains(.equipThree))
        XCTAssertTrue(ids.contains(.knightOwner))
    }

    func testIdempotentUnlocksDoNotDoubleCountBonuses() {
        var lifetime = LifetimeStats.empty
        lifetime.deepestLayer = 30
        lifetime.totalGoldEarned = 200_000
        lifetime.totalDescents = 20

        let ctx = AchievementContext(
            lifetime: lifetime,
            best: .empty,
            totalShards: 80,
            treeLevels: [:],
            discoveredRelics: [],
            mercenaryCounts: [:],
            equippedRelicCount: 0,
            clearedFinalBoss: true,
            firstDeathBeatShown: true,
            onboardingCompleted: true,
            runStats: .empty,
            witness: AchievementWitnessFlags(),
            masteredSigilCount: 1,
            weakSigilWitnessed: false
        )

        let evaluator = AchievementEvaluator.shared
        let first = evaluator.backfill(context: ctx, from: .empty)
        let second = evaluator.backfill(context: ctx, from: first.state)

        XCTAssertEqual(first.state.bonusGoldPercent, second.state.bonusGoldPercent)
        XCTAssertEqual(first.state.bonusStartingHpPercent, second.state.bonusStartingHpPercent)
        XCTAssertEqual(Set(first.unlocked), Set(second.unlocked).union(first.unlocked))
    }

    func testSigilAchievementsUnlockOnEventAndBackfill() {
        let base = AchievementContext(
            lifetime: .empty,
            best: .empty,
            totalShards: 0,
            treeLevels: [:],
            discoveredRelics: [],
            mercenaryCounts: [:],
            equippedRelicCount: 0,
            clearedFinalBoss: false,
            firstDeathBeatShown: false,
            onboardingCompleted: true,
            runStats: .empty,
            witness: AchievementWitnessFlags(),
            masteredSigilCount: 1,
            weakSigilWitnessed: false
        )

        let weakResult = AchievementEvaluator.shared.evaluate(
            event: .sigilWeakHit,
            context: base,
            from: .empty
        )
        XCTAssertTrue(weakResult.unlocked.contains(.weakSigil))

        let scholarCtx = AchievementContext(
            lifetime: base.lifetime,
            best: base.best,
            totalShards: base.totalShards,
            treeLevels: base.treeLevels,
            discoveredRelics: base.discoveredRelics,
            mercenaryCounts: base.mercenaryCounts,
            equippedRelicCount: base.equippedRelicCount,
            clearedFinalBoss: base.clearedFinalBoss,
            firstDeathBeatShown: base.firstDeathBeatShown,
            onboardingCompleted: base.onboardingCompleted,
            runStats: base.runStats,
            witness: base.witness,
            masteredSigilCount: 2,
            weakSigilWitnessed: true
        )
        let (_, backfilled) = AchievementEvaluator.shared.backfill(context: scholarCtx, from: weakResult.state)
        XCTAssertTrue(backfilled.contains(.sigilScholar))
    }
}

