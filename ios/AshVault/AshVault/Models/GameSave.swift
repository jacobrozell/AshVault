import Foundation

/// Serializable snapshot of an in-progress run, persisted to `UserDefaults` so
/// the hybrid idle loop survives app close (and powers offline progress).
///
/// Transient combat detail (the current enemy, status effects, popup/log) is
/// intentionally *not* saved — on resume we rebuild a fresh enemy at the saved
/// layer/index. `BestRun` persists separately.
struct GameSave: Codable {
    var version = 5

    // Player
    var name: String
    var hp: Int
    var maxHp: Int
    var attack: Int
    var maxAttack: Int
    var defense: Int
    var maxDefense: Int
    var luck: Int
    var level: Int
    var gold: Int
    var mana: Int
    var maxMana: Int
    var potions: Int
    var ethers: Int
    var phoenixAshes: Int? = nil

    // Run meta
    var layer: Int
    var enemyIndex: Int
    var scaleLevel: Int
    var clearedFinalBoss: Bool
    var victoryShown: Bool
    var purchaseCounts: [String: Int]   // ShopItem.rawValue → count
    var phase: String                   // restorable: combat/draft/ringChoice/shop
    var autoBattle: Bool
    var runGoldEarned: Int
    /// Equipped sigil slots (`SpellID.rawValue` or nil).
    var sigilLoadoutSlots: [String?]? = nil
    var awaitingRingAdvance: Bool? = nil
    var killsSinceDraft: Int? = nil
    var bossKillsThisRun: Int? = nil
    var draftOptionRawValues: [String]? = nil
    var supplies: Int? = nil
    var ringModifierRaw: String? = nil
    var doorOfferKinds: [String]? = nil
    var nextSpawnIsElite: Bool? = nil
    var runBuildJSON: Data? = nil
    var draftPickIDs: [String]? = nil

    var lastSeen: Date
}

/// Summary of progress while the app was closed, shown on resume.
struct OfflineReport: Identifiable {
    let id = UUID()
    let gold: Int
    /// Wall-clock time away.
    let duration: TimeInterval
    /// Time actually credited toward earnings (≤ `offlineCap`).
    let creditedDuration: TimeInterval
    let estimatedKills: Int
    let hitCap: Bool
    let wasAutoBattle: Bool
    let mercenaryGold: Int
}

/// Save-slot persistence (single slot). JSON in `UserDefaults`.
enum SaveStore {
    private static let key = "save.run.v1"

    static func write(_ save: GameSave) {
        guard let data = try? JSONEncoder().encode(save) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func read() -> GameSave? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let save = try? JSONDecoder().decode(GameSave.self, from: data) else { return nil }
        return save
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

/// Persisted prestige meta — survives death and new runs.
/// `load`/`save` handle cumulative Ash Shards earned; `loadTree`/`saveTree`
/// handle the spent skill-tree levels.
enum PrestigeStore {
    private static let shardsKey = "prestige.shards.v1"
    private static let treeKey = "prestige.tree.v1"

    static func load() -> Int { UserDefaults.standard.integer(forKey: shardsKey) }
    static func save(_ shards: Int) { UserDefaults.standard.set(shards, forKey: shardsKey) }

    static func loadTree() -> [String: Int] {
        (UserDefaults.standard.dictionary(forKey: treeKey) as? [String: Int]) ?? [:]
    }
    static func saveTree(_ levels: [String: Int]) {
        UserDefaults.standard.set(levels, forKey: treeKey)
    }
}
