import Foundation
import CoreLocation

// MARK: - Pollen Risk Level

enum PollenRiskLevel: Int, Comparable, CaseIterable {
    case none = 0
    case veryLow = 1
    case low = 2
    case moderate = 3
    case high = 4
    case veryHigh = 5

    var label: String {
        switch self {
        case .none: return "None"
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }

    var emoji: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .veryLow: return "leaf.fill"
        case .low: return "leaf.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .veryHigh: return "xmark.octagon.fill"
        }
    }

    static func < (lhs: PollenRiskLevel, rhs: PollenRiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(index: Int) -> PollenRiskLevel {
        switch index {
        case 0: return .none
        case 1: return .veryLow
        case 2: return .low
        case 3: return .moderate
        case 4: return .high
        default: return .veryHigh
        }
    }
}

// MARK: - Pollen Type

enum PollenCategory: String, Codable, CaseIterable, Identifiable {
    case tree = "TREE"
    case grass = "GRASS"
    case weed = "WEED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tree: return "Tree"
        case .grass: return "Grass"
        case .weed: return "Weed"
        }
    }

    var icon: String {
        switch self {
        case .tree: return "tree.fill"
        case .grass: return "leaf.fill"
        case .weed: return "allergens"
        }
    }
}

// MARK: - Pollen Type Breakdown

struct PollenTypeBreakdown: Identifiable {
    let id = UUID()
    let category: PollenCategory
    let indexValue: Int
    let riskLevel: PollenRiskLevel
    let displayName: String
    let inSeason: Bool

    var contributionDescription: String {
        "\(category.displayName) pollen: \(riskLevel.label)"
    }
}

// MARK: - Pollen Day

struct PollenDay: Identifiable {
    let id = UUID()
    let date: Date
    let overallIndex: Int
    let overallRiskLevel: PollenRiskLevel
    let typeBreakdowns: [PollenTypeBreakdown]

    var dominantType: PollenTypeBreakdown? {
        typeBreakdowns.max(by: { $0.indexValue < $1.indexValue })
    }

    var dayLabel: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Pollen Snapshot (current conditions)

struct PollenSnapshot {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let overallIndex: Int
    let overallRiskLevel: PollenRiskLevel
    let typeBreakdowns: [PollenTypeBreakdown]
    let dominantType: PollenTypeBreakdown?

    var summaryText: String {
        guard let dominant = dominantType else {
            return "Pollen levels are currently \(overallRiskLevel.label.lowercased())."
        }
        let typeText = "\(dominant.category.displayName) pollen"
        switch overallRiskLevel {
        case .none:
            return "No significant pollen detected. Great conditions for outdoor activities."
        case .veryLow:
            return "\(typeText) is present at very low levels. Enjoy the outdoors."
        case .low:
            return "\(typeText) is present at low levels. Most people should be comfortable outdoors."
        case .moderate:
            return "\(typeText) is elevated right now. Sensitive individuals may notice symptoms."
        case .high:
            return "\(typeText) is high. Consider limiting prolonged outdoor exposure."
        case .veryHigh:
            return "\(typeText) is very high. Take precautions if you're pollen-sensitive."
        }
    }
}

// MARK: - Pollen Forecast

struct PollenForecast {
    let coordinate: CLLocationCoordinate2D
    let fetchedAt: Date
    let days: [PollenDay]

    var today: PollenDay? {
        days.first
    }

    var upcoming: [PollenDay] {
        Array(days.dropFirst())
    }
}
