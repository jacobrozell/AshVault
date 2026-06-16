import XCTest
@testable import AshVault

final class SerializationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    func testGameSaveCodableRoundTrip() throws {
        let original = GameSave(
            name: "Aria", hp: 45, maxHp: 70, attack: 30, maxAttack: 35,
            defense: 15, maxDefense: 20, luck: 2, level: 3, gold: 250,
            mana: 12, maxMana: 25, potions: 2, ethers: 1,
            layer: 3, enemyIndex: 2, scaleLevel: 1,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: ["whetstone": 1], phase: "combat",
            autoBattle: true, runGoldEarned: 500,
            lastSeen: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameSave.self, from: data)
        XCTAssertEqual(decoded.name, "Aria")
        XCTAssertEqual(decoded.layer, 3)
        XCTAssertEqual(decoded.gold, 250)
        XCTAssertEqual(decoded.purchaseCounts["whetstone"], 1)
        XCTAssertEqual(decoded.autoBattle, true)
        XCTAssertEqual(decoded.runGoldEarned, 500)
    }

    func testPlayerRestoresFromGameSave() {
        let save = GameSave(
            name: "Aria", hp: 40, maxHp: 80, attack: 35, maxAttack: 40,
            defense: 18, maxDefense: 20, luck: 2, level: 4, gold: 99,
            mana: 10, maxMana: 30, potions: 3, ethers: 2,
            layer: 2, enemyIndex: 3, scaleLevel: 1,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: false,
            runGoldEarned: 0, lastSeen: Date()
        )
        let p = Player(restoring: save)
        XCTAssertEqual(p.name, "Aria")
        XCTAssertEqual(p.hp, 40)
        XCTAssertEqual(p.attack, 35)
        XCTAssertEqual(p.level, 4)
        XCTAssertEqual(p.potions, 3)
        XCTAssertEqual(p.ethers, 2)
        XCTAssertTrue(p.statuses.isEmpty)
    }

    func testBestRunLoadClampsMinimums() {
        let d = UserDefaults.standard
        d.set(0, forKey: "best.layer")
        d.set(0, forKey: "best.level")
        d.set(50, forKey: "best.gold")
        defer { BestRun.empty.save() }
        let loaded = BestRun.load()
        XCTAssertEqual(loaded.layer, 1)
        XCTAssertEqual(loaded.level, 1)
        XCTAssertEqual(loaded.gold, 50)
    }

    func testSaveStoreWriteReadClear() {
        let save = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 25, maxAttack: 25,
            defense: 10, maxDefense: 10, luck: 3, level: 1, gold: 0,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 1, enemyIndex: 1, scaleLevel: 0,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: false,
            runGoldEarned: 0, lastSeen: Date()
        )
        SaveStore.write(save)
        XCTAssertNotNil(SaveStore.read())
        SaveStore.clear()
        XCTAssertNil(SaveStore.read())
    }
}
