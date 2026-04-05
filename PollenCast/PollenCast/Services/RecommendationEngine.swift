import Foundation

// MARK: - Recommendation Engine

struct RecommendationEngine {

    static func generate(pollen: PollenSnapshot?, weather: WeatherContext?) -> RecommendationSummary {
        let pollenRisk = pollen?.overallRiskLevel ?? .none
        let windSpeed = weather?.windSpeed ?? 0
        let rainChance = weather?.precipitationChance ?? 0
        let isWindy = windSpeed > 25
        let isRainy = rainChance > 0.5

        let rating = computeRating(pollen: pollenRisk, isWindy: isWindy, isRainy: isRainy)
        let headline = computeHeadline(rating: rating, pollenRisk: pollenRisk)
        let details = computeDetails(pollen: pollen, weather: weather, isWindy: isWindy, isRainy: isRainy)
        let bestTime = computeBestTime(pollenRisk: pollenRisk, isRainy: isRainy)

        return RecommendationSummary(
            headline: headline,
            details: details,
            outdoorRating: rating,
            bestTimeHint: bestTime
        )
    }

    // MARK: - Rating

    private static func computeRating(pollen: PollenRiskLevel, isWindy: Bool, isRainy: Bool) -> OutdoorRating {
        switch pollen {
        case .none:
            return .great
        case .low:
            return isWindy ? .good : .great
        case .moderate:
            if isRainy { return .good } // Rain washes pollen
            return isWindy ? .fair : .good
        case .high:
            if isRainy { return .fair }
            return isWindy ? .bad : .poor
        case .veryHigh:
            if isRainy { return .poor }
            return .bad
        }
    }

    // MARK: - Headline

    private static func computeHeadline(rating: OutdoorRating, pollenRisk: PollenRiskLevel) -> String {
        switch rating {
        case .great:
            return "Great day to be outside!"
        case .good:
            return "Good conditions for outdoor activities"
        case .fair:
            return "Fair conditions — sensitive individuals should take care"
        case .poor:
            return "High pollen — limit prolonged outdoor exposure"
        case .bad:
            return "Very high pollen — stay indoors if possible"
        }
    }

    // MARK: - Details

    private static func computeDetails(pollen: PollenSnapshot?, weather: WeatherContext?, isWindy: Bool, isRainy: Bool) -> [String] {
        var details: [String] = []
        let risk = pollen?.overallRiskLevel ?? .none

        // Pollen-specific advice
        if let dominant = pollen?.dominantType {
            details.append("\(dominant.category.displayName) pollen is the primary contributor at \(dominant.riskLevel.label.lowercased()) levels.")
        }

        // Wind interaction
        if isWindy && risk >= .moderate {
            details.append("Breezy conditions may increase pollen exposure. Wind can carry pollen further.")
        }

        // Rain interaction
        if isRainy {
            if risk >= .moderate {
                details.append("Rain expected — this may help wash pollen from the air and provide temporary relief.")
            } else {
                details.append("Rain in the forecast. Good news for pollen-sensitive individuals.")
            }
        }

        // Severity-based
        switch risk {
        case .none:
            details.append("No significant pollen detected. Enjoy the outdoors freely.")
        case .low:
            details.append("Most people should be comfortable. Those with severe allergies may want to monitor.")
        case .moderate:
            details.append("Consider taking allergy medication if you're sensitive. Keep windows closed.")
        case .high:
            details.append("Consider wearing a mask outdoors. Take allergy medication before going out.")
            details.append("Shower and change clothes after outdoor activities.")
        case .veryHigh:
            details.append("Strongly consider staying indoors. Keep all windows and doors closed.")
            details.append("Run air purifiers if available. Take allergy medication as directed.")
        }

        return details
    }

    // MARK: - Best Time

    private static func computeBestTime(pollenRisk: PollenRiskLevel, isRainy: Bool) -> String? {
        switch pollenRisk {
        case .none, .low:
            return nil // No need for timing advice
        case .moderate:
            return isRainy ? "After the rain may be a good window" : "Early morning or evening tends to be better"
        case .high, .veryHigh:
            return isRainy ? "Wait for the rain to pass — it should help clear the air" : "Best outdoor window: early morning before 10 AM"
        }
    }
}
