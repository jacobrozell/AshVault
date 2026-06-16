import Foundation

/// Player-facing AshVault copy — lore beats, UI labels, and terminology.
///
/// Spec: `ios/docs/ashvault-narrative-plan.md`
enum Narrative {

    static let appName = "AshVault"

    // MARK: - Terminology (UI labels)

    enum Term {
        static let ashShards = "Ash Shards"
        static let ashTree = "Ash Tree"
        static let ashGallery = "Ash Gallery"
        static let shrine = "The Shrine"
        static let deepAshVault = "The Deep AshVault"
        static let playerRole = "crawler"
        static let ashDragon = "Ash Dragon"

        static let titleSubtitle =
            "Descend the vault. Slay the wardens.\nBreak the crown seal on the \(ashDragon)."

        static let victorySubtitle =
            "You felled the \(ashDragon) and broke the crown seal! "
            + "Now descend into the Deep AshVault — how deep can you go?"

        static let defeatSubtitle =
            "The vault claims another crawler. Your ash scatters."

        static let enterDeepAshVault = "Enter the Deep AshVault"
        static let beginCrawl = "Begin the Crawl"
        static let withdrawToShrine = "Withdraw to the Shrine"
        static let keepCrawling = "Keep crawling"
        static let campFlavor =
            "Sellswords bivouacked at the vault mouth. Hires persist forever."
        static let galleryHeader =
            "Trophies carved from warden-ash. Equip up to three passives."
        static let ascensionBody =
            "End this run to distill Ash Shards at the Shrine. "
            + "Shards permanently raise your starting power — every future crawl starts stronger."
        static let ascensionEmptyHint =
            "Earn more gold this run before withdrawing pays off."
        static let automationHint =
            "Earn your first Ash Shard to unlock automation and auto-withdraw."
        static let offlineAshTreeHint =
            "Patience in the Ash Tree extends it."

        static func ashShardsAvailable(_ count: Int) -> String {
            "\(count) \(ashShards)"
        }

        static func ashShardsAndTree(available: Int) -> String {
            "\(available) \(ashShards) · \(ashTree)"
        }

        static func ashGalleryProgress(found: Int, total: Int) -> String {
            "Relics \(found)/\(total)"
        }

        static func breakSeal(layer: Int) -> String {
            "Break the seal — Layer \(layer)"
        }

        static func withdrawGainShards(_ count: Int) -> String {
            "Withdraw — bank \(count) shards"
        }

        static let withdrawAnyway = "Withdraw anyway"
        static let openAshTree = "Open Ash Tree"
        static let relicFoundTitle = "Ash Trophy Found!"
        static let relicFoundButton = "Equip & Continue"
        static let withdrawAccessibility = "Withdraw to the Shrine and bank ash shards"

        static func withdrawAccessibility(shards: Int) -> String {
            "Withdraw to the Shrine, \(shards) ash shards banked"
        }

        static func autoWithdrawThreshold(_ min: Int) -> String {
            "When earning ≥ \(min) Ash Shards"
        }

        static let autoWithdraw = "Auto-withdraw"
        static let abandonRunMessage =
            "Your current run will be lost. Ash Shards you've already banked are kept."
        static let abandonRunAccessibilityHint =
            "Returns to the title screen without banking Ash Shards"
        static let abandonRunFooter =
            "Return to the title screen. Run progress and unbanked gold won't become Ash Shards."

        static func autoWithdrawActiveFooter(pending: Int) -> String {
            "During auto-battle, withdraw automatically when pending Ash Shards reach the threshold. Current pending: \(pending)."
        }
    }

    // MARK: - Story beats (combat log & milestones)

    enum Beat: Equatable {
        case welcome(name: String)
        case tutorial(index: Int)
        case layerEntry(layer: Int)
        case bossSpawn(isFinalBoss: Bool)
        case relicNew(name: String, icon: String)
        case relicDuplicate(gold: Int)
        case ascensionGained(shards: Int)
        case ascensionEmpty
        case ascensionFollowUp
        case dragonSlain
        case crownSealBroken
        case defeatScatter
        case milestoneFirstShard
        case milestoneFirstRelic
        case milestoneFirstMercenary
        case milestoneAutomationUnlock
    }

    static func text(for beat: Beat) -> String {
        switch beat {
        case .welcome(let name):
            return "Welcome to \(appName), \(name)!"
        case .tutorial(let index):
            switch index {
            case 0:
                return "\(appName) sleeps beneath the old empire — seals, wardens, and ash that never cools."
            case 1:
                return "Clear five guardians per ring. Every fifth is a warden who holds the next seal."
            default:
                return "Break the crown seal on the \(Term.ashDragon). Then keep going."
            }
        case .layerEntry(let layer):
            return layerEntry(layer: layer) ?? ""
        case .bossSpawn(let isFinalBoss):
            if isFinalBoss {
                return "The \(Term.ashDragon) — last warden of the crown seal."
            }
            return "A warden rises to hold the seal."
        case .relicNew(let name, let icon):
            return "A sliver of the warden's ash. The vault lets you keep this — \(name)! \(icon)"
        case .relicDuplicate(let gold):
            return "More ash-dust — \(Formatting.short(gold))g scraped from the seal."
        case .ascensionGained(let shards):
            return "You climb back to the Shrine. \(shards) Ash Shards harden in your grasp."
        case .ascensionEmpty:
            return "You withdraw, but this run left little to distill."
        case .ascensionFollowUp:
            return "Plant them in the Ash Tree before you crawl again."
        case .dragonSlain:
            return "You felled the \(Term.ashDragon)! 🐉"
        case .crownSealBroken:
            return "The crown seal shatters. The Vault exhales. The map ends. The descent does not."
        case .defeatScatter:
            return "The vault claims another crawler. Your ash scatters."
        case .milestoneFirstShard:
            return "The Shrine remembers you now."
        case .milestoneFirstRelic:
            return "The Ash Gallery gains its first trophy."
        case .milestoneFirstMercenary:
            return "A sellsword signs on at the vault mouth."
        case .milestoneAutomationUnlock:
            return "The crawl can continue without your hand — the camp takes over."
        }
    }

    /// Optional flavor when the first enemy of a ring spawns.
    static func layerEntry(layer: Int) -> String? {
        switch layer {
        case 1:  return "The air tastes of old incense and burnt gold."
        case 5:  return "The crown vault. The \(Term.ashDragon) stirs beneath the seal."
        case 6...9: return "No architect planned this deep."
        case 10...: return "The ash here is older than the empire."
        case 3, 4: return "Ring \(layer) — the stone grows warmer."
        default: return nil
        }
    }

    static var tutorialLineCount: Int { 3 }

    // MARK: - Onboarding (first-run walkthrough)

    struct OnboardingPage: Identifiable, Equatable {
        let id: Int
        let symbol: String
        let title: String
        let body: String
        let bullets: [String]
    }

    enum Onboarding {
        static let skip = "Skip"
        static let next = "Next"
        static let getStarted = "Get Started"
        static let howToPlay = "How to Play"

        static let pages: [OnboardingPage] = [
            OnboardingPage(
                id: 0,
                symbol: "building.columns.fill",
                title: "Welcome to \(appName)",
                body: "You are an ash-crawler descending a buried imperial vault — ring by ring, seal by seal.",
                bullets: [
                    "Fight through five guardians per ring; every fifth is a warden-boss.",
                    "Break the crown seal on the \(Term.ashDragon) to open the endless Deep AshVault.",
                    "Return to \(Term.shrine) between runs to grow permanently stronger."
                ]
            ),
            OnboardingPage(
                id: 1,
                symbol: "burst.fill",
                title: "Combat",
                body: "Turn-based fights in the vault. Pick a move each turn — or let auto-battle play for you.",
                bullets: [
                    "Attack, Dodge, and Heal cost no mana.",
                    "Heavy Strike, Magic Bolt, and Poison Dagger spend mana for extra effects.",
                    "Use potions and ethers from your inventory when you need a heal or full mana."
                ]
            ),
            OnboardingPage(
                id: 2,
                symbol: "arrow.down.circle.fill",
                title: "The Crawl",
                body: "Each boss you fell makes you stronger and opens the merchant between rings.",
                bullets: [
                    "After a warden: choose Attack, Defense, or Health, then visit the shop.",
                    "Spend gold on consumables and run-long upgrades (Whetstone, Shield, and more).",
                    "Hire mercenaries at the camp — they persist forever and boost your damage."
                ]
            ),
            OnboardingPage(
                id: 3,
                symbol: "sparkles",
                title: "Withdraw & \(Term.ashTree)",
                body: "Tap ✨ during a run to \(Term.withdrawToShrine.lowercased()) and bank \(Term.ashShards.lowercased()).",
                bullets: [
                    "Shards are permanent — run gold is lost when you withdraw or die.",
                    "Plant shards in the \(Term.ashTree) for lasting Attack, HP, gold, defense, and offline gains.",
                    "After your first shard, automation can auto-resolve level-ups and the shop."
                ]
            ),
            OnboardingPage(
                id: 4,
                symbol: "archivebox.fill",
                title: "Relics & Idle Play",
                body: "Bosses may drop ash trophies. Collect them, equip passives, and let the camp work while you're away.",
                bullets: [
                    "View and equip relics in the \(Term.ashGallery) (up to three at once).",
                    "Mercenary DPS helps in combat and earns offline gold when you close the app.",
                    "Patience in the \(Term.ashTree) extends offline earnings."
                ]
            ),
        ]
    }
}
