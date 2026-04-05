import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Map View Model

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: - Published State

    @Published var region: MKCoordinateRegion = .defaultRegion
    @Published var selectedPollen: PollenSnapshot?
    @Published var selectionState: MapSelectionState = .currentLocation
    @Published var savedLocations: [LocationItem] = []
    @Published var isLoadingPollen = false
    @Published var showBottomSheet = false

    // MARK: - Dependencies

    private let locationService: LocationService
    private let pollenService: PollenAPIServiceProtocol
    private let cacheService: CacheService
    private var cancellables = Set<AnyCancellable>()
    private var lastFetchedCoordinate: CLLocationCoordinate2D?

    /// Minimum distance to trigger a new pollen fetch from map movement
    private let fetchDistanceThreshold: CLLocationDistance = 5000 // 5km

    // MARK: - Init

    init(
        locationService: LocationService,
        pollenService: PollenAPIServiceProtocol = PollenAPIService(),
        cacheService: CacheService = .shared
    ) {
        self.locationService = locationService
        self.pollenService = pollenService
        self.cacheService = cacheService

        savedLocations = cacheService.loadSavedLocations()
        observeLocation()
    }

    // MARK: - Observe Location

    private func observeLocation() {
        locationService.$currentLocation
            .compactMap { $0 }
            .first() // Only auto-center once
            .sink { [weak self] location in
                self?.centerOnLocation(location.coordinate)
                Task { [weak self] in
                    await self?.fetchPollenForCoordinate(location.coordinate)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Map Actions

    func centerOnCurrentLocation() {
        guard let location = locationService.currentLocation else { return }
        centerOnLocation(location.coordinate)
        selectionState = .currentLocation
        Task {
            await fetchPollenForCoordinate(location.coordinate)
        }
    }

    func centerOnLocation(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func selectSavedLocation(_ location: LocationItem) {
        centerOnLocation(location.coordinate)
        selectionState = .savedLocation(location)
        Task {
            await fetchPollenForCoordinate(location.coordinate)
        }
    }

    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        selectionState = .customPoint(coordinate)
        Task {
            await fetchPollenForCoordinate(coordinate)
        }
    }

    // MARK: - Fetch Pollen

    func fetchPollenForCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        // Debounce: skip if too close to last fetch
        if let last = lastFetchedCoordinate {
            let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if lastLocation.distance(from: newLocation) < fetchDistanceThreshold && selectedPollen != nil {
                return
            }
        }

        isLoadingPollen = true
        lastFetchedCoordinate = coordinate

        do {
            let snapshot = try await pollenService.fetchCurrentPollen(for: coordinate)
            selectedPollen = snapshot
            showBottomSheet = true
        } catch {
            // Keep showing previous data if available
        }

        isLoadingPollen = false
    }

    func refreshSavedLocations() {
        savedLocations = cacheService.loadSavedLocations()
    }
}

// MARK: - Default Region

extension MKCoordinateRegion {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
}
