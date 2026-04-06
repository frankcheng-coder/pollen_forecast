import SwiftUI

// MARK: - Pollen Color Theme

extension PollenRiskLevel {
    var color: Color {
        switch self {
        case .none: return .green
        case .veryLow: return .green
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }

    var backgroundColor: Color {
        color.opacity(0.15)
    }

    var gradientColors: [Color] {
        switch self {
        case .none, .veryLow: return [.green.opacity(0.3), .green.opacity(0.1)]
        case .low: return [.green.opacity(0.3), .green.opacity(0.1)]
        case .moderate: return [.yellow.opacity(0.3), .orange.opacity(0.1)]
        case .high: return [.orange.opacity(0.3), .red.opacity(0.1)]
        case .veryHigh: return [.red.opacity(0.3), .red.opacity(0.15)]
        }
    }
}

extension OutdoorRating {
    var color: Color {
        switch self {
        case .great: return .green
        case .good: return .mint
        case .fair: return .yellow
        case .poor: return .orange
        case .bad: return .red
        }
    }
}

// MARK: - App Colors

extension Color {
    static let appBackground = Color(.systemBackground)
    static let appSecondaryBackground = Color(.secondarySystemBackground)
    static let appTertiaryBackground = Color(.tertiarySystemBackground)
    static let appPrimary = Color.blue
    static let appSecondaryText = Color(.secondaryLabel)
}
