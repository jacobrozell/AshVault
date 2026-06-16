import Foundation

/// Offensive sigil identity — replaces the single Magic Bolt move.
enum SpellID: String, CaseIterable, Codable, Identifiable {
    case emberBolt
    case frostShard
    case venomLash
    case arcLance

    var id: String { rawValue }
}

/// How a sigil is cast; v1 is always instant; rune trace ships later.
enum CastingStyle: Equatable {
    case instant
}

struct SpellDefinition: Equatable {
    let id: SpellID
    let displayName: String
    let subtitle: String
    let element: Element
    let manaCost: Int
    let flatBonus: Int
    let ignoresDefense: Bool
    let burnChancePercent: Int?
    let castingStyle: CastingStyle
    /// `nil` = not sold (starter sigil).
    let shopScrollPrice: Int?
}

enum SpellCatalog {

    static let all: [SpellDefinition] = [.emberBolt, .frostShard, .venomLash, .arcLance]

    static func definition(for id: SpellID) -> SpellDefinition {
        switch id {
        case .emberBolt:  return .emberBolt
        case .frostShard: return .frostShard
        case .venomLash:  return .venomLash
        case .arcLance:   return .arcLance
        }
    }

    static var shopScrolls: [SpellID] {
        all.compactMap { def in def.shopScrollPrice != nil ? def.id : nil }
    }

    /// Scrolls the auto-shop may purchase (arc is manual opt-in — expensive).
    static var autoShopScrolls: [SpellID] {
        [.frostShard]
    }
}

extension SpellDefinition {

    static let emberBolt = SpellDefinition(
        id: .emberBolt,
        displayName: "Ember Bolt",
        subtitle: "Sears · may burn",
        element: .ember,
        manaCost: Balance.emberBoltManaCost,
        flatBonus: Balance.emberBoltFlatBonus,
        ignoresDefense: true,
        burnChancePercent: Balance.emberBurnChancePercent,
        castingStyle: .instant,
        shopScrollPrice: nil
    )

    static let frostShard = SpellDefinition(
        id: .frostShard,
        displayName: "Frost Shard",
        subtitle: "Piercing cold",
        element: .frost,
        manaCost: Balance.frostShardManaCost,
        flatBonus: Balance.frostShardFlatBonus,
        ignoresDefense: true,
        burnChancePercent: nil,
        castingStyle: .instant,
        shopScrollPrice: Balance.frostShardScrollPrice
    )

    static let venomLash = SpellDefinition(
        id: .venomLash,
        displayName: "Venom Lash",
        subtitle: "Toxic strike · stacks poison",
        element: .venom,
        manaCost: Balance.venomLashManaCost,
        flatBonus: Balance.venomLashFlatBonus,
        ignoresDefense: true,
        burnChancePercent: nil,
        castingStyle: .instant,
        shopScrollPrice: Balance.venomLashScrollPrice
    )

    static let arcLance = SpellDefinition(
        id: .arcLance,
        displayName: "Arc Lance",
        subtitle: "Heavy arcane burst",
        element: .arc,
        manaCost: Balance.arcLanceManaCost,
        flatBonus: Balance.arcLanceFlatBonus,
        ignoresDefense: true,
        burnChancePercent: nil,
        castingStyle: .instant,
        shopScrollPrice: Balance.arcLanceScrollPrice
    )
}

/// Three Pokémon-style sigil slots; `nil` = vacant.
struct SigilLoadout: Codable, Equatable {
    static let slotCount = 3

    var slots: [SpellID?]

    init(slots: [SpellID?] = [nil, nil, nil]) {
        var padded = Array(slots.prefix(Self.slotCount))
        while padded.count < Self.slotCount { padded.append(nil) }
        self.slots = padded
    }

    var equipped: [SpellID] { slots.compactMap { $0 } }
}

/// Sigils permanently learned across runs.
struct SigilMastery: Codable, Equatable {
    var mastered: Set<SpellID>

    static let starter = SigilMastery(mastered: [.emberBolt])

    func defaultLoadout() -> SigilLoadout {
        SigilLoadout(slots: [.emberBolt, nil, nil])
    }
}
