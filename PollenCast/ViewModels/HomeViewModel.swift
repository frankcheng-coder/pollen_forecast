import Foundation
import CoreLocation
import Combine

// MARK: - Home View Model

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    @Published var locationName: String = "Loading..."
    @Published var pollenSnapshot: PollenSnapshot?
    @Published var pollenForecast: PollenForecast?
    @Published var weatherContext: WeatherContext?
    @Published var recommendation: RecommendationSummary?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?

    // MARK: - Dependencies

    private let locationService: LocationService
    private let pollenService: PollenAPIServiceProtocol
    private let weatherService: WeatherServiceProtocol
    private let cacheService: CacheService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        locationService: LocationService,
        pollenService: PollenAPIServiceProtocol = PollenAPIService(),
        weatherService: WeatherServiceProtocol = MockWeatherService(), // TODO: Switch to WeatherKitService when entitlement is configured
        cacheService: CacheService = .shared
    ) {
        self.locationService = locationService
        self.pollenService = pollenService
        self.weatherService = weatherService
        self.cacheService = cacheService

        observeLocation()
    }

    // MARK: - Observe Location

    private func observeLocation() {
        locationService.$currentLocation
            .compactMap { $0 }
            .removeDuplicates { old, new in
                old.distance(from: new) < 500
            }
            .sink { [weak self] location in
                Task { [weak self] in
                    await self?.loadData(for: location.coordinate)
                }
            }
            .store(in: &cancellables)

        locationService.$currentPlacemark
            .compactMap { $0 }
            .sink { [weak self] placemark in
                self?.locationName = placemark.locality ?? placemark.name ?? "Current Location"
            }
            .store(in: &cancellables)

        locationService.$authorizationStatus
            .sink { [weak self] status in
                if status == .denied || status == .restricted {
                    self?.locationName = "Location unavailable"
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Data

    func loadData(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil

        async let pollenResult = loadPollen(for: coordinate)
        async let weatherResult = loadWeather(for: coordinate)

        let (pollenOk, weatherOk) = await (pollenResult, weatherResult)

        if !pollenOk && !weatherOk {
            error = "Unable to load data. Pull to refresh."
        }

        // Generate recommendation from whatever data we have
        recommendation = RecommendationEngine.generate(
            pollen: pollenSnapshot,
            weather: weatherContext
        )

        lastUpdated = Date()
        isLoading = false
    }

    func refresh() async {
        guard let location = locationService.currentLocation else {
            // Try requesting location again
            locationService.requestCurrentLocation()
            return
        }
        await loadData(for: location.coordinate)
    }

    func loadDataForLocation(_ item: LocationItem) async {
        locationName = item.displayName
        await loadData(for: item.coordinate)
    }

    // MARK: - Private Loaders

    @discardableResult
    private func loadPollen(for coordinate: CLLocationCoordinate2D) async -> Bool {
        do {
            let forecast = try await pollenService.fetchForecast(for: coordinate, days: 5)
            pollenForecast = forecast

            if let today = forecast.today {
                pollenSnapshot = PollenSnapshot(
                    coordinate: coordinate,
                    timestamp: Date(),
                    overallIndex: today.overallIndex,
                    overallRiskLevel: today.overallRiskLevel,
                    typeBreakdowns: today.typeBreakdowns,
                    dominantType: today.dominantType
                )
            }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    @discardableResult
    private func loadWeather(for coordinate: CLLocationCoordinate2D) async -> Bool {
        do {
            weatherContext = try await weatherService.fetchCurrentWeather(for: coordinate)
            return true
        } catch {
            // Weather is supplementary — don't block on failure
            return false
        }
    }
}
