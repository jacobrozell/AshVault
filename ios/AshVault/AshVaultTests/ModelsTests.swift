import XCTest
@testable import AshVault

final class ModelsTests: XCTestCase {

    func testMoveManaCosts() {
        XCTAssertEqual(Move.attack.manaCost, 0)
        XCTAssertEqual(Move.dodge.manaCost, 0)
        XCTAssertEqual(Move.heal.manaCost, 0)
        XCTAssertEqual(Move.heavy.manaCost, Balance.heavyManaCost)
        XCTAssertEqual(SpellCatalog.definition(for: .emberBolt).manaCost, Balance.emberBoltManaCost)
        XCTAssertEqual(SpellCatalog.definition(for: .venomLash).manaCost, Balance.venomLashManaCost)
    }

    func testMoveCaseIterable() {
        XCTAssertEqual(Move.allCases.count, 4)
        XCTAssertTrue(Move.allCases.contains(.attack))
        XCTAssertFalse(Move.allCases.contains(where: { $0.rawValue == "Poison Dagger" }))
    }

    func testShopItemPermanentFlags() {
        XCTAssertFalse(ShopItem.potion.isPermanent)
        XCTAssertFalse(ShopItem.ether.isPermanent)
        XCTAssertFalse(ShopItem.phoenixAsh.isPermanent)
        XCTAssertTrue(ShopItem.whetstone.isPermanent)
        XCTAssertTrue(ShopItem.towerShield.isPermanent)
        XCTAssertTrue(ShopItem.heartVial.isPermanent)
        XCTAssertTrue(ShopItem.luckyCoin.isPermanent)
    }

    func testShopItemBasePrices() {
        XCTAssertEqual(ShopItem.potion.basePrice, 25)
        XCTAssertEqual(ShopItem.ether.basePrice, 20)
        XCTAssertGreaterThan(ShopItem.phoenixAsh.basePrice, ShopItem.potion.basePrice * 5)
        XCTAssertGreaterThan(ShopItem.luckyCoin.basePrice, ShopItem.potion.basePrice)
    }

    func testSkillNodeMaxLevels() {
        for node in SkillNode.allCases {
            XCTAssertEqual(node.maxLevel, 25)
        }
    }

    func testSkillNodeRelativeCosts() {
        XCTAssertGreaterThan(SkillNode.ward.cost(currentLevel: 0),
                             SkillNode.might.cost(currentLevel: 0))
        XCTAssertGreaterThan(SkillNode.patience.cost(currentLevel: 0),
                             SkillNode.might.cost(currentLevel: 0))
    }

    func testCombatantHealthFraction() {
        let p = Player(name: "Hero")
        XCTAssertEqual(p.healthFraction, 1.0, accuracy: 1e-9)
        p.takeHit(30)
        XCTAssertEqual(p.healthFraction, 0.5, accuracy: 1e-9)
        p.takeHit(999)
        XCTAssertEqual(p.healthFraction, 0.0, accuracy: 1e-9)
    }

    func testStatusKindLabelsAndBadges() {
        XCTAssertEqual(StatusKind.burn.label, "Burn")
        XCTAssertEqual(StatusKind.poison.badge, "☠️")
        XCTAssertTrue(StatusKind.burn.isDamageOverTime)
        XCTAssertFalse(StatusKind.stun.isDamageOverTime)
    }

    func testFormattingTrillionTier() {
        XCTAssertEqual(Formatting.short(1_000_000_000_000), "1.00T")
    }

    func testFormattingDoubleOverload() {
        XCTAssertEqual(Formatting.short(1500.0), "1.50K")
    }

    func testBestiaryHasExpectedRoster() {
        XCTAssertEqual(Bestiary.fodder.count, 10)
        XCTAssertEqual(Bestiary.bosses.count, 7)
        XCTAssertEqual(Bestiary.finalBoss.name, Narrative.Term.theSinter)
    }

    func testPhaseEquatable() {
        XCTAssertEqual(Phase.combat, Phase.combat)
        XCTAssertNotEqual(Phase.combat, Phase.shop)
    }

    func testMoveSymbolsAreNonEmpty() {
        for move in Move.allCases {
            XCTAssertFalse(move.sfSymbol.isEmpty)
            XCTAssertFalse(move.rawValue.isEmpty)
        }
    }

    func testShopItemMetadata() {
        for item in ShopItem.allCases {
            XCTAssertFalse(item.name.isEmpty)
            XCTAssertFalse(item.icon.isEmpty)
            XCTAssertFalse(item.blurb.isEmpty)
            XCTAssertGreaterThan(item.basePrice, 0)
        }
    }

    func testSkillNodeIconsAndBlurbs() {
        for node in SkillNode.allCases {
            XCTAssertFalse(node.name.isEmpty)
            XCTAssertFalse(node.icon.isEmpty)
            XCTAssertFalse(node.blurb.isEmpty)
        }
    }

    func testBalanceConstantsAreSane() {
        XCTAssertGreaterThan(Balance.heavyDamageMultiplier, 1.0)
        XCTAssertGreaterThan(Balance.shopPriceGrowth, 1.0)
        XCTAssertLessThanOrEqual(Balance.maxDamageReduction, 1.0)
        XCTAssertGreaterThan(Balance.prestigeShardDivisor, 0)
    }
}
