import XCTest
@testable import AshVault

/// A `RandomSource` that returns a scripted queue of values, so tests can force
/// exact hit/crit/proc/spawn outcomes. Once the queue is exhausted it returns
/// `fallback` (clamped into the requested range).
final class ScriptedRandom: RandomSource {
    private var queue: [Int]
    private let fallback: Int

    /// - Parameters:
    ///   - values: rolls returned in order (each interpreted within the asked range).
    ///   - fallback: value returned after the queue empties (default 0 → always "hit"
    ///     for `checkHit`, "no crit" for `chance`, first element for `element`).
    init(_ values: [Int] = [], fallback: Int = 0) {
        self.queue = values
        self.fallback = fallback
    }

    func roll(_ range: Range<Int>) -> Int {
        let raw = queue.isEmpty ? fallback : queue.removeFirst()
        guard !range.isEmpty else { return range.lowerBound }
        // Clamp into range so a scripted value can't crash the generator.
        return min(max(raw, range.lowerBound), range.upperBound - 1)
    }
}

/// Start a run through oath select (for tests).
@MainActor
func startTestRun(_ engine: GameEngine, named name: String = "Hero", oath: DelverOath = .hound) {
    engine.startGame(named: name, automaticOath: oath)
}

/// Clear persisted run/prestige/meta data so `GameEngine.init` doesn't restore stale saves.
func clearPersistence() {
    SaveStore.clear()
    PrestigeStore.save(0)
    PrestigeStore.saveTree([:])
    MetaStore.clearAll()
    BestRun.empty.save()
    AutoDescendSettings.setEnabled(false)
}

/// Kill fodder then the ring warden to trigger ring choice.
@MainActor
func killBossRing(_ e: GameEngine) {
    while e.phase == .combat, e.enemyIndex < Balance.enemiesPerLayer {
        e.enemy.hp = 1
        e.perform(.attack)
        resolveNonCombatPhases(e)
    }
    if e.phase == .combat, e.enemyIndex == Balance.enemiesPerLayer {
        e.enemy.hp = 1
        e.perform(.attack)
    }
}

/// Auto-resolve draft / ring-choice / oath pauses during tests.
@MainActor
func resolveNonCombatPhases(_ e: GameEngine) {
    var steps = 0
    while steps < 24 {
        steps += 1
        switch e.phase {
        case .oathSelect:
            e.chooseDelverOath(.hound)
        case .draft:
            guard let pick = e.draftOptions.first else { return }
            e.chooseDraft(pick)
        case .ringChoice:
            e.pushDeeper()
        case .ringIngress:
            if let door = e.doorOffers.first(where: { $0.kind == .guardPatrol }) ?? e.doorOffers.first {
                e.chooseDoor(door)
            }
        case .sealedRoom:
            e.chooseSealedRoom(copy: false)
        case .levelUp:
            e.chooseUpgrade(.attack)
        default:
            return
        }
    }
}

/// Clear ring choice by camping through the shop.
@MainActor
func campAndAdvance(_ e: GameEngine) {
    guard e.phase == .ringChoice else { return }
    e.enterCamp()
    e.leaveShop()
}

extension XCTestCase {
    /// `checkHit` lands when roll >= chance; a roll of 9 (max d10) always lands,
    /// a roll of 0 lands only when chance == 0. These helpers make intent clear.
    func alwaysHitRNG() -> ScriptedRandom { ScriptedRandom(fallback: 9) }
    func alwaysMissRNG() -> ScriptedRandom { ScriptedRandom(fallback: 0) } // misses when chance > 0

    /// `startGame` consumes one RNG roll for enemy spawn; prefix a throwaway value.
    func combatRNG(_ values: [Int], fallback: Int = 0) -> ScriptedRandom {
        ScriptedRandom([0] + values, fallback: fallback)
    }
}
