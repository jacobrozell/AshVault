import XCTest
@testable import AshVault

final class PlayerTests: XCTestCase {

    func testBaseStatsMatchJavaOriginal() {
        let p = Player(name: "Hero")
        XCTAssertEqual(p.hp, 60)
        XCTAssertEqual(p.attack, 25)
        XCTAssertEqual(p.defense, 10)
        XCTAssertEqual(p.luck, 3)
        XCTAssertEqual(p.level, 1)
        XCTAssertEqual(p.gold, 0)
    }

    func testEmptyNameFallsBackToDelver() {
        XCTAssertEqual(Player(name: "").name, "Delver")
        XCTAssertEqual(Player(name: "Aria").name, "Aria")
    }

    func testLevelUpAttackBumpsChosenStatMoreAndRestores() {
        let p = Player(name: "Hero")
        p.takeHit(40)                 // hp 20
        p.levelUp(.attack)
        XCTAssertEqual(p.level, 2)
        XCTAssertEqual(p.attack, 35)  // +10 chosen
        XCTAssertEqual(p.defense, 15) // +5 others
        XCTAssertEqual(p.maxHp, 70)   // +10 others
        XCTAssertEqual(p.hp, 70)      // fully restored
    }

    func testLevelUpHealthBumpsHpBy20() {
        let p = Player(name: "Hero")
        p.levelUp(.health)
        XCTAssertEqual(p.maxHp, 80)   // +20 chosen
        XCTAssertEqual(p.attack, 30)  // +5 others
        XCTAssertEqual(p.defense, 15) // +5 others
    }

    func testRestoreHpClampsToMax() {
        let p = Player(name: "Hero")
        p.takeHit(10)
        p.restoreHp(999)
        XCTAssertEqual(p.hp, p.maxHp)
    }

    func testManaSpendAndRestoreClamp() {
        let p = Player(name: "Hero")
        p.spendMana(8)
        XCTAssertEqual(p.mana, 12)
        p.spendMana(999)
        XCTAssertEqual(p.mana, 0)     // never negative
        p.restoreMana(999)
        XCTAssertEqual(p.mana, p.maxMana)
    }

    func testTakeHitFloorsAtZero() {
        let p = Player(name: "Hero")
        p.takeHit(9999)
        XCTAssertEqual(p.hp, 0)
        XCTAssertFalse(p.isAlive)
    }

    func testSpendGoldReturnsFalseWhenBroke() {
        let p = Player(name: "Hero")
        XCTAssertFalse(p.spendGold(1))
        p.addGold(10)
        XCTAssertTrue(p.spendGold(10))
        XCTAssertEqual(p.gold, 0)
    }

    func testUseEtherRefillsMana() {
        let p = Player(name: "Hero")
        p.addEthers(1)
        p.spendMana(p.mana)
        XCTAssertTrue(p.useEther())
        XCTAssertEqual(p.mana, p.maxMana)
        XCTAssertEqual(p.ethers, 0)
    }

    func testImproveLuckFloorsAtOne() {
        let p = Player(name: "Hero")
        for _ in 0..<10 { p.improveLuck() }
        XCTAssertEqual(p.luck, 1)
    }

    func testApplyPrestigeScalesStats() {
        let p = Player(name: "Hero")
        p.applyPrestige(attackMult: 1.1, hpMult: 1.2)
        XCTAssertEqual(p.attack, 28) // 25 × 1.1 rounded
        XCTAssertEqual(p.maxHp, 72)  // 60 × 1.2 rounded
    }

    func testLevelUpDefenseBumpsDefenseByTen() {
        let p = Player(name: "Hero")
        p.levelUp(.defense)
        XCTAssertEqual(p.defense, 20)
        XCTAssertEqual(p.attack, 30)
        XCTAssertEqual(p.maxHp, 70)
    }

    func testUsePotionFailsWhenEmpty() {
        let p = Player(name: "Hero")
        XCTAssertFalse(p.usePotion())
    }

    func testShopPermanentUpgrades() {
        let p = Player(name: "Hero")
        p.upgradeAttack()
        p.upgradeDefense()
        p.upgradeMaxHp()
        XCTAssertEqual(p.attack, 30)
        XCTAssertEqual(p.defense, 15)
        XCTAssertEqual(p.maxHp, 75)
    }

    func testAddGoldAccumulates() {
        let p = Player(name: "Hero")
        p.addGold(50)
        p.addGold(25)
        XCTAssertEqual(p.gold, 75)
    }

    func testLevelUpRestoresMana() {
        let p = Player(name: "Hero")
        p.spendMana(15)
        p.levelUp(.attack)
        XCTAssertEqual(p.mana, p.maxMana)
        XCTAssertEqual(p.maxMana, 25)
    }

    func testUsePotionHealScalesWithLevel() {
        let p = Player(name: "Hero")
        p.addPotions(1)
        p.levelUp(.attack)
        p.takeHit(50)
        let hpBefore = p.hp
        p.usePotion()
        XCTAssertEqual(p.hp, hpBefore + 15 * p.level)
    }

    func testUpgradeLabelsAndIcons() {
        for upgrade in Player.Upgrade.allCases {
            XCTAssertFalse(upgrade.label.isEmpty)
            XCTAssertFalse(upgrade.icon.isEmpty)
        }
    }
}
