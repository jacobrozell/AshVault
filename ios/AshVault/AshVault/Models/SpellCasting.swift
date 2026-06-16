import Foundation

enum CastQuality {
    case perfect, clean, partial, fumbled

    var damageMultiplier: Double {
        switch self {
        case .perfect, .clean: return 1.0
        case .partial:         return Balance.partialCastMultiplier
        case .fumbled:         return Balance.fumbledCastMultiplier
        }
    }
}

struct CastResult {
    let quality: CastQuality

    var damageMultiplier: Double { quality.damageMultiplier }
}

/// Injection point for the future rune-tracing minigame. v1 always instant-casts.
protocol SpellCastResolver: AnyObject {
    func resolve(spell: SpellID, engine: GameEngine) -> CastResult
}

final class InstantSpellCastResolver: SpellCastResolver {
    func resolve(spell: SpellID, engine: GameEngine) -> CastResult {
        _ = spell
        _ = engine
        return CastResult(quality: .clean)
    }
}
