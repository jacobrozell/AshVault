import Foundation

// MARK: - Run-scoped stats (reset each run)

struct RunStats: Equatable {
    var healsUsed: Int = 0
    var phoenixAshUsed: Bool = false
    var layersClearedThisRun: Int = 0
    var enemiesSlain: Int = 0
    var killsSinceDraft: Int = 0
    var bossKillsThisRun: Int = 0
    var damageTaken: Int = 0
    var manualMoves: Int = 0

    static let empty = RunStats()
}

// MARK: - IDs, categories, rewards

enum AchievementID: String, CaseIterable, Codable {
    // The Crawl
    case firstBlood
    case firstFall
    case tenDeaths
    case layer3Reach
    case dragonSlain
    case deep10
    case deep25
    case deep50
    case newBestLayer
    case phoenixRise
    case noPhoenixClear

    // The Shrine
    case firstWithdrawal
    case tenWithdrawals
    case shardHoarder
    case might5
    case ward10
    case treeMaxOne

    // The Camp
    case gold1k
    case gold100k
    case gold1m
    case hireFirstMerc
    case milestone25
    case fullRoster
    case knightOwner
    case phoenixBuyer

    // The Gallery
    case firstRelic
    case fullGallery
    case boss10
    case boss100
    case equipThree

    // Secrets
    case idleCap
    case autoWithdraw
    case firstCrit
    case surviveOneshot
    case weakSigil
    case sigilScholar
}

enum AchievementCategory: String, Codable, CaseIterable {
    case crawl
    case shrine
    case camp
    case gallery
    case secrets

    static let displayOrder: [AchievementCategory] = [.crawl, .shrine, .camp, .gallery, .secrets]

    var title: String { Narrative.Achievement.categoryTitle(self) }
}

enum AchievementReward: Codable, Equatable {
    case accountGoldPercent(Int)
    case accountStartingHpPercent(Int)
    case cosmeticTitle(String)
    case none

    var badgeLabel: String? {
        switch self {
        case .accountGoldPercent(let n): return "+\(n)% gold"
        case .accountStartingHpPercent(let n): return "+\(n)% starting HP"
        case .cosmeticTitle(let title): return title
        case .none: return nil
        }
    }
}

enum AchievementCaps {
    static let maxBonusGoldPercent = 5
    static let maxBonusStartingHpPercent = 5
}

struct AchievementDefinition: Identifiable {
    var id: AchievementID { achievementID }
    let achievementID: AchievementID
    let category: AchievementCategory
    let name: String
    let description: String
    let lore: String
    let icon: String
    let secret: Bool
    let reward: AchievementReward
    let progress: (AchievementContext) -> (current: Int, target: Int)?
    let isMet: (AchievementEvent, AchievementContext) -> Bool
}

/// One-shot witness flags for secret trophies (persisted).
struct AchievementWitnessFlags: Codable, Equatable {
    var idleCapHit: Bool = false
    var autoWithdrawUsed: Bool = false
    var firstCritLanded: Bool = false
    var survivedBigHit: Bool = false
    var weakSigilLanded: Bool = false
}

// MARK: - Persisted state

struct AchievementState: Codable, Equatable {
    var unlocked: Set<String>
    var unlockedAt: [String: Date]
    var bonusGoldPercent: Int
    var bonusStartingHpPercent: Int
    var lastSeenUnlockedCount: Int
    var backfillSummaryDismissed: Bool
    var witness: AchievementWitnessFlags

    static let empty = AchievementState(
        unlocked: [],
        unlockedAt: [:],
        bonusGoldPercent: 0,
        bonusStartingHpPercent: 0,
        lastSeenUnlockedCount: 0,
        backfillSummaryDismissed: false,
        witness: AchievementWitnessFlags()
    )

    var hasUnread: Bool { unlocked.count > lastSeenUnlockedCount }

    mutating func unlock(_ id: AchievementID, reward: AchievementReward, date: Date = Date()) {
        let key = id.rawValue
        guard !unlocked.contains(key) else { return }
        unlocked.insert(key)
        unlockedAt[key] = date

        switch reward {
        case .accountGoldPercent(let delta):
            bonusGoldPercent = min(bonusGoldPercent + delta, AchievementCaps.maxBonusGoldPercent)
        case .accountStartingHpPercent(let delta):
            bonusStartingHpPercent = min(bonusStartingHpPercent + delta, AchievementCaps.maxBonusStartingHpPercent)
        case .cosmeticTitle, .none:
            break
        }
    }

    func contains(_ id: AchievementID) -> Bool {
        unlocked.contains(id.rawValue)
    }

    mutating func markViewed() {
        lastSeenUnlockedCount = unlocked.count
    }

    mutating func dismissBackfillSummary() {
        backfillSummaryDismissed = true
    }

    private enum CodingKeys: String, CodingKey {
        case unlocked, unlockedAt, bonusGoldPercent, bonusStartingHpPercent
        case lastSeenUnlockedCount, backfillSummaryDismissed, witness
    }

    init(unlocked: Set<String>,
         unlockedAt: [String: Date],
         bonusGoldPercent: Int,
         bonusStartingHpPercent: Int,
         lastSeenUnlockedCount: Int,
         backfillSummaryDismissed: Bool,
         witness: AchievementWitnessFlags) {
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
        self.bonusGoldPercent = bonusGoldPercent
        self.bonusStartingHpPercent = bonusStartingHpPercent
        self.lastSeenUnlockedCount = lastSeenUnlockedCount
        self.backfillSummaryDismissed = backfillSummaryDismissed
        self.witness = witness
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        unlocked = try c.decodeIfPresent(Set<String>.self, forKey: .unlocked) ?? []
        unlockedAt = try c.decodeIfPresent([String: Date].self, forKey: .unlockedAt) ?? [:]
        bonusGoldPercent = try c.decodeIfPresent(Int.self, forKey: .bonusGoldPercent) ?? 0
        bonusStartingHpPercent = try c.decodeIfPresent(Int.self, forKey: .bonusStartingHpPercent) ?? 0
        lastSeenUnlockedCount = try c.decodeIfPresent(Int.self, forKey: .lastSeenUnlockedCount) ?? 0
        backfillSummaryDismissed = try c.decodeIfPresent(Bool.self, forKey: .backfillSummaryDismissed) ?? false
        witness = try c.decodeIfPresent(AchievementWitnessFlags.self, forKey: .witness) ?? AchievementWitnessFlags()
    }
}

// MARK: - Evaluator context & events

struct AchievementContext {
    let lifetime: LifetimeStats
    let best: BestRun
    let totalShards: Int
    let treeLevels: [SkillNode: Int]
    let discoveredRelics: Set<String>
    let mercenaryCounts: [Mercenary: Int]
    let equippedRelicCount: Int
    let clearedFinalBoss: Bool
    let firstDeathBeatShown: Bool
    let onboardingCompleted: Bool
    let runStats: RunStats
    let witness: AchievementWitnessFlags
    let masteredSigilCount: Int
    let weakSigilWitnessed: Bool
}

enum AchievementEvent {
    case runStarted
    case enemyKilled(wasBoss: Bool)
    case playerDied
    case phoenixAshRevived
    case layerCleared(layer: Int)
    case dragonSlain
    case campaignClearedNoPhoenix
    case prestige(shardsGained: Int, totalShards: Int)
    case relicDiscovered
    case mercenaryHired(merc: Mercenary, totalOwned: Int)
    case offlineGold(hitCap: Bool)
    case shopPurchase(ShopItem)
    case runEnded(reason: String)
    case treeUpgraded
    case relicEquipped(count: Int)
    case critLanded
    case survivedBigHit
    case autoAscended
    case backfill
    case sigilWeakHit
    case sigilMasteryUpdated(count: Int)
}

// MARK: - Catalog helpers

private func achievementProgressValue(_ current: Int, target: Int) -> (Int, Int) {
    (min(max(0, current), target), target)
}

private func treeLevel(_ node: SkillNode, in ctx: AchievementContext) -> Int {
    ctx.treeLevels[node, default: 0]
}

private func maxMercCount(_ ctx: AchievementContext) -> Int {
    ctx.mercenaryCounts.values.max() ?? 0
}

private func fullMercRoster(_ ctx: AchievementContext) -> Bool {
    Mercenary.allCases.allSatisfy { ctx.mercenaryCounts[$0, default: 0] >= 1 }
}

// MARK: - Evaluator

final class AchievementEvaluator {
    static let shared = AchievementEvaluator()

    private init() {}

    let catalog: [AchievementDefinition] = {
        func def(
            _ id: AchievementID,
            _ category: AchievementCategory,
            secret: Bool = false,
            reward: AchievementReward = .none,
            progress: @escaping (AchievementContext) -> (current: Int, target: Int)? = { _ in nil },
            meets: @escaping (AchievementEvent, AchievementContext) -> Bool
        ) -> AchievementDefinition {
            AchievementDefinition(
                achievementID: id,
                category: category,
                name: Narrative.Achievement.name(for: id),
                description: Narrative.Achievement.description(for: id),
                lore: Narrative.Achievement.lore(for: id),
                icon: Narrative.Achievement.icon(for: id),
                secret: secret,
                reward: reward,
                progress: progress,
                isMet: meets
            )
        }

        return [
            // The Crawl
            def(.firstBlood, .crawl,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalKills, target: 1) }
            ) { _, ctx in ctx.lifetime.totalKills >= 1 },

            def(.firstFall, .crawl,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalDeaths, target: 1) }
            ) { _, ctx in ctx.firstDeathBeatShown || ctx.lifetime.totalDeaths >= 1 },

            def(.tenDeaths, .crawl,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalDeaths, target: 10) }
            ) { _, ctx in ctx.lifetime.totalDeaths >= 10 },

            def(.layer3Reach, .crawl,
                progress: { ctx in achievementProgressValue(ctx.lifetime.deepestLayer, target: 3) }
            ) { _, ctx in ctx.lifetime.deepestLayer >= 3 },

            def(.dragonSlain, .crawl,
                reward: .accountGoldPercent(1),
                progress: { ctx in ctx.clearedFinalBoss ? (1, 1) : (0, 1) }
            ) { _, ctx in ctx.clearedFinalBoss },

            def(.deep10, .crawl,
                progress: { ctx in achievementProgressValue(ctx.lifetime.deepestLayer, target: 10) }
            ) { _, ctx in ctx.lifetime.deepestLayer >= 10 },

            def(.deep25, .crawl,
                reward: .accountGoldPercent(1),
                progress: { ctx in achievementProgressValue(ctx.lifetime.deepestLayer, target: 25) }
            ) { _, ctx in ctx.lifetime.deepestLayer >= 25 },

            def(.deep50, .crawl,
                reward: .accountStartingHpPercent(1),
                progress: { ctx in achievementProgressValue(ctx.lifetime.deepestLayer, target: 50) }
            ) { _, ctx in ctx.lifetime.deepestLayer >= 50 },

            def(.newBestLayer, .crawl,
                progress: { ctx in achievementProgressValue(min(ctx.best.layer, 6), target: 6) }
            ) { _, ctx in ctx.best.layer >= 6 },

            def(.phoenixRise, .crawl,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalRevives, target: 1) }
            ) { _, ctx in ctx.lifetime.totalRevives >= 1 },

            def(.noPhoenixClear, .crawl,
                reward: .accountGoldPercent(1),
                progress: { ctx in (ctx.runStats.phoenixAshUsed ? 0 : 1, 1) }
            ) { event, ctx in
                if case .campaignClearedNoPhoenix = event { return true }
                return ctx.clearedFinalBoss && !ctx.runStats.phoenixAshUsed
            },

            def(.weakSigil, .crawl,
                progress: { ctx in achievementProgressValue(ctx.weakSigilWitnessed ? 1 : 0, target: 1) }
            ) { event, ctx in
                if case .sigilWeakHit = event { return true }
                return ctx.weakSigilWitnessed
            },

            def(.sigilScholar, .crawl,
                progress: { ctx in achievementProgressValue(ctx.masteredSigilCount, target: 2) }
            ) { event, ctx in
                if case .sigilMasteryUpdated(let count) = event { return count >= 2 }
                return ctx.masteredSigilCount >= 2
            },

            // The Shrine
            def(.firstWithdrawal, .shrine,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalDescents, target: 1) }
            ) { _, ctx in ctx.lifetime.totalDescents >= 1 },

            def(.tenWithdrawals, .shrine,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalDescents, target: 10) }
            ) { _, ctx in ctx.lifetime.totalDescents >= 10 },

            def(.shardHoarder, .shrine,
                progress: { ctx in achievementProgressValue(ctx.totalShards, target: 50) }
            ) { _, ctx in ctx.totalShards >= 50 },

            def(.might5, .shrine,
                progress: { ctx in achievementProgressValue(treeLevel(.might, in: ctx), target: 5) }
            ) { _, ctx in treeLevel(.might, in: ctx) >= 5 },

            def(.ward10, .shrine,
                reward: .accountStartingHpPercent(1),
                progress: { ctx in achievementProgressValue(treeLevel(.ward, in: ctx), target: 10) }
            ) { _, ctx in treeLevel(.ward, in: ctx) >= 10 },

            def(.treeMaxOne, .shrine,
                reward: .accountGoldPercent(1),
                progress: { ctx in
                    let maxLvl = SkillNode.allCases.map { treeLevel($0, in: ctx) }.max() ?? 0
                    return achievementProgressValue(maxLvl, target: 25)
                }
            ) { _, ctx in
                SkillNode.allCases.contains { treeLevel($0, in: ctx) >= 25 }
            },

            // The Camp
            def(.gold1k, .camp,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalGoldEarned, target: 1_000) }
            ) { _, ctx in ctx.lifetime.totalGoldEarned >= 1_000 },

            def(.gold100k, .camp,
                reward: .accountGoldPercent(1),
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalGoldEarned, target: 100_000) }
            ) { _, ctx in ctx.lifetime.totalGoldEarned >= 100_000 },

            def(.gold1m, .camp,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalGoldEarned, target: 1_000_000) }
            ) { _, ctx in ctx.lifetime.totalGoldEarned >= 1_000_000 },

            def(.hireFirstMerc, .camp,
                progress: { ctx in
                    let owned = ctx.mercenaryCounts.values.reduce(0, +)
                    return achievementProgressValue(owned, target: 1)
                }
            ) { _, ctx in ctx.mercenaryCounts.values.reduce(0, +) >= 1 },

            def(.milestone25, .camp,
                progress: { ctx in achievementProgressValue(maxMercCount(ctx), target: 25) }
            ) { _, ctx in maxMercCount(ctx) >= 25 },

            def(.fullRoster, .camp,
                progress: { ctx in
                    let tiers = Mercenary.allCases.filter { ctx.mercenaryCounts[$0, default: 0] >= 1 }.count
                    return achievementProgressValue(tiers, target: Mercenary.allCases.count)
                }
            ) { _, ctx in fullMercRoster(ctx) },

            def(.knightOwner, .camp,
                progress: { ctx in achievementProgressValue(ctx.mercenaryCounts[.knight, default: 0], target: 1) }
            ) { _, ctx in ctx.mercenaryCounts[.knight, default: 0] >= 1 },

            def(.phoenixBuyer, .camp,
                progress: { ctx in achievementProgressValue(ctx.lifetime.phoenixAshesBought, target: 1) }
            ) { _, ctx in ctx.lifetime.phoenixAshesBought >= 1 },

            // The Gallery
            def(.firstRelic, .gallery,
                progress: { ctx in
                    let found = max(ctx.lifetime.relicsFound, ctx.discoveredRelics.count)
                    return achievementProgressValue(found, target: 1)
                }
            ) { _, ctx in ctx.lifetime.relicsFound >= 1 || !ctx.discoveredRelics.isEmpty },

            def(.fullGallery, .gallery,
                reward: .accountStartingHpPercent(1),
                progress: { ctx in achievementProgressValue(ctx.discoveredRelics.count, target: Relic.allCases.count) }
            ) { _, ctx in ctx.discoveredRelics.count >= Relic.allCases.count },

            def(.boss10, .gallery,
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalBossKills, target: 10) }
            ) { _, ctx in ctx.lifetime.totalBossKills >= 10 },

            def(.boss100, .gallery,
                reward: .accountGoldPercent(1),
                progress: { ctx in achievementProgressValue(ctx.lifetime.totalBossKills, target: 100) }
            ) { _, ctx in ctx.lifetime.totalBossKills >= 100 },

            def(.equipThree, .gallery,
                progress: { ctx in achievementProgressValue(ctx.equippedRelicCount, target: 3) }
            ) { event, ctx in
                if case .relicEquipped(let n) = event { return n >= 3 }
                return ctx.equippedRelicCount >= 3
            },

            // Secrets
            def(.idleCap, .secrets, secret: true
            ) { _, ctx in ctx.witness.idleCapHit },

            def(.autoWithdraw, .secrets, secret: true
            ) { _, ctx in ctx.witness.autoWithdrawUsed },

            def(.firstCrit, .secrets, secret: true
            ) { _, ctx in ctx.witness.firstCritLanded },

            def(.surviveOneshot, .secrets, secret: true
            ) { _, ctx in ctx.witness.survivedBigHit },
        ]
    }()

    func definition(for id: AchievementID) -> AchievementDefinition? {
        catalog.first { $0.achievementID == id }
    }

    func progress(for id: AchievementID, in context: AchievementContext) -> (current: Int, target: Int)? {
        definition(for: id)?.progress(context)
    }

    func evaluate(
        event: AchievementEvent,
        context: AchievementContext,
        from state: AchievementState,
        now: Date = Date()
    ) -> (state: AchievementState, unlocked: [AchievementID]) {
        var updated = state
        var newlyUnlocked: [AchievementID] = []

        for def in catalog {
            if updated.contains(def.achievementID) { continue }
            guard def.isMet(event, context) else { continue }
            updated.unlock(def.achievementID, reward: def.reward, date: now)
            newlyUnlocked.append(def.achievementID)
        }

        return (updated, newlyUnlocked)
    }

    func backfill(
        context: AchievementContext,
        from state: AchievementState,
        now: Date = Date()
    ) -> (state: AchievementState, unlocked: [AchievementID]) {
        evaluate(event: .backfill, context: context, from: state, now: now)
    }
}
