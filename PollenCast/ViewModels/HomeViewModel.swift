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

    /// When non-nil, Home is showing a saved/manual location and GPS updates are ignored.
    @Published var pinnedLocation: LocationItem?

    /// True when Home is showing a pinned saved location rather than live GPS.
    var isShowingPinnedLocation: Bool { pinnedLocation != nil }

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
        weatherService: WeatherServiceProtocol = WeatherKitService(),
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
                guard let self else { return }
                // Don't overwrite a pinned saved location with GPS
                guard self.pinnedLocation == nil else {
                    logger.debug("GPS update ignored — showing pinned location")
                    return
                }
                logger.info("Location update -> startLoad (\(location.coordinate.latitude), \(location.coordinate.longitude))")
                self.startLoad(for: location.coordinate, reason: "location-update")
            }
            .store(in: &cancellables)

        locationService.$currentPlacemark
            .compactMap { $0 }
            .sink { [weak self] placemark in
                guard let self else { return }
                // Don't overwrite the header when showing a pinned location
                guard self.pinnedLocation == nil else { return }
                self.locationName = placemark.locality ?? placemark.name ?? "Current Location"
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
            if !Task.isCancelled {
                loadTask = nil
            }
        }
    }

    // MARK: - Public Triggers

    /// Called by pull-to-refresh. Reloads whichever location Home is currently showing.
    func refresh() async {
        let coordinate: CLLocationCoordinate2D
        if let pinned = pinnedLocation {
            coordinate = pinned.coordinate
            logger.info("Pull-to-refresh -> reload pinned: \(pinned.name)")
        } else if let location = locationService.currentLocation {
            coordinate = location.coordinate
            logger.info("Pull-to-refresh -> reload current location")
        } else {
            locationService.requestCurrentLocation()
            return
        }
        startLoad(for: coordinate, reason: "pull-to-refresh")
        await loadTask?.value
    }

    /// Called when user taps a saved location. Pins it and loads its data.
    func loadDataForLocation(_ item: LocationItem) async {
        pinnedLocation = item
        locationName = item.displayName
        logger.info("Pinned location -> startLoad: \(item.name)")
        startLoad(for: item.coordinate, reason: "saved-location")
        await loadTask?.value
    }

    /// Called when user wants to go back to live GPS location.
    func switchToCurrentLocation() {
        pinnedLocation = nil
        logger.info("Switched back to current location")
        if let location = locationService.currentLocation {
            // Update header from placemark
            if let placemark = locationService.currentPlacemark {
                locationName = placemark.locality ?? placemark.name ?? "Current Location"
            } else {
                locationName = "Current Location"
            }
            startLoad(for: location.coordinate, reason: "switch-to-current")
        } else {
            locationName = "Loading..."
            locationService.requestCurrentLocation()
        }
    }

    // MARK: - Load Data

    private func loadData(for coordinate: CLLocationCoordinate2D, reason: String) async {
        isLoading = true
        pollenError = nil

        async let pollenResult = loadPollen(for: coordinate)
        async let weatherResult = loadWeather(for: coordinate)

        let (_, _) = await (pollenResult, weatherResult)

        guard !Task.isCancelled else {
            logger.debug("Load (\(reason)) cancelled — skipping state update")
            return
        }

        logger.info("Load (\(reason)) completed")

        recommendation = RecommendationEngine.generate(
            pollen: pollenSnapshot,
            weather: weatherContext
        )

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
