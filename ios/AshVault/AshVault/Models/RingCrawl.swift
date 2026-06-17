import Foundation

/// Procedural crawl layer: ring-wide modifier + ingress door offers.
enum RingModifier: String, CaseIterable, Codable, Identifiable {
    case ashGreed
    case brittleSeal
    case hoardersToll
    case quietRing
    case fungalRing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ashGreed:      return "Ash Greed"
        case .brittleSeal:   return "Brittle Seal"
        case .hoardersToll:  return "Hoarder's Toll"
        case .quietRing:     return "Quiet Ring"
        case .fungalRing:    return "Fungal Ring"
        }
    }

    var blurb: String {
        switch self {
        case .ashGreed:      return "+35% gold this ring"
        case .brittleSeal:   return "Enemy attacks +15%"
        case .hoardersToll:  return "Camp −25% prices; warden +25% HP"
        case .quietRing:     return "+2 kills per draft"
        case .fungalRing:    return "Enemy HP +10%"
        }
    }

    var icon: String {
        switch self {
        case .ashGreed:      return "dollarsign.circle.fill"
        case .brittleSeal:   return "exclamationmark.triangle.fill"
        case .hoardersToll:  return "bag.fill"
        case .quietRing:     return "moon.fill"
        case .fungalRing:    return "leaf.fill"
        }
    }
}

/// Ingress door — first encounter bias for the ring.
enum DoorKind: String, CaseIterable, Codable, Identifiable {
    case guardPatrol
    case elite
    case shrine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guardPatrol: return "Guard Patrol"
        case .elite:       return "Elite Guard"
        case .shrine:      return "Ash Shrine"
        }
    }

    var subtitle: String {
        switch self {
        case .guardPatrol: return "Standard fight"
        case .elite:       return "Tougher foe · bonus gold"
        case .shrine:      return "Heal · skip a fight"
        }
    }

    var icon: String {
        switch self {
        case .guardPatrol: return "shield.fill"
        case .elite:       return "flame.fill"
        case .shrine:      return "flame.circle.fill"
        }
    }
}

struct DoorOffer: Identifiable, Equatable, Codable {
    var id: String { kind.rawValue }
    let kind: DoorKind
}

enum RingCrawl {

    static func rollModifier(rng: RandomSource) -> RingModifier {
        rng.element(RingModifier.allCases) ?? .brittleSeal
    }

    /// Two distinct door offers; ring depth biases toward risk on deeper rings.
    static func rollDoors(ring: Int, rng: RandomSource) -> [DoorOffer] {
        var pool = DoorKind.allCases
        var offers: [DoorOffer] = []
        let wantElite = ring >= 4 && rng.chance(40)
        if wantElite, let elite = pool.first(where: { $0 == .elite }) {
            offers.append(DoorOffer(kind: elite))
            pool.removeAll { $0 == .elite }
        }
        while offers.count < 2, let kind = rng.element(pool) {
            offers.append(DoorOffer(kind: kind))
            pool.removeAll { $0 == kind }
        }
        if offers.count < 2 {
            offers.append(DoorOffer(kind: .guardPatrol))
        }
        return offers
    }

    static func draftKillsNeeded(base: Int, modifier: RingModifier?) -> Int {
        guard modifier == .quietRing else { return base }
        return base + Balance.quietRingExtraDraftKills
    }

    static func goldMultiplier(modifier: RingModifier?) -> Double {
        modifier == .ashGreed ? Balance.ashGreedGoldBonus : 1.0
    }

    static func campPriceMultiplier(modifier: RingModifier?) -> Double {
        modifier == .hoardersToll ? Balance.hoardersTollShopDiscount : 1.0
    }

    /// Apply ring modifier + elite flag to a freshly spawned enemy.
    static func applyEncounterModifiers(
        to enemy: Enemy,
        modifier: RingModifier?,
        elite: Bool,
        isWarden: Bool,
        suppliesStarved: Bool
    ) {
        var hpMult = 1.0
        var atkMult = 1.0

        if modifier == .brittleSeal { atkMult *= 1.0 + Double(Balance.brittleSealEnemyAtkPercent) / 100.0 }
        if modifier == .fungalRing { hpMult *= 1.0 + Double(Balance.fungalRingEnemyHpPercent) / 100.0 }
        if modifier == .hoardersToll, isWarden {
            hpMult *= 1.0 + Double(Balance.hoardersTollWardenHpPercent) / 100.0
        }
        if elite, !isWarden {
            hpMult *= 1.0 + Double(Balance.eliteEncounterHpPercent) / 100.0
            atkMult *= 1.0 + Double(Balance.eliteEncounterAtkPercent) / 100.0
        }
        if suppliesStarved {
            atkMult *= 1.0 + Double(Balance.supplyStarvedEnemyAtkPercent) / 100.0
        }

        enemy.scaleStats(hpMultiplier: hpMult, atkMultiplier: atkMult)
    }
}
