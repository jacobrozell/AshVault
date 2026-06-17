import Foundation

/// A single enemy archetype: name plus the sprite/colour used to draw it.
struct EnemyKind {
    let name: String
    let sprite: String   // emoji "sprite"
    let tint: String     // asset/colour name hint, resolved in the view layer
    let aspect: Element
    let tags: Set<EnemyTag>
}

/// The bestiary. The first five names match the Java original
/// (Goblin, Troll, Pixie, Wolf, Gnoll); the rest are new to the iOS clone
/// to give each layer more variety.
enum Bestiary {
    static let fodder: [EnemyKind] = [
        EnemyKind(name: "Goblin",       sprite: "👺", tint: "green",  aspect: .stone, tags: [.fey]),
        EnemyKind(name: "Troll",        sprite: "🧌", tint: "green",  aspect: .stone, tags: []),
        EnemyKind(name: "Pixie",        sprite: "🧚", tint: "pink",   aspect: .stone, tags: [.fey]),
        EnemyKind(name: "Wolf",         sprite: "🐺", tint: "gray",   aspect: .frost, tags: [.wild]),
        EnemyKind(name: "Gnoll",        sprite: "🦴", tint: "brown",  aspect: .frost, tags: [.wild]),
        EnemyKind(name: "Skeleton",     sprite: "💀", tint: "gray",   aspect: .ember, tags: [.undead]),
        EnemyKind(name: "Giant Spider", sprite: "🕷️", tint: "purple", aspect: .venom, tags: []),
        EnemyKind(name: "Slime",        sprite: "🟢", tint: "green",  aspect: .stone, tags: []),
        EnemyKind(name: "Bat Swarm",    sprite: "🦇", tint: "purple", aspect: .arc,   tags: [.wild]),
        EnemyKind(name: "Cave Imp",     sprite: "👹", tint: "red",    aspect: .ember, tags: [.fey]),
    ]

    /// Mid-layer bosses (the original five plus extras).
    static let bosses: [EnemyKind] = [
        EnemyKind(name: "Blue Dragon Boss",            sprite: "🐲", tint: "blue",   aspect: .frost, tags: [.wyrm]),
        EnemyKind(name: "Giant Troll Boss",            sprite: "🧌", tint: "green",  aspect: .stone, tags: []),
        EnemyKind(name: "Warlord Shaman Boss",         sprite: "🧙", tint: "purple", aspect: .arc,   tags: []),
        EnemyKind(name: "Treasure Seeker Goblin Boss", sprite: "🤑", tint: "yellow", aspect: .stone, tags: [.fey]),
        EnemyKind(name: "Bloodthirsty Gnoll Boss",     sprite: "🐗", tint: "red",    aspect: .frost, tags: [.wild]),
        EnemyKind(name: "Lich King Boss",              sprite: "☠️", tint: "purple", aspect: .ember, tags: [.undead]),
        EnemyKind(name: "Minotaur Boss",               sprite: "🐂", tint: "brown",  aspect: .stone, tags: []),
    ]

    static let finalBoss = EnemyKind(
        name: Narrative.Term.theSinter, sprite: "🌫️", tint: "pink",
        aspect: .ember, tags: [.undead]
    )
}

/// An enemy instance, ported from `Enemy.java`.
///
/// In the Java version the per-enemy max stats were `static`, so every enemy
/// permanently strengthened the *whole* bestiary as the run went on. The clone
/// reproduces that escalating difficulty by feeding the cumulative scaling in
/// through `scaleLevel` (managed by `GameEngine`) rather than via globals.
final class Enemy: Combatant {
    let name: String
    let sprite: String
    let tint: String
    let aspect: Element
    let tags: Set<EnemyTag>

    var hp: Int
    private(set) var maxHp: Int
    private(set) var attack: Int
    private(set) var defense: Int
    private(set) var luck: Int
    private(set) var level: Int
    var statuses: [StatusEffect] = []

    let isBoss: Bool

    /// Base stats match the Java defaults: HP 50 / ATK 15 / DEF 5 / luck 5.
    ///
    /// `postGameDepth` is `layer - 5` once the dragon is beaten (0 during the
    /// faithful layers 1–5). In the endless "score chase" it compounds enemy
    /// stats so that no linear/polynomial player build can keep up forever —
    /// every run eventually ends. Pre-game balance is untouched.
    init(kind: EnemyKind, scaleLevel: Int, layer: Int = 1,
         isBoss: Bool, isFinalBoss: Bool, postGameDepth: Int) {
        self.name = kind.name
        self.sprite = kind.sprite
        self.tint = kind.tint
        self.aspect = kind.aspect
        self.tags = kind.tags
        self.isBoss = isBoss

        let postGame = postGameDepth > 0

        // Cumulative scaling: every completed group of 5 strengthens the line.
        var hpStat = Balance.enemyBaseHp + Balance.enemyScaleHpPerGroup * scaleLevel
        var atkStat = Balance.enemyBaseAtk + Balance.enemyScaleAtkPerGroup * scaleLevel
        var defStat = Balance.enemyBaseDef + Balance.enemyScaleDefPerGroup * scaleLevel
        var luckStat = 5
        var lvl = 1 + scaleLevel

        // Luck improved (became 3, i.e. easier to hit you) once the bestiary
        // reached level 4 in the original; post-game it's pinned harsher.
        if scaleLevel + 1 >= 4 { luckStat = 3 }
        if postGame { luckStat = 1 }

        if isFinalBoss {
            // Vault Heart — The Sinter (reliquary horror).
            hpStat = 150
            atkStat = 95
            defStat = 0
            lvl = max(lvl, 6)
        } else if isBoss {
            // Bosses get a flat bump over the current fodder line.
            hpStat += Balance.enemyBossHpBonus
            atkStat += Balance.enemyBossAtkBonus
            defStat = max(0, defStat - 5)
            if !postGame { luckStat += 1 }
        }

        // Campaign layers 2–5 ramp on top of scaleLevel (pre-dragon only).
        if postGameDepth == 0, layer > 1, !isFinalBoss {
            let layerM = 1.0 + Balance.campaignLayerStatGrowth * Double(layer - 1)
            hpStat = Int((Double(hpStat) * layerM).rounded())
            atkStat = Int((Double(atkStat) * layerM).rounded())
            defStat = Int((Double(defStat) * layerM).rounded())
        }

        // Endless escalation:
        // eventually outscale any build (HP outpaces your damage, ATK outpaces
        // your defense). Ramps gently from ~1.15× at the first post-game layer.
        if postGame {
            let hpM = pow(Balance.enemyEndlessHpGrowth, Double(postGameDepth))
            let atkM = pow(Balance.enemyEndlessAtkGrowth, Double(postGameDepth))
            hpStat = Int((Double(hpStat) * hpM).rounded())
            atkStat = Int((Double(atkStat) * atkM).rounded())
            defStat = Int((Double(defStat) * atkM).rounded())
        }

        self.maxHp = hpStat
        self.hp = hpStat
        self.attack = atkStat
        self.defense = defStat
        self.luck = luckStat
        self.level = lvl
    }

    /// Gold reward: attack × level, scaled by `Balance.goldRewardScale`.
    func generateGold() -> Int {
        Int((Double(attack * level) * Balance.goldRewardScale).rounded())
    }

    /// Scale current combat stats (ring modifiers, elite routes, supply starvation).
    func scaleStats(hpMultiplier: Double, atkMultiplier: Double) {
        guard hpMultiplier != 1.0 || atkMultiplier != 1.0 else { return }
        let newMax = max(1, Int((Double(maxHp) * hpMultiplier).rounded()))
        maxHp = newMax
        hp = min(hp, newMax)
        attack = max(1, Int((Double(attack) * atkMultiplier).rounded()))
    }
}
