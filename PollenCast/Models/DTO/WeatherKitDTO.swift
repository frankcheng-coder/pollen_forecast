import Foundation
import WeatherKit

// MARK: - WeatherKit DTO Mapping
// WeatherKit returns native Swift types. These extensions map them to our domain models.

enum WeatherKitMapper {

    static func mapCurrentWeather(_ weather: CurrentWeather) -> WeatherContext {
        WeatherContext(
            temperature: weather.temperature.value,
            humidity: weather.humidity * 100,
            windSpeed: weather.wind.speed.converted(to: .kilometersPerHour).value,
            windDirection: weather.wind.compassDirection.abbreviation,
            precipitationChance: 0, // Current weather doesn't have this; filled from daily
            uvIndex: weather.uvIndex.value,
            condition: mapCondition(weather.condition),
            conditionDescription: weather.condition.description,
            timestamp: weather.date
        )
    }

    static func mapDailyForecast(_ forecast: Forecast<DayWeather>) -> [DailyWeather] {
        forecast.map { day in
            DailyWeather(
                date: day.date,
                highTemperature: day.highTemperature.value,
                lowTemperature: day.lowTemperature.value,
                condition: mapCondition(day.condition),
                precipitationChance: day.precipitationChance,
                humidity: 0, // DayWeather doesn't expose humidity directly
                windSpeed: day.wind.speed.converted(to: .kilometersPerHour).value,
                uvIndex: day.uvIndex.value
            )
        }
    }

    static func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .hot, .mostlyClear:
            return .clear
        case .partlyCloudy:
            return .partlyCloudy
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .rain, .drizzle, .freezingRain:
            return .rain
        case .heavyRain:
            return .heavyRain
        case .snow, .flurries, .heavySnow, .sleet, .freezingDrizzle, .wintryMix, .blizzard:
            return .snow
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms:
            return .thunderstorm
        case .foggy, .haze, .smoky:
            return .fog
        case .windy, .breezy:
            return .windy
        default:
            return .unknown
        }
    }
}

// MARK: - Wind Direction Abbreviation

extension Wind.CompassDirection {
    var abbreviation: String {
        switch self {
        case .north: return "N"
        case .northNortheast: return "NNE"
        case .northeast: return "NE"
        case .eastNortheast: return "ENE"
        case .east: return "E"
        case .eastSoutheast: return "ESE"
        case .southeast: return "SE"
        case .southSoutheast: return "SSE"
        case .south: return "S"
        case .southSouthwest: return "SSW"
        case .southwest: return "SW"
        case .westSouthwest: return "WSW"
        case .west: return "W"
        case .westNorthwest: return "WNW"
        case .northwest: return "NW"
        case .northNorthwest: return "NNW"
        @unknown default: return "N/A"
        }
    }
}
