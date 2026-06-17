import Foundation

/// Stat-only draft options (survivor crawl).
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

/// Sigil tuning picks offered in draft pools.
enum SigilTune: String, CaseIterable, Codable, Identifiable {
    case emberBurnBoost
    case frostChill

    var id: String { rawValue }

    var spell: SpellID {
        switch self {
        case .emberBurnBoost: return .emberBolt
        case .frostChill:       return .frostShard
        }
    }

    var title: String {
        switch self {
        case .emberBurnBoost: return "Sear Longer"
        case .frostChill:       return "Rime Touch"
        }
    }

    var blurb: String {
        switch self {
        case .emberBurnBoost: return "Ember burns last +1 turn."
        case .frostChill:       return "Frost applies chill on hit."
        }
    }

    var icon: String {
        switch self {
        case .emberBurnBoost: return "flame.fill"
        case .frostChill:       return "snowflake"
        }
    }

    var synergy: SynergyTag {
        switch self {
        case .emberBurnBoost: return .burn
        case .frostChill:       return .frost
        }
    }
}

/// One draft card — stat, relic, ink, tune, or evolution unlock.
enum DraftPick: Identifiable, Equatable, Codable {
    case stat(DraftOption)
    case relic(RunRelic)
    case evolutionInk(spell: SpellID, amount: Int)
    case sigilTune(SigilTune)
    case evolutionUnlock(spell: SpellID, evolution: SigilEvolution)

    var id: String {
        switch self {
        case .stat(let o): return "stat:\(o.rawValue)"
        case .relic(let r): return "relic:\(r.rawValue)"
        case .evolutionInk(let s, let n): return "ink:\(s.rawValue):\(n)"
        case .sigilTune(let t): return "tune:\(t.rawValue)"
        case .evolutionUnlock(let s, let e): return "evo:\(s.rawValue):\(e.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .stat(let o): return o.title
        case .relic(let r): return r.title
        case .evolutionInk(let s, _):
            return "\(SpellCatalog.definition(for: s).displayName) Ink"
        case .sigilTune(let t): return t.title
        case .evolutionUnlock(_, let e): return "Evolve: \(e.title)"
        }
    }

    var blurb: String {
        switch self {
        case .stat(let o): return o.blurb
        case .relic(let r): return r.blurb
        case .evolutionInk(_, let n): return "+\(n) evolution ink toward an evo."
        case .sigilTune(let t): return t.blurb
        case .evolutionUnlock(_, let e): return e.blurb
        }
    }

    var icon: String {
        switch self {
        case .stat(let o): return o.icon
        case .relic(let r): return r.icon
        case .evolutionInk: return "paintbrush.fill"
        case .sigilTune(let t): return t.icon
        case .evolutionUnlock(_, let e): return e.icon
        }
    }

    /// Legacy save restore: stat-only raw values.
    init?(legacyRawValue: String) {
        guard let stat = DraftOption(rawValue: legacyRawValue) else { return nil }
        self = .stat(stat)
    }
}

enum RunDraft {

    private struct Weighted<T> {
        let value: T
        let weight: Int
    }

    static func rollOptions(
        rng: RandomSource,
        build: RunBuild,
        equipped: [SpellID],
        oath: DelverOath? = nil,
        count: Int = 3,
        autoBattle: Bool = false
    ) -> [DraftPick] {
        var pool: [Weighted<DraftPick>] = []

        for stat in DraftOption.allCases {
            var weight = Balance.draftStatBaseWeight
            if let oath { weight += oath.draftStatWeightBonus(for: stat) }
            pool.append(Weighted(value: .stat(stat), weight: weight))
        }

        if build.runRelics.count < Balance.maxRunRelics {
            for relic in RunRelic.allCases where !build.has(relic) {
                var weight = Balance.draftRelicBaseWeight
                weight += build.synergyWeight(for: relic.synergy, equipped: equipped)
                if let oath { weight += oath.draftSynergyWeightBonus(for: relic.synergy) }
                if autoBattle { weight = max(1, weight / 2) }
                pool.append(Weighted(value: .relic(relic), weight: weight))
            }
        }

        for spell in equipped {
            if build.evolution(for: spell) == nil {
                pool.append(Weighted(
                    value: .evolutionInk(spell: spell, amount: Balance.evolutionInkPerPick),
                    weight: Balance.draftInkBaseWeight + build.ink(for: spell)
                ))
                if let evo = SigilEvolution.eligibleUnlock(for: spell, build: build) {
                    pool.append(Weighted(
                        value: .evolutionUnlock(spell: spell, evolution: evo),
                        weight: Balance.draftEvolutionUnlockWeight
                    ))
                }
            }
            for tune in SigilTune.allCases where tune.spell == spell {
                var weight = Balance.draftTuneBaseWeight
                weight += build.synergyWeight(for: tune.synergy, equipped: equipped)
                if let oath { weight += oath.draftSynergyWeightBonus(for: tune.synergy) }
                pool.append(Weighted(value: .sigilTune(tune), weight: weight))
            }
        }

        var picks: [DraftPick] = []
        var usedIDs = Set<String>()
        while picks.count < count {
            guard let chosen = weightedPick(from: pool, rng: rng) else { break }
            guard !usedIDs.contains(chosen.id) else {
                pool.removeAll { $0.value.id == chosen.id }
                continue
            }
            picks.append(chosen)
            usedIDs.insert(chosen.id)
            pool.removeAll { $0.value.id == chosen.id }
        }
        return picks
    }

    private static func weightedPick(from pool: [Weighted<DraftPick>], rng: RandomSource) -> DraftPick? {
        let total = pool.reduce(0) { $0 + max(1, $1.weight) }
        guard total > 0 else { return nil }
        var roll = rng.roll(0..<total)
        for entry in pool {
            let w = max(1, entry.weight)
            if roll < w { return entry.value }
            roll -= w
        }
        return pool.last?.value
    }

    static func apply(
        _ pick: DraftPick,
        to player: Player,
        build: inout RunBuild,
        loadout: SigilLoadout
    ) {
        switch pick {
        case .stat(let option):
            applyStat(option, to: player)
        case .relic(let relic):
            if !build.has(relic), build.runRelics.count < Balance.maxRunRelics {
                build.runRelics.append(relic)
            }
        case .evolutionInk(let spell, let amount):
            build.addInk(amount, for: spell)
        case .sigilTune(let tune):
            build.sigilTunes.insert(tune.rawValue)
        case .evolutionUnlock(let spell, let evolution):
            build.evolved[spell.rawValue] = evolution.rawValue
        }
        build.draftsTaken += 1
    }

    static func applyStat(_ option: DraftOption, to player: Player) {
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

    /// Restore draft picks from persisted IDs (save/resume).
    static func decodePicks(from ids: [String]) -> [DraftPick] {
        ids.compactMap { decodePick(id: $0) }
    }

    static func decodePick(id: String) -> DraftPick? {
        let parts = id.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard let head = parts.first else { return nil }
        switch head {
        case "stat":
            guard parts.count >= 2, let o = DraftOption(rawValue: parts[1]) else { return nil }
            return .stat(o)
        case "relic":
            guard parts.count >= 2, let r = RunRelic(rawValue: parts[1]) else { return nil }
            return .relic(r)
        case "ink":
            guard parts.count >= 3, let s = SpellID(rawValue: parts[1]), let n = Int(parts[2]) else { return nil }
            return .evolutionInk(spell: s, amount: n)
        case "tune":
            guard parts.count >= 2, let t = SigilTune(rawValue: parts[1]) else { return nil }
            return .sigilTune(t)
        case "evo":
            guard parts.count >= 3,
                  let s = SpellID(rawValue: parts[1]),
                  let e = SigilEvolution(rawValue: parts[2]) else { return nil }
            return .evolutionUnlock(spell: s, evolution: e)
        default:
            return DraftPick(legacyRawValue: id)
        }
    }
}
