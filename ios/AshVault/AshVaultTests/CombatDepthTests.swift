import XCTest
@testable import AshVault

@MainActor
final class CombatDepthTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine(rng: ScriptedRandom = ScriptedRandom(fallback: 9)) -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: rng)
        e.startGame(named: "Hero")
        return e
    }

    func testGuardUpSoftensIncomingHits() {
        let guarded = engine(rng: combatRNG([9, 99, 9], fallback: 9))
        guarded.player.applyStatus(.guardUp, turns: 2, magnitude: 0)
        guarded.enemy.hp = 999
        let hpBefore = guarded.player.hp
        guarded.perform(.attack)
        let guardedLoss = hpBefore - guarded.player.hp

        let vanilla = engine(rng: combatRNG([9, 99, 9], fallback: 9))
        vanilla.enemy.hp = 999
        let vanillaHp = vanilla.player.hp
        vanilla.perform(.attack)
        let vanillaLoss = vanillaHp - vanilla.player.hp

        XCTAssertGreaterThan(vanillaLoss, guardedLoss)
    }

    func testFocusBoostsCritChance() {
        let focused = engine(rng: combatRNG([9, 25]))
        focused.player.applyStatus(.focus, turns: 2, magnitude: 0)
        focused.enemy.hp = 999
        focused.perform(.attack)
        XCTAssertTrue(focused.log.contains { $0.text.contains("Critical") })

        let vanilla = engine(rng: combatRNG([9, 25]))
        vanilla.enemy.hp = 999
        vanilla.perform(.attack)
        XCTAssertFalse(vanilla.log.contains { $0.text.contains("Critical") })
    }

    func testPlayerPoisonTickCanEndRun() {
        let e = engine(rng: alwaysHitRNG())
        e.player.hp = 1
        e.player.applyStatus(.poison, turns: 2, magnitude: 3, maxStacks: 3)
        e.player.applyStatus(.stun, turns: 1, magnitude: 0)
        e.enemy.hp = 999
        e.perform(.attack) // stunned → endRound → poison kills
        XCTAssertEqual(e.phase, .defeat)
        XCTAssertFalse(e.player.isAlive)
    }

    func testAutoMovePrefersSigilWithFullMana() {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 3))
        e.startGame(named: "Hero")
        e.autoBattle = true
        e.enemy.hp = 999
        e.player.hp = 50
        e.player.restoreMana(100)
        e.tick()
        XCTAssertTrue(e.log.contains { $0.text.contains("Ember Bolt") || $0.text.contains("super effective") })
    }

    func testAutoMoveFallsBackToAttackWithoutMana() {
        let e = engine(rng: alwaysHitRNG())
        e.autoBattle = true
        e.enemy.hp = 999
        e.player.hp = 50
        e.player.spendMana(e.player.mana)
        let enemyHp = e.enemy.hp
        e.tick()
        XCTAssertLessThan(e.enemy.hp, enemyHp)
    }

    func testHealMoveRestoresTenTimesLevel() {
        let e = engine(rng: alwaysMissRNG())
        e.player.takeHit(30)
        let hpBefore = e.player.hp
        e.perform(.heal)
        XCTAssertEqual(e.player.hp, hpBefore + 10 * e.player.level)
    }

    func testPoisonStacksCapAtFive() {
        let enemy = Enemy(kind: Bestiary.fodder[0], scaleLevel: 0,
                          isBoss: false, isFinalBoss: false, postGameDepth: 0)
        for _ in 0..<7 {
            enemy.applyStatus(.poison, turns: 3, magnitude: 1, maxStacks: 5)
        }
        XCTAssertEqual(enemy.statuses.first?.stacks, 5)
    }

    func testPlayerPoisonTickInCombat() {
        let e = engine(rng: alwaysMissRNG())
        e.player.applyStatus(.poison, turns: 2, magnitude: 4, maxStacks: 3)
        e.enemy.hp = 999
        let hpBefore = e.player.hp
        e.perform(.dodge)
        XCTAssertLessThan(e.player.hp, hpBefore)
        XCTAssertTrue(e.log.contains { $0.text.contains("lingering effects") })
    }

    func testSimultaneousDeathIsDefeat() {
        let e = engine(rng: alwaysMissRNG())
        e.player.hp = 1
        e.player.applyStatus(.poison, turns: 2, magnitude: 3, maxStacks: 3)
        e.player.applyStatus(.stun, turns: 1, magnitude: 0)
        e.enemy.hp = 3
        e.enemy.applyStatus(.burn, turns: 2, magnitude: 3)
        e.perform(.attack) // stunned skip → endRound ticks both → player death wins
        XCTAssertEqual(e.phase, .defeat)
    }

    func testFifthEnemyIsBoss() {
        let e = engine()
        for _ in 1...4 {
            XCTAssertFalse(e.enemy.isBoss)
            e.enemy.hp = 1
            e.perform(.attack)
        }
        XCTAssertEqual(e.enemyIndex, Balance.enemiesPerLayer)
        XCTAssertTrue(e.enemy.isBoss)
    }

    func testDraftDefenseBump() {
        let e = engine()
        while e.phase == .combat, e.runStats.killsSinceDraft < e.draftKillsNeeded {
            e.enemy.hp = 1
            e.perform(.attack)
            resolveNonCombatPhases(e)
        }
        let defBefore = e.player.defense
        let pick = e.draftOptions.first { $0 == .ironSkin } ?? e.draftOptions[0]
        e.chooseDraft(pick)
        if pick == .ironSkin {
            XCTAssertEqual(e.player.defense, defBefore + Balance.draftDefenseBonus)
        }
        XCTAssertGreaterThan(e.player.level, 1)
    }
}
