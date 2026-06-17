import Foundation

/// Run-only sigil evolution paths (Ember + Frost in Phase 2).
enum SigilEvolution: String, CaseIterable, Codable, Identifiable {
    case meteor
    case kindling
    case glacier
    case needle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meteor:   return "Meteor"
        case .kindling: return "Kindling"
        case .glacier:  return "Glacier"
        case .needle:   return "Needle"
        }
    }

    var blurb: String {
        switch self {
        case .meteor:   return "Ember +50% dmg; burns stack ×2."
        case .kindling: return "Ember +dmg per burn on target."
        case .glacier:  return "Frost bonus vs high-HP foes."
        case .needle:   return "Frost crits pierce defense."
        }
    }

    var icon: String {
        switch self {
        case .meteor:   return "flame.fill"
        case .kindling: return "flame.circle.fill"
        case .glacier:  return "snowflake"
        case .needle:   return "scope"
        }
    }

    var baseSpell: SpellID {
        switch self {
        case .meteor, .kindling: return .emberBolt
        case .glacier, .needle:  return .frostShard
        }
    }

    /// Paths available for a base sigil.
    static func paths(for spell: SpellID) -> [SigilEvolution] {
        switch spell {
        case .emberBolt:  return [.meteor, .kindling]
        case .frostShard: return [.glacier, .needle]
        default:          return []
        }
    }

    /// Condition label for the build panel.
    func conditionLabel(build: RunBuild) -> String {
        switch self {
        case .meteor:
            return "Burn procs \(build.burnProcs)/\(Balance.meteorBurnProcsNeeded)"
        case .kindling:
            return "Drafts \(build.draftsTaken)/\(Balance.kindlingDraftsNeeded)"
        case .glacier:
            return "Chills \(build.chillProcs)/\(Balance.glacierChillProcsNeeded)"
        case .needle:
            return "Crits \(build.critCount)/\(Balance.needleCritsNeeded)"
        }
    }

    /// Whether the run has met this path's unlock condition.
    func conditionMet(in build: RunBuild) -> Bool {
        switch self {
        case .meteor:   return build.burnProcs >= Balance.meteorBurnProcsNeeded
        case .kindling: return build.draftsTaken >= Balance.kindlingDraftsNeeded
        case .glacier:  return build.chillProcs >= Balance.glacierChillProcsNeeded
        case .needle:   return build.critCount >= Balance.needleCritsNeeded
        }
    }

    /// First eligible evolution for an equipped sigil (ink + condition).
    static func eligibleUnlock(for spell: SpellID, build: RunBuild) -> SigilEvolution? {
        guard build.evolved[spell.rawValue] == nil else { return nil }
        let ink = build.ink(for: spell)
        guard ink >= Balance.evolutionInkThreshold else { return nil }
        return paths(for: spell).first { $0.conditionMet(in: build) }
    }
}
