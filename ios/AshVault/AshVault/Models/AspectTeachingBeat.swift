import Foundation

/// One-shot combat-log teaching beats for the elemental sigil system.
enum AspectTeachingBeat {
    private enum Key {
        static let intro = "teaching.aspectIntro"
        static let weak = "teaching.aspectWeak"
        static let resist = "teaching.aspectResist"
        static let scroll = "teaching.sigilScroll"
        static let loadout = "teaching.loadoutIntro"
    }

    static var hasShownIntro: Bool { UserDefaults.standard.bool(forKey: Key.intro) }
    static var hasShownWeak: Bool { UserDefaults.standard.bool(forKey: Key.weak) }
    static var hasShownResist: Bool { UserDefaults.standard.bool(forKey: Key.resist) }
    static var hasShownScroll: Bool { UserDefaults.standard.bool(forKey: Key.scroll) }
    static var hasShownLoadout: Bool { UserDefaults.standard.bool(forKey: Key.loadout) }

    static func markIntroShown() { UserDefaults.standard.set(true, forKey: Key.intro) }
    static func markWeakShown() { UserDefaults.standard.set(true, forKey: Key.weak) }
    static func markResistShown() { UserDefaults.standard.set(true, forKey: Key.resist) }
    static func markScrollShown() { UserDefaults.standard.set(true, forKey: Key.scroll) }
    static func markLoadoutShown() { UserDefaults.standard.set(true, forKey: Key.loadout) }

    static func reset() {
        for key in [Key.intro, Key.weak, Key.resist, Key.scroll, Key.loadout] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
