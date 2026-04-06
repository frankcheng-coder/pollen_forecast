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
                logger.info("Location update -> startLoad (\(location.coordinate.latitude), \(location.coordinate.longitude))")
                self?.startLoad(for: location.coordinate, reason: "location-update")
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

    /// The single entry point for all loads. Cancels any in-flight load first.
    private func startLoad(for coordinate: CLLocationCoordinate2D, reason: String) {
        if let existing = loadTask {
            logger.info("Cancelling previous load (reason for new: \(reason))")
            existing.cancel()
        }
        loadTask = Task {
            await loadData(for: coordinate, reason: reason)
            // Clear the reference when done (only if this is still the active task)
            if !Task.isCancelled {
                loadTask = nil
            }
        }
    }

    // MARK: - Public Triggers

    /// Called by pull-to-refresh via .refreshable. Returns when load completes.
    func refresh() async {
        guard let location = locationService.currentLocation else {
            locationService.requestCurrentLocation()
            return
        }
        logger.info("Pull-to-refresh -> startLoad")
        // Cancel any in-flight load, start a new one, then await it
        // so the refreshable spinner stays visible until completion.
        startLoad(for: location.coordinate, reason: "pull-to-refresh")
        // Await the task we just created
        await loadTask?.value
    }

    func loadDataForLocation(_ item: LocationItem) async {
        locationName = item.displayName
        logger.info("Manual location select -> startLoad: \(item.name)")
        startLoad(for: item.coordinate, reason: "manual-select")
        await loadTask?.value
    }

    // MARK: - Load Data

    private func loadData(for coordinate: CLLocationCoordinate2D, reason: String) async {
        isLoading = true
        pollenError = nil

        async let pollenResult = loadPollen(for: coordinate)
        async let weatherResult = loadWeather(for: coordinate)

        let (_, _) = await (pollenResult, weatherResult)

        // If this task was cancelled mid-flight, don't touch published state
        guard !Task.isCancelled else {
            logger.debug("Load (\(reason)) cancelled — skipping state update")
            return
        }

        logger.info("Load (\(reason)) completed")

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

    // MARK: - Private Loaders

    @discardableResult
    private func loadPollen(for coordinate: CLLocationCoordinate2D) async -> Bool {
        do {
            try Task.checkCancellation()
            let forecast = try await pollenService.fetchForecast(for: coordinate, days: 5)

            // Check again after the await
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
                logger.info("Pollen loaded: \(today.overallRiskLevel.label), \(forecast.days.count) days")
            } else {
                pollenSnapshot = nil
                pollenError = "Pollen API returned no daily data"
                logger.warning("Pollen forecast had 0 days")
            }
            return true
        } catch is CancellationError {
            // Cancelled by a newer startLoad() — not an error
            logger.debug("Pollen request cancelled (superseded)")
            return false
        } catch {
            guard !Task.isCancelled else { return false }
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
        } catch {
            guard !Task.isCancelled else { return false }
            return false
        }
    }
}
