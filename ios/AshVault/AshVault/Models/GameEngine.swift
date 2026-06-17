import Foundation
import SwiftUI

/// The four combat actions. Attack / Dodge / Heal are the original Java moves;
/// Heavy Strike is new to the iOS clone. Offensive sigils (Ember, Frost, Venom, …)
/// are separate — see `SpellID`.
enum Move: String, CaseIterable, Identifiable {
    case attack      = "Attack"
    case heavy       = "Heavy Strike"
    case dodge       = "Dodge"
    case heal        = "Heal"

    var id: String { rawValue }

    /// Player-facing label (may differ from `rawValue` for clarity).
    var displayName: String {
        switch self {
        case .heal: return "Second Wind"
        default:    return rawValue
        }
    }

    /// Short hint under the move name in combat.
    var subtitle: String {
        switch self {
        case .attack: return "Reliable strike"
        case .heavy:  return "Big hit · may stun"
        case .dodge:  return "Evade · +HP & mana"
        case .heal:   return "Big heal · enemy hits back"
        }
    }

    var sfSymbol: String {
        // SF Symbols that are guaranteed to exist across iOS versions.
        switch self {
        case .attack: return "burst.fill"
        case .heavy:  return "hammer.fill"
        case .dodge:  return "figure.run"
        case .heal:   return "cross.case.fill"
        }
    }

    var manaCost: Int {
        switch self {
        case .heavy:  return Balance.heavyManaCost
        default:      return 0
        }
    }
}

/// A single line in the scrolling combat log, with a flavour for colouring.
struct LogLine: Identifiable {
    enum Kind { case info, playerHit, enemyHit, miss, reward, system, danger }
    let id = UUID()
    let text: String
    let kind: Kind
    /// Extra top padding — used before layer transitions and section breaks.
    var spacedAbove: Bool = false
}

/// A transient number/word that floats up over a combatant (e.g. "−42", "CRIT!",
/// "Miss", "+30"). The view layer watches `GameEngine.popup` and animates it.
struct CombatPopup: Identifiable, Equatable {
    enum Flavor { case damage, crit, weak, heal, miss }
    let id = UUID()
    let text: String
    let flavor: Flavor
    let onPlayer: Bool   // shown over the player panel vs. the enemy sprite
}

/// Best run achieved so far, persisted across launches via `UserDefaults`.
struct BestRun: Equatable {
    var layer: Int
    var level: Int
    var gold: Int

    static let empty = BestRun(layer: 1, level: 1, gold: 0)
    var hasRecord: Bool { layer > 1 || level > 1 || gold > 0 }

    private enum Key {
        static let layer = "best.layer"
        static let level = "best.level"
        static let gold = "best.gold"
    }

    static func load() -> BestRun {
        let d = UserDefaults.standard
        return BestRun(layer: max(1, d.integer(forKey: Key.layer)),
                       level: max(1, d.integer(forKey: Key.level)),
                       gold: d.integer(forKey: Key.gold))
    }

    func save() {
        let d = UserDefaults.standard
        d.set(layer, forKey: Key.layer)
        d.set(level, forKey: Key.level)
        d.set(gold, forKey: Key.gold)
    }
}

/// High-level phases that drive which screen is shown.
enum Phase: Equatable {
    case title
    case combat
    case draft        // kill-bar full — pick 1 of 3 run upgrades
    case ringChoice   // warden slain — push deeper or camp
    case ringIngress  // new ring — modifier banner + door fork
    case levelUp      // legacy save restore only
    case shop         // camp — spend gold between rings
    case ascension    // prestige / withdraw to the Shrine
    case defeat
    case victory      // Vault Heart felled — celebrate once
}

/// Observable port of `GameDriver`'s main loop.
@MainActor
final class GameEngine: ObservableObject {
    @Published private(set) var player: Player
    @Published private(set) var enemy: Enemy
    @Published private(set) var phase: Phase = .title
    @Published private(set) var log: [LogLine] = []

    @Published private(set) var layer = 1
    @Published private(set) var enemyIndex = 0      // 1...enemiesPerLayer within a layer ("num")
    @Published private(set) var clearedFinalBoss = false
    @Published private(set) var draftOptions: [DraftOption] = []
    @Published private(set) var awaitingRingAdvance = false
    @Published private(set) var supplies = Balance.startingSupplies
    @Published private(set) var currentRingModifier: RingModifier?
    @Published private(set) var doorOffers: [DoorOffer] = []
    private var nextSpawnIsElite = false
    private var currentEncounterElite = false

    /// Lightweight animation hooks for the view layer.
    @Published var playerFlash = false
    @Published var enemyFlash = false
    @Published var shakeTrigger = 0
    @Published var spawnCounter = 0      // bumps whenever a new enemy appears
    @Published var popup: CombatPopup?   // latest floating combat number/word

    /// Best run so far, and whether the last finished run set a new record.
    @Published private(set) var best: BestRun
    @Published private(set) var setNewRecord = false

    /// Set when offline auto-battle earned gold; the view shows a summary sheet.
    @Published var offlineReport: OfflineReport?

    /// When the app was last backgrounded (for warm-resume offline accrual).
    private var backgroundedAt: Date?

    /// Prestige: Ash Shards (`totalShards`) persist across runs and are
    /// *spent* in the skill tree (`treeLevels`). `runGoldEarned` feeds the shard
    /// payout on descent.
    @Published private(set) var totalShards: Int
    @Published private(set) var treeLevels: [SkillNode: Int]
    @Published private(set) var runGoldEarned = 0

    /// Gold no longer converts to Ash Shards in survivor crawl (run gold = crawl power).
    var goldShards: Int { 0 }

    /// Depth-based shard payout: ring depth + wardens slain + Vault Heart bonus.
    var crawlDepthBonus: Int {
        var shards = layer / 2 * Balance.shardsPerTwoRings
        shards += runStats.bossKillsThisRun * Balance.shardsPerBossKill
        if clearedFinalBoss { shards += Balance.vaultHeartShardBonus }
        return shards
    }

    /// Shards awarded for withdrawing now (depth-based; gold ignored).
    var pendingShards: Int { crawlDepthBonus }

    /// Kills needed before the next draft pick on the current ring.
    var draftKillsNeeded: Int {
        RingCrawl.draftKillsNeeded(
            base: RunDraft.killsNeeded(forRing: layer),
            modifier: currentRingModifier
        )
    }

    var suppliesStarved: Bool { supplies <= 0 }

    var campSupplyCost: Int { Balance.supplyCostCamp }

    /// Progress toward the next draft (0…1).
    var draftKillProgress: Double {
        guard draftKillsNeeded > 0 else { return 0 }
        return min(1, Double(runStats.killsSinceDraft) / Double(draftKillsNeeded))
    }

    /// Shards the Shrine salvages when a crawl ends in death.
    var deathSalvagedShards: Int {
        Int((Double(pendingShards) * Balance.deathShardRetention).rounded(.down))
    }

    /// Last death payout (for results UI); cleared on `startGame`.
    @Published private(set) var lastDeathSalvagedShards = 0

    /// Shards already committed to the tree, and what's left to spend.
    var spentShards: Int {
        SkillNode.allCases.reduce(0) { total, node in
            let level = treeLevels[node, default: 0]
            return total + (0..<level).reduce(0) { $0 + node.cost(currentLevel: $1) }
        }
    }
    var availableShards: Int { max(0, totalShards - spentShards) }

    // Skill-tree effects (all default to neutral at level 0).
    private func level(_ node: SkillNode) -> Int { treeLevels[node, default: 0] }
    var attackMultiplier: Double { 1 + Balance.mightAttackPerLevel * Double(level(.might)) }
    var goldMultiplier: Double {
        let treeMult = 1 + Balance.fortuneGoldPerLevel * Double(level(.fortune))
        let achievementMult = 1 + Double(achievementState.bonusGoldPercent) / 100.0
        return treeMult * achievementMult
    }
    var hpMultiplier: Double {
        let treeMult = 1 + Balance.vitalityHpPerLevel * Double(level(.vitality))
        let achievementMult = 1 + Double(achievementState.bonusStartingHpPercent) / 100.0
        return treeMult * achievementMult
    }
    /// Ward: flat fraction of incoming direct damage prevented (capped).
    var damageReduction: Double {
        min(Balance.maxDamageReduction, Balance.wardReductionPerLevel * Double(level(.ward)))
    }

    /// Apply Ward to an incoming direct hit (floored at 0).
    private func mitigated(_ base: Int) -> Int {
        max(0, Int((Double(max(0, base)) * (1 - damageReduction)).rounded()))
    }

    /// Ward + campaign hit cap (layers 1–5 only).
    private func damageToPlayer(_ raw: Int) -> Int {
        let dmg = mitigated(raw)
        guard layer <= Balance.campaignDragonLayer else { return dmg }
        let cap = max(1, player.maxHp * Balance.maxCampaignHitPercent / 100)
        return min(dmg, cap)
    }
    var offlineCap: TimeInterval {
        (Balance.baseOfflineHours + Double(Balance.patienceHoursPerLevel * level(.patience))) * 3600
    }
    var offlineEfficiency: Double {
        min(Balance.maxOfflineEfficiency,
            Balance.baseOfflineEfficiency + Balance.patienceEfficiencyPerLevel * Double(level(.patience)))
    }

    /// How many of each permanent upgrade have been bought (drives price scaling).
    @Published private(set) var purchaseCounts: [ShopItem: Int] = [:]

    /// Meta generators — persist across runs (see `MercenaryCampView`).
    @Published private(set) var mercenaryCounts: [Mercenary: Int] = [:]
    @Published private(set) var discoveredRelics: Set<String> = []
    @Published private(set) var equippedRelics: [String] = []
    @Published private(set) var lifetime = LifetimeStats.empty
    @Published private(set) var achievementState = AchievementState.empty
    @Published private(set) var runStats = RunStats.empty

    /// Next trophy toast to show (queued in-run unlocks).
    @Published var pendingAchievementUnlock: AchievementID?
    /// One-time veteran summary after backfill; cleared on dismiss.
    @Published var achievementBackfillCount: Int?

    private var achievementUnlockQueue: [AchievementID] = []

    /// Latest relic find, surfaced as a sheet from combat.
    @Published var newRelicFound: Relic?

    /// Hybrid idle: when on, a periodic `tick()` auto-plays combat. The player
    /// still steps in for level-up / shop / ascension choices (tick pauses
    /// outside `.combat`).
    @Published var autoBattle = false

    private var scaleLevel = 0                       // cumulative enemy strengthening
    private var victoryShown = false                 // celebrate the dragon only once

    @Published private(set) var sigilMastery = SigilMastery.starter
    @Published var sigilLoadout = SigilLoadout()

    /// Injectable randomness — `SystemRandom` in the app, `SeededRandom`/stub in tests.
    private let rng: RandomSource
    private let castResolver: SpellCastResolver

    init(playerName: String = "Crawler", rng: RandomSource = SystemRandom(),
         castResolver: SpellCastResolver = InstantSpellCastResolver()) {
        self.rng = rng
        self.castResolver = castResolver
        let p = Player(name: playerName)
        self.player = p
        self.enemy = Enemy(kind: Bestiary.fodder[0], scaleLevel: 0,
                           isBoss: false, isFinalBoss: false, postGameDepth: 0)
        self.best = BestRun.load()
        self.totalShards = PrestigeStore.load()
        var levels: [SkillNode: Int] = [:]
        for (raw, n) in PrestigeStore.loadTree() {
            if let node = SkillNode(rawValue: raw) { levels[node] = n }
        }
        self.treeLevels = levels
        loadMeta()
        loadIfAvailable()
    }

    private func loadMeta() {
        var counts: [Mercenary: Int] = [:]
        for (raw, n) in MetaStore.loadMercenaryCounts() {
            if let m = Mercenary(rawValue: raw) { counts[m] = n }
        }
        mercenaryCounts = counts
        discoveredRelics = MetaStore.loadDiscoveredRelics()
        equippedRelics = MetaStore.loadEquippedRelics()
        lifetime = MetaStore.loadLifetime()
        achievementState = MetaStore.loadAchievements()
        sigilMastery = MetaStore.loadSigilMastery()
        sigilLoadout = sigilMastery.defaultLoadout()

        // Backfill achievements for existing players from current meta.
        let ctx = achievementContext()
        let result = AchievementEvaluator.shared.backfill(context: ctx, from: achievementState)
        achievementState = result.state
        MetaStore.saveAchievements(achievementState)

        if !achievementState.backfillSummaryDismissed && !achievementState.unlocked.isEmpty {
            achievementBackfillCount = achievementState.unlocked.count
        }
    }

    private func persistMercenaries() {
        var raw: [String: Int] = [:]
        for (m, n) in mercenaryCounts { raw[m.rawValue] = n }
        MetaStore.saveMercenaryCounts(raw)
    }

    // MARK: - Meta combat bonuses

    /// Flat DPS from hired mercenaries (offline income only in Phase 1).
    var mercenaryDPS: Int {
        let raw = Mercenary.allCases.reduce(0) { $0 + $1.dps(count: mercenaryCounts[$1, default: 0]) }
        return Int(Double(raw) * Balance.mercenaryCombatDpsFactor)
    }

    /// Hero attack for damage formulas (mercs demoted from combat DPS).
    var combatAttack: Int { player.attack + mercenaryDPS }

    /// Manual play hits harder; auto-battle trades damage for hands-off pacing.
    var combatDamageMultiplier: Double {
        autoBattle ? Balance.autoDamageMultiplier : Balance.manualDamageMultiplier
    }

    private func hasEquipped(_ relic: Relic) -> Bool {
        equippedRelics.contains(relic.rawValue)
    }

    private var relicGoldMultiplier: Double {
        hasEquipped(.goldTooth) ? 1 + Balance.relicGoldBonus : 1
    }

    private var relicHpMultiplier: Double {
        hasEquipped(.ironHeart) ? 1 + Balance.relicHpBonus : 1
    }

    private var relicCritBonus: Int {
        hasEquipped(.luckyCharm) ? Balance.relicCritBonus : 0
    }

    private var relicLifestealPercent: Int {
        hasEquipped(.vampiricFang) ? Balance.relicLifestealPercent : 0
    }

    private var relicThornsPercent: Int {
        hasEquipped(.thornMail) ? Balance.relicThornsPercent : 0
    }

    private var relicManaRegenBonus: Int {
        hasEquipped(.manaStone) ? Balance.relicManaRegenBonus : 0
    }

    private func applyLifesteal(for damage: Int) {
        guard relicLifestealPercent > 0, damage > 0, player.isAlive else { return }
        let heal = max(1, damage * relicLifestealPercent / 100)
        player.restoreHp(heal)
    }

    private func applyThorns(for damageTaken: Int) {
        guard relicThornsPercent > 0, damageTaken > 0, enemy.isAlive else { return }
        let reflected = max(1, damageTaken * relicThornsPercent / 100)
        enemy.takeHit(reflected)
        append("🌵 Thorns lash back for \(reflected)!", .playerHit)
    }

    // MARK: - Lifecycle

    /// True while a run is in progress and can be abandoned from Settings.
    var canAbandonRun: Bool {
        switch phase {
        case .combat, .draft, .ringChoice, .ringIngress, .levelUp, .shop, .ascension: return true
        case .title, .defeat, .victory: return false
        }
    }

    /// Bail to the title screen without banking shards. Clears the resumable save.
    func abandonRun() {
        guard canAbandonRun else { return }
        GameAnalytics.track(.runEnded(reason: "abandon", layer: layer, level: player.level))
        SaveStore.clear()
        backgroundedAt = nil
        autoBattle = false
        offlineReport = nil
        popup = nil
        phase = .title
    }

    func startGame(named name: String) {
        SaveStore.clear()
        player = Player(name: name)
        player.applyPrestige(attackMult: attackMultiplier,
                             hpMult: hpMultiplier * relicHpMultiplier)
        runGoldEarned = 0
        runStats = .empty
        lastDeathSalvagedShards = 0
        layer = 1
        enemyIndex = 0
        scaleLevel = 0
        clearedFinalBoss = false
        awaitingRingAdvance = false
        draftOptions = []
        supplies = Balance.startingSupplies
        currentRingModifier = RingCrawl.rollModifier(rng: rng)
        doorOffers = []
        nextSpawnIsElite = false
        currentEncounterElite = false
        victoryShown = false
        setNewRecord = false
        autoBattle = false
        offlineReport = nil
        popup = nil
        purchaseCounts = [:]
        if sigilLoadout.equipped.isEmpty {
            sigilLoadout = sigilMastery.defaultLoadout()
        }
        log = []
        append(Narrative.text(for: .welcome(name: player.name)), .system)
        for i in 0..<Narrative.tutorialLineCount {
            append(Narrative.text(for: .tutorial(index: i)), .info)
        }
        if !AspectTeachingBeat.hasShownLoadout {
            append(Narrative.text(for: .loadoutIntro), .info)
            AspectTeachingBeat.markLoadoutShown()
        }
        spawnNextEnemy()
        phase = .combat
        GameAnalytics.track(.runStarted)
        lifetime.totalRunsStarted += 1
        MetaStore.saveLifetime(lifetime)
        handleAchievementEvent(.runStarted)
    }

    // MARK: - Spawning (ports the num/layer bookkeeping from GameDriver)

    private func spawnNextEnemy(advance: Bool = true) {
        if advance {
            enemyIndex += 1
            if enemyIndex > Balance.enemiesPerLayer {
                enemyIndex = 1
                // A new group of fodder: the bestiary permanently strengthens.
                scaleLevel += 1
            }
        }
        // 0 during campaign; drives endless exponential scaling after the dragon.
        let postGameDepth = max(0, layer - Balance.campaignDragonLayer)

        let isBoss = enemyIndex == Balance.enemiesPerLayer
        let isFinalBoss = isBoss && layer == Balance.campaignDragonLayer

        let kind: EnemyKind
        if isFinalBoss {
            kind = Bestiary.finalBoss
        } else if isBoss {
            kind = rng.element(Bestiary.bosses)!
        } else {
            kind = rng.element(Bestiary.fodder)!
        }

        enemy = Enemy(kind: kind, scaleLevel: scaleLevel, layer: layer,
                      isBoss: isBoss, isFinalBoss: isFinalBoss, postGameDepth: postGameDepth)
        let elite = nextSpawnIsElite && !isBoss && !isFinalBoss
        nextSpawnIsElite = false
        currentEncounterElite = elite
        RingCrawl.applyEncounterModifiers(
            to: enemy,
            modifier: currentRingModifier,
            elite: elite,
            isWarden: isBoss,
            suppliesStarved: suppliesStarved
        )
        spawnCounter += 1

        if enemyIndex == 1, layer > 1, log.count > 8 {
            trimLogForNewLayer()
        }
        append("— Layer \(layer): Enemy \(enemyIndex) of \(Balance.enemiesPerLayer) —", .system, spacedAbove: true)
        if enemyIndex == 1, let flavor = Narrative.layerEntry(layer: layer) {
            append(flavor, .info)
        }
        if isBoss {
            append(Narrative.text(for: .bossSpawn(isFinalBoss: isFinalBoss)),
                   isFinalBoss ? .danger : .danger)
        }
        append("A \(enemy.name) appears! \(enemy.sprite)", isBoss ? .danger : .info)
        if !AspectTeachingBeat.hasShownIntro {
            append(Narrative.text(for: .aspectIntro(aspect: enemy.aspect)), .info)
            AspectTeachingBeat.markIntroShown()
        }
        if isBoss { SoundManager.shared.play(.bossAppear) }
    }

    // MARK: - Idle tick

    func toggleAuto() { autoBattle.toggle() }

    /// Automation (auto-resolve level-up & shop so idle doesn't stall) unlocks
    /// after the first prestige — early runs stay hands-on.
    var automationUnlocked: Bool { totalShards >= Balance.automationUnlockShards }

    /// Driven by the view's timeline (~1 Hz). With auto-battle on: plays a combat
    /// action, and — once automation is unlocked — also clears the between-layer
    /// level-up/shop so the run keeps diving unattended.
    func tick() {
        guard autoBattle else { return }
        switch phase {
        case .combat:
            if automationUnlocked,
               AutoDescendSettings.enabled,
               pendingShards >= AutoDescendSettings.minShards {
                performAutoAscend()
                return
            }
            switch autoAction() {
            case .move(let move):
                perform(move)
            case .sigil(let spell):
                performSigil(spell)
            }
        case .draft where automationUnlocked:
            if let pick = draftOptions.first { chooseDraft(pick) }
        case .ringChoice where automationUnlocked:
            if autoShouldCamp() { enterCamp() } else { pushDeeper() }
        case .ringIngress where automationUnlocked:
            autoChooseDoor()
        case .levelUp where automationUnlocked:
            chooseUpgrade(autoUpgrade())
        case .shop where automationUnlocked:
            autoShop()
        default:
            break
        }
    }

    /// Round-robin stat picks keep the build balanced under automation.
    private func autoUpgrade() -> Player.Upgrade {
        switch player.level % 3 {
        case 0:  return .health
        case 1:  return .attack
        default: return .defense
        }
    }

    /// Auto-battle: camp for shop when hurt, low on potions, or on a cadence.
    private func autoShouldCamp() -> Bool {
        let hpPct = player.hp * 100 / max(1, player.maxHp)
        if hpPct < Balance.autoCampHpThresholdPercent { return true }
        if runStats.layersClearedThisRun > 0,
           runStats.layersClearedThisRun % Balance.autoCampEveryNRings == 0 {
            return true
        }
        if player.potions == 0, canAfford(.potion) { return true }
        return false
    }

    /// Exposed for headless playtest harness (mirrors `tick()` camp logic).
    func autoShouldCampForHarness() -> Bool { autoShouldCamp() }

    /// Headless combat step for manual-damage playtests (`perform` uses manual multiplier).
    func playtestCombatStep() {
        guard phase == .combat else { return }
        switch autoAction() {
        case .move(let move):
            perform(move)
        case .sigil(let spell):
            performSigil(spell)
        }
    }

    /// Headless shop resolution when auto-battle is off (manual pacing harness).
    func playtestAutoShop() {
        guard phase == .shop else { return }
        autoShop()
    }

    /// Headless draft pick for manual pacing harness.
    func playtestChooseDraft() {
        guard phase == .draft, let pick = draftOptions.first else { return }
        chooseDraft(pick)
    }

    /// Buy affordable permanent upgrades, hire mercenaries, then one scroll, then dive on.
    private func autoShop() {
        for item in [ShopItem.whetstone, .towerShield, .heartVial, .luckyCoin]
        where canAfford(item) {
            buy(item)
        }
        if player.potions < 3, canAfford(.potion) { buy(.potion) }
        if player.ethers < 1, canAfford(.ether) { buy(.ether) }
        var hired = 0
        while hired < Balance.autoShopMaxMercenariesPerVisit,
              let merc = Mercenary.allCases.first(where: { canHire($0) }) {
            hireMercenary(merc)
            hired += 1
        }
        var scrolls = 0
        for spell in SpellCatalog.autoShopScrolls {
            guard scrolls < Balance.autoShopMaxSigilScrollsPerVisit,
                  canBuySigilScroll(spell) else { continue }
            buySigilScroll(spell)
            scrolls += 1
        }
        autoEquipPurchasedSigils()
        leaveShop()
    }

    private enum AutoAction {
        case move(Move)
        case sigil(SpellID)
    }

    /// Heal/dodge when hurt, else sigil picks, else heavy/attack.
    private func autoAction() -> AutoAction {
        let healAmount = 10 * player.level
        let lowHp = player.hp * 100 / max(1, player.maxHp) < Balance.autoBattleHealThresholdPercent
        if lowHp && player.hp < player.maxHp {
            let incoming = damageToPlayer(max(1, enemy.attack - player.defense))
            if healAmount > incoming {
                return .move(.heal)
            }
            if incoming >= healAmount {
                return .move(.dodge)
            }
        }
        if let sigil = autoSigil(minScore: 3) { return .sigil(sigil) }
        if let sigil = autoSigil(minScore: 2) { return .sigil(sigil) }
        // Legacy Magic Bolt priority: cast the primary sigil when mana allows.
        if let primary = sigilLoadout.slots[0],
           player.mana >= SpellCatalog.definition(for: primary).manaCost {
            return .sigil(primary)
        }
        if let sigil = autoSigil(minScore: 1) { return .sigil(sigil) }
        return .move(autoPhysicalMove())
    }

    private func autoPhysicalMove() -> Move {
        if player.mana >= Move.heavy.manaCost { return .heavy }
        return .attack
    }

    /// Picks the best affordable equipped sigil at or above `minScore` (3=weak, 2=neutral).
    private func autoSigil(minScore: Int) -> SpellID? {
        var best: (SpellID, Int)?
        for spell in sigilLoadout.equipped {
            let def = SpellCatalog.definition(for: spell)
            guard player.mana >= def.manaCost else { continue }
            let eff = TypeChart.effectiveness(
                spellElement: def.element,
                enemyAspect: enemy.aspect,
                enemyTags: enemy.tags
            )
            let score: Int
            switch eff {
            case .weak:    score = 3
            case .neutral: score = 2
            case .resist:  score = 1
            }
            guard score >= minScore else { continue }
            if best == nil
                || score > best!.1
                || (score == best!.1 && def.manaCost < SpellCatalog.definition(for: best!.0).manaCost) {
                best = (spell, score)
            }
        }
        return best?.0
    }

    private func autoEquipPurchasedSigils() {
        for spell in SpellCatalog.shopScrolls where sigilMastery.mastered.contains(spell) {
            equipIntoFirstVacantSlot(spell)
        }
    }

    /// Slots a mastered sigil into the first vacant loadout slot.
    @discardableResult
    private func equipIntoFirstVacantSlot(_ spell: SpellID) -> Bool {
        guard sigilMastery.mastered.contains(spell) else { return false }
        guard !sigilLoadout.equipped.contains(spell) else { return false }
        guard let vacant = sigilLoadout.slots.firstIndex(where: { $0 == nil }) else { return false }
        equipSigil(spell, slot: vacant)
        return true
    }

    // MARK: - Player actions

    func perform(_ move: Move) {
        guard phase == .combat else { return }
        runStats.manualMoves += 1

        // A stunned hero loses the turn; the enemy still gets to act.
        if player.consumeStunIfNeeded() {
            append("You are stunned and skip your turn! 💫", .danger)
            enemyRetaliates(bonusChance: 0)
            endRound()
            return
        }

        guard player.mana >= move.manaCost else {
            append("Not enough mana for \(move.rawValue)!", .miss)
            return
        }
        player.spendMana(move.manaCost)

        switch move {
        case .attack: resolveAttack(multiplier: 1.0, label: "strike", stunChance: 0)
        case .heavy:  resolveAttack(multiplier: Balance.heavyDamageMultiplier,
                                    label: "heavy blow", stunChance: Balance.heavyStunChancePercent)
        case .dodge:  resolveDodge()
        case .heal:   resolveHeal()
        }

        endRound()
    }

    // MARK: - Sigils

    var canEditSigilLoadout: Bool {
        phase == .title || phase == .shop
    }

    func performSigil(_ spell: SpellID) {
        guard phase == .combat else { return }
        guard sigilLoadout.equipped.contains(spell) else { return }
        runStats.manualMoves += 1

        if player.consumeStunIfNeeded() {
            append("You are stunned and skip your turn! 💫", .danger)
            enemyRetaliates(bonusChance: 0)
            endRound()
            return
        }

        let def = SpellCatalog.definition(for: spell)
        guard player.mana >= def.manaCost else {
            append("Not enough mana for \(def.displayName)!", .miss)
            return
        }
        player.spendMana(def.manaCost)
        resolveSigil(spell)
        endRound()
    }

    func sigilScrollPrice(_ spell: SpellID) -> Int {
        SpellCatalog.definition(for: spell).shopScrollPrice ?? 0
    }

    func canBuySigilScroll(_ spell: SpellID) -> Bool {
        guard phase == .shop else { return false }
        guard let price = SpellCatalog.definition(for: spell).shopScrollPrice else { return false }
        guard !sigilMastery.mastered.contains(spell) else { return false }
        return player.gold >= price
    }

    func buySigilScroll(_ spell: SpellID) {
        guard phase == .shop else { return }
        let def = SpellCatalog.definition(for: spell)
        guard let price = def.shopScrollPrice else { return }
        guard !sigilMastery.mastered.contains(spell) else {
            append("You already know \(def.displayName).", .miss)
            Haptics.play(.warning)
            SoundManager.shared.play(.denied)
            return
        }
        guard player.spendGold(price) else {
            append("Not enough gold for the \(def.displayName) scroll.", .miss)
            Haptics.play(.warning)
            SoundManager.shared.play(.denied)
            return
        }
        sigilMastery.mastered.insert(spell)
        MetaStore.saveSigilMastery(sigilMastery)
        append("Bought \(def.displayName) scroll for \(price)g.", .reward)
        if equipIntoFirstVacantSlot(spell) {
            append("\(def.displayName) slotted into your loadout.", .info)
        } else if !sigilLoadout.equipped.contains(spell) {
            append("Loadout full — swap sigils at the Sigil Bench.", .info)
        }
        if !AspectTeachingBeat.hasShownScroll {
            append(Narrative.text(for: .sigilScroll), .system)
            AspectTeachingBeat.markScrollShown()
        }
        Haptics.play(.success)
        SoundManager.shared.play(.purchase)
        handleAchievementEvent(.sigilMasteryUpdated(count: sigilMastery.mastered.count))
    }

    func equipSigil(_ spell: SpellID, slot: Int) {
        guard canEditSigilLoadout else { return }
        guard (0..<SigilLoadout.slotCount).contains(slot) else { return }
        guard sigilMastery.mastered.contains(spell) else { return }
        for i in 0..<SigilLoadout.slotCount where sigilLoadout.slots[i] == spell {
            sigilLoadout.slots[i] = nil
        }
        sigilLoadout.slots[slot] = spell
        if phase != .title { save() }
    }

    func clearSigilSlot(_ slot: Int) {
        guard canEditSigilLoadout else { return }
        guard (0..<SigilLoadout.slotCount).contains(slot) else { return }
        sigilLoadout.slots[slot] = nil
        if phase != .title { save() }
    }

    /// End-of-round upkeep: damage-over-time ticks (enemy then player), then
    /// centralized death handling. All death detection stays in `resolveDeaths`.
    private func endRound() {
        // Passive mana regen keeps the ability kit usable over a fight.
        if player.isAlive { player.restoreMana(Balance.manaRegenPerTurn + relicManaRegenBonus) }
        applyTick(to: enemy, onPlayer: false)
        applyTick(to: player, onPlayer: true)
        resolveDeaths()
    }

    /// Tick one combatant's statuses and surface any DoT as a popup + log line.
    /// The model's `tickStatuses()` applies the damage and decrements durations;
    /// this wrapper keeps the UI/feedback in the engine so the model stays clean.
    private func applyTick(to combatant: Combatant, onPlayer: Bool) {
        guard combatant.isAlive else { return }
        let burning = combatant.statuses.contains { $0.kind == .burn }
        let dot = combatant.tickStatuses()
        guard dot > 0 else { return }
        showPopup("−\(dot)", .damage, onPlayer: onPlayer)
        if onPlayer { flashPlayer() } else { flashEnemy() }
        let icon = burning ? "🔥" : "☠️"
        let who = onPlayer ? "You take" : "\(combatant.name) takes"
        append("\(icon) \(who) \(dot) from lingering effects.", onPlayer ? .enemyHit : .playerHit)
    }

    /// Standard / heavy attack. Heavy hits harder and can stun, but a lethal
    /// hit skips the enemy's retaliation — matching the original where a lethal
    /// hit `break`s out before the enemy can swing back.
    private func resolveAttack(multiplier: Double, label: String, stunChance: Int) {
        if Dice.checkHit(chance: player.luck, rng: rng) {
            let crit = rollCrit()
            let critMult = crit ? 2.0 : 1.0
            let raw = Int(Double(combatAttack) * multiplier * critMult * combatDamageMultiplier) - enemy.defense
            let dmg = max(1, raw)
            enemy.takeHit(dmg)
            applyLifesteal(for: dmg)
            flashEnemy()
            if crit {
                showPopup("CRIT! −\(dmg)", .crit, onPlayer: false)
                append("Critical \(label)! \(enemy.name) takes \(dmg)! 💥", .playerHit)
                Haptics.play(.medium)
                SoundManager.shared.play(.crit)
                handleAchievementEvent(.critLanded)
            } else {
                showPopup("−\(dmg)", .damage, onPlayer: false)
                append("Your \(label) hits \(enemy.name) for \(dmg)! 💥", .playerHit)
                SoundManager.shared.play(.swing)
            }
            if !enemy.isAlive { return }
            if stunChance > 0, rng.chance(stunChance) {
                enemy.applyStatus(.stun, turns: 1, magnitude: 0)
                append("\(enemy.name) is dazed and will lose its next turn! 💫", .reward)
            }
        } else {
            showPopup("Miss", .miss, onPlayer: false)
            append("You missed!", .miss)
        }
        enemyRetaliates(bonusChance: 0)
    }

    /// Typed sigils: ignores enemy defense, always lands.
    private func resolveSigil(_ spell: SpellID) {
        let def = SpellCatalog.definition(for: spell)
        let cast = castResolver.resolve(spell: spell, engine: self)
        let result = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: combatAttack,
            targetDefense: enemy.defense,
            targetAspect: enemy.aspect,
            targetTags: enemy.tags,
            castMultiplier: cast.damageMultiplier * combatDamageMultiplier,
            useSpellBaseFormula: true
        ))
        enemy.takeHit(result.finalDamage)
        applyLifesteal(for: result.finalDamage)
        flashEnemy()
        surfaceSigilHit(spell: def, damage: result.finalDamage, effectiveness: result.effectiveness)
        if !enemy.isAlive { return }
        if spell == .emberBolt, let chance = def.burnChancePercent, rng.chance(chance) {
            enemy.applyStatus(.burn, turns: 3, magnitude: max(2, player.level))
            append("\(enemy.name) catches fire! 🔥", .reward)
        }
        if spell == .venomLash {
            enemy.applyStatus(.poison, turns: 3, magnitude: max(1, player.level), maxStacks: 5)
            let dot = max(1, player.level)
            append("Poison will deal \(dot) per turn (stacks up to 5). ☠️", .info)
            SoundManager.shared.play(.poison)
        }
        enemyRetaliates(bonusChance: 0)
    }

    private func surfaceSigilHit(spell: SpellDefinition, damage: Int, effectiveness: Effectiveness) {
        switch effectiveness {
        case .weak:
            showPopup("WEAK! −\(damage)", .weak, onPlayer: false)
            append("The sigil finds its mark — super effective!", .reward)
            if !AspectTeachingBeat.hasShownWeak {
                append(Narrative.text(for: .aspectWeak), .info)
                AspectTeachingBeat.markWeakShown()
            }
            handleAchievementEvent(.sigilWeakHit)
            append("✨ Your \(spell.displayName) strikes \(enemy.name) for \(damage)!", .playerHit)
            Haptics.play(.medium)
            SoundManager.shared.play(.crit)
        case .resist:
            showPopup("−\(damage)", .damage, onPlayer: false)
            append("The guardian shrugs off the sigil.", .info)
            if !AspectTeachingBeat.hasShownResist {
                append(Narrative.text(for: .aspectResist), .info)
                AspectTeachingBeat.markResistShown()
            }
            append("Your \(spell.displayName) barely scratches \(enemy.name) for \(damage).", .playerHit)
            SoundManager.shared.play(.magic)
        case .neutral:
            showPopup("−\(damage)", .damage, onPlayer: false)
            append("✨ Your \(spell.displayName) hits \(enemy.name) for \(damage)!", .playerHit)
            SoundManager.shared.play(.magic)
        }
    }

    /// Dodge, ported from case 'D': harder for the enemy to connect; on a clean
    /// dodge you recover a little HP and some mana.
    private func resolveDodge() {
        append("You brace and watch for the opening…", .info)
        if Dice.checkHit(chance: enemy.luck + 3, rng: rng) {
            let dmg = damageToPlayer(enemy.attack - player.defense)
            applyDirectDamageToPlayer(dmg)
            flashPlayer()
            showPopup("−\(dmg)", .damage, onPlayer: true)
            append("\(enemy.name) still landed \(dmg)!", .enemyHit)
        } else {
            let healed = 5 * player.level
            player.restoreHp(healed)
            player.restoreMana(4)
            showPopup("Dodge +\(healed)", .heal, onPlayer: true)
            append("Dodged! You recover \(healed) HP and focus. 🌀", .reward)
        }
    }

    /// Heal, ported from case 'H': restore 10×level HP, then the enemy gets a
    /// slightly-better-than-normal swing. No-op (and no retaliation) at full HP.
    private func resolveHeal() {
        if player.hp >= player.maxHp {
            append("You are already at full health!", .info)
            return
        }
        let amount = 10 * player.level
        player.restoreHp(amount)
        runStats.healsUsed += 1
        showPopup("+\(amount)", .heal, onPlayer: true)
        append("You catch your breath and restore \(amount) HP. ❤️", .reward)
        enemyRetaliates(bonusChance: 1)
    }

    /// Enemy's swing back, ported from the shared `e1.checkHit` blocks.
    /// A stunned enemy forfeits the swing. Bosses may inflict poison on a hit.
    private func enemyRetaliates(bonusChance: Int) {
        guard enemy.isAlive else { return }
        if enemy.consumeStunIfNeeded() {
            append("\(enemy.name) is stunned and can't strike! 💫", .reward)
            return
        }
        if Dice.checkHit(chance: enemy.luck + bonusChance, rng: rng) {
            // Guard buff softens incoming hits while active; Ward reduces the rest.
            let guardBonus = player.statuses.contains { $0.kind == .guardUp } ? 5 : 0
            let dmg = damageToPlayer(enemy.attack - player.defense - guardBonus)
            applyDirectDamageToPlayer(dmg)
            flashPlayer()
            showPopup("−\(dmg)", .damage, onPlayer: true)
            append("\(enemy.name) hits you for \(dmg)!", .enemyHit)
            if enemy.isBoss, player.isAlive, rng.chance(Balance.bossPoisonChancePercent) {
                player.applyStatus(.poison, turns: 2, magnitude: max(1, enemy.level), maxStacks: 3)
                append("\(enemy.name)'s strike leaves you poisoned! ☠️", .danger)
            }
        } else {
            showPopup("Miss", .miss, onPlayer: true)
            append("\(enemy.name) missed!", .miss)
        }
    }

    /// Crit chance leans on luck: in this game a *lower* luck value lands hits
    /// more often, so it also crits more. Player luck 3 → ~21%. A `focus` buff
    /// adds a flat bonus while active.
    private func applyDirectDamageToPlayer(_ dmg: Int) {
        player.takeHit(dmg)
        applyThorns(for: dmg)
        runStats.damageTaken += dmg
        if player.isAlive, dmg >= max(1, player.maxHp * 45 / 100) {
            handleAchievementEvent(.survivedBigHit)
        }
    }

    private func rollCrit() -> Bool {
        let focusBonus = player.statuses.contains { $0.kind == .focus } ? 25 : 0
        return rng.chance(max(Balance.minCritChancePercent, (10 - player.luck) * 3) + focusBonus + relicCritBonus)
    }

    // MARK: - Death handling

    private func resolveDeaths() {
        // Player death takes precedence — if a lethal end-of-round DoT drops both
        // the hero and the enemy in the same tick, it's still a defeat (rather
        // than silently advancing at 0 HP).
        if !player.isAlive {
            if !tryPhoenixAshRevive() {
                lifetime.totalDeaths += 1
                MetaStore.saveLifetime(lifetime)
                handleAchievementEvent(.playerDied)
                if !FirstDeathBeat.hasShown {
                    append(Narrative.text(for: .firstDeathTwist), .danger)
                    FirstDeathBeat.markShown()
                }
                append("You died on Layer \(layer)… 💀", .danger)
                append(Narrative.text(for: .defeatScatter), .danger)
                let salvaged = deathSalvagedShards
                if salvaged > 0 {
                    totalShards += salvaged
                    PrestigeStore.save(totalShards)
                    lastDeathSalvagedShards = salvaged
                    append(Narrative.text(for: .deathShardsSalvaged(salvaged)), .reward)
                }
                append("Final gold: \(player.gold). Reached level \(player.level).", .info)
                Haptics.play(.error)
                SoundManager.shared.play(.playerDie)
                recordRun()
                SaveStore.clear()        // run over — next launch starts fresh
                phase = .defeat
                GameAnalytics.track(.runEnded(reason: "defeat", layer: layer, level: player.level))
                return
            }
        }

        if !enemy.isAlive {
            let baseGold = enemy.generateGold()
            var payoutMult = goldMultiplier * relicGoldMultiplier
                * RingCrawl.goldMultiplier(modifier: currentRingModifier)
            if currentEncounterElite {
                payoutMult *= 1.0 + Double(Balance.eliteBonusGoldPercent) / 100.0
                currentEncounterElite = false
            }
            let gold = Int((Double(baseGold) * payoutMult).rounded())
            player.addGold(gold)
            runGoldEarned += gold
            lifetime.totalGoldEarned += gold
            lifetime.totalKills += 1
            runStats.enemiesSlain += 1
            if enemyIndex == Balance.enemiesPerLayer {
                lifetime.totalBossKills += 1
                tryRelicDrop()
            }
            MetaStore.saveLifetime(lifetime)
            handleAchievementEvent(.enemyKilled(wasBoss: enemyIndex == Balance.enemiesPerLayer))
            append("You gained \(Formatting.short(gold)) gold! 🪙", .reward)
            append("The \(enemy.name) was slain!", .reward)
            Haptics.play(.success)
            SoundManager.shared.play(.enemyDie)

            recordRun()
            if enemyIndex == Balance.enemiesPerLayer {
                handleBossDefeated()
            } else {
                runStats.killsSinceDraft += 1
                if shouldTriggerDraft() {
                    beginDraft()
                } else {
                    spawnNextEnemy()
                }
            }
        }
    }

    private func shouldTriggerDraft() -> Bool {
        runStats.killsSinceDraft >= draftKillsNeeded
    }

    private func beginDraft() {
        draftOptions = RunDraft.rollOptions(rng: rng)
        runStats.killsSinceDraft = 0
        append("Kill bar full — choose a run upgrade.", .system)
        SoundManager.shared.play(.levelUp)
        phase = .draft
        save()
    }

    /// Pick one of the rolled draft options, then resume combat.
    func chooseDraft(_ option: DraftOption) {
        guard phase == .draft, draftOptions.contains(option) else { return }
        RunDraft.apply(option, to: player)
        player.incrementLevel()
        append("Drafted \(option.title)! \(option.blurb)", .reward)
        draftOptions = []
        phase = .combat
        spawnNextEnemy()
        save()
    }

    /// Skip the camp and dive into the next ring immediately.
    func pushDeeper() {
        guard phase == .ringChoice else { return }
        if awaitingRingAdvance { advanceToNextRing() }
        awaitingRingAdvance = false
        beginRingIngress()
        save()
    }

    /// Rest at camp — spend gold before the next ring.
    func enterCamp() {
        guard phase == .ringChoice else { return }
        spendSupplies(Balance.supplyCostCamp)
        append("You make camp (−\(Balance.supplyCostCamp) supplies). Spend gold, then push on.", .system)
        phase = .shop
        save()
    }

    /// Pick an ingress door and begin the ring's first encounter (or shrine boon).
    func chooseDoor(_ offer: DoorOffer) {
        guard phase == .ringIngress, doorOffers.contains(offer) else { return }
        doorOffers = []
        switch offer.kind {
        case .guardPatrol:
            append("You take the patrol route.", .info)
            enterNextEncounter()
        case .elite:
            append("You kick down the elite's door.", .danger)
            nextSpawnIsElite = true
            enterNextEncounter()
        case .shrine:
            let heal = max(1, player.maxHp * Balance.shrineHealPercent / 100)
            player.restoreHp(heal)
            player.addGold(Balance.shrineBonusGold)
            runGoldEarned += Balance.shrineBonusGold
            append("The ash shrine warms you (+\(heal) HP, +\(Balance.shrineBonusGold) gold).", .reward)
            enterNextEncounter()
        }
        save()
    }

    private func beginRingIngress() {
        spendSupplies(Balance.supplyCostPerRing)
        currentRingModifier = RingCrawl.rollModifier(rng: rng)
        append("— Ring \(layer): \(currentRingModifier?.title ?? "Vault") —", .system, spacedAbove: true)
        append(currentRingModifier?.blurb ?? "", .info)
        if layer >= Balance.doorChoiceMinRing {
            doorOffers = RingCrawl.rollDoors(ring: layer, rng: rng)
            append("Two paths branch ahead. Choose a door.", .system)
            phase = .ringIngress
        } else {
            enterNextEncounter()
        }
    }

    private func autoChooseDoor() {
        guard phase == .ringIngress else { return }
        let hpPct = player.hp * 100 / max(1, player.maxHp)
        if hpPct < 50, let shrine = doorOffers.first(where: { $0.kind == .shrine }) {
            chooseDoor(shrine)
            return
        }
        if let guardRoute = doorOffers.first(where: { $0.kind == .guardPatrol }) {
            chooseDoor(guardRoute)
        } else if let first = doorOffers.first {
            chooseDoor(first)
        }
    }

    private func spendSupplies(_ amount: Int) {
        guard amount > 0 else { return }
        supplies = max(0, supplies - amount)
        if supplies == 0 {
            append("Supplies exhausted — the vault presses in.", .danger)
        }
    }

    /// Consumes Phoenix Ash and claws back from 0 HP — once per run only.
    /// Returns true when the crawl continues (enemy may still be slain this tick).
    @discardableResult
    private func tryPhoenixAshRevive() -> Bool {
        guard player.consumePhoenixAsh() else { return false }
        runStats.phoenixAshUsed = true
        player.riseFromAsh(hpPercent: Balance.phoenixAshReviveHpPercent,
                           manaPercent: Balance.phoenixAshReviveManaPercent)
        showPopup("Revived!", .heal, onPlayer: true)
        append(Narrative.text(for: .phoenixAshRevive), .reward)
        Haptics.play(.warning)
        SoundManager.shared.play(.heal)
        save()
        lifetime.totalRevives += 1
        MetaStore.saveLifetime(lifetime)
        handleAchievementEvent(.phoenixAshRevived)
        return true
    }

    private func handleBossDefeated() {
        let wasFinal = (layer == Balance.vaultHeartLayer)
        runStats.bossKillsThisRun += 1
        runStats.layersClearedThisRun += 1

        if wasFinal {
            clearedFinalBoss = true
            append(Narrative.text(for: .dragonSlain), .reward)
            append(Narrative.text(for: .crownSealBroken), .system)
            append(Narrative.text(for: .progressionAfterDragon), .system)
            SoundManager.shared.play(.victory)
            GameAnalytics.track(.dragonSlain)
            handleAchievementEvent(.dragonSlain)
            if !runStats.phoenixAshUsed {
                handleAchievementEvent(.campaignClearedNoPhoenix)
            }
        }

        GameAnalytics.track(.layerCleared(layer: layer))
        lifetime.deepestLayer = max(lifetime.deepestLayer, layer)
        MetaStore.saveLifetime(lifetime)
        handleAchievementEvent(.layerCleared(layer: layer))

        awaitingRingAdvance = true
        append("Warden fallen. Push deeper or make camp?", .system)
        SoundManager.shared.play(.levelUp)
        phase = .ringChoice
        save()
    }

    private func advanceToNextRing() {
        layer += 1
        if layer == 2 {
            append("Enemies get tougher each ring — but so do you.", .system)
        }
    }

    /// Legacy level-up path (old saves / tests).
    /// Called by the level-up screen; then opens the shop before the next layer.
    func chooseUpgrade(_ upgrade: Player.Upgrade) {
        player.levelUp(upgrade)
        append("Upgraded \(upgrade.label)! Now level \(player.level).", .reward)
        phase = .shop
    }

    /// Spawn the next enemy and resume combat — or show the victory screen once.
    private func enterNextEncounter() {
        spawnNextEnemy()
        if clearedFinalBoss && !victoryShown {
            // Show the victory celebration once, then continue endlessly.
            victoryShown = true
            phase = .victory
        } else {
            phase = .combat
        }
    }

    /// From the victory screen: dive on into endless mode.
    func continueEndless() {
        phase = .combat
    }

    // MARK: - Prestige / ascension

    /// Open the ascension screen (from combat). Auto-battle pauses there.
    func enterAscension() {
        guard phase == .combat else { return }
        phase = .ascension
    }

    /// Back out of the ascension screen without descending.
    func cancelAscension() {
        guard phase == .ascension else { return }
        phase = .combat
    }

    /// Descend: bank `pendingShards`, then restart the run. Spend the shards in
    /// the skill tree to actually boost future runs.
    func ascend() {
        guard phase == .ascension else { return }
        performAscension()
    }

    private func performAutoAscend() {
        guard phase == .combat, pendingShards > 0 else { return }
        handleAchievementEvent(.autoAscended)
        performAscension()
    }

    private func performAscension() {
        let gained = pendingShards
        let firstShardEver = totalShards == 0 && gained > 0
        let automationWasLocked = !automationUnlocked

        if gained > 0 {
            totalShards += gained
            PrestigeStore.save(totalShards)
            GameAnalytics.track(.prestigeCompleted(shards: gained, totalShards: totalShards))
            handleAchievementEvent(.prestige(shardsGained: gained, totalShards: totalShards))
        }
        lifetime.totalDescents += 1
        lifetime.highestRunGold = max(lifetime.highestRunGold, runGoldEarned)
        MetaStore.saveLifetime(lifetime)
        let name = player.name
        startGame(named: name)

        if gained > 0 {
            append(Narrative.text(for: .ascensionGained(shards: gained)), .system)
            if firstShardEver {
                append(Narrative.text(for: .milestoneFirstShard), .system)
                if automationWasLocked && automationUnlocked {
                    append(Narrative.text(for: .milestoneAutomationUnlock), .system)
                }
            }
        } else {
            append(Narrative.text(for: .ascensionEmpty), .system)
        }
        append(Narrative.text(for: .ascensionFollowUp), .system)
    }

    // MARK: - Mercenaries & relics

    func mercenaryCost(_ merc: Mercenary) -> Int {
        merc.cost(owned: mercenaryCounts[merc, default: 0])
    }

    func canHire(_ merc: Mercenary) -> Bool {
        player.gold >= mercenaryCost(merc)
    }

    /// Hire a mercenary with run gold; ownership persists forever.
    func hireMercenary(_ merc: Mercenary) {
        guard phase == .shop else { return }
        let cost = mercenaryCost(merc)
        guard player.spendGold(cost) else {
            append("Not enough gold to hire a \(merc.name).", .miss)
            Haptics.play(.warning)
            SoundManager.shared.play(.denied)
            return
        }
        let firstHire = mercenaryCounts.values.reduce(0, +) == 0
        mercenaryCounts[merc, default: 0] += 1
        persistMercenaries()
        append("Hired \(merc.name)! Party DPS is now \(mercenaryDPS). \(merc.icon)", .reward)
        if firstHire {
            append(Narrative.text(for: .milestoneFirstMercenary), .system)
        }
        Haptics.play(.success)
        SoundManager.shared.play(.purchase)
        let totalOwned = mercenaryCounts.values.reduce(0, +)
        handleAchievementEvent(.mercenaryHired(merc: merc, totalOwned: totalOwned))
    }

    func isRelicDiscovered(_ relic: Relic) -> Bool {
        discoveredRelics.contains(relic.rawValue)
    }

    func isRelicEquipped(_ relic: Relic) -> Bool {
        equippedRelics.contains(relic.rawValue)
    }

    func toggleEquipRelic(_ relic: Relic) {
        guard isRelicDiscovered(relic) else { return }
        if isRelicEquipped(relic) {
            equippedRelics.removeAll { $0 == relic.rawValue }
        } else if equippedRelics.count < Balance.maxEquippedRelics {
            equippedRelics.append(relic.rawValue)
        }
        MetaStore.saveEquippedRelics(equippedRelics)
        Haptics.play(.success)
        handleAchievementEvent(.relicEquipped(count: equippedRelics.count))
    }

    private func tryRelicDrop() {
        guard rng.chance(Balance.bossRelicDropChancePercent) else { return }
        let pool = Relic.allCases.filter { !discoveredRelics.contains($0.rawValue) }
        if let relic = pool.isEmpty ? nil : rng.element(pool) {
            let firstRelic = discoveredRelics.isEmpty
            discoveredRelics.insert(relic.rawValue)
            MetaStore.saveDiscoveredRelics(discoveredRelics)
            lifetime.relicsFound += 1
            MetaStore.saveLifetime(lifetime)
            append(Narrative.text(for: .relicNew(name: relic.name, icon: relic.icon)), .reward)
            if firstRelic {
                append(Narrative.text(for: .milestoneFirstRelic), .system)
            }
            if equippedRelics.count < Balance.maxEquippedRelics {
                equippedRelics.append(relic.rawValue)
                MetaStore.saveEquippedRelics(equippedRelics)
                handleAchievementEvent(.relicEquipped(count: equippedRelics.count))
            }
            newRelicFound = relic
            handleAchievementEvent(.relicDiscovered)
        } else {
            let bonus = Balance.relicDuplicateGoldBonus
            player.addGold(bonus)
            runGoldEarned += bonus
            lifetime.totalGoldEarned += bonus
            append(Narrative.text(for: .relicDuplicate(gold: bonus)), .reward)
        }
    }

    // MARK: - Skill tree

    func cost(_ node: SkillNode) -> Int {
        node.cost(currentLevel: treeLevels[node, default: 0])
    }

    func canUpgrade(_ node: SkillNode) -> Bool {
        treeLevels[node, default: 0] < node.maxLevel && availableShards >= cost(node)
    }

    /// Spend shards to raise a node one level; persists the tree.
    func upgradeNode(_ node: SkillNode) {
        guard canUpgrade(node) else { return }
        treeLevels[node, default: 0] += 1
        var raw: [String: Int] = [:]
        for (n, lvl) in treeLevels { raw[n.rawValue] = lvl }
        PrestigeStore.saveTree(raw)
        Haptics.play(.success)
        SoundManager.shared.play(.purchase)
        handleAchievementEvent(.treeUpgraded)
    }

    func level(of node: SkillNode) -> Int { treeLevels[node, default: 0] }

    // MARK: - Shop

    /// Current price for an item. Consumables are flat; permanent upgrades
    /// inflate *geometrically* per copy owned (1.7× each) so gold — which grows
    /// quadratically with depth — can't fully out-buy the endless scaling.
    func price(_ item: ShopItem) -> Int {
        let raw: Int
        if item.isPermanent {
            let owned = purchaseCounts[item, default: 0]
            raw = Int((Double(item.basePrice) * pow(Balance.shopPriceGrowth, Double(owned))).rounded())
        } else {
            raw = item.basePrice
        }
        let discounted = Int((Double(raw) * RingCrawl.campPriceMultiplier(modifier: currentRingModifier)).rounded())
        return max(1, discounted)
    }

    func canAfford(_ item: ShopItem) -> Bool { player.gold >= price(item) }

    /// Whether the item can be purchased now (gold + run limits).
    func canBuy(_ item: ShopItem) -> Bool {
        guard canAfford(item) else { return false }
        if item == .phoenixAsh, player.phoenixAshes > 0 { return false }
        return true
    }

    /// Attempt to buy an item; applies its effect and logs the result.
    func buy(_ item: ShopItem) {
        guard phase == .shop else { return }
        guard canBuy(item) else {
            if item == .phoenixAsh, player.phoenixAshes > 0 {
                append("You already carry Phoenix Ash.", .miss)
            } else {
                append("Not enough gold for \(item.name).", .miss)
            }
            Haptics.play(.warning)
            SoundManager.shared.play(.denied)
            return
        }
        let cost = price(item)
        guard player.spendGold(cost) else {
            append("Not enough gold for \(item.name).", .miss)
            Haptics.play(.warning)
            SoundManager.shared.play(.denied)
            return
        }

        switch item {
        case .potion:      player.addPotions(1)
        case .ether:       player.addEthers(1)
        case .phoenixAsh:  player.addPhoenixAsh()
        case .whetstone:   player.upgradeAttack()
        case .towerShield: player.upgradeDefense()
        case .heartVial:   player.upgradeMaxHp()
        case .luckyCoin:   player.improveLuck()
        }
        if item == .phoenixAsh {
            lifetime.phoenixAshesBought += 1
            MetaStore.saveLifetime(lifetime)
        }
        if item.isPermanent {
            purchaseCounts[item, default: 0] += 1
        }
        append("Bought \(item.name) for \(cost)g. \(item.icon)", .reward)
        Haptics.play(.success)
        SoundManager.shared.play(.purchase)
        handleAchievementEvent(.shopPurchase(item))
    }

    /// Leave the camp and enter the next ring.
    func leaveShop() {
        if awaitingRingAdvance {
            advanceToNextRing()
            awaitingRingAdvance = false
        }
        beginRingIngress()
    }

    // MARK: - Consumables (used during combat)

    func usePotion() {
        guard phase == .combat, player.isAlive, player.potions > 0 else { return }
        let before = player.hp
        player.usePotion()
        let healed = player.hp - before
        showPopup("+\(healed)", .heal, onPlayer: true)
        append("You quaff a potion (+\(healed) HP). 🧪", .reward)
        enemyRetaliates(bonusChance: 1)
        endRound()
    }

    func useEther() {
        guard phase == .combat, player.isAlive, player.ethers > 0 else { return }
        player.useEther()
        showPopup("Mana", .heal, onPlayer: true)
        append("You drink an ether and restore mana. 🔮", .reward)
        enemyRetaliates(bonusChance: 1)
        endRound()
    }

    // MARK: - Persistence & offline progress

    /// App moved to the background: stamp the time and persist.
    func backgrounded() {
        backgroundedAt = Date()
        save()
    }

    /// App returned to the foreground: accrue offline gold since backgrounding.
    func foregrounded() {
        if let t = backgroundedAt {
            grantOffline(since: t)
            backgroundedAt = nil
        }
    }

    /// Persist the run, but only while it's live and resumable.
    func save() {
        switch phase {
        case .combat, .draft, .ringChoice, .ringIngress, .levelUp, .shop:
            SaveStore.write(snapshot())
        default:
            break
        }
    }

    private func snapshot() -> GameSave {
        var counts: [String: Int] = [:]
        for (item, n) in purchaseCounts { counts[item.rawValue] = n }
        let phaseStr: String
        switch phase {
        case .draft:     phaseStr = "draft"
        case .ringChoice: phaseStr = "ringChoice"
        case .ringIngress: phaseStr = "ringIngress"
        case .levelUp:   phaseStr = "levelUp"
        case .shop:      phaseStr = "shop"
        default:         phaseStr = "combat"
        }
        return GameSave(
            name: player.name, hp: player.hp, maxHp: player.maxHp,
            attack: player.attack, maxAttack: player.maxAttack,
            defense: player.defense, maxDefense: player.maxDefense,
            luck: player.luck, level: player.level, gold: player.gold,
            mana: player.mana, maxMana: player.maxMana,
            potions: player.potions, ethers: player.ethers,
            phoenixAshes: player.phoenixAshes,
            layer: layer, enemyIndex: enemyIndex, scaleLevel: scaleLevel,
            clearedFinalBoss: clearedFinalBoss, victoryShown: victoryShown,
            purchaseCounts: counts, phase: phaseStr, autoBattle: autoBattle,
            runGoldEarned: runGoldEarned,
            sigilLoadoutSlots: sigilLoadout.slots.map { $0?.rawValue },
            awaitingRingAdvance: awaitingRingAdvance,
            killsSinceDraft: runStats.killsSinceDraft,
            bossKillsThisRun: runStats.bossKillsThisRun,
            draftOptionRawValues: draftOptions.map(\.rawValue),
            supplies: supplies,
            ringModifierRaw: currentRingModifier?.rawValue,
            doorOfferKinds: doorOffers.map(\.kind.rawValue),
            nextSpawnIsElite: nextSpawnIsElite,
            lastSeen: Date())
    }

    private func loadIfAvailable() {
        guard let save = SaveStore.read() else { return }
        restore(from: save)
    }

    private func restore(from save: GameSave) {
        player = Player(restoring: save)
        layer = save.layer
        enemyIndex = save.enemyIndex
        scaleLevel = save.scaleLevel
        clearedFinalBoss = save.clearedFinalBoss
        victoryShown = save.victoryShown
        autoBattle = save.autoBattle
        runGoldEarned = save.runGoldEarned
        awaitingRingAdvance = save.awaitingRingAdvance ?? false
        runStats.killsSinceDraft = save.killsSinceDraft ?? 0
        runStats.bossKillsThisRun = save.bossKillsThisRun ?? 0
        if let rawDraft = save.draftOptionRawValues {
            draftOptions = rawDraft.compactMap { DraftOption(rawValue: $0) }
        }
        supplies = save.supplies ?? Balance.startingSupplies
        if let rawMod = save.ringModifierRaw {
            currentRingModifier = RingModifier(rawValue: rawMod)
        }
        if let kinds = save.doorOfferKinds {
            doorOffers = kinds.compactMap { DoorKind(rawValue: $0) }.map { DoorOffer(kind: $0) }
        }
        nextSpawnIsElite = save.nextSpawnIsElite ?? false

        var counts: [ShopItem: Int] = [:]
        for (raw, n) in save.purchaseCounts {
            if let item = ShopItem(rawValue: raw) { counts[item] = n }
        }
        purchaseCounts = counts

        if let slots = save.sigilLoadoutSlots {
            sigilLoadout = SigilLoadout(slots: slots.map { raw in
                raw.flatMap { SpellID(rawValue: $0) }
            })
        } else {
            sigilLoadout = sigilMastery.defaultLoadout()
        }

        log = []
        append("Welcome back, \(player.name)!", .system)
        if save.phase != "ringIngress" {
            spawnNextEnemy(advance: false)
        }

        switch save.phase {
        case "draft":      phase = .draft
        case "ringChoice": phase = .ringChoice
        case "ringIngress": phase = .ringIngress
        case "levelUp":    phase = .ringChoice
        case "shop":       phase = .shop
        default:           phase = .combat
        }

        grantOffline(since: save.lastSeen)
    }

    /// Grant capped, reduced-rate gold for time spent away. Auto-battle earns
    /// full efficiency; manual runs still get partial credit.
    private func grantOffline(since lastSeen: Date) {
        guard phase == .combat else { return }
        let elapsed = Date().timeIntervalSince(lastSeen)
        guard elapsed > 60 else { return }

        let rate = autoBattle ? offlineEfficiency : Balance.manualOfflineEfficiency
        let effective = min(elapsed, offlineCap)
        let heroDps = Double(max(1, player.attack - enemy.defense))
        let mercDps = Double(mercenaryDPS) * Balance.offlineMercenaryDpsFactor
        let totalDps = heroDps + mercDps
        let killsPerSec = totalDps / Double(max(1, enemy.maxHp))
        let goldPerSec = killsPerSec * Double(max(1, enemy.generateGold()))
        let gold = min(
            Int(goldPerSec * effective * rate * goldMultiplier * relicGoldMultiplier),
            Balance.offlineGoldCap(layer: layer)
        )
        guard gold > 0 else { return }

        let kills = max(1, Int(killsPerSec * effective))
        let mercGold = Int(Double(gold) * (mercDps / totalDps))

        player.addGold(gold)
        runGoldEarned += gold
        lifetime.totalGoldEarned += gold
        lifetime.totalKills += kills
        MetaStore.saveLifetime(lifetime)
        recordRun()
        offlineReport = OfflineReport(gold: gold, duration: elapsed,
                                      creditedDuration: effective,
                                      estimatedKills: kills,
                                      hitCap: elapsed > offlineCap,
                                      wasAutoBattle: autoBattle,
                                      mercenaryGold: mercGold)
        let mode = autoBattle ? "Auto-battle" : "Passive crawl"
        append("\(mode) earned \(Formatting.short(gold)) gold while away. 🪙", .reward)
        handleAchievementEvent(.offlineGold(hitCap: elapsed > offlineCap))
    }

    // MARK: - Records

    /// Roll the current progress into the persisted best run, flagging when this
    /// run set a new record (shown on the game-over screen).
    private func recordRun() {
        var updated = best
        var improved = false
        if layer > updated.layer { updated.layer = layer; improved = true }
        if player.level > updated.level { updated.level = player.level; improved = true }
        if player.gold > updated.gold { updated.gold = player.gold; improved = true }
        if improved {
            best = updated
            best.save()
            setNewRecord = true
            handleAchievementEvent(.runEnded(reason: "record"))
        }
        lifetime.highestRunGold = max(lifetime.highestRunGold, runGoldEarned)
        MetaStore.saveLifetime(lifetime)
    }

    // MARK: - Achievements

    private func achievementContext() -> AchievementContext {
        AchievementContext(
            lifetime: lifetime,
            best: best,
            totalShards: totalShards,
            treeLevels: treeLevels,
            discoveredRelics: discoveredRelics,
            mercenaryCounts: mercenaryCounts,
            equippedRelicCount: equippedRelics.count,
            clearedFinalBoss: clearedFinalBoss,
            firstDeathBeatShown: FirstDeathBeat.hasShown,
            onboardingCompleted: OnboardingSettings.hasCompleted,
            runStats: runStats,
            witness: achievementState.witness,
            masteredSigilCount: sigilMastery.mastered.count,
            weakSigilWitnessed: achievementState.witness.weakSigilLanded || AspectTeachingBeat.hasShownWeak
        )
    }

    private func handleAchievementEvent(_ event: AchievementEvent) {
        switch event {
        case .offlineGold(let hitCap):
            if hitCap { achievementState.witness.idleCapHit = true }
        case .critLanded:
            achievementState.witness.firstCritLanded = true
        case .survivedBigHit:
            achievementState.witness.survivedBigHit = true
        case .autoAscended:
            achievementState.witness.autoWithdrawUsed = true
        case .sigilWeakHit:
            achievementState.witness.weakSigilLanded = true
        default:
            break
        }

        let ctx = achievementContext()
        let result = AchievementEvaluator.shared.evaluate(
            event: event,
            context: ctx,
            from: achievementState
        )
        achievementState = result.state
        guard !result.unlocked.isEmpty else {
            MetaStore.saveAchievements(achievementState)
            return
        }
        MetaStore.saveAchievements(achievementState)
        deliverAchievementUnlocks(result.unlocked)
    }

    private func deliverAchievementUnlocks(_ ids: [AchievementID]) {
        for id in ids {
            if let def = AchievementEvaluator.shared.definition(for: id) {
                GameAnalytics.track(.achievementUnlocked(
                    id: id.rawValue,
                    category: def.category.rawValue
                ))
            }
            if let beat = Narrative.Achievement.beat(for: id) {
                append(Narrative.text(for: beat), .system)
            }
        }
        achievementUnlockQueue.append(contentsOf: ids)
        presentNextAchievementToast()
    }

    private func presentNextAchievementToast() {
        guard pendingAchievementUnlock == nil, !achievementUnlockQueue.isEmpty else { return }
        pendingAchievementUnlock = achievementUnlockQueue.removeFirst()
        Haptics.play(.success)
        SoundManager.shared.play(.purchase)
    }

    func dismissAchievementUnlockToast() {
        pendingAchievementUnlock = nil
        presentNextAchievementToast()
    }

    func dismissAchievementBackfillSummary() {
        achievementBackfillCount = nil
        achievementState.dismissBackfillSummary()
        MetaStore.saveAchievements(achievementState)
    }

    func markAchievementsViewed() {
        guard achievementState.hasUnread else { return }
        achievementState.markViewed()
        MetaStore.saveAchievements(achievementState)
    }

    func achievementProgress(for id: AchievementID) -> (current: Int, target: Int)? {
        AchievementEvaluator.shared.progress(for: id, in: achievementContext())
    }

    // MARK: - Log + animation helpers

    /// Publish a floating combat number/word. The view animates and then calls
    /// `clearPopup(_:)` to remove it (only if it's still the same one).
    private func showPopup(_ text: String, _ flavor: CombatPopup.Flavor, onPlayer: Bool) {
        popup = CombatPopup(text: text, flavor: flavor, onPlayer: onPlayer)
    }

    func clearPopup(_ id: UUID) {
        if popup?.id == id { popup = nil }
    }

    private func append(_ text: String, _ kind: LogLine.Kind, spacedAbove: Bool = false) {
        log.append(LogLine(text: text, kind: kind, spacedAbove: spacedAbove))
        if log.count > 80 { log.removeFirst(log.count - 80) }
    }

    /// Keep the log readable across layer transitions — retain recent context only.
    private func trimLogForNewLayer() {
        log = Array(log.suffix(6))
        append("—", .system, spacedAbove: true)
    }

    private func flashEnemy() {
        enemyFlash = true
        shakeTrigger += 1
        Haptics.play(.light)
    }

    private func flashPlayer() {
        playerFlash = true
        shakeTrigger += 1
        Haptics.play(.heavy)
        SoundManager.shared.play(.playerHurt)
    }
}
