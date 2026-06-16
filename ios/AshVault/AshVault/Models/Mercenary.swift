import Foundation

/// Meta generators hired at the Camp. Ownership persists across runs; each hire
/// adds flat DPS (combat + offline) and scales with milestone multipliers.
///
/// Spec: `ios/docs/game-design-spec.md` §6.1
enum Mercenary: String, CaseIterable, Identifiable {
    case goblinSlayer
    case archer
    case mage
    case cleric
    case knight

    var id: String { rawValue }

    var name: String {
        switch self {
        case .goblinSlayer: return "Goblin Slayer"
        case .archer:       return "Archer"
        case .mage:         return "Mage"
        case .cleric:       return "Cleric"
        case .knight:       return "Knight"
        }
    }

    var icon: String {
        switch self {
        case .goblinSlayer: return "🗡️"
        case .archer:       return "🏹"
        case .mage:         return "🧙"
        case .cleric:       return "✨"
        case .knight:       return "🛡️"
        }
    }

    var blurb: String {
        switch self {
        case .goblinSlayer: return "Cheap fodder-clearer."
        case .archer:       return "Steady ranged DPS."
        case .mage:         return "Strong arcane damage."
        case .cleric:       return "Supportive strikes."
        case .knight:       return "Elite heavy hitter."
        }
    }

    /// AshVault flavor for the mercenary camp.
    var lore: String {
        switch self {
        case .goblinSlayer: return "First to answer the vault's call."
        case .archer:       return "Fires down the stairwell by torchlight."
        case .mage:         return "Reads the ash like scripture."
        case .cleric:       return "Blesses blades before each descent."
        case .knight:       return "Veteran of a dozen failed seals."
        }
    }

    var baseCost: Int {
        switch self {
        case .goblinSlayer: return 50
        case .archer:       return 200
        case .mage:         return 800
        case .cleric:       return 3_000
        case .knight:       return 12_000
        }
    }

    var baseDPS: Int {
        switch self {
        case .goblinSlayer: return 2
        case .archer:       return 8
        case .mage:         return 35
        case .cleric:       return 120
        case .knight:       return 500
        }
    }

    /// Shard cost to hire the next copy (`baseCost · r^owned`).
    func cost(owned: Int) -> Int {
        Int((Double(baseCost) * pow(Balance.mercenaryPriceGrowth, Double(owned))).rounded())
    }

    /// Total DPS from `count` hires, including milestone doubles.
    func dps(count: Int) -> Int {
        guard count > 0 else { return 0 }
        let mult = Self.milestoneMultiplier(count: count)
        return Int((Double(baseDPS * count) * mult).rounded())
    }

    /// ×2 output at each milestone threshold (classic idle generator pattern).
    static func milestoneMultiplier(count: Int) -> Double {
        var mult = 1.0
        for threshold in Balance.mercenaryMilestones where count >= threshold {
            mult *= 2
        }
        return mult
    }

    /// Next milestone count for UI hints (nil if past all thresholds).
    static func nextMilestone(after count: Int) -> Int? {
        Balance.mercenaryMilestones.first { $0 > count }
    }
}
