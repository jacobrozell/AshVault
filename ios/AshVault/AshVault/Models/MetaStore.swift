import Foundation

/// Long-term meta that survives runs, deaths, and prestige resets.
///
/// Spec: `ios/docs/game-design-spec.md` §6–8
enum MetaStore {
    private static let mercenariesKey = "meta.mercenaries.v1"
    private static let discoveredRelicsKey = "meta.relics.discovered.v1"
    private static let equippedRelicsKey = "meta.relics.equipped.v1"
    private static let lifetimeKey = "meta.lifetime.v1"

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

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: mercenariesKey)
        UserDefaults.standard.removeObject(forKey: discoveredRelicsKey)
        UserDefaults.standard.removeObject(forKey: equippedRelicsKey)
        UserDefaults.standard.removeObject(forKey: lifetimeKey)
    }
}

/// Cumulative counters for the museum / future achievements screen.
struct LifetimeStats: Codable, Equatable {
    var totalGoldEarned: Int
    var totalKills: Int
    var totalBossKills: Int
    var totalDescents: Int
    var relicsFound: Int

    static let empty = LifetimeStats(totalGoldEarned: 0, totalKills: 0,
                                     totalBossKills: 0, totalDescents: 0, relicsFound: 0)
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
