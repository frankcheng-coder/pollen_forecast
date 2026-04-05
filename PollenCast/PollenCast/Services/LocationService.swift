import Foundation
import CoreLocation
import Combine

// MARK: - Location Authorization Status

enum LocationAuthStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    var canAccessLocation: Bool {
        self == .authorized
    }

    var needsRequest: Bool {
        self == .notDetermined
    }
}

// MARK: - Location Service

@MainActor
final class LocationService: NSObject, ObservableObject {

    @Published var authorizationStatus: LocationAuthStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    @Published var locationError: Error?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// Minimum distance change (meters) before we consider location "meaningfully changed"
    private let significantDistanceThreshold: CLLocationDistance = 500

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        updateAuthStatus()
    }

    // MARK: - Public API

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        guard authorizationStatus.canAccessLocation else { return }
        locationManager.requestLocation()
    }

    func startMonitoringLocation() {
        guard authorizationStatus.canAccessLocation else { return }
        locationManager.startUpdatingLocation()
    }

    func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
    }

    func reverseGeocode(location: CLLocation) async -> CLPlacemark? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first
        } catch {
            return nil
        }
    }

    func currentLocationItem() async -> LocationItem? {
        guard let location = currentLocation else { return nil }

        let placemark = await reverseGeocode(location: location)
        let name = placemark?.locality ?? placemark?.name ?? "Current Location"

        return LocationItem(
            name: name,
            locality: placemark?.locality,
            administrativeArea: placemark?.administrativeArea,
            country: placemark?.country,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            isCurrent: true
        )
    }

    // MARK: - Private

    private func updateAuthStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        case .restricted:
            authorizationStatus = .restricted
        @unknown default:
            authorizationStatus = .denied
        }
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        if let previous = currentLocation {
            let distance = location.distance(from: previous)
            guard distance > significantDistanceThreshold else { return }
        }
        currentLocation = location
        Task {
            currentPlacemark = await reverseGeocode(location: location)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthStatus()
            if authorizationStatus.canAccessLocation {
                requestCurrentLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            handleLocationUpdate(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error
        }
    }
}
