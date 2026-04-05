import Foundation

enum AppConstants {
    static let appName = "PollenCast"
    static let cacheTTLMinutes = 30
    static let maxForecastDays = 5
    static let searchDebounceMilliseconds = 400
    static let mapFetchThresholdMeters: Double = 5000
    static let locationSignificantChangeMeters: Double = 500
}
