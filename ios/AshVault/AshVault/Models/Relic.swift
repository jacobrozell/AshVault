import Foundation

/// Permanent gallery trophies (meta). Small passives when equipped in the museum.
/// Run-scoped power comes from `RunRelic` drops during crawls.
enum Relic: String, CaseIterable, Identifiable, Codable {
    case luckyCharm
    case goldTooth
    case vampiricFang
    case thornMail
    case manaStone
    case ironHeart

    var id: String { rawValue }

    var name: String {
        switch self {
        case .luckyCharm:   return "Lucky Charm"
        case .goldTooth:    return "Gold Tooth"
        case .vampiricFang: return "Vampiric Fang"
        case .thornMail:    return "Thorn Mail"
        case .manaStone:    return "Mana Stone"
        case .ironHeart:    return "Iron Heart"
        }
    }

    var icon: String {
        switch self {
        case .luckyCharm:   return "🍀"
        case .goldTooth:    return "🦷"
        case .vampiricFang: return "🧛"
        case .thornMail:    return "🌵"
        case .manaStone:    return "💎"
        case .ironHeart:    return "💠"
        }
    }

    var blurb: String {
        switch self {
        case .luckyCharm:   return "+8% crit chance."
        case .goldTooth:    return "+12% gold earned."
        case .vampiricFang: return "Heal 6% of damage dealt."
        case .thornMail:    return "Reflect 10% of damage taken."
        case .manaStone:    return "+1 mana regen per turn."
        case .ironHeart:    return "+8% starting max HP."
        }
    }

    /// AshVault flavor for the gallery (not shown in combat).
    var lore: String {
        switch self {
        case .luckyCharm:   return "A gambler's luck, frozen in ash."
        case .goldTooth:    return "Looted from a treasury warden's grin."
        case .vampiricFang: return "Still thirsty after all these years."
        case .thornMail:    return "Barbed ash-mail from a sealed ring."
        case .manaStone:    return "Warm crystal from a mage-warden's vault."
        case .ironHeart:    return "The last beat of an iron sentinel."
        }
    }
}
