import Foundation
import WeatherKit
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "com.pollencast.app", category: "Weather")

// MARK: - WeatherKit Error

enum WeatherServiceError: LocalizedError {
    case notAvailable
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Weather data is not available"
        case .fetchFailed(let error): return "Weather fetch failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Weather Service Protocol

protocol WeatherServiceProtocol {
    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherContext
    func fetchDailyForecast(for coordinate: CLLocationCoordinate2D, days: Int) async throws -> [DailyWeather]
}

// MARK: - WeatherKit Service

final class WeatherKitService: WeatherServiceProtocol {

    private let weatherService = WeatherService.shared

    init() {
        logger.info("WeatherKitService (live Apple WeatherKit) initialized")
    }

    // MARK: - Fetch Current Weather

    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherContext {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let weather = try await weatherService.weather(for: location)
            var context = WeatherKitMapper.mapCurrentWeather(weather.currentWeather)

            // Enrich with today's precipitation chance from daily forecast
            if let today = weather.dailyForecast.first {
                context = WeatherContext(
                    temperature: context.temperature,
                    humidity: context.humidity,
                    windSpeed: context.windSpeed,
                    windDirection: context.windDirection,
                    precipitationChance: today.precipitationChance,
                    uvIndex: context.uvIndex,
                    condition: context.condition,
                    conditionDescription: context.conditionDescription,
                    timestamp: context.timestamp
                )
            }

            return context
        } catch {
            throw WeatherServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Daily Forecast

    func fetchDailyForecast(for coordinate: CLLocationCoordinate2D, days: Int = 5) async throws -> [DailyWeather] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let weather = try await weatherService.weather(for: location)
            let mapped = WeatherKitMapper.mapDailyForecast(weather.dailyForecast)
            return Array(mapped.prefix(days))
        } catch {
            throw WeatherServiceError.fetchFailed(error)
        }
    }
}

// MARK: - Mock Weather Service (for development without WeatherKit entitlement)

final class MockWeatherService: WeatherServiceProtocol {

    init() {
        logger.warning("MockWeatherService initialized — weather data will be static/fake")
    }

    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherContext {
        MockDataProvider.mockWeatherContext()
    }

    func fetchDailyForecast(for coordinate: CLLocationCoordinate2D, days: Int) async throws -> [DailyWeather] {
        MockDataProvider.mockDailyWeather(days: days)
    }
}
