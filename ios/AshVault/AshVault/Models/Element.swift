import Foundation
import SwiftUI

/// Elements used by sigils and enemy aspects.
enum Element: String, CaseIterable, Codable, Identifiable {
    case ember, frost, arc, venom, stone

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ember: return "Ember"
        case .frost: return "Frost"
        case .arc:   return "Arc"
        case .venom: return "Venom"
        case .stone: return "Stone"
        }
    }

    var sfSymbol: String {
        switch self {
        case .ember: return "flame.fill"
        case .frost: return "snowflake"
        case .arc:   return "bolt.fill"
        case .venom: return "drop.fill"
        case .stone: return "mountain.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .ember: return .orange
        case .frost: return .cyan
        case .arc:   return Theme.mana
        case .venom: return .green
        case .stone: return .brown
        }
    }
}

/// Extra chart keys for enemies (wild beasts, fey, undead, wyrm bosses).
enum EnemyTag: String, Codable, Hashable, CaseIterable {
    case wild, fey, undead, wyrm
}

/// Super-effective / neutral / resisted matchup result.
enum Effectiveness: Double, Equatable {
    case weak = 1.5
    case neutral = 1.0
    case resist = 0.5

    var multiplier: Double { rawValue }
}
