import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum GameAnalyticsEvent: Equatable {
    case appOpen
    case runStarted
    case runEnded(reason: String, layer: Int, level: Int)
    case layerCleared(layer: Int)
    case dragonSlain
    case prestigeCompleted(shards: Int, totalShards: Int)
    case onboardingCompleted
    case achievementUnlocked(id: String, category: String)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .runStarted: return "run_started"
        case .runEnded: return "run_ended"
        case .layerCleared: return "layer_cleared"
        case .dragonSlain: return "dragon_slayed"
        case .prestigeCompleted: return "prestige_completed"
        case .onboardingCompleted: return "onboarding_completed"
        case .achievementUnlocked: return "achievement_unlocked"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .appOpen, .runStarted, .dragonSlain, .onboardingCompleted:
            return [:]
        case let .runEnded(reason, layer, level):
            return [
                "reason": reason,
                "layer": String(layer),
                "level": String(level),
            ]
        case let .layerCleared(layer):
            return ["layer": String(layer)]
        case let .prestigeCompleted(shards, totalShards):
            return [
                "shards": String(shards),
                "total_shards": String(totalShards),
            ]
        case let .achievementUnlocked(id, category):
            return [
                "id": id,
                "category": category,
            ]
        }
    }
}

enum GameAnalytics {
    private static let allowlistedEvents: Set<String> = [
        "app_open",
        "run_started",
        "run_ended",
        "layer_cleared",
        "dragon_slayed",
        "prestige_completed",
        "onboarding_completed",
        "achievement_unlocked",
    ]

    private static let allowlistedParameterKeys: Set<String> = [
        "reason",
        "layer",
        "level",
        "shards",
        "total_shards",
        "app_version",
        "id",
        "category",
    ]

    static func track(_ event: GameAnalyticsEvent) {
        guard allowlistedEvents.contains(event.name) else { return }
        #if canImport(FirebaseAnalytics)
        guard FirebaseBootstrap.isAnalyticsCollectionEnabled else { return }
        var parameters = sanitizedParameters(from: event.parameters)
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !version.isEmpty {
            parameters["app_version"] = version
        }
        Analytics.logEvent(event.name, parameters: parameters.isEmpty ? nil : parameters)
        #endif
    }

    static func sanitizedParameters(from metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { result, pair in
            guard allowlistedParameterKeys.contains(pair.key) else { return }
            let value = String(pair.value.prefix(100))
            guard !value.isEmpty else { return }
            result[pair.key] = value
        }
    }
}
