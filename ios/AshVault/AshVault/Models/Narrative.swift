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
        static let shrineRecords = "Shrine Records"
        static let sigilBench = "Sigil Bench"
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
            "Permanent hires — they never leave between runs. DPS adds to your attacks and offline gold."
        static let mercenaryPermanent =
            "Owned forever · DPS stacks with milestones at 25, 50, 100…"
        static let progressionAfterVictory =
            "Tap ✨ anytime to withdraw and bank Ash Shards. Spend them in the Ash Tree so every crawl starts stronger."
        static let progressionEndless =
            "The crown seal is broken — keep descending for score, gold, and relics. Withdraw when you're ready to grow permanent power."
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

        static func shrineRecordsProgress(unlocked: Int, total: Int) -> String {
            "Shrine Records \(unlocked)/\(total)"
        }

        static func achievementBonusSummary(goldPercent: Int, hpPercent: Int) -> String? {
            var parts: [String] = []
            if goldPercent > 0 { parts.append("+\(goldPercent)% gold") }
            if hpPercent > 0 { parts.append("+\(hpPercent)% starting HP") }
            guard !parts.isEmpty else { return nil }
            return parts.joined(separator: " · ") + " from trophies"
        }

        static let achievementBackfillTitle = "The Shrine Remembers"
        static let achievementBackfillBody =
            "The Shrine remembers your past crawls. Your trophies wait in the records."
        static let achievementUnlockToastTitle = "Trophy earned"

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
        case progressionAfterDragon
        case defeatScatter
        case firstDeathTwist
        case phoenixAshRevive
        case milestoneFirstShard
        case milestoneFirstRelic
        case milestoneFirstMercenary
        case milestoneAutomationUnlock
        case achievementSealBreaker
        case achievementFirstWithdrawal
        case achievementDeepAshVault
        case loadoutIntro
        case aspectIntro(aspect: Element)
        case aspectWeak
        case aspectResist
        case sigilScroll
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
        case .progressionAfterDragon:
            return Term.progressionEndless
        case .defeatScatter:
            return "The vault claims another crawler. Your ash scatters."
        case .firstDeathTwist:
            return "Ha. You thought this was a little idle game?"
        case .phoenixAshRevive:
            return "Phoenix Ash flares! You stagger back at \(Balance.phoenixAshReviveHpPercent)% HP — once per run."
        case .milestoneFirstShard:
            return "The Shrine remembers you now."
        case .milestoneFirstRelic:
            return "The Ash Gallery gains its first trophy."
        case .milestoneFirstMercenary:
            return "A sellsword signs on at the vault mouth."
        case .milestoneAutomationUnlock:
            return "The crawl can continue without your hand — the camp takes over."
        case .achievementSealBreaker:
            return "The Shrine etches your name among seal-breakers."
        case .achievementFirstWithdrawal:
            return "The Shrine records your first withdrawal."
        case .achievementDeepAshVault:
            return "The Shrine notes how deep you have crawled."
        case .loadoutIntro:
            return "Three sigils. Choose before you descend."
        case .aspectIntro(let aspect):
            return "This one bears the \(aspect.displayName) aspect. Match your sigil."
        case .aspectWeak:
            return "The ash remembers what burns what."
        case .aspectResist:
            return "Wrong sigil. The guardian barely flinches."
        case .sigilScroll:
            return "A scrap of ritual. Slot it before the next ring."
        }
    }

    // MARK: - Achievements (Shrine Records)

    enum Achievement {
        static func name(for id: AchievementID) -> String {
            switch id {
            case .firstBlood: return "First Blood"
            case .firstFall: return "First Fall"
            case .tenDeaths: return "Familiar Scattering"
            case .layer3Reach: return "Ring Three"
            case .dragonSlain: return "Seal-Breaker"
            case .deep10: return "Deep AshVault X"
            case .deep25: return "Deep AshVault XXV"
            case .deep50: return "Deep AshVault L"
            case .newBestLayer: return "Personal Best"
            case .phoenixRise: return "Ashen Resurrection"
            case .noPhoenixClear: return "Uninsured Victory"
            case .firstWithdrawal: return "First Withdrawal"
            case .tenWithdrawals: return "Habitual Pilgrim"
            case .shardHoarder: return "Shard Hoarder"
            case .might5: return "Might V"
            case .ward10: return "Ward X"
            case .treeMaxOne: return "Branch to the Sky"
            case .gold1k: return "Pocket of Ash"
            case .gold100k: return "Treasury Taster"
            case .gold1m: return "Vault's Ledger"
            case .hireFirstMerc: return "Signed at the Mouth"
            case .milestone25: return "Quarter Century"
            case .fullRoster: return "Full Camp"
            case .knightOwner: return "Knight's Banner"
            case .phoenixBuyer: return "Bought Insurance"
            case .firstRelic: return "First Trophy"
            case .fullGallery: return "Complete Gallery"
            case .boss10: return "Warden Hunter"
            case .boss100: return "Warden Breaker"
            case .equipThree: return "Triple Crown"
            case .idleCap: return "Clock's Edge"
            case .autoWithdraw: return "Hands-Off Pilgrim"
            case .firstCrit: return "Lucky Strike"
            case .surviveOneshot: return "Still Standing"
            case .weakSigil: return "Aspect Reader"
            case .sigilScholar: return "Second Binding"
            }
        }

        static func description(for id: AchievementID) -> String {
            switch id {
            case .firstBlood: return "Slay your first enemy."
            case .firstFall: return "Die once in the vault."
            case .tenDeaths: return "Die ten times."
            case .layer3Reach: return "Clear layer 3."
            case .dragonSlain: return "Slay the Ash Dragon once."
            case .deep10: return "Reach layer 10."
            case .deep25: return "Reach layer 25."
            case .deep50: return "Reach layer 50."
            case .newBestLayer: return "Set a personal best of layer 6 or deeper."
            case .phoenixRise: return "Revive with Phoenix Ash once."
            case .noPhoenixClear: return "Slay the Ash Dragon without using Phoenix Ash."
            case .firstWithdrawal: return "Withdraw to the Shrine once."
            case .tenWithdrawals: return "Withdraw ten times."
            case .shardHoarder: return "Bank fifty Ash Shards."
            case .might5: return "Raise Might to level 5."
            case .ward10: return "Raise Ward to level 10."
            case .treeMaxOne: return "Max out any Ash Tree branch."
            case .gold1k: return "Earn 1,000 gold across all runs."
            case .gold100k: return "Earn 100,000 gold across all runs."
            case .gold1m: return "Earn 1,000,000 gold across all runs."
            case .hireFirstMerc: return "Hire your first mercenary."
            case .milestone25: return "Own 25 of any mercenary tier."
            case .fullRoster: return "Own at least one of every mercenary."
            case .knightOwner: return "Hire a knight."
            case .phoenixBuyer: return "Buy Phoenix Ash once."
            case .firstRelic: return "Discover your first relic."
            case .fullGallery: return "Discover every relic."
            case .boss10: return "Slay ten wardens."
            case .boss100: return "Slay one hundred wardens."
            case .equipThree: return "Equip three relics at once."
            case .idleCap: return "Hit the offline earnings cap."
            case .autoWithdraw: return "Auto-withdraw to the Shrine."
            case .firstCrit: return "Land your first critical hit."
            case .surviveOneshot: return "Survive a hit dealing at least 45% max HP."
            case .weakSigil: return "Land your first super-effective sigil."
            case .sigilScholar: return "Master a second sigil scroll."
            }
        }

        static func lore(for id: AchievementID) -> String {
            switch id {
            case .firstBlood: return "The Shrine notes the first ash you scattered."
            case .firstFall: return "You laughed. The Vault did not."
            case .tenDeaths: return "The Shrine stops counting the first way you broke."
            case .layer3Reach: return "Beyond the easy rings, the stone grows warm."
            case .dragonSlain: return "Seal-breaker. The crown ring is behind you now."
            case .deep10: return "Maps end. The descent does not."
            case .deep25: return "Nothing in the empire ever lived this deep."
            case .deep50: return "The stone forgets sunlight down here."
            case .newBestLayer: return "Your name carved a little deeper than last time."
            case .phoenixRise: return "The Vault let you stand up. It won't again."
            case .noPhoenixClear: return "You beat the dragon on the first verdict."
            case .firstWithdrawal: return "The Shrine remembers the first time you walked away."
            case .tenWithdrawals: return "You know the path back to the Shrine by feel."
            case .shardHoarder: return "The Shrine floor glitters where you drop your burdens."
            case .might5: return "Your strikes carry weight the stone can feel."
            case .ward10: return "The vault's teeth slide off you more often than not."
            case .treeMaxOne: return "One branch touches the ceiling of what ash can buy."
            case .gold1k: return "Dust on your hands, enough for a campfire."
            case .gold100k: return "You have started to scrape at the vault's hoard."
            case .gold1m: return "The ledgers groan under your name."
            case .hireFirstMerc: return "Someone else was willing to die a little slower for you."
            case .milestone25: return "Twenty-five of the same fool — loyalty or habit."
            case .fullRoster: return "Every mouth at the camp knows your whistle."
            case .knightOwner: return "Steel at your back. Someone else's problem."
            case .phoenixBuyer: return "You paid to argue with the vault's first verdict."
            case .firstRelic: return "The Ash Gallery gains its first trophy."
            case .fullGallery: return "Every seal broken, every trophy hung."
            case .boss10: return "The seals remember which hand broke them."
            case .boss100: return "Wardens fear your shadow more than their masters."
            case .equipThree: return "Three trophies, one crawler — the Shrine approves."
            case .idleCap: return "Even while you slept, the vault stopped paying."
            case .autoWithdraw: return "You let the Shrine pull you home without asking."
            case .firstCrit: return "Luck bent once. Remember the feeling."
            case .surviveOneshot: return "Most would have scattered. You didn't."
            case .weakSigil: return "The aspect yielded. The Shrine took note."
            case .sigilScholar: return "A second scrap of ritual inked into memory."
            }
        }

        static func icon(for id: AchievementID) -> String {
            switch id {
            case .firstBlood: return "drop.fill"
            case .firstFall: return "figure.fall"
            case .tenDeaths: return "skull.fill"
            case .layer3Reach: return "3.circle"
            case .dragonSlain: return "trophy.fill"
            case .deep10: return "10.circle"
            case .deep25: return "25.circle"
            case .deep50: return "50.circle"
            case .newBestLayer: return "star.circle.fill"
            case .phoenixRise: return "flame.fill"
            case .noPhoenixClear: return "shield.lefthalf.filled"
            case .firstWithdrawal: return "arrow.uturn.up"
            case .tenWithdrawals: return "arrow.triangle.2.circlepath"
            case .shardHoarder: return "diamond.fill"
            case .might5: return "bolt.fill"
            case .ward10: return "shield.fill"
            case .treeMaxOne: return "tree.fill"
            case .gold1k: return "creditcard.fill"
            case .gold100k: return "banknote.fill"
            case .gold1m: return "dollarsign.circle.fill"
            case .hireFirstMerc: return "person.2.fill"
            case .milestone25: return "25.square.fill"
            case .fullRoster: return "person.3.fill"
            case .knightOwner: return "shield.lefthalf.filled"
            case .phoenixBuyer: return "flame.circle.fill"
            case .firstRelic: return "rosette"
            case .fullGallery: return "square.grid.3x3.fill"
            case .boss10: return "shield.fill"
            case .boss100: return "shield.lefthalf.filled.slash"
            case .equipThree: return "crown.fill"
            case .idleCap: return "clock.badge.exclamationmark"
            case .autoWithdraw: return "arrow.down.circle.fill"
            case .firstCrit: return "sparkles"
            case .surviveOneshot: return "heart.fill"
            case .weakSigil: return "wand.and.stars"
            case .sigilScholar: return "book.closed.fill"
            }
        }

        static func categoryTitle(_ category: AchievementCategory) -> String {
            switch category {
            case .crawl: return "The Crawl"
            case .shrine: return "The Shrine"
            case .camp: return "The Camp"
            case .gallery: return "The Gallery"
            case .secrets: return "Secrets"
            }
        }

        /// Combat-log beats for milestone trophies only.
        static func beat(for id: AchievementID) -> Beat? {
            switch id {
            case .dragonSlain: return .achievementSealBreaker
            case .firstWithdrawal: return .achievementFirstWithdrawal
            case .deep25: return .achievementDeepAshVault
            default: return nil
            }
        }

        static func lockedAccessibilityLabel(
            name: String,
            progress: (current: Int, target: Int)?
        ) -> String {
            if let progress {
                return "Locked achievement. Progress \(progress.current) of \(progress.target)."
            }
            return "Locked achievement."
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
                    "Heavy Strike and your equipped sigils spend mana for extra effects.",
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
