import Foundation

/// Run-scoped build state: relics, evolutions, synergy counters.
struct RunBuild: Equatable, Codable {
    var runRelics: [RunRelic] = []
    /// Spell rawValue → evolution rawValue.
    var evolved: [String: String] = [:]
    /// Evolution ink per sigil.
    var inkBySpell: [String: Int] = [:]
    /// Sigil tunes unlocked via draft (`SigilTune.rawValue`).
    var sigilTunes: Set<String> = []
    var burnProcs: Int = 0
    var chillProcs: Int = 0
    var critCount: Int = 0
    var draftsTaken: Int = 0
    /// Frost Crown: chill once per encounter.
    var frostCrownUsedThisFight: Bool = false

    static let empty = RunBuild()

    func has(_ relic: RunRelic) -> Bool { runRelics.contains(relic) }

    func hasTune(_ tune: SigilTune) -> Bool { sigilTunes.contains(tune.rawValue) }

    func evolution(for spell: SpellID) -> SigilEvolution? {
        guard let raw = evolved[spell.rawValue] else { return nil }
        return SigilEvolution(rawValue: raw)
    }

    func ink(for spell: SpellID) -> Int { inkBySpell[spell.rawValue, default: 0] }

    mutating func addInk(_ amount: Int, for spell: SpellID) {
        inkBySpell[spell.rawValue, default: 0] += amount
    }

    /// Active synergy tags from relics + equipped sigils.
    func activeSynergies(equipped: [SpellID]) -> Set<SynergyTag> {
        var tags = Set(runRelics.map(\.synergy))
        for spell in equipped {
            tags.formUnion(RunRelic.tags(for: spell))
        }
        return tags
    }

    /// Weight boost for draft pools when a tag is stacked.
    func synergyWeight(for tag: SynergyTag, equipped: [SpellID]) -> Int {
        let active = activeSynergies(equipped: equipped)
        guard active.contains(tag) else { return 0 }
        let relicMatches = runRelics.filter { $0.synergy == tag }.count
        let sigilMatches = equipped.filter { RunRelic.tags(for: $0).contains(tag) }.count
        return Balance.draftSynergyWeightBase * (relicMatches + sigilMatches)
    }
}
