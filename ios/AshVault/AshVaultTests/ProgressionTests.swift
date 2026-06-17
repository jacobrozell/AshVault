import XCTest
@testable import AshVault

@MainActor
final class ProgressionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        return e
    }

    private func advancePastInterruptions(_ e: GameEngine) {
        resolveNonCombatPhases(e)
        if e.phase == .shop { e.leaveShop() }
    }

    private func grindToDragon(_ e: GameEngine) {
        while !(e.layer == Balance.vaultHeartLayer
                && e.enemyIndex == Balance.enemiesPerLayer && e.phase == .combat) {
            advancePastInterruptions(e)
            if e.phase == .victory { e.continueEndless() }
            if e.phase == .combat {
                e.enemy.hp = 1
                e.perform(.attack)
            }
        }
    }

    func testVictoryPhaseAfterDragon() {
        let e = engine()
        grindToDragon(e)
        e.enemy.hp = 1
        e.perform(.attack)
        advancePastInterruptions(e)
        XCTAssertEqual(e.phase, .victory)
        XCTAssertTrue(e.clearedFinalBoss)
    }

    func testContinueEndlessResumesCombat() {
        let e = engine()
        grindToDragon(e)
        e.enemy.hp = 1
        e.perform(.attack)
        advancePastInterruptions(e)
        XCTAssertEqual(e.phase, .victory)
        e.continueEndless()
        XCTAssertEqual(e.phase, .combat)
    }

    func testCancelAscensionReturnsToCombat() {
        let e = engine()
        e.enterAscension()
        XCTAssertEqual(e.phase, .ascension)
        e.cancelAscension()
        XCTAssertEqual(e.phase, .combat)
    }

    func testRecordRunTracksGoldEarned() {
        let e = engine()
        e.enemy.hp = 1
        e.perform(.attack)
        XCTAssertGreaterThan(e.player.gold, 0)
    }

    func testVitalityNodeBoostsStartingHp() {
        PrestigeStore.save(50)
        PrestigeStore.saveTree([:])
        defer { clearPersistence() }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.upgradeNode(.vitality)
        e.startGame(named: "Hero")
        XCTAssertGreaterThan(e.player.maxHp, 60)
    }

    func testPatienceNodeExtendsOfflineCap() {
        PrestigeStore.save(100)
        PrestigeStore.saveTree([:])
        defer { clearPersistence() }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        let baseCap = e.offlineCap
        e.upgradeNode(.patience)
        XCTAssertGreaterThan(e.offlineCap, baseCap)
        XCTAssertGreaterThan(e.offlineEfficiency, Balance.baseOfflineEfficiency)
    }

    func testOfflineProgressGrantsGoldOnResume() {
        let lastSeen = Date().addingTimeInterval(-7200)
        let save = GameSave(
            name: "Hero", hp: 60, maxHp: 60, attack: 25, maxAttack: 25,
            defense: 10, maxDefense: 10, luck: 3, level: 1, gold: 0,
            mana: 20, maxMana: 20, potions: 0, ethers: 0,
            layer: 1, enemyIndex: 1, scaleLevel: 0,
            clearedFinalBoss: false, victoryShown: false,
            purchaseCounts: [:], phase: "combat", autoBattle: true,
            runGoldEarned: 0, lastSeen: lastSeen
        )
        SaveStore.write(save)

        let e = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertGreaterThan(e.player.gold, 0)
        XCTAssertNotNil(e.offlineReport)
    }

    func testSkillNodeCostGrowsGeometrically() {
        let first = SkillNode.might.cost(currentLevel: 0)
        let second = SkillNode.might.cost(currentLevel: 1)
        XCTAssertGreaterThan(second, first)
    }

    func testSkillNodeMaxLevelBlocksUpgrade() {
        PrestigeStore.save(1_000_000)
        PrestigeStore.saveTree([SkillNode.might.rawValue: SkillNode.might.maxLevel])
        defer { clearPersistence() }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        XCTAssertFalse(e.canUpgrade(.might))
        e.upgradeNode(.might)
        XCTAssertEqual(e.level(of: .might), SkillNode.might.maxLevel)
    }
}
