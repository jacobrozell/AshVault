import Foundation

/// Player-facing copy — lore beats, UI labels, and terminology.
///
/// Spec: `ios/docs/avasia-integration-spec.md` (Avasia prequel · NW penitentiary)
enum Narrative {

    static let appName = "Ash Vault"
    static let sagaName = "Avasia"
    static let fullTitle = "Avasia: Ash Vault"

    // MARK: - Terminology (UI labels)

    enum Term {
        static let ashShards = "Ash Shards"
        static let ashTree = "Ash Tree"
        static let ashGallery = "Ash Gallery"
        static let shrineRecords = "Camp Records"
        static let sigilBench = "Sigil Bench"
        static let shrine = "Surface Camp"
        static let deepAshVault = "Below the Seal"
        static let playerRole = "delver"
        static let theSinter = "The Sinter"

        /// Legacy identifier — same display name as `theSinter`.
        static var ashDragon: String { theSinter }

        static let titleSubtitle =
            "Descend the NW penitentiary.\nReach the Vault Heart. Sever \(theSinter)."

        static let victorySubtitle =
            "You cut the anchor at the Vault Heart. "
            + "The camp will seal the mouth — but Below the Seal still waits."

        static let defeatSubtitle =
            "Another delver for the branches. Your ash scatters."

        static let enterDeepAshVault = "Descend Below the Seal"
        static let beginCrawl = "Begin the Descent"
        static let withdrawToShrine = "Withdraw to Camp"
        static let keepCrawling = "Keep descending"
        static let campFlavor =
            "Kaefden penal detachment at the mountain mouth — hires and provisions between delves."
        static let mercenaryPermanent =
            "Owned forever · DPS stacks with milestones at 25, 50, 100…"
        static let progressionAfterVictory =
            "Tap ✨ anytime to withdraw to camp and bank Ash Shards. Spend them in the Ash Tree so the next descent starts sharper."
        static let progressionEndless =
            "The anchor is cut — keep descending for score, gold, and relics. Withdraw when the oil runs out."
        static let galleryHeader =
            "Trophies from warden-ash. Equip up to three passives."
        static let ascensionBody =
            "End this delve to distill Ash Shards at the Surface Camp. "
            + "Shards permanently raise your starting power — every future descent starts stronger."
        static let ascensionEmptyHint =
            "Earn more gold this run before withdrawing pays off."
        static let automationHint =
            "Earn your first Ash Shard to unlock automation and auto-withdraw."
        static let offlineAshTreeHint =
            "Patience in the Ash Tree extends it."

        static let wardenFallenChoice = "Warden fallen. Push deeper or make camp?"

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
            "Camp Records \(unlocked)/\(total)"
        }

        static func codexProgress(unlocked: Int, total: Int) -> String {
            "Codex \(unlocked)/\(total)"
        }

        static let codex = "Camp Codex"

        static func achievementBonusSummary(goldPercent: Int, hpPercent: Int) -> String? {
            var parts: [String] = []
            if goldPercent > 0 { parts.append("+\(goldPercent)% gold") }
            if hpPercent > 0 { parts.append("+\(hpPercent)% starting HP") }
            guard !parts.isEmpty else { return nil }
            return parts.joined(separator: " · ") + " from trophies"
        }

        static let achievementBackfillTitle = "The Camp Remembers"
        static let achievementBackfillBody =
            "The Surface Camp remembers your past delves. Your trophies wait in the records."
        static let achievementUnlockToastTitle = "Trophy earned"

        static func breakSeal(layer: Int) -> String {
            "Descend — Ring \(layer)"
        }

        static func withdrawGainShards(_ count: Int) -> String {
            "Withdraw — bank \(count) shards"
        }

        static let withdrawAnyway = "Withdraw anyway"
        static let openAshTree = "Open Ash Tree"
        static let relicFoundTitle = "Ash Trophy Found!"
        static let relicFoundButton = "Equip & Continue"
        static let withdrawAccessibility = "Withdraw to camp and bank ash shards"

        static func withdrawAccessibility(shards: Int) -> String {
            "Withdraw to camp, \(shards) ash shards banked"
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
        case deathShardsSalvaged(Int)
        case firstDeathTwist
        case phoenixAshRevive
        case milestoneFirstShard
        case milestoneFirstRelic
        case milestoneFirstMercenary
        case milestoneAutomationUnlock
        case achievementSealBreaker
        case achievementFirstWithdrawal
        case achievementDeepAshVault
        case vaultHeartEpilogue
        case loadoutIntro
        case aspectIntro(aspect: Element)
        case aspectWeak
        case aspectResist
        case sigilScroll
    }

    static func text(for beat: Beat) -> String {
        switch beat {
        case .welcome(let name):
            return "Welcome, \(name). The mountain mouth waits."
        case .tutorial(let index):
            switch index {
            case 0:
                return "The NW penitentiary still breathes below the mountain — pink stone, iron, and sentences that outlived the judged."
            case 1:
                return "Descend ring by ring. Oil runs low. The last guardian in each ring is a warden."
            default:
                return "Reach the Vault Heart. Sever \(Term.theSinter). Or climb back before the camp seals the mouth."
            }
        case .layerEntry(let layer):
            return layerEntry(layer: layer) ?? ""
        case .bossSpawn(let isFinalBoss):
            if isFinalBoss {
                return "\(Term.theSinter) — heat without flame, hunger without a mouth."
            }
            return "A warden rises from the ring."
        case .relicNew(let name, let icon):
            return "A sliver of warden-ash. The mountain lets you keep this — \(name)! \(icon)"
        case .relicDuplicate(let gold):
            return "More ash-dust — \(Formatting.short(gold))g scraped from the stone."
        case .ascensionGained(let shards):
            return "You climb to the Surface Camp. \(shards) Ash Shards harden in your grasp."
        case .ascensionEmpty:
            return "You withdraw, but this delve left little to distill."
        case .ascensionFollowUp:
            return "Plant them in the Ash Tree before you descend again."
        case .dragonSlain:
            return "The Heart goes cold. \(Term.theSinter) scatters."
        case .crownSealBroken:
            return "The anchor is cut. The camp will seal the mouth at dusk."
        case .progressionAfterDragon:
            return Term.progressionEndless
        case .defeatScatter:
            return Term.defeatSubtitle
        case .deathShardsSalvaged(let shards):
            return "The camp salvages \(shards) Ash Shards from what you carried — not all is lost."
        case .firstDeathTwist:
            return "Ha. You thought this was a little idle game?"
        case .phoenixAshRevive:
            return "Phoenix Ash flares! You stagger back at \(Balance.phoenixAshReviveHpPercent)% HP — once per run."
        case .milestoneFirstShard:
            return "The Surface Camp remembers you now."
        case .milestoneFirstRelic:
            return "The Ash Gallery gains its first trophy."
        case .milestoneFirstMercenary:
            return "A sellsword signs on at the mountain mouth."
        case .milestoneAutomationUnlock:
            return "The descent can continue without your hand — the camp takes over."
        case .achievementSealBreaker:
            return "The camp etches your name among heart-breakers."
        case .achievementFirstWithdrawal:
            return "The camp records your first withdrawal."
        case .achievementDeepAshVault:
            return "The camp notes how deep you have delved Below the Seal."
        case .vaultHeartEpilogue:
            return "Kaefden's surveyors will strike this place from the maps. "
                + "In time, three old mages will hide their quarrels behind worthiness. "
                + "You will not be named. The ash will remember."
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
            case .dragonSlain: return "Heart-Breaker"
            case .deep10: return "Below the Seal X"
            case .deep25: return "Below the Seal XXV"
            case .deep50: return "Below the Seal L"
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
            case .firstFall: return "Die once in the penitentiary."
            case .tenDeaths: return "Die ten times."
            case .layer3Reach: return "Clear ring 3."
            case .dragonSlain: return "Sever \(Term.theSinter) once."
            case .deep10: return "Reach ring 10."
            case .deep25: return "Reach ring 25 Below the Seal."
            case .deep50: return "Reach ring 50 Below the Seal."
            case .newBestLayer: return "Set a personal best of ring 6 or deeper."
            case .phoenixRise: return "Revive with Phoenix Ash once."
            case .noPhoenixClear: return "Sever \(Term.theSinter) without using Phoenix Ash."
            case .firstWithdrawal: return "Withdraw to camp once."
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
            case .firstBlood: return "The camp notes the first ash you scattered."
            case .firstFall: return "You laughed. The mountain did not."
            case .tenDeaths: return "The camp stops counting the first way you broke."
            case .layer3Reach: return "Manacle Hall is behind you. The stone grows warmer."
            case .dragonSlain: return "Heart-breaker. The Vault Heart is cold — for now."
            case .deep10: return "Surveyors never planned this deep."
            case .deep25: return "Nothing in Kaefden's maps ever lived this far down."
            case .deep50: return "The stone forgets sunlight down here."
            case .newBestLayer: return "Your tally carved a little deeper than last time."
            case .phoenixRise: return "The mountain let you stand up. It won't again."
            case .noPhoenixClear: return "You severed the Sinter on the first verdict."
            case .firstWithdrawal: return "The camp remembers the first time you climbed out."
            case .tenWithdrawals: return "You know the path back to the mouth by feel."
            case .shardHoarder: return "The camp floor glitters where you drop your burdens."
            case .might5: return "Your strikes carry weight the stone can feel."
            case .ward10: return "The ring's teeth slide off you more often than not."
            case .treeMaxOne: return "One branch touches the ceiling of what ash can buy."
            case .gold1k: return "Dust on your hands, enough for lamp oil."
            case .gold100k: return "You have started to scrape at the mountain's hoard."
            case .gold1m: return "The ledgers groan under your name."
            case .hireFirstMerc: return "Someone else was willing to die a little slower for you."
            case .milestone25: return "Twenty-five of the same fool — loyalty or habit."
            case .fullRoster: return "Every mouth at the camp knows your whistle."
            case .knightOwner: return "Steel at your back. Someone else's problem."
            case .phoenixBuyer: return "You paid to argue with the mountain's first verdict."
            case .firstRelic: return "The Ash Gallery gains its first trophy."
            case .fullGallery: return "Every warden broken, every trophy hung."
            case .boss10: return "The rings remember which hand broke them."
            case .boss100: return "Wardens fear your shadow more than Malvek's sermons."
            case .equipThree: return "Three trophies, one delver — the camp approves."
            case .idleCap: return "Even while you slept, the camp stopped paying."
            case .autoWithdraw: return "You let the camp pull you home without asking."
            case .firstCrit: return "Luck bent once. Remember the feeling."
            case .surviveOneshot: return "Most would have scattered. You didn't."
            case .weakSigil: return "The aspect yielded. The camp took note."
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
            case .crawl: return "The Descent"
            case .shrine: return "Surface Camp"
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
        case 1:  return "Lantern smoke. Pink crystal in wet stone."
        case 2:  return "\"Both. Always both.\" — schism graffiti on the wall."
        case 3:  return "Iron that outlived its prisoners."
        case 4:  return "The lanterns were not meant for this depth."
        case 5:  return "Ore dust and old sermons. LET THEM SEE WHAT LAW COSTS."
        case 6:  return "Blue crystal weeps into the rock."
        case 7:  return "Malvek called this deterrence."
        case 8:  return "Chains that bind the binder."
        case 9:  return "You hear your own footsteps twice."
        case 10: return "Something hot without flame."
        case 11...: return "No surveyor planned this deep."
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
                symbol: "mountain.2.fill",
                title: "Welcome to \(fullTitle)",
                body: "You are a nameless delver sent into the NW penitentiary — ring by ring, oil flask by oil flask.",
                bullets: [
                    "Fight guardians each ring; the last is a warden.",
                    "Reach the Vault Heart and sever \(Term.theSinter).",
                    "Return to \(Term.shrine) between delves to grow permanently stronger."
                ]
            ),
            OnboardingPage(
                id: 1,
                symbol: "burst.fill",
                title: "Combat",
                body: "Turn-based fights in the rings. Pick a move each turn — or let auto-battle play for you.",
                bullets: [
                    "Attack, Dodge, and Heal cost no mana.",
                    "Heavy Strike and your equipped sigils spend mana for extra effects.",
                    "Read each guardian's aspect — match your sigil for bonus damage."
                ]
            ),
            OnboardingPage(
                id: 2,
                symbol: "arrow.down.circle.fill",
                title: "The Descent",
                body: "Draft power from kills. Camp when you must. Supplies are your lamp oil — they run out.",
                bullets: [
                    "After a warden: push deeper or make camp.",
                    "Spend gold on consumables and run upgrades at camp.",
                    "Door forks offer guard, elite, or shrine paths — from ring 2 onward."
                ]
            ),
            OnboardingPage(
                id: 3,
                symbol: "sparkles",
                title: "Withdraw & \(Term.ashTree)",
                body: "Tap ✨ during a run to \(Term.withdrawToShrine.lowercased()) and bank \(Term.ashShards.lowercased()).",
                bullets: [
                    "Shards are permanent — run gold is lost when you withdraw or die.",
                    "Plant shards in the \(Term.ashTree) for lasting Attack, HP, gold, and defense.",
                    "After your first shard, automation can help between rings."
                ]
            ),
            OnboardingPage(
                id: 4,
                symbol: "archivebox.fill",
                title: "Relics & Camp",
                body: "Wardens may drop ash trophies. Equip passives and hire help at the mountain mouth.",
                bullets: [
                    "View and equip relics in the \(Term.ashGallery) (up to three at once).",
                    "Mercenaries persist between runs and boost your damage.",
                    "Patience in the \(Term.ashTree) extends offline earnings."
                ]
            ),
        ]
    }

    // MARK: - Codex (Camp Records lore)

    enum Codex {
        static let title = "Camp Codex"
        static let lockedHint = "Descend deeper to unlock this entry."

        static let nwPenitentiary =
            "Kaefden's NW Mountain Penitentiary — civic sentence carved into pink ore. "
            + "Convicts mined crystal under sky-warded chains. The crown called it law. The stone called it hunger."
        static let twoHands =
            "\"Both. Always both.\" Schism prisoners carved Agroman numerals beside Kaefden oaths. "
            + "Neither faction innocent — only the mountain remembers both wrists."
        static let jalChains =
            "Before the prison: Jal's chain-mine. Humans and mages cut ore for the forge. "
            + "Wrist rings at kneeling height still line Manacle Hall."
        static let theMiner =
            "A surveyor speared mining pink shards — greed or trap, the ledgers disagree. "
            + "His pickaxe rusts in Branching Dark beside colorless stone."
        static let malvek =
            "Warden-Magister Malvek: *Let them see what law costs.* "
            + "He expanded the rings and preached deterrence until deterrence became appetite."
        static let anulaBleed =
            "Blue Anula weeps pink in deep ore — earth anchor leaking through prison stone. "
            + "Heat without flame. Pre-Inflame dread the camp will not name aloud."
        static let clerkBera =
            "Clerk Bera copied bark sheets while Commander Pell sealed the mouth. "
            + "Neutral truth survived Kaefden's suppression — the archive outlived the riot lie."
        static let theBinding =
            "Malvek bound pain, ash, and crystal bleed into a Vault Heart reliquary without consent. "
            + "Anchor law demands vessel or oath. He offered neither."
        static let commanderPell =
            "Surface Camp captain Pell ordered the emergency seal when the Sinter woke. "
            + "Surveyors struck the penitentiary from maps. Delvers became expendable."
        static let delverSeven =
            "Ledger myth: Delver 7 breached ring ten and severed the anchor. "
            + "The name was lost. The camp kept the number."
        static let theSinter =
            "The reliquary woke hungry — crystallized ash, prisoner echoes, Malvek's sermons ground into fog. "
            + "Not dragon. Not mage. Binding without law."
        static let suppression =
            "Kaefden buried the Binding. Maps redacted. Folk curse-name: Ash Vault. "
            + "Vashirr later exploits what the crown hid — but that is another war."
        static let threeMages =
            "Decades after the seal, three old mages wallpapered the ruin with worthiness trials. "
            + "They told the world only the worthy may pass. They lied about the horror below."
        static let ashShape =
            "Sinter victims hold form in black ash — flesh-memory the fireball room will echo decades hence. "
            + "Binding leaves a silhouette of what was judged."
        static let lanternHabit =
            "Leave oil at the mouth. Cataracta druids later train fox-form scouts — "
            + "Kite-oath delvers learn the habit before they learn the rings."
        static let turnkeyHess =
            "Turnkey Hess took crown coin either way. Graffiti Gallery was his beat until the Binding."
        static let echoSergeant =
            "Flesh-bound turnkey remnant — still on shift when the Sinter spread through Pink Saturation."
        static let delverOaths =
            "Hound, Mast, Kite — survivor oaths sworn at the mouth. "
            + "The camp does not ask your name. It asks how you intend to die."
        static let surfaceCamp =
            "Kaefden penal detachment at the mountain mouth — tents, ledgers, and hires between delves. "
            + "Withdraw here to bank Ash Shards in the Ash Tree."
        static let belowTheSeal =
            "Below ring ten: uncharted Anula bleed. No surveyor planned it. "
            + "Endless descent for those who severed the Heart and kept walking."

        static let sealedRoomIntro =
            "A clerk's nook behind the warden's post. Bark sheets stacked beside a hidden oil stash."
        static let sealedRoomCopy =
            "You copy Bera's sheets. Truth travels — and so does blame."
        static let sealedRoomLeave =
            "You leave the sheets and take the oil. Memory is an archive that dies with you."
    }
}
