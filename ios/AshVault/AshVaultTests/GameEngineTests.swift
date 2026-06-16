import XCTest
@testable import AshVault

@MainActor
final class GameEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    /// Always-hit RNG (d10 roll of 9 clears any luck threshold).
    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        return e
    }

    func testStartGameEntersCombatOnFirstEnemy() {
        let e = engine()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 1)
        XCTAssertEqual(e.enemyIndex, 1)
        XCTAssertFalse(e.log.isEmpty)
    }

    func testKillAwardsGoldAndSpawnsNext() {
        let e = engine()
        let goldBefore = e.player.gold
        let reward = e.enemy.generateGold()
        e.enemy.hp = 1                 // one hit will kill
        e.perform(.attack)
        XCTAssertEqual(e.player.gold, goldBefore + reward)
        XCTAssertEqual(e.enemyIndex, 2)
        XCTAssertEqual(e.phase, .combat)
    }

    func testFifthKillIsBossAndTriggersLevelUp() {
        let e = engine()
        for _ in 1...5 {
            e.enemy.hp = 1
            e.perform(.attack)
        }
        XCTAssertEqual(e.phase, .levelUp)
        XCTAssertEqual(e.layer, 2)      // advanced after the boss
    }

    func testChooseUpgradeOpensShopThenCombat() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        XCTAssertEqual(e.phase, .shop)        // shop sits between level-up and combat
        XCTAssertEqual(e.player.level, 2)
        e.leaveShop()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.enemyIndex, 1)       // first enemy of the new layer
    }

    func testBuyPermanentUpgradeChargesAndScales() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)              // now in .shop
        e.player.addGold(1000)
        let atkBefore = e.player.attack
        let first = e.price(.whetstone)
        e.buy(.whetstone)
        XCTAssertEqual(e.player.attack, atkBefore + 5)
        // Geometric pricing: next copy costs `shopPriceGrowth`× the first.
        XCTAssertEqual(e.price(.whetstone),
                       Int((Double(first) * Balance.shopPriceGrowth).rounded()))
    }

    func testBuyBlockedWhenBroke() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        // Drain gold below any price.
        e.player.spendGold(e.player.gold)
        let goldBefore = e.player.gold
        let maxHpBefore = e.player.maxHp
        e.buy(.heartVial)
        XCTAssertEqual(e.player.gold, goldBefore)   // nothing spent
        XCTAssertEqual(e.player.maxHp, maxHpBefore) // unchanged
    }

    func testPotionPurchaseAndUse() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        e.player.addGold(1000)
        e.buy(.potion)
        XCTAssertEqual(e.player.potions, 1)
        e.leaveShop()
        e.player.hp = 1
        e.usePotion()
        XCTAssertEqual(e.player.potions, 0)
        XCTAssertGreaterThan(e.player.hp, 1)
    }

    func testPlayerDeathEndsRun() {
        let e = engine()
        e.player.hp = 1                  // next enemy swing is lethal
        e.perform(.attack)               // enemy survives (full HP), then retaliates
        XCTAssertEqual(e.phase, .defeat)
        XCTAssertFalse(e.player.isAlive)
    }

    func testFirstDeathShowsTwistOnce() {
        FirstDeathBeat.reset()
        defer { FirstDeathBeat.reset() }
        let e = engine()
        e.player.hp = 1
        e.perform(.attack)
        XCTAssertTrue(e.log.contains { $0.text.contains("idle game") })
        XCTAssertTrue(FirstDeathBeat.hasShown)

        let e2 = engine()
        e2.player.hp = 1
        e2.perform(.attack)
        XCTAssertEqual(e2.log.filter { $0.text.contains("idle game") }.count, 0)
    }

    func testHealMoveDoesNotMentionPotion() {
        let e = GameEngine(playerName: "Hero", rng: alwaysMissRNG())
        e.startGame(named: "Hero")
        e.player.takeHit(30)
        e.perform(.heal)
        XCTAssertTrue(e.log.contains { $0.text.contains("catch your breath") })
        XCTAssertFalse(e.log.contains { $0.text.contains("quaff") })
    }

    func testCampaignHitsAreCapped() {
        // Roll 9 for hits, 99 for status procs (poison won't land on d100).
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 99))
        e.startGame(named: "Hero")
        while !(e.layer == 5 && e.enemyIndex == 5 && e.phase == .combat) {
            if e.phase == .levelUp { e.chooseUpgrade(.health) }
            if e.phase == .shop { e.leaveShop() }
            if e.phase == .victory { e.continueEndless() }
            if e.phase == .combat { e.enemy.hp = 1; e.perform(.attack) }
        }
        let uncapped = max(0, e.enemy.attack - e.player.defense)
        XCTAssertGreaterThanOrEqual(uncapped, e.player.maxHp / 2, "Dragon should hit hard without cap")
        let hpBefore = e.player.hp
        e.perform(.attack)
        let loss = hpBefore - e.player.hp
        let cap = max(1, e.player.maxHp * Balance.maxCampaignHitPercent / 100)
        XCTAssertLessThanOrEqual(loss, cap)
        XCTAssertGreaterThan(loss, 0)
    }

    func testAutoBattleTickFightsAutomatically() {
        let e = engine()
        e.enemy.hp = 1
        e.autoBattle = true
        e.tick()                          // auto-plays a move that kills the enemy
        XCTAssertEqual(e.enemyIndex, 2)   // advanced without manual input
    }

    func testTickIsNoopWhenAutoOff() {
        let e = engine()
        e.enemy.hp = 1
        let idx = e.enemyIndex
        e.tick()                          // auto-battle off → nothing happens
        XCTAssertEqual(e.enemyIndex, idx)
    }

    func testSaveAndRestoreRoundTrip() {
        SaveStore.clear()
        defer { SaveStore.clear() }
        let a = engine()
        a.enemy.hp = 1
        a.perform(.attack)              // gold gained, advanced to enemy 2
        let gold = a.player.gold
        let idx = a.enemyIndex
        a.save()

        // A fresh engine loads the save in its init.
        let b = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(b.player.gold, gold)
        XCTAssertEqual(b.enemyIndex, idx)
        XCTAssertEqual(b.player.name, "Hero")
        XCTAssertEqual(b.phase, .combat)
    }

    func testAscendBanksShardsAndBoostsStartingPower() {
        SaveStore.clear()
        PrestigeStore.save(0)
        defer { SaveStore.clear(); PrestigeStore.save(0) }

        let e = engine()
        let baseAttack = e.player.attack
        // Drive many kills, auto-resolving the level-up/shop interruptions, so
        // enough gold accrues for shards: floor(sqrt(runGoldEarned / 100)).
        for _ in 0..<40 {
            switch e.phase {
            case .combat:  e.enemy.hp = 1; e.perform(.attack)
            case .levelUp: e.chooseUpgrade(.attack)
            case .shop:    e.leaveShop()
            case .victory: e.continueEndless()   // dragon beaten — resume endless combat
            default:       break
            }
        }
        if e.phase == .victory { e.continueEndless() }
        if e.phase == .levelUp { e.chooseUpgrade(.attack) }
        if e.phase == .shop { e.leaveShop() }
        let expectedShards = e.pendingShards
        XCTAssertGreaterThan(expectedShards, 0, "grind should earn run gold for shards")

        e.enterAscension()
        XCTAssertEqual(e.phase, .ascension)
        e.ascend()

        XCTAssertEqual(e.totalShards, expectedShards)
        XCTAssertEqual(e.availableShards, expectedShards) // nothing spent yet
        XCTAssertEqual(e.phase, .combat)                  // fresh run begins
        XCTAssertEqual(e.layer, 1)
        XCTAssertEqual(e.player.attack, baseAttack)       // unspent shards = no boost
    }

    func testSkillTreeSpendBoostsNextRun() {
        SaveStore.clear()
        PrestigeStore.save(50)
        PrestigeStore.saveTree([:])
        defer { SaveStore.clear(); PrestigeStore.save(0); PrestigeStore.saveTree([:]) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(e.availableShards, 50)
        let costFirst = e.cost(.might)
        e.upgradeNode(.might)
        XCTAssertEqual(e.level(of: .might), 1)
        XCTAssertEqual(e.availableShards, 50 - costFirst)

        e.startGame(named: "Hero")        // applies +5% attack from Might Lv1
        XCTAssertGreaterThan(e.player.attack, 25)
    }

    func testWardDamageReductionScalesWithLevels() {
        SaveStore.clear()
        PrestigeStore.save(1000)
        PrestigeStore.saveTree([:])
        defer { SaveStore.clear(); PrestigeStore.save(0); PrestigeStore.saveTree([:]) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(e.damageReduction, 0.0, accuracy: 1e-9)
        for _ in 0..<5 { e.upgradeNode(.ward) }
        XCTAssertEqual(e.level(of: .ward), 5)
        XCTAssertEqual(e.damageReduction, 0.15, accuracy: 1e-9) // 5 × 3%
        XCTAssertLessThanOrEqual(e.damageReduction, Balance.maxDamageReduction)
    }

    func testCannotUpgradeBeyondAffordableShards() {
        SaveStore.clear()
        PrestigeStore.save(0)
        PrestigeStore.saveTree([:])
        defer { SaveStore.clear() }
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertFalse(e.canUpgrade(.might))   // 0 shards
        e.upgradeNode(.might)
        XCTAssertEqual(e.level(of: .might), 0) // no-op
    }

    func testAutomationClearsLevelUpWhenUnlocked() {
        SaveStore.clear()
        PrestigeStore.save(5)            // automation unlocked (>= 1 shard)
        defer { SaveStore.clear(); PrestigeStore.save(0) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        e.autoBattle = true
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }  // 5th kill → levelUp
        XCTAssertEqual(e.phase, .levelUp)
        e.tick()                          // automation auto-picks the upgrade
        XCTAssertEqual(e.player.level, 2)
        XCTAssertNotEqual(e.phase, .levelUp)
    }

    func testAutomationLockedBeforeFirstPrestige() {
        SaveStore.clear()
        PrestigeStore.save(0)
        let e = engine()                  // 0 shards
        XCTAssertFalse(e.automationUnlocked)
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        XCTAssertEqual(e.phase, .levelUp)
        e.autoBattle = true
        e.tick()                          // must NOT auto-advance
        XCTAssertEqual(e.phase, .levelUp)
    }

    func testSigilBlockedWithoutMana() {
        let e = engine()
        e.player.spendMana(e.player.mana)   // drain to 0
        let countBefore = e.log.count
        e.performSigil(.emberBolt)
        XCTAssertTrue(e.log.last?.text.contains("Not enough mana") == true)
        // Only the rejection line was added; no combat resolved.
        XCTAssertEqual(e.log.count, countBefore + 1)
    }
}
