import Foundation

// MARK: - Recommendation

struct RecommendationSummary {
    let headline: String
    let details: [String]
    let outdoorRating: OutdoorRating
    let bestTimeHint: String?
}

enum OutdoorRating: Int, CaseIterable {
    case great = 1
    case good = 2
    case fair = 3
    case poor = 4
    case bad = 5

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .bad: return "Bad"
        }
    }

    var icon: String {
        switch self {
        case .great: return "hand.thumbsup.fill"
        case .good: return "hand.thumbsup"
        case .fair: return "hand.raised"
        case .poor: return "hand.thumbsdown"
        case .bad: return "hand.thumbsdown.fill"
        }
    }
}
