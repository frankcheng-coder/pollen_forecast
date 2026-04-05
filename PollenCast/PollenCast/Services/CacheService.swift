import Foundation
import CoreLocation

// MARK: - Cache Service

final class CacheService {

    static let shared = CacheService()

    private let defaults = UserDefaults.standard
    private let pollenCacheKey = "cached_pollen_data"
    private let weatherCacheKey = "cached_weather_data"

    /// Default TTL: 30 minutes
    var cacheTTL: TimeInterval = 30 * 60

    // MARK: - Coordinate Key

    /// Round coordinates to ~1km precision for cache keying
    func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = (coordinate.latitude * 100).rounded() / 100
        let lon = (coordinate.longitude * 100).rounded() / 100
        return "\(lat),\(lon)"
    }

    // MARK: - Pollen Cache

    func cachedPollenForecast(for coordinate: CLLocationCoordinate2D) -> CachedItem<PollenForecastCache>? {
        let key = "\(pollenCacheKey)_\(cacheKey(for: coordinate))"
        guard let data = defaults.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedItem<PollenForecastCache>.self, from: data) else {
            return nil
        }
        return cached.isExpired(ttl: cacheTTL) ? nil : cached
    }

    func cachePollenForecast(_ forecast: PollenForecastCache, for coordinate: CLLocationCoordinate2D) {
        let key = "\(pollenCacheKey)_\(cacheKey(for: coordinate))"
        let cached = CachedItem(item: forecast, cachedAt: Date())
        if let data = try? JSONEncoder().encode(cached) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Weather Cache

    func cachedWeather(for coordinate: CLLocationCoordinate2D) -> CachedItem<WeatherCache>? {
        let key = "\(weatherCacheKey)_\(cacheKey(for: coordinate))"
        guard let data = defaults.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedItem<WeatherCache>.self, from: data) else {
            return nil
        }
        return cached.isExpired(ttl: cacheTTL) ? nil : cached
    }

    func cacheWeather(_ weather: WeatherCache, for coordinate: CLLocationCoordinate2D) {
        let key = "\(weatherCacheKey)_\(cacheKey(for: coordinate))"
        let cached = CachedItem(item: weather, cachedAt: Date())
        if let data = try? JSONEncoder().encode(cached) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Saved Locations

    private let savedLocationsKey = "saved_locations"

    func loadSavedLocations() -> [LocationItem] {
        guard let data = defaults.data(forKey: savedLocationsKey),
              let locations = try? JSONDecoder().decode([LocationItem].self, from: data) else {
            return []
        }
        return locations
    }

    func saveSavedLocations(_ locations: [LocationItem]) {
        if let data = try? JSONEncoder().encode(locations) {
            defaults.set(data, forKey: savedLocationsKey)
        }
    }
}

// MARK: - Cache Wrapper

struct CachedItem<T: Codable>: Codable {
    let item: T
    let cachedAt: Date

    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }

    var ageDescription: String {
        let minutes = Int(Date().timeIntervalSince(cachedAt) / 60)
        if minutes < 1 { return "Just now" }
        if minutes == 1 { return "1 min ago" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }
}

// MARK: - Cacheable DTOs (simplified for UserDefaults)

struct PollenForecastCache: Codable {
    let overallIndex: Int
    let riskLevel: Int
    let days: [PollenDayCache]
}

struct PollenDayCache: Codable {
    let date: Date
    let overallIndex: Int
    let riskLevel: Int
    let breakdowns: [PollenBreakdownCache]
}

struct PollenBreakdownCache: Codable {
    let category: String
    let indexValue: Int
    let riskLevel: Int
    let displayName: String
    let inSeason: Bool
}

struct WeatherCache: Codable {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
    let precipitationChance: Double
    let uvIndex: Int
    let condition: String
    let conditionDescription: String
}
