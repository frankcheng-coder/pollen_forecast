import Foundation

// MARK: - Weather Context

struct WeatherContext {
    let temperature: Double // Celsius
    let humidity: Double // 0-100 percentage
    let windSpeed: Double // km/h
    let windDirection: String
    let precipitationChance: Double // 0-1
    let uvIndex: Int
    let condition: WeatherCondition
    let conditionDescription: String
    let timestamp: Date

    var temperatureFormatted: String {
        "\(Int(round(temperature)))°"
    }

    var humidityFormatted: String {
        "\(Int(round(humidity)))%"
    }

    var windFormatted: String {
        "\(Int(round(windSpeed))) km/h"
    }

    var precipitationFormatted: String {
        "\(Int(round(precipitationChance * 100)))%"
    }
}

// MARK: - Weather Condition

enum WeatherCondition: String {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case heavyRain
    case snow
    case thunderstorm
    case fog
    case windy
    case unknown

    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .fog: return "cloud.fog.fill"
        case .windy: return "wind"
        case .unknown: return "questionmark.circle"
        }
    }

    var label: String {
        switch self {
        case .clear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .rain: return "Rain"
        case .heavyRain: return "Heavy Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        case .fog: return "Fog"
        case .windy: return "Windy"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Daily Weather

struct DailyWeather: Identifiable {
    let id = UUID()
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let condition: WeatherCondition
    let precipitationChance: Double
    let humidity: Double
    let windSpeed: Double
    let uvIndex: Int
}
