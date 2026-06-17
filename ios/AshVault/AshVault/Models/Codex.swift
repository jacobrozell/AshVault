import Foundation

/// Lore entries unlocked by depth, bosses, and choices (spec §24).
enum CodexID: String, CaseIterable, Codable, Identifiable {
    case nwPenitentiary
    case twoHands
    case jalChains
    case theMiner
    case malvek
    case anulaBleed
    case clerkBera
    case theBinding
    case commanderPell
    case delverSeven
    case theSinter
    case suppression
    case threeMages
    case ashShape
    case lanternHabit
    case turnkeyHess
    case echoSergeant
    case delverOaths
    case surfaceCamp
    case belowTheSeal

    var id: String { rawValue }
}

struct CodexEntry: Identifiable, Equatable {
    let id: CodexID
    let title: String
    let body: String
    let unlockRing: Int?
    let unlockOnCopy: Bool

    var idKey: String { id.rawValue }
}

enum Codex {

    static let catalog: [CodexEntry] = [
        CodexEntry(id: .nwPenitentiary, title: "NW Penitentiary",
                   body: Narrative.Codex.nwPenitentiary, unlockRing: 1, unlockOnCopy: false),
        CodexEntry(id: .twoHands, title: "Two Hands on One Wrist",
                   body: Narrative.Codex.twoHands, unlockRing: 2, unlockOnCopy: false),
        CodexEntry(id: .jalChains, title: "Chains Below the Forge",
                   body: Narrative.Codex.jalChains, unlockRing: 3, unlockOnCopy: false),
        CodexEntry(id: .theMiner, title: "The Miner's Warning",
                   body: Narrative.Codex.theMiner, unlockRing: 4, unlockOnCopy: false),
        CodexEntry(id: .malvek, title: "Let Them See",
                   body: Narrative.Codex.malvek, unlockRing: 5, unlockOnCopy: false),
        CodexEntry(id: .anulaBleed, title: "Anula Bleed",
                   body: Narrative.Codex.anulaBleed, unlockRing: 6, unlockOnCopy: false),
        CodexEntry(id: .clerkBera, title: "The Clerk's Nook",
                   body: Narrative.Codex.clerkBera, unlockRing: nil, unlockOnCopy: true),
        CodexEntry(id: .theBinding, title: "The Binding",
                   body: Narrative.Codex.theBinding, unlockRing: 8, unlockOnCopy: false),
        CodexEntry(id: .commanderPell, title: "Commander Pell",
                   body: Narrative.Codex.commanderPell, unlockRing: 8, unlockOnCopy: false),
        CodexEntry(id: .delverSeven, title: "Delver 7",
                   body: Narrative.Codex.delverSeven, unlockRing: 10, unlockOnCopy: false),
        CodexEntry(id: .theSinter, title: "The Sinter",
                   body: Narrative.Codex.theSinter, unlockRing: 10, unlockOnCopy: false),
        CodexEntry(id: .suppression, title: "The Suppression",
                   body: Narrative.Codex.suppression, unlockRing: 10, unlockOnCopy: false),
        CodexEntry(id: .threeMages, title: "Three Mages",
                   body: Narrative.Codex.threeMages, unlockRing: 10, unlockOnCopy: false),
        CodexEntry(id: .ashShape, title: "Ash Shape",
                   body: Narrative.Codex.ashShape, unlockRing: 6, unlockOnCopy: false),
        CodexEntry(id: .lanternHabit, title: "Lantern Habit",
                   body: Narrative.Codex.lanternHabit, unlockRing: 1, unlockOnCopy: false),
        CodexEntry(id: .turnkeyHess, title: "Turnkey Hess",
                   body: Narrative.Codex.turnkeyHess, unlockRing: 2, unlockOnCopy: false),
        CodexEntry(id: .echoSergeant, title: "Echo Sergeant",
                   body: Narrative.Codex.echoSergeant, unlockRing: 6, unlockOnCopy: false),
        CodexEntry(id: .delverOaths, title: "Delver Oaths",
                   body: Narrative.Codex.delverOaths, unlockRing: 1, unlockOnCopy: false),
        CodexEntry(id: .surfaceCamp, title: "Surface Camp",
                   body: Narrative.Codex.surfaceCamp, unlockRing: 1, unlockOnCopy: false),
        CodexEntry(id: .belowTheSeal, title: "Below the Seal",
                   body: Narrative.Codex.belowTheSeal, unlockRing: 11, unlockOnCopy: false),
    ]

    static func entry(for id: CodexID) -> CodexEntry? {
        catalog.first { $0.id == id }
    }

    /// Unlock every entry whose ring threshold is met.
    static func unlocks(forRing ring: Int) -> [CodexID] {
        catalog.compactMap { entry in
            guard let need = entry.unlockRing, ring >= need, !entry.unlockOnCopy else { return nil }
            return entry.id
        }
    }
}
