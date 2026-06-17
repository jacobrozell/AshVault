import XCTest
@testable import AshVault

@MainActor
final class ShopAndEconomyTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engineInShop() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        killBossRing(e)
        e.enterCamp()
        XCTAssertEqual(e.phase, .shop)
        return e
    }

    func testConsumablePricesAreFlat() {
        let e = engineInShop()
        XCTAssertEqual(e.price(.potion), ShopItem.potion.basePrice)
        XCTAssertEqual(e.price(.ether), ShopItem.ether.basePrice)
        XCTAssertEqual(e.price(.phoenixAsh), ShopItem.phoenixAsh.basePrice)
        e.buy(.potion)
        XCTAssertEqual(e.price(.potion), ShopItem.potion.basePrice)
    }

    func testPhoenixAshPurchaseAndRevive() {
        let e = engineInShop()
        e.player.addGold(500)
        e.buy(.phoenixAsh)
        XCTAssertEqual(e.player.phoenixAshes, 1)
        e.buy(.phoenixAsh)
        XCTAssertEqual(e.player.phoenixAshes, 1)
        e.leaveShop()
        e.player.takeHit(e.player.hp)
        XCTAssertFalse(e.player.isAlive)
        e.enemy.hp = 999
        e.perform(.attack)
        XCTAssertTrue(e.player.isAlive)
        XCTAssertEqual(e.player.phoenixAshes, 0)
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.player.hp, e.player.maxHp * Balance.phoenixAshReviveHpPercent / 100)
        e.player.takeHit(e.player.hp)
        e.perform(.attack)
        XCTAssertEqual(e.phase, .defeat)
    }

    func testEtherPurchaseAndUse() {
        let e = engineInShop()
        e.player.addGold(1000)
        e.buy(.ether)
        XCTAssertEqual(e.player.ethers, 1)
        e.leaveShop()
        e.player.spendMana(e.player.mana)
        e.useEther()
        XCTAssertEqual(e.player.ethers, 0)
        XCTAssertEqual(e.player.mana, e.player.maxMana)
    }

    func testTowerShieldPurchase() {
        let e = engineInShop()
        e.player.addGold(1000)
        let defBefore = e.player.defense
        e.buy(.towerShield)
        XCTAssertEqual(e.player.defense, defBefore + 5)
    }

    func testHeartVialPurchase() {
        let e = engineInShop()
        e.player.addGold(1000)
        e.player.takeHit(20)
        let maxBefore = e.player.maxHp
        e.buy(.heartVial)
        XCTAssertEqual(e.player.maxHp, maxBefore + 15)
        XCTAssertEqual(e.player.hp, e.player.maxHp)
    }

    func testLuckyCoinImprovesLuck() {
        let e = engineInShop()
        e.player.addGold(1000)
        let luckBefore = e.player.luck
        e.buy(.luckyCoin)
        XCTAssertEqual(e.player.luck, luckBefore - 1)
    }

    func testFortuneNodeBoostsGoldRewards() {
        PrestigeStore.save(100)
        PrestigeStore.saveTree([:])
        defer { clearPersistence() }

        let boosted = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        boosted.upgradeNode(.fortune)
        boosted.startGame(named: "Hero")
        boosted.enemy.hp = 1
        let goldBefore = boosted.player.gold
        let baseReward = boosted.enemy.generateGold()
        boosted.perform(.attack)
        let gained = boosted.player.gold - goldBefore
        XCTAssertEqual(gained, Int((Double(baseReward) * boosted.goldMultiplier).rounded()))
        XCTAssertGreaterThan(boosted.goldMultiplier, 1.0)
    }

    func testAutoShopBuysAffordablePermanents() {
        PrestigeStore.save(Balance.automationUnlockShards)
        defer { clearPersistence() }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        e.autoBattle = true
        killBossRing(e)
        XCTAssertEqual(e.phase, .ringChoice)
        e.enterCamp()
        e.player.addGold(500)
        XCTAssertEqual(e.phase, .shop)
        let atkBefore = e.player.attack
        e.tick()
        XCTAssertGreaterThan(e.player.attack, atkBefore)
        XCTAssertEqual(e.phase, .combat)
    }
}
