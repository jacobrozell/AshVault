import XCTest
@testable import AshVault

@MainActor
final class RingCrawlTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testStartRunHasSuppliesAndModifier() {
        let e = GameEngine(playerName: "Test", rng: ScriptedRandom())
        e.startGame(named: "Test")
        XCTAssertEqual(e.supplies, Balance.startingSupplies)
        XCTAssertNotNil(e.currentRingModifier)
        XCTAssertEqual(e.phase, .combat)
    }

    func testEnteringRingSpendsSupply() {
        let e = GameEngine(playerName: "Test", rng: alwaysHitRNG())
        e.startGame(named: "Test")
        let before = e.supplies
        killBossRing(e)
        e.pushDeeper()
        XCTAssertEqual(e.supplies, before - Balance.supplyCostPerRing)
    }

    func testCampSpendsSupplies() {
        let e = GameEngine(playerName: "Test", rng: alwaysHitRNG())
        e.startGame(named: "Test")
        killBossRing(e)
        XCTAssertEqual(e.phase, .ringChoice)
        let before = e.supplies
        e.enterCamp()
        XCTAssertEqual(e.phase, .shop)
        XCTAssertEqual(e.supplies, before - Balance.supplyCostCamp)
    }

    func testRingTwoShowsDoorIngress() {
        let e = GameEngine(playerName: "Test", rng: alwaysHitRNG())
        e.startGame(named: "Test")
        killBossRing(e)
        e.pushDeeper()
        XCTAssertEqual(e.layer, 2)
        XCTAssertEqual(e.phase, .ringIngress)
        XCTAssertEqual(e.doorOffers.count, 2)
    }

    func testEliteModifierScalesEnemy() {
        let enemy = Enemy(
            kind: Bestiary.fodder[0], scaleLevel: 0, layer: 2,
            isBoss: false, isFinalBoss: false, postGameDepth: 0
        )
        let baseHp = enemy.maxHp
        RingCrawl.applyEncounterModifiers(
            to: enemy, modifier: nil, elite: true, isWarden: false, suppliesStarved: false
        )
        XCTAssertGreaterThan(enemy.maxHp, baseHp)
    }

    func testQuietRingIncreasesDraftThreshold() {
        let base = RunDraft.killsNeeded(forRing: 3)
        let quiet = RingCrawl.draftKillsNeeded(base: base, modifier: .quietRing)
        XCTAssertEqual(quiet, base + Balance.quietRingExtraDraftKills)
    }

    func testRollDoorsProducesTwoOffers() {
        let rng = ScriptedRandom([0, 1, 2])
        let doors = RingCrawl.rollDoors(ring: 5, rng: rng)
        XCTAssertEqual(doors.count, 2)
        XCTAssertNotEqual(doors[0].kind, doors[1].kind)
    }

    @MainActor
    func testWardenCanDropRunRelic() {
        let e = GameEngine(playerName: "Test", rng: alwaysHitRNG())
        e.startGame(named: "Test")
        while e.phase == .combat, e.enemyIndex < Balance.enemiesPerLayer {
            e.enemy.hp = 1
            e.perform(.attack)
            resolveNonCombatPhases(e)
        }
        XCTAssertEqual(e.enemyIndex, Balance.enemiesPerLayer)
        let before = e.runBuild.runRelics.count
        e.enemy.hp = 1
        e.perform(.attack)
        XCTAssertGreaterThan(e.runBuild.runRelics.count, before)
    }
}
