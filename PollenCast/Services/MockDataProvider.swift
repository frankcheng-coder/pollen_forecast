import Foundation
import CoreLocation

// MARK: - Mock Data Provider
/// Provides realistic mock data for development and SwiftUI previews.
/// Used when API keys are not configured or for Preview builds.

enum MockDataProvider {

    // MARK: - Pollen

    static func mockPollenSnapshot(for coordinate: CLLocationCoordinate2D = .sanFrancisco) -> PollenSnapshot {
        let breakdowns = mockPollenBreakdowns()
        return PollenSnapshot(
            coordinate: coordinate,
            timestamp: Date(),
            overallIndex: 3,
            overallRiskLevel: .high,
            typeBreakdowns: breakdowns,
            dominantType: breakdowns.first
        )
    }

    static func mockPollenForecast(for coordinate: CLLocationCoordinate2D = .sanFrancisco) -> PollenForecast {
        let days = (0..<5).map { offset -> PollenDay in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            let risks: [PollenRiskLevel] = [.high, .moderate, .high, .low, .moderate]
            let indices = [3, 2, 3, 1, 2]
            let risk = risks[offset]
            let index = indices[offset]

            return PollenDay(
                date: date,
                overallIndex: index,
                overallRiskLevel: risk,
                typeBreakdowns: mockPollenBreakdowns(baseRisk: risk)
            )
        }

        return PollenForecast(
            coordinate: coordinate,
            fetchedAt: Date(),
            days: days
        )
    }

    static func mockPollenBreakdowns(baseRisk: PollenRiskLevel = .high) -> [PollenTypeBreakdown] {
        [
            PollenTypeBreakdown(
                category: .tree,
                indexValue: baseRisk.rawValue,
                riskLevel: baseRisk,
                displayName: "Tree",
                inSeason: true
            ),
            PollenTypeBreakdown(
                category: .grass,
                indexValue: max(0, baseRisk.rawValue - 1),
                riskLevel: PollenRiskLevel.from(index: max(0, baseRisk.rawValue - 1)),
                displayName: "Grass",
                inSeason: true
            ),
            PollenTypeBreakdown(
                category: .weed,
                indexValue: max(0, baseRisk.rawValue - 2),
                riskLevel: PollenRiskLevel.from(index: max(0, baseRisk.rawValue - 2)),
                displayName: "Weed",
                inSeason: false
            )
        ]
    }

    // MARK: - Weather

    static func mockWeatherContext() -> WeatherContext {
        WeatherContext(
            temperature: 22,
            humidity: 55,
            windSpeed: 15,
            windDirection: "NW",
            precipitationChance: 0.1,
            uvIndex: 6,
            condition: .partlyCloudy,
            conditionDescription: "Partly Cloudy",
            timestamp: Date()
        )
    }

    static func mockDailyWeather(days: Int = 5) -> [DailyWeather] {
        (0..<days).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            let conditions: [WeatherCondition] = [.partlyCloudy, .clear, .cloudy, .rain, .clear]
            return DailyWeather(
                date: date,
                highTemperature: Double.random(in: 18...28),
                lowTemperature: Double.random(in: 8...15),
                condition: conditions[offset % conditions.count],
                precipitationChance: Double.random(in: 0...0.6),
                humidity: Double.random(in: 40...70),
                windSpeed: Double.random(in: 5...30),
                uvIndex: Int.random(in: 1...10)
            )
        }
    }

    // MARK: - Recommendation

    static func mockRecommendation() -> RecommendationSummary {
        RecommendationEngine.generate(
            pollen: mockPollenSnapshot(),
            weather: mockWeatherContext()
        )
    }

    // MARK: - Location

    static func mockSavedLocations() -> [LocationItem] {
        [
            LocationItem(name: "New York", locality: "New York", administrativeArea: "NY", country: "US", latitude: 40.7128, longitude: -74.0060),
            LocationItem(name: "Los Angeles", locality: "Los Angeles", administrativeArea: "CA", country: "US", latitude: 34.0522, longitude: -118.2437),
            LocationItem(name: "Chicago", locality: "Chicago", administrativeArea: "IL", country: "US", latitude: 41.8781, longitude: -87.6298),
        ]
    }
}

// MARK: - CLLocationCoordinate2D Convenience

extension CLLocationCoordinate2D {
    static let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
}
