import XCTest
@testable import PollenCast

final class PollenCastTests: XCTestCase {

    func testPollenRiskLevelOrdering() {
        XCTAssertTrue(PollenRiskLevel.low < PollenRiskLevel.high)
        XCTAssertTrue(PollenRiskLevel.none < PollenRiskLevel.veryHigh)
    }

    func testPollenRiskFromIndex() {
        XCTAssertEqual(PollenRiskLevel.from(index: 0), .none)
        XCTAssertEqual(PollenRiskLevel.from(index: 1), .low)
        XCTAssertEqual(PollenRiskLevel.from(index: 2), .moderate)
        XCTAssertEqual(PollenRiskLevel.from(index: 3), .high)
        XCTAssertEqual(PollenRiskLevel.from(index: 99), .veryHigh)
    }

    func testRecommendationEngineHighPollenWindy() {
        let snapshot = MockDataProvider.mockPollenSnapshot()
        let weather = WeatherContext(
            temperature: 22,
            humidity: 50,
            windSpeed: 30,
            windDirection: "NW",
            precipitationChance: 0.1,
            uvIndex: 5,
            condition: .clear,
            conditionDescription: "Clear",
            timestamp: Date()
        )
        let rec = RecommendationEngine.generate(pollen: snapshot, weather: weather)
        XCTAssertEqual(rec.outdoorRating, .bad)
    }

    func testCacheKeyRoundsCoordinates() {
        let cache = CacheService.shared
        let key1 = cache.cacheKey(for: .init(latitude: 37.7749, longitude: -122.4194))
        let key2 = cache.cacheKey(for: .init(latitude: 37.7751, longitude: -122.4196))
        XCTAssertEqual(key1, key2)
    }
}
