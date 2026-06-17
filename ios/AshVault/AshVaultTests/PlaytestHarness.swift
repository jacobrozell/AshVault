import Foundation
@testable import AshVault

/// Codified playtest targets from `ios/docs/progressive-unlock-spec.md` §14 and
/// `ios/docs/game-design-spec.md` §1 (north star). These are **proxy metrics** —
/// they catch pacing regressions, not whether a human finds the game fun.
enum SatisfactionBenchmarks {
    /// Session 1: one full Layer 1 ring at 1 Hz auto-battle (~2 min cap).
    static let maxLayer1Ticks = 120
    /// First campaign clear should feel materially rewarded.
    static let minFirstCampaignGold = 2_000
    static let minFirstCampaignShards = 4
    /// Seed sweep: at least this fraction of seeds clear on full auto (10-ring campaign).
    static let minCampaignClearRate = 0.06
    /// After spending prestige, the next campaign should finish faster.
    static let minCampaignSpeedupFromMight = 0.08
    /// Ward investment should push endless depth at least this many layers deeper.
    static let minEndlessDepthGainFromWard = 1
    /// Layer 1 should produce enough kills to feel like progress (all guardians in ring).
    static let layer1KillCount = Balance.enemiesPerLayer
}

/// Headless auto-battle runner for pacing and satisfaction diagnostics.
@MainActor
enum PlaytestHarness {

    struct CampaignResult {
        let seed: UInt64
        let ticks: Int
        let runGold: Int
        let pendingShards: Int
        let layerTicks: [Int: Int]
    }

    struct RunUntilResult {
        let ticks: Int
        let phase: Phase
        let layer: Int
        let runGold: Int
        let pendingShards: Int
    }

    struct DefeatResult {
        let seed: UInt64
        let ticks: Int
        let layer: Int
        let gold: Int
    }

    /// Run until defeat; returns death ring and tick count (for tuning diagnostics).
    static func runUntilDefeat(seed: UInt64, maxTicks: Int = 300_000) -> DefeatResult? {
        clearPersistence()
        PrestigeStore.save(Balance.automationUnlockShards)
        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        e.toggleAuto()
        var ticks = 0
        while ticks < maxTicks {
            if e.phase == .defeat {
                return DefeatResult(seed: seed, ticks: ticks, layer: e.layer, gold: e.runGoldEarned)
            }
            smartTick(e)
            ticks += 1
        }
        return nil
    }

    /// Runs until campaign victory, defeat, or tick budget (`autoBattle` off = manual damage).
    static func runCampaign(
        seed: UInt64,
        maxTicks: Int = 300_000,
        shards: Int = Balance.automationUnlockShards,
        spendMightLevels: Int = 0,
        spendWardLevels: Int = 0,
        manualCombat: Bool = false
    ) -> CampaignResult? {
        clearPersistence()
        PrestigeStore.save(shards)
        if spendMightLevels > 0 || spendWardLevels > 0 {
            seedTree(might: spendMightLevels, ward: spendWardLevels, shards: shards)
        }
        return runCampaignOnEngine(seed: seed, maxTicks: maxTicks, manualCombat: manualCombat)
    }

    /// Auto-battle from fresh save through endless until death.
    static func runEndlessUntilDeath(
        seed: UInt64,
        maxTicks: Int = 100_000,
        shards: Int = Balance.automationUnlockShards,
        wardLevels: Int = 0
    ) -> RunUntilResult? {
        clearPersistence()
        PrestigeStore.save(shards)
        if wardLevels > 0 {
            seedTree(might: 0, ward: wardLevels, shards: shards)
        }

        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        e.toggleAuto()

        var ticks = 0
        while ticks < maxTicks {
            if e.phase == .defeat {
                return RunUntilResult(
                    ticks: ticks,
                    phase: .defeat,
                    layer: e.layer,
                    runGold: e.runGoldEarned,
                    pendingShards: e.pendingShards
                )
            }
            smartTick(e)
            ticks += 1
        }
        return nil
    }

    /// Full loop: clear campaign → ascend → spend shards on might → repeat.
    /// Starts with zero shards (first run uses manual level-up/shop resolution).
    static func runPrestigeLoops(
        seed: UInt64,
        loops: Int,
        maxTicksPerLoop: Int = 300_000
    ) -> (shardHistory: [Int], treeMight: Int, descents: Int)? {
        clearPersistence()

        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        e.toggleAuto()

        var shardHistory: [Int] = [e.totalShards]
        var ticks = 0

        for _ in 0..<loops {
            var loopTicks = 0
            while loopTicks < maxTicksPerLoop {
                if e.phase == .defeat { return nil }
                if e.phase == .victory, e.clearedFinalBoss { break }
                smartTick(e)
                loopTicks += 1
                ticks += 1
            }
            guard e.phase == .victory, e.clearedFinalBoss else { return nil }

            // Ascension only opens from combat, not the victory celebration screen.
            e.continueEndless()
            e.enterAscension()
            e.ascend()
            e.autoBattle = true
            shardHistory.append(e.totalShards)

            while e.canUpgrade(.might) { e.upgradeNode(.might) }
        }

        return (shardHistory, e.level(of: .might), e.lifetime.totalDescents)
    }

    /// Layer 1 only — measures session-1 engagement hook (no pre-granted shards).
    static func runLayer1(
        seed: UInt64,
        maxTicks: Int = 5_000
    ) -> (ticks: Int, kills: Int, gold: Int)? {
        clearPersistence()
        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        e.toggleAuto()

        var ticks = 0
        let killsAtStart = e.lifetime.totalKills

        while ticks < maxTicks {
            if e.layer > 1 || e.phase == .defeat {
                let kills = e.lifetime.totalKills - killsAtStart
                return (ticks, kills, e.runGoldEarned)
            }
            smartTick(e)
            ticks += 1
        }
        return nil
    }

    static func firstClearingSeed(in range: ClosedRange<UInt64> = 1...32) -> UInt64? {
        range.first { runCampaign(seed: $0) != nil }
    }

    /// Seed that clears the campaign from a true fresh save (no pre-granted shards).
    static func firstFreshClearingSeed(in range: ClosedRange<UInt64> = 1...64) -> UInt64? {
        range.first { seed in
            clearPersistence()
            return runCampaignOnEngine(seed: seed, maxTicks: 300_000) != nil
        }
    }

    // MARK: - Internals

    private static func runCampaignOnEngine(
        seed: UInt64,
        maxTicks: Int,
        manualCombat: Bool = false
    ) -> CampaignResult? {
        let e = GameEngine(playerName: "Playtest", rng: SeededRandom(seed: seed))
        e.startGame(named: "Playtest")
        if manualCombat {
            // Manual damage multiplier; still automate drafts/shop for headless pacing.
        } else {
            e.toggleAuto()
        }

        var ticks = 0
        var layerTicks: [Int: Int] = [:]
        var trackedLayer = e.layer
        var ticksAtLayerStart = 0

        while ticks < maxTicks {
            if e.phase == .defeat { return nil }
            if e.phase == .victory, e.clearedFinalBoss {
                layerTicks[trackedLayer, default: 0] += ticks - ticksAtLayerStart
                return CampaignResult(
                    seed: seed,
                    ticks: ticks,
                    runGold: e.runGoldEarned,
                    pendingShards: e.pendingShards,
                    layerTicks: layerTicks
                )
            }

            if e.layer != trackedLayer {
                layerTicks[trackedLayer, default: 0] += ticks - ticksAtLayerStart
                trackedLayer = e.layer
                ticksAtLayerStart = ticks
            }

            smartTick(e, manualCombat: manualCombat)
            ticks += 1
        }
        return nil
    }

    /// Advances one tick, resolving level-up/shop manually when automation is locked.
    private static func smartTick(_ e: GameEngine, manualCombat: Bool = false) {
        switch e.phase {
        case .combat:
            if manualCombat { e.playtestCombatStep() } else { e.tick() }
        case .draft where manualCombat:
            e.playtestChooseDraft()
        case .draft where e.automationUnlocked:
            e.tick()
        case .draft:
            if let pick = e.draftOptions.first { e.chooseDraft(pick) }
        case .ringChoice where e.automationUnlocked && !manualCombat:
            if e.autoShouldCampForHarness() { e.enterCamp() } else { e.pushDeeper() }
        case .ringChoice where manualCombat:
            if manualShouldCamp(e) { e.enterCamp() } else { e.pushDeeper() }
        case .ringIngress where e.automationUnlocked && !manualCombat:
            e.tick()
        case .ringIngress where manualCombat:
            if let door = e.doorOffers.first(where: { $0.kind == .guardPatrol }) ?? e.doorOffers.first {
                e.chooseDoor(door)
            }
        case .ringIngress:
            if let door = e.doorOffers.first { e.chooseDoor(door) }
        case .ringChoice:
            e.pushDeeper()
        case .levelUp where manualCombat:
            e.chooseUpgrade(autoUpgrade(for: e))
        case .levelUp where e.automationUnlocked:
            e.tick()
        case .levelUp:
            e.chooseUpgrade(autoUpgrade(for: e))
        case .shop where manualCombat:
            e.playtestAutoShop()
        case .shop where e.automationUnlocked:
            e.tick()
        case .shop:
            autoShopManual(e)
        case .victory:
            e.continueEndless()
        default:
            break
        }
    }

    /// Manual players camp when hurt or out of potions; camp every other ring for upgrades.
    private static func manualShouldCamp(_ e: GameEngine) -> Bool {
        let hpPct = e.player.hp * 100 / max(1, e.player.maxHp)
        if hpPct < 50 { return true }
        if e.runStats.layersClearedThisRun > 0,
           e.runStats.layersClearedThisRun % 2 == 0 { return true }
        if e.player.potions == 0, e.canAfford(.potion) { return true }
        return false
    }

    private static func autoUpgrade(for e: GameEngine) -> Player.Upgrade {
        switch e.player.level % 3 {
        case 0:  return .health
        case 1:  return .attack
        default: return .defense
        }
    }

    private static func autoShopManual(_ e: GameEngine) {
        for item in [ShopItem.whetstone, .towerShield, .heartVial, .luckyCoin]
        where e.canAfford(item) {
            e.buy(item)
        }
        if e.player.potions < 3, e.canAfford(.potion) { e.buy(.potion) }
        var hired = 0
        while hired < Balance.autoShopMaxMercenariesPerVisit,
              let merc = Mercenary.allCases.first(where: { e.canHire($0) }) {
            e.hireMercenary(merc)
            hired += 1
        }
        var scrolls = 0
        for spell in SpellCatalog.autoShopScrolls {
            guard scrolls < Balance.autoShopMaxSigilScrollsPerVisit,
                  e.canBuySigilScroll(spell) else { continue }
            e.buySigilScroll(spell)
            scrolls += 1
        }
        autoEquipSigils(e)
        e.leaveShop()
    }

    private static func autoEquipSigils(_ e: GameEngine) {
        for spell in SpellCatalog.shopScrolls where e.sigilMastery.mastered.contains(spell) {
            guard !e.sigilLoadout.equipped.contains(spell) else { continue }
            if let vacant = e.sigilLoadout.slots.firstIndex(where: { $0 == nil }) {
                e.equipSigil(spell, slot: vacant)
            }
        }
    }

    private static func seedTree(might: Int, ward: Int, shards: Int) {
        PrestigeStore.save(max(shards, might + ward * 4 + 10))
        var tree: [String: Int] = [:]
        if might > 0 { tree[SkillNode.might.rawValue] = might }
        if ward > 0 { tree[SkillNode.ward.rawValue] = ward }
        PrestigeStore.saveTree(tree)
    }
}
