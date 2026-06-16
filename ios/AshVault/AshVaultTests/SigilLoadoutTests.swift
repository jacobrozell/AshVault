import XCTest
@testable import AshVault

@MainActor
final class SigilLoadoutTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testDefaultLoadoutHasEmberInSlotOne() {
        let loadout = SigilMastery.starter.defaultLoadout()
        XCTAssertEqual(loadout.slots[0], .emberBolt)
        XCTAssertNil(loadout.slots[1])
        XCTAssertNil(loadout.slots[2])
    }

    func testEquipAndClearSlots() {
        let engine = GameEngine()
        engine.equipSigil(.emberBolt, slot: 1)
        XCTAssertNil(engine.sigilLoadout.slots[0])
        XCTAssertEqual(engine.sigilLoadout.slots[1], .emberBolt)

        engine.clearSigilSlot(1)
        XCTAssertNil(engine.sigilLoadout.slots[1])
    }

    func testPerformSigilRequiresEquippedSlot() {
        let engine = GameEngine()
        engine.startGame(named: "Hero")
        let hpBefore = engine.enemy.hp
        engine.performSigil(.frostShard)
        XCTAssertEqual(engine.enemy.hp, hpBefore)
    }

    func testEmberBoltDamagesEnemy() {
        let engine = GameEngine()
        engine.startGame(named: "Hero")
        let hpBefore = engine.enemy.hp
        engine.player.restoreMana(100)
        engine.performSigil(.emberBolt)
        XCTAssertLessThan(engine.enemy.hp, hpBefore)
    }

    func testBuyFrostScrollInShop() {
        let engine = GameEngine()
        engine.startGame(named: "Hero")
        for _ in 1...5 { engine.enemy.hp = 1; engine.perform(.attack) }
        engine.chooseUpgrade(.attack)
        engine.player.addGold(500)
        engine.buySigilScroll(.frostShard)
        XCTAssertTrue(engine.sigilMastery.mastered.contains(.frostShard))
        XCTAssertEqual(engine.sigilLoadout.slots[1], .frostShard)
        XCTAssertTrue(engine.achievementState.contains(.sigilScholar))
    }

    func testBuyVenomScrollInShop() {
        let engine = GameEngine()
        engine.startGame(named: "Hero")
        for _ in 1...5 { engine.enemy.hp = 1; engine.perform(.attack) }
        engine.chooseUpgrade(.attack)
        engine.player.addGold(500)
        engine.buySigilScroll(.venomLash)
        XCTAssertTrue(engine.sigilMastery.mastered.contains(.venomLash))
        XCTAssertEqual(engine.sigilLoadout.slots[1], .venomLash)
    }

    func testBuyArcScrollInShop() {
        let engine = GameEngine()
        engine.startGame(named: "Hero")
        for _ in 1...5 { engine.enemy.hp = 1; engine.perform(.attack) }
        engine.chooseUpgrade(.attack)
        engine.player.addGold(500)
        engine.buySigilScroll(.arcLance)
        XCTAssertTrue(engine.sigilMastery.mastered.contains(.arcLance))
        XCTAssertEqual(engine.sigilLoadout.slots[1], .arcLance)
    }
}
