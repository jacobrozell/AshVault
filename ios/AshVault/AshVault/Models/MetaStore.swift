import Foundation

/// Long-term meta that survives runs, deaths, and prestige resets.
///
/// Spec: `ios/docs/game-design-spec.md` §6–8
enum MetaStore {
    private static let mercenariesKey = "meta.mercenaries.v1"
    private static let discoveredRelicsKey = "meta.relics.discovered.v1"
    private static let equippedRelicsKey = "meta.relics.equipped.v1"
    private static let lifetimeKey = "meta.lifetime.v1"
    private static let achievementsKey = "meta.achievements.v1"
    private static let sigilsKey = "meta.sigils.v1"
    private static let delverOathKey = "meta.delverOath.v1"
    private static let codexKey = "meta.codex.v1"

    // MARK: Mercenaries

    static func loadMercenaryCounts() -> [String: Int] {
        (UserDefaults.standard.dictionary(forKey: mercenariesKey) as? [String: Int]) ?? [:]
    }

    static func saveMercenaryCounts(_ counts: [String: Int]) {
        UserDefaults.standard.set(counts, forKey: mercenariesKey)
    }

    // MARK: Relics

    static func loadDiscoveredRelics() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: discoveredRelicsKey) ?? [])
    }

    static func saveDiscoveredRelics(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: discoveredRelicsKey)
    }

    static func loadEquippedRelics() -> [String] {
        Array((UserDefaults.standard.stringArray(forKey: equippedRelicsKey) ?? []).prefix(Balance.maxEquippedRelics))
    }

    static func saveEquippedRelics(_ ids: [String]) {
        UserDefaults.standard.set(Array(ids.prefix(Balance.maxEquippedRelics)), forKey: equippedRelicsKey)
    }

    // MARK: Lifetime stats

    static func loadLifetime() -> LifetimeStats {
        guard let data = UserDefaults.standard.data(forKey: lifetimeKey),
              let stats = try? JSONDecoder().decode(LifetimeStats.self, from: data) else {
            return .empty
        }
        return stats
    }

    static func saveLifetime(_ stats: LifetimeStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: lifetimeKey)
    }

    // MARK: Achievements

    static func loadAchievements() -> AchievementState {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey),
              let state = try? JSONDecoder().decode(AchievementState.self, from: data) else {
            return .empty
        }
        return state
    }

    static func saveAchievements(_ state: AchievementState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: achievementsKey)
    }

    // MARK: Sigils

    static func loadSigilMastery() -> SigilMastery {
        guard let data = UserDefaults.standard.data(forKey: sigilsKey),
              let mastery = try? JSONDecoder().decode(SigilMastery.self, from: data) else {
            return .starter
        }
        return mastery.mastered.isEmpty ? .starter : mastery
    }

    static func saveSigilMastery(_ mastery: SigilMastery) {
        guard let data = try? JSONEncoder().encode(mastery) else { return }
        UserDefaults.standard.set(data, forKey: sigilsKey)
    }

    // MARK: Delver oath

    static func loadDelverOath() -> DelverOath? {
        guard let raw = UserDefaults.standard.string(forKey: delverOathKey) else { return nil }
        return DelverOath(rawValue: raw)
    }

    static func saveDelverOath(_ oath: DelverOath) {
        UserDefaults.standard.set(oath.rawValue, forKey: delverOathKey)
    }

    // MARK: Codex

    static func loadDiscoveredCodex() -> Set<CodexID> {
        let raw = UserDefaults.standard.stringArray(forKey: codexKey) ?? []
        return Set(raw.compactMap { CodexID(rawValue: $0) })
    }

    static func saveDiscoveredCodex(_ ids: Set<CodexID>) {
        UserDefaults.standard.set(ids.map(\.rawValue), forKey: codexKey)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: mercenariesKey)
        UserDefaults.standard.removeObject(forKey: discoveredRelicsKey)
        UserDefaults.standard.removeObject(forKey: equippedRelicsKey)
        UserDefaults.standard.removeObject(forKey: lifetimeKey)
        UserDefaults.standard.removeObject(forKey: achievementsKey)
        UserDefaults.standard.removeObject(forKey: sigilsKey)
        UserDefaults.standard.removeObject(forKey: delverOathKey)
        UserDefaults.standard.removeObject(forKey: codexKey)
        OnboardingSettings.reset()
        FirstDeathBeat.reset()
    }
}

/// First-run onboarding completion flag (global).
/// One-shot tone-setting beat on the player's first death.
enum FirstDeathBeat {
    private static let key = "beat.firstDeathShown"

    static var hasShown: Bool { UserDefaults.standard.bool(forKey: key) }

    static func markShown() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

enum OnboardingSettings {
    private static let completedKey = "onboarding.completed.v1"

    static var hasCompleted: Bool { UserDefaults.standard.bool(forKey: completedKey) }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: completedKey)
    }
}

/// Cumulative counters for the museum / future achievements screen.
struct LifetimeStats: Codable, Equatable {
    var totalGoldEarned: Int
    var totalKills: Int
    var totalBossKills: Int
    var totalDescents: Int
    var relicsFound: Int
    var totalDeaths: Int
    var totalRevives: Int
    var totalRunsStarted: Int
    var deepestLayer: Int
    var highestRunGold: Int
    var phoenixAshesBought: Int

    static let empty = LifetimeStats(
        totalGoldEarned: 0,
        totalKills: 0,
        totalBossKills: 0,
        totalDescents: 0,
        relicsFound: 0,
        totalDeaths: 0,
        totalRevives: 0,
        totalRunsStarted: 0,
        deepestLayer: 0,
        highestRunGold: 0,
        phoenixAshesBought: 0
    )

    init(totalGoldEarned: Int,
         totalKills: Int,
         totalBossKills: Int,
         totalDescents: Int,
         relicsFound: Int,
         totalDeaths: Int,
         totalRevives: Int,
         totalRunsStarted: Int,
         deepestLayer: Int,
         highestRunGold: Int,
         phoenixAshesBought: Int) {
        self.totalGoldEarned = totalGoldEarned
        self.totalKills = totalKills
        self.totalBossKills = totalBossKills
        self.totalDescents = totalDescents
        self.relicsFound = relicsFound
        self.totalDeaths = totalDeaths
        self.totalRevives = totalRevives
        self.totalRunsStarted = totalRunsStarted
        self.deepestLayer = deepestLayer
        self.highestRunGold = highestRunGold
        self.phoenixAshesBought = phoenixAshesBought
    }

    private enum CodingKeys: String, CodingKey {
        case totalGoldEarned
        case totalKills
        case totalBossKills
        case totalDescents
        case relicsFound
        case totalDeaths
        case totalRevives
        case totalRunsStarted
        case deepestLayer
        case highestRunGold
        case phoenixAshesBought
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalGoldEarned = try container.decodeIfPresent(Int.self, forKey: .totalGoldEarned) ?? 0
        totalKills = try container.decodeIfPresent(Int.self, forKey: .totalKills) ?? 0
        totalBossKills = try container.decodeIfPresent(Int.self, forKey: .totalBossKills) ?? 0
        totalDescents = try container.decodeIfPresent(Int.self, forKey: .totalDescents) ?? 0
        relicsFound = try container.decodeIfPresent(Int.self, forKey: .relicsFound) ?? 0
        totalDeaths = try container.decodeIfPresent(Int.self, forKey: .totalDeaths) ?? 0
        totalRevives = try container.decodeIfPresent(Int.self, forKey: .totalRevives) ?? 0
        totalRunsStarted = try container.decodeIfPresent(Int.self, forKey: .totalRunsStarted) ?? 0
        deepestLayer = try container.decodeIfPresent(Int.self, forKey: .deepestLayer) ?? 0
        highestRunGold = try container.decodeIfPresent(Int.self, forKey: .highestRunGold) ?? 0
        phoenixAshesBought = try container.decodeIfPresent(Int.self, forKey: .phoenixAshesBought) ?? 0
    }
}

/// Auto-descend preferences (global, not per-run).
enum AutoDescendSettings {
    private static let enabledKey = "autoDescend.enabled"
    private static let minShardsKey = "autoDescend.minShards"

    static var enabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    static var minShards: Int {
        let stored = UserDefaults.standard.integer(forKey: minShardsKey)
        return stored > 0 ? stored : Balance.autoDescendDefaultMinShards
    }

    static func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: enabledKey)
    }

    static func setMinShards(_ n: Int) {
        UserDefaults.standard.set(max(1, n), forKey: minShardsKey)
    }
}
