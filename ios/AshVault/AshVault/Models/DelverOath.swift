import Foundation

/// Survivor-crawl class oath — chosen at the start of each delve.
enum DelverOath: String, CaseIterable, Codable, Identifiable {
    case hound
    case mast
    case kite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hound: return "Hound Oath"
        case .mast:  return "Mast Oath"
        case .kite:  return "Kite Oath"
        }
    }

    var icon: String {
        switch self {
        case .hound: return "pawprint.fill"
        case .mast:  return "shield.lefthalf.filled"
        case .kite:  return "wind"
        }
    }

    /// One-line perk summary for the picker.
    var perkSummary: String {
        switch self {
        case .hound: return "+10% damage vs wounded foes"
        case .mast:  return "Camp rest grants +5% max HP"
        case .kite:  return "Scouts the next ring's modifier early"
        }
    }

    /// Stat line shown under the oath card.
    var statLine: String {
        switch self {
        case .hound: return "+3 Attack"
        case .mast:  return "+15 max HP, +3 Defense"
        case .kite:  return "Luck −1, −8 max HP"
        }
    }

    var flavor: String {
        switch self {
        case .hound:
            return "You swear to finish what the vault started — wounded things do not walk away."
        case .mast:
            return "You swear to hold the line. The camp remembers who still stands."
        case .kite:
            return "You swear to read the ash before the doors open. Speed over bulk."
        }
    }

    /// Apply starting stat shifts after prestige bonuses.
    func apply(to player: Player) {
        switch self {
        case .hound:
            player.boostAttack(Balance.oathHoundAttackBonus)
        case .mast:
            player.boostMaxHp(Balance.oathMastHpBonus, heal: true)
            player.boostDefense(Balance.oathMastDefenseBonus)
        case .kite:
            player.improveLuck(steps: Balance.oathKiteLuckSteps)
            player.boostMaxHp(-Balance.oathKiteHpPenalty, heal: false)
        }
    }

    /// Extra draft weight for stat picks that match the oath.
    func draftStatWeightBonus(for stat: DraftOption) -> Int {
        switch (self, stat) {
        case (.hound, .sharpBlade), (.hound, .luckyStrike): return 6
        case (.mast, .ironSkin), (.mast, .heartOfAsh):     return 6
        case (.kite, .luckyStrike), (.kite, .arcaneWell):  return 4
        default: return 0
        }
    }

    /// Extra draft weight for relic/tune synergies that match the oath.
    func draftSynergyWeightBonus(for tag: SynergyTag) -> Int {
        switch (self, tag) {
        case (.hound, .crit):              return 3
        case (.mast, .ward), (.mast, .thorns): return 3
        case (.kite, .crit), (.kite, .greed):  return 3
        default: return 0
        }
    }
}
