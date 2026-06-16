import XCTest
@testable import AshVault

final class DamagePipelineTests: XCTestCase {

    func testSpellIgnoresDefense() {
        let def = SpellCatalog.definition(for: .emberBolt)
        let result = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: 20,
            targetDefense: 99,
            targetAspect: .arc,
            targetTags: [],
            castMultiplier: 1.0,
            useSpellBaseFormula: true
        ))
        XCTAssertEqual(result.baseDamage, 25)
        XCTAssertEqual(result.finalDamage, 25)
    }

    func testWeakMultiplier() {
        let def = SpellCatalog.definition(for: .emberBolt)
        let result = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: 20,
            targetDefense: 0,
            targetAspect: .frost,
            targetTags: [],
            castMultiplier: 1.0,
            useSpellBaseFormula: true
        ))
        XCTAssertEqual(result.effectiveness, .weak)
        XCTAssertEqual(result.finalDamage, 38) // 25 * 1.5 = 37.5 → 38 (banker's round)
    }

    func testResistMinimumOne() {
        let def = SpellCatalog.definition(for: .frostShard)
        let result = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: 10,
            targetDefense: 0,
            targetAspect: .venom,
            targetTags: [],
            castMultiplier: 1.0,
            useSpellBaseFormula: true
        ))
        XCTAssertEqual(result.effectiveness, .resist)
        XCTAssertEqual(result.finalDamage, 6) // 12 * 0.5
    }

    func testVenomLashWeakAgainstStone() {
        let def = SpellCatalog.definition(for: .venomLash)
        let result = DamagePipeline.spellDamage(SpellDamageRequest(
            spell: def,
            attackerAttack: 20,
            targetDefense: 99,
            targetAspect: .stone,
            targetTags: [],
            castMultiplier: 1.0,
            useSpellBaseFormula: true
        ))
        XCTAssertEqual(result.baseDamage, 21)
        XCTAssertEqual(result.effectiveness, .weak)
        XCTAssertEqual(result.finalDamage, 32)
    }
}
