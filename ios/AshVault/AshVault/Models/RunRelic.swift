import Foundation

/// Synergy tags for run relics and draft weighting.
enum SynergyTag: String, CaseIterable, Codable, Identifiable {
    case burn, frost, poison, crit, thorns, greed, ward

    var id: String { rawValue }

    var label: String {
        switch self {
        case .burn:   return "Burn"
        case .frost:  return "Frost"
        case .poison: return "Poison"
        case .crit:   return "Crit"
        case .thorns: return "Thorns"
        case .greed:  return "Greed"
        case .ward:   return "Ward"
        }
    }

    var icon: String {
        switch self {
        case .burn:   return "flame.fill"
        case .frost:  return "snowflake"
        case .poison: return "drop.triangle.fill"
        case .crit:   return "sparkles"
        case .thorns: return "leaf.fill"
        case .greed:  return "dollarsign.circle.fill"
        case .ward:   return "shield.fill"
        }
    }
}

/// In-run passive items — up to `Balance.maxRunRelics` held; all active at once.
/// Dropped by wardens; separate from gallery `Relic` trophies.
enum RunRelic: String, CaseIterable, Identifiable, Codable {
    case cinderHeart
    case coalTinder
    case frostCrown
    case rimeShard
    case venomPouch
    case luckyFlint
    case thornLattice
    case greedSeal
    case ashWard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cinderHeart:  return "Cinder Heart"
        case .coalTinder:   return "Coal Tinder"
        case .frostCrown:   return "Frost Crown"
        case .rimeShard:    return "Rime Shard"
        case .venomPouch:   return "Venom Pouch"
        case .luckyFlint:   return "Lucky Flint"
        case .thornLattice: return "Thorn Lattice"
        case .greedSeal:    return "Greed Seal"
        case .ashWard:      return "Ash Ward"
        }
    }

    var icon: String {
        switch self {
        case .cinderHeart:  return "heart.fill"
        case .coalTinder:   return "flame.circle.fill"
        case .frostCrown:   return "crown.fill"
        case .rimeShard:    return "snowflake"
        case .venomPouch:   return "drop.triangle.fill"
        case .luckyFlint:   return "sparkle"
        case .thornLattice: return "leaf.fill"
        case .greedSeal:    return "seal.fill"
        case .ashWard:      return "shield.lefthalf.filled"
        }
    }

    var blurb: String {
        switch self {
        case .cinderHeart:  return "Burn ticks deal double damage."
        case .coalTinder:   return "+15% Ember burn chance."
        case .frostCrown:   return "First hit each fight chills the foe."
        case .rimeShard:    return "Frost sigils deal +20% damage."
        case .venomPouch:   return "Poison lasts +1 turn."
        case .luckyFlint:   return "+5% crit chance."
        case .thornLattice: return "Thorns damage +50%."
        case .greedSeal:    return "+40% gold from kills."
        case .ashWard:      return "Take 5% less damage."
        }
    }

    var synergy: SynergyTag {
        switch self {
        case .cinderHeart, .coalTinder: return .burn
        case .frostCrown, .rimeShard:     return .frost
        case .venomPouch:                 return .poison
        case .luckyFlint:                 return .crit
        case .thornLattice:               return .thorns
        case .greedSeal:                  return .greed
        case .ashWard:                    return .ward
        }
    }

    var anchor: AnchorTag {
        switch self {
        case .cinderHeart, .coalTinder: return .flesh
        case .frostCrown, .rimeShard:   return .earth
        case .venomPouch:               return .flesh
        case .luckyFlint:               return .sky
        case .thornLattice:             return .earth
        case .greedSeal:                return .civic
        case .ashWard:                  return .civic
        }
    }

    /// Map equipped sigils to synergy tags for draft weighting.
    static func tags(for spell: SpellID) -> Set<SynergyTag> {
        switch spell {
        case .emberBolt:  return [.burn]
        case .frostShard: return [.frost]
        case .venomLash:  return [.poison]
        case .arcLance:   return [.crit]
        }
    }
}
