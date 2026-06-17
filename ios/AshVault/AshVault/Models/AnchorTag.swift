import Foundation

/// Anchor law binding — sky, earth, flesh, or civic faith (Avasia pillar).
enum AnchorTag: String, CaseIterable, Codable, Identifiable {
    case sky, earth, flesh, civic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sky:   return "Sky"
        case .earth: return "Earth"
        case .flesh: return "Flesh"
        case .civic: return "Civic"
        }
    }

    var icon: String {
        switch self {
        case .sky:   return "cloud.fill"
        case .earth: return "mountain.2.fill"
        case .flesh: return "figure.stand"
        case .civic: return "building.columns.fill"
        }
    }
}
