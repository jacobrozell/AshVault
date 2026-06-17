import Foundation

/// Campaign ring names (Avasia prequel — NW penitentiary).
enum RingName {
    static func title(ring: Int) -> String {
        switch ring {
        case 1:  return "The Mouth"
        case 2:  return "Graffiti Gallery"
        case 3:  return "Manacle Hall"
        case 4:  return "Branching Dark"
        case 5:  return "Forge Descent"
        case 6:  return "Pink Saturation"
        case 7:  return "Reliquary Approach"
        case 8:  return "Binding Gallery"
        case 9:  return "Ash Choir"
        case 10: return "Vault Heart"
        default: return "Below the Seal"
        }
    }
}

/// Named wardens and ring flavor (spec §4.4, §22).
enum WardenCatalog {

    static let hess = EnemyKind(
        name: "Turnkey Hess", sprite: "🛡️", tint: "gray",
        aspect: .stone, tags: []
    )
    static let pinkBloom = EnemyKind(
        name: "Pink Bloom", sprite: "💎", tint: "pink",
        aspect: .stone, tags: []
    )
    static let echoSergeant = EnemyKind(
        name: "Echo Sergeant", sprite: "⛓️", tint: "purple",
        aspect: .ember, tags: [.undead]
    )
    static let malvekShade = EnemyKind(
        name: "Malvek's Shade", sprite: "👤", tint: "blue",
        aspect: .arc, tags: [.undead]
    )

    /// Campaign warden for this ring; generic bosses fill gaps.
    static func wardenKind(for ring: Int, rng: RandomSource) -> EnemyKind {
        switch ring {
        case 2:  return hess
        case 4:  return pinkBloom
        case 6:  return echoSergeant
        case 8:  return malvekShade
        case Balance.vaultHeartLayer: return Bestiary.finalBoss
        default: return rng.element(Bestiary.bosses) ?? Bestiary.bosses[0]
        }
    }

    static func defeatLine(for ring: Int, isFinalBoss: Bool) -> String? {
        if isFinalBoss {
            return "\"You are late. You are always late.\""
        }
        switch ring {
        case 2:  return "\"The crown pays me either way.\" — Hess"
        case 4:  return "Crystal screams without a mouth."
        case 6:  return "\"Still… on… shift…\""
        case 8:  return "\"I only wanted them to see.\" — Malvek"
        default: return nil
        }
    }

    /// First-guardian flavor when a ring begins (spec §22).
    static func guardianFlavor(for ring: Int) -> String? {
        switch ring {
        case 1:  return "A turnkey's whistle — but the shifts ended years ago."
        case 2:  return "Schism ink. Agroman numerals beside Kaefden oaths."
        case 3:  return "Wrist rings at kneeling height. Jal's generation."
        case 4:  return "A pickaxe rusts beside colorless shards."
        case 5:  return "Malvek's words carved over forge slag."
        case 6:  return "Heat without flame. Pre-Inflame dread."
        case 7:  return "A clerk's nook behind a sealed door."
        case 8:  return "Chains that bind the binder."
        case 9:  return "Whispers in condemned names."
        case 10: return "Something hot without flame stirs below."
        default: return nil
        }
    }
}
