import XCTest
@testable import AshVault

@MainActor
final class DelverOathTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testHoundAppliesAttackBonus() {
        let p = Player(name: "Hero")
        DelverOath.hound.apply(to: p)
        XCTAssertEqual(p.attack, 25 + Balance.oathHoundAttackBonus)
    }

    func testMastAppliesHpAndDefense() {
        let p = Player(name: "Hero")
        DelverOath.mast.apply(to: p)
        XCTAssertEqual(p.maxHp, 60 + Balance.oathMastHpBonus)
        XCTAssertEqual(p.defense, 10 + Balance.oathMastDefenseBonus)
    }

    func testKiteAppliesLuckAndHpPenalty() {
        let p = Player(name: "Hero")
        DelverOath.kite.apply(to: p)
        XCTAssertEqual(p.luck, 3 - Balance.oathKiteLuckSteps)
        XCTAssertEqual(p.maxHp, 60 - Balance.oathKiteHpPenalty)
    }

    func testHoundWoundedDamageBonus() {
        clearPersistence()
        let engine = GameEngine(rng: ScriptedRandom(fallback: 9))
        startTestRun(engine, oath: .hound)
        let baseHp = engine.enemy.hp
        engine.enemy.hp = baseHp - 1
        let wounded = engine.combatDamageMultiplier
        engine.enemy.hp = baseHp
        let full = engine.combatDamageMultiplier
        XCTAssertGreaterThan(wounded, full)
    }

    func testMastCampGrantsMaxHp() {
        clearPersistence()
        let engine = GameEngine(rng: alwaysHitRNG())
        startTestRun(engine, oath: .mast)
        killBossRing(engine)
        guard engine.phase == .ringChoice else {
            return XCTFail("Expected ring choice, got \(engine.phase)")
        }
        let before = engine.player.maxHp
        engine.enterCamp()
        XCTAssertGreaterThan(engine.player.maxHp, before)
    }

    func testKiteScoutsNextRingModifier() {
        clearPersistence()
        let engine = GameEngine(rng: ScriptedRandom(fallback: 0))
        startTestRun(engine, oath: .kite)
        XCTAssertNotNil(engine.scoutedNextRingModifier)
        XCTAssertEqual(engine.delverOath, .kite)
    }

    func testOathPersistedInMetaStore() {
        MetaStore.saveDelverOath(.mast)
        XCTAssertEqual(MetaStore.loadDelverOath(), .mast)
    }
}
