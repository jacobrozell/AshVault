import Foundation

/// Pokémon-style effectiveness for sigil elements vs enemy aspects and tags.
enum TypeChart {

    static func effectiveness(
        spellElement: Element,
        enemyAspect: Element,
        enemyTags: Set<EnemyTag>
    ) -> Effectiveness {
        if isWeak(spell: spellElement, aspect: enemyAspect, tags: enemyTags) { return .weak }
        if isResist(spell: spellElement, aspect: enemyAspect, tags: enemyTags) { return .resist }
        return .neutral
    }

    private static func isWeak(spell: Element, aspect: Element, tags: Set<EnemyTag>) -> Bool {
        switch spell {
        case .ember:
            return aspect == .frost || aspect == .venom || tags.contains(.undead)
        case .frost:
            return aspect == .ember || tags.contains(.wild)
        case .arc:
            return aspect == .stone || tags.contains(.undead)
        case .venom:
            return aspect == .stone || tags.contains(.fey)
        case .stone:
            return false
        }
    }

    private static func isResist(spell: Element, aspect: Element, tags: Set<EnemyTag>) -> Bool {
        switch spell {
        case .ember:  return aspect == .stone
        case .frost:  return aspect == .venom
        case .arc:    return aspect == .ember
        case .venom:  return aspect == .frost || aspect == .arc
        case .stone:  return false
        }
    }
}
