import Foundation

struct SpellDamageRequest {
    let spell: SpellDefinition
    let attackerAttack: Int
    let targetDefense: Int
    let targetAspect: Element
    let targetTags: Set<EnemyTag>
    let castMultiplier: Double
    /// When false, uses physical-style formula (legacy; no sigils use this in v1).
    let useSpellBaseFormula: Bool
}

struct SpellDamageResult {
    let baseDamage: Int
    let finalDamage: Int
    let effectiveness: Effectiveness
}

enum DamagePipeline {

    static func spellDamage(_ req: SpellDamageRequest) -> SpellDamageResult {
        let base: Int
        if req.useSpellBaseFormula && req.spell.ignoresDefense {
            base = max(1, req.attackerAttack + req.spell.flatBonus)
        } else {
            base = max(1, req.attackerAttack / 2 - req.targetDefense)
        }

        let eff = TypeChart.effectiveness(
            spellElement: req.spell.element,
            enemyAspect: req.targetAspect,
            enemyTags: req.targetTags
        )
        let scaled = Int((Double(base) * req.castMultiplier * eff.multiplier).rounded())
        let final = max(1, scaled)

        return SpellDamageResult(baseDamage: base, finalDamage: final, effectiveness: eff)
    }
}
