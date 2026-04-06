import Foundation
import CoreLocation
import Combine
import OSLog

private let logger = Logger(subsystem: "com.pollencast.app", category: "HomeVM")

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
    @Published var pollenError: String?
    @Published var lastUpdated: Date?
    @Published var debugInfo: PollenDebugInfo?

    // MARK: - Dependencies

    private let locationService: LocationService
    private let pollenService: PollenAPIServiceProtocol
    private let weatherService: WeatherServiceProtocol
    private let cacheService: CacheService
    private var cancellables = Set<AnyCancellable>()

    /// Single active load task — cancelled before starting a new one.
    private var loadTask: Task<Void, Never>?

    // MARK: - Init

    init(
        locationService: LocationService,
        pollenService: PollenAPIServiceProtocol = PollenAPIService(),
        weatherService: WeatherServiceProtocol = MockWeatherService(),
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
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.startLoad(for: location.coordinate)
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

    // MARK: - Load Coordination

    /// Cancel any in-flight load and start a new one.
    private func startLoad(for coordinate: CLLocationCoordinate2D) {
        loadTask?.cancel()
        loadTask = Task {
            await loadData(for: coordinate)
        }
    }

    // MARK: - Load Data

    private func loadData(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        pollenError = nil

        async let pollenResult = loadPollen(for: coordinate)
        async let weatherResult = loadWeather(for: coordinate)

        let (_, _) = await (pollenResult, weatherResult)

        // If this task was cancelled mid-flight, don't touch published state
        guard !Task.isCancelled else {
            logger.debug("Load cancelled — skipping state update")
            return
        }

        // Only generate recommendation when we actually have pollen data
        recommendation = RecommendationEngine.generate(
            pollen: pollenSnapshot,
            weather: weatherContext
        )

        // Update debug info from service
        debugInfo = pollenService.lastDebugInfo

        lastUpdated = Date()
        isLoading = false
    }

    /// Called by pull-to-refresh. Coordinates with location-driven loads.
    func refresh() async {
        guard let location = locationService.currentLocation else {
            locationService.requestCurrentLocation()
            return
        }
        // Cancel any pending location-driven load, then run synchronously
        // so the refreshable spinner waits for completion.
        loadTask?.cancel()
        loadTask = nil
        await loadData(for: location.coordinate)
    }

    func loadDataForLocation(_ item: LocationItem) async {
        locationName = item.displayName
        loadTask?.cancel()
        loadTask = nil
        await loadData(for: item.coordinate)
    }

    // MARK: - Private Loaders

    @discardableResult
    private func loadPollen(for coordinate: CLLocationCoordinate2D) async -> Bool {
        do {
            try Task.checkCancellation()
            let forecast = try await pollenService.fetchForecast(for: coordinate, days: 5)

            // Check again after the await — task may have been cancelled while waiting
            guard !Task.isCancelled else { return false }

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
            } else {
                pollenSnapshot = nil
                pollenError = "Pollen API returned no daily data"
                logger.warning("Pollen forecast had 0 days")
            }
            return true
        } catch is CancellationError {
            logger.debug("Pollen request cancelled (superseded by newer load)")
            return false
        } catch let error as URLError where error.code == .cancelled {
            logger.debug("Pollen URLSession request cancelled")
            return false
        } catch {
            logger.error("Pollen load failed: \(error)")
            pollenSnapshot = nil
            pollenForecast = nil
            pollenError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    private func loadWeather(for coordinate: CLLocationCoordinate2D) async -> Bool {
        do {
            try Task.checkCancellation()
            weatherContext = try await weatherService.fetchCurrentWeather(for: coordinate)
            return true
        } catch is CancellationError {
            return false
        } catch let error as URLError where error.code == .cancelled {
            return false
        } catch {
            return false
        }
    }
}
