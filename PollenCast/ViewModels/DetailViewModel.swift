import Foundation
import CoreLocation

// MARK: - Detail View Model

@MainActor
final class DetailViewModel: ObservableObject {

    @Published var pollenDay: PollenDay?
    @Published var dailyWeather: DailyWeather?
    @Published var recommendation: RecommendationSummary?
    @Published var locationName: String
    @Published var isLoading = false

    private let pollenService: PollenAPIServiceProtocol
    private let weatherService: WeatherServiceProtocol

    init(
        locationName: String,
        pollenService: PollenAPIServiceProtocol = PollenAPIService(),
        weatherService: WeatherServiceProtocol = WeatherKitService()
    ) {
        self.locationName = locationName
        self.pollenService = pollenService
        self.weatherService = weatherService
    }

    // MARK: - Load for a specific day

    func loadDetail(for day: PollenDay, weather: DailyWeather?) {
        self.pollenDay = day
        self.dailyWeather = weather

        // Generate recommendation based on pollen day data
        let snapshot = PollenSnapshot(
            coordinate: .sanFrancisco, // Coordinate not critical for recommendation
            timestamp: day.date,
            overallIndex: day.overallIndex,
            overallRiskLevel: day.overallRiskLevel,
            typeBreakdowns: day.typeBreakdowns,
            dominantType: day.dominantType
        )

        let weatherContext: WeatherContext? = weather.map { w in
            WeatherContext(
                temperature: w.highTemperature,
                humidity: w.humidity,
                windSpeed: w.windSpeed,
                windDirection: "",
                precipitationChance: w.precipitationChance,
                uvIndex: w.uvIndex,
                condition: w.condition,
                conditionDescription: w.condition.label,
                timestamp: w.date
            )
        }

        recommendation = RecommendationEngine.generate(pollen: snapshot, weather: weatherContext)
    }

    // MARK: - Load for a coordinate (e.g., from map tap)

    func loadDetail(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let forecast = try await pollenService.fetchForecast(for: coordinate, days: 1)
            if let today = forecast.today {
                let weather = try? await weatherService.fetchDailyForecast(for: coordinate, days: 1).first
                loadDetail(for: today, weather: weather)
            }
        } catch {
            // Keep existing state
        }
    }
}
