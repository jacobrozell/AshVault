import Foundation

/// Run-scoped draft pick (survivor-style level-up). Phase 1: stat boosts only.
enum DraftOption: String, CaseIterable, Identifiable, Equatable, Codable {
    case sharpBlade
    case ironSkin
    case heartOfAsh
    case luckyStrike
    case arcaneWell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharpBlade:   return "Sharp Blade"
        case .ironSkin:     return "Iron Skin"
        case .heartOfAsh:   return "Heart of Ash"
        case .luckyStrike:  return "Lucky Strike"
        case .arcaneWell:   return "Arcane Well"
        }
    }

    var icon: String {
        switch self {
        case .sharpBlade:   return "burst.fill"
        case .ironSkin:     return "shield.lefthalf.filled"
        case .heartOfAsh:   return "heart.fill"
        case .luckyStrike:  return "sparkles"
        case .arcaneWell:   return "drop.fill"
        }
    }

    var blurb: String {
        switch self {
        case .sharpBlade:   return "+10 Attack"
        case .ironSkin:     return "+8 Defense"
        case .heartOfAsh:   return "+25 max HP, heal to full"
        case .luckyStrike:  return "Luck −1 (easier hits & crits)"
        case .arcaneWell:   return "+10 max Mana, refill"
        }
    }
}

enum RunDraft {

    static func rollOptions(rng: RandomSource, count: Int = 3) -> [DraftOption] {
        var pool = DraftOption.allCases
        var picks: [DraftOption] = []
        while picks.count < count, let pick = rng.element(pool) {
            picks.append(pick)
            pool.removeAll { $0 == pick }
        }
        return picks
    }

    static func apply(_ option: DraftOption, to player: Player) {
        switch option {
        case .sharpBlade:
            player.boostAttack(Balance.draftAttackBonus)
        case .ironSkin:
            player.boostDefense(Balance.draftDefenseBonus)
        case .heartOfAsh:
            player.boostMaxHp(Balance.draftHpBonus, heal: true)
        case .luckyStrike:
            player.improveLuck()
        case .arcaneWell:
            player.boostMana(Balance.draftManaBonus, refill: true)
        }
    }

    static func killsNeeded(forRing layer: Int) -> Int {
        max(Balance.killsPerDraftMin,
            Balance.killsPerDraftBase - (layer - 1) / Balance.killsPerDraftRingStep)
    }
}
