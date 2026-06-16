import XCTest
@testable import AshVault

final class EnemyTests: XCTestCase {

    private func make(scale: Int = 0, layer: Int = 1, isBoss: Bool = false,
                      isFinal: Bool = false, postGameDepth: Int = 0) -> Enemy {
        Enemy(kind: Bestiary.fodder[0], scaleLevel: scale, layer: layer,
              isBoss: isBoss, isFinalBoss: isFinal, postGameDepth: postGameDepth)
    }

    func testBaseStatsMatchJavaOriginal() {
        let e = make()
        XCTAssertEqual(e.hp, Balance.enemyBaseHp)
        XCTAssertEqual(e.attack, Balance.enemyBaseAtk)
        XCTAssertEqual(e.defense, Balance.enemyBaseDef)
        XCTAssertEqual(e.luck, 5)
        XCTAssertEqual(e.level, 1)
    }

    func testScalingAddsPerGroup() {
        let e = make(scale: 2)
        XCTAssertEqual(e.hp, Balance.enemyBaseHp + Balance.enemyScaleHpPerGroup * 2)
        XCTAssertEqual(e.attack, Balance.enemyBaseAtk + Balance.enemyScaleAtkPerGroup * 2)
        XCTAssertEqual(e.defense, Balance.enemyBaseDef + Balance.enemyScaleDefPerGroup * 2)
        XCTAssertEqual(e.level, 3)
    }

    func testLuckTightensAtScale3AndPostGame() {
        XCTAssertEqual(make(scale: 3).luck, 3)   // bestiary "level 4"
        XCTAssertEqual(make(postGameDepth: 1).luck, 1)
    }

    func testEndlessScalingCompoundsAndOutgrows() {
        let base = make(scale: 5)                       // a layer-6-ish fodder, pre-mult
        let deep = make(scale: 5, postGameDepth: 1)     // same, first post-game layer
        let deeper = make(scale: 5, postGameDepth: 12)  // far into endless
        XCTAssertGreaterThan(deep.attack, base.attack)   // post-game multiplier kicks in
        XCTAssertGreaterThan(deeper.attack, deep.attack) // ATK compounds (gently)
        XCTAssertGreaterThan(deeper.hp, deep.hp * 2)     // HP compounds faster
        XCTAssertGreaterThan(deeper.hp, deeper.attack)   // HP outpaces ATK in endless
    }

    func testFinalBossFixedStatBlock() {
        let dragon = make(isBoss: true, isFinal: true)
        XCTAssertEqual(dragon.hp, 150)
        XCTAssertEqual(dragon.attack, 100)
        XCTAssertEqual(dragon.defense, 0)
    }

    func testNormalBossBump() {
        let boss = make(scale: 0, isBoss: true)
        XCTAssertEqual(boss.hp, Balance.enemyBaseHp + Balance.enemyBossHpBonus)
        XCTAssertEqual(boss.attack, Balance.enemyBaseAtk + Balance.enemyBossAtkBonus)
        XCTAssertEqual(boss.defense, 0)   // 5 - 5
    }

    func testGenerateGoldIsAttackTimesLevel() {
        let e = make(scale: 1)            // attack 32, level 2
        let raw = e.attack * e.level
        XCTAssertEqual(e.generateGold(), Int((Double(raw) * Balance.goldRewardScale).rounded()))
    }

    func testBossLuckBumpPrePostGame() {
        XCTAssertEqual(make(isBoss: true).luck, 6)
        XCTAssertEqual(make(isBoss: true, postGameDepth: 1).luck, 1)
    }

    func testEnemyPreservesKindMetadata() {
        let kind = Bestiary.fodder[2]
        let pixie = Enemy(kind: kind, scaleLevel: 0, isBoss: false,
                          isFinalBoss: false, postGameDepth: 0)
        XCTAssertEqual(pixie.name, "Pixie")
        XCTAssertEqual(pixie.sprite, "🧚")
        XCTAssertEqual(pixie.tint, "pink")
    }

    func testCampaignLayerBoostsPreDragonStats() {
        let shallow = make(scale: 1, layer: 1)
        let deep = make(scale: 1, layer: 4)
        XCTAssertGreaterThan(deep.hp, shallow.hp)
        XCTAssertGreaterThan(deep.attack, shallow.attack)
    }

    func testHealthFractionTracksDamage() {
        let e = make()
        e.takeHit(25)
        XCTAssertEqual(e.healthFraction, 0.5, accuracy: 1e-9)
    }
}
