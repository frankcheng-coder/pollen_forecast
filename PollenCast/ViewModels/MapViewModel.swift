import Foundation
import CoreLocation
import MapKit
import OSLog

private let logger = Logger(subsystem: "com.pollencast.app", category: "PollenMap")

// MARK: - Pollen Grid Cell

struct PollenGridCell: Identifiable {
    let id = UUID()
    let corners: [CLLocationCoordinate2D]
    let riskLevel: PollenRiskLevel
}

// MARK: - Map View Model

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: - Published State

    @Published var gridCells: [PollenGridCell] = []
    @Published var isLoading = false

    // MARK: - Dependencies

    private let locationService: LocationService
    private let pollenService: PollenAPIServiceProtocol
    private var loadTask: Task<Void, Never>?
    private var lastSampledRegion: MKCoordinateRegion?

    private let gridSize = 4 // 4×4 = 16 cells

    // MARK: - Init

    init(
        locationService: LocationService,
        pollenService: PollenAPIServiceProtocol = PollenAPIService(),
        cacheService: CacheService = .shared
    ) {
        self.locationService = locationService
        self.pollenService = pollenService
    }

    // MARK: - Initial Location

    var initialCoordinate: CLLocationCoordinate2D {
        locationService.currentLocation?.coordinate ?? .sanFrancisco
    }

    // MARK: - Region Changed

    func onRegionChanged(_ region: MKCoordinateRegion) {
        // Skip if region hasn't moved meaningfully since last sample
        if let last = lastSampledRegion {
            let latShift = abs(last.center.latitude - region.center.latitude)
            let lonShift = abs(last.center.longitude - region.center.longitude)
            let zoomChange = abs(last.span.latitudeDelta - region.span.latitudeDelta)
                / max(last.span.latitudeDelta, 0.001)

            if latShift < region.span.latitudeDelta * 0.15
                && lonShift < region.span.longitudeDelta * 0.15
                && zoomChange < 0.3 {
                return
            }
        }

        loadTask?.cancel()
        loadTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await sampleGrid(for: region)
        }
    }

    // MARK: - Grid Sampling

    private func sampleGrid(for region: MKCoordinateRegion) async {
        isLoading = true
        lastSampledRegion = region

        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let latStep = region.span.latitudeDelta / Double(gridSize)
        let lonStep = region.span.longitudeDelta / Double(gridSize)
        let size = gridSize
        let service = pollenService

        var cells: [PollenGridCell] = []

        await withTaskGroup(of: PollenGridCell?.self) { group in
            for row in 0..<size {
                for col in 0..<size {
                    group.addTask {
                        let cellMinLat = minLat + Double(row) * latStep
                        let cellMinLon = minLon + Double(col) * lonStep

                        let corners = [
                            CLLocationCoordinate2D(latitude: cellMinLat, longitude: cellMinLon),
                            CLLocationCoordinate2D(latitude: cellMinLat + latStep, longitude: cellMinLon),
                            CLLocationCoordinate2D(latitude: cellMinLat + latStep, longitude: cellMinLon + lonStep),
                            CLLocationCoordinate2D(latitude: cellMinLat, longitude: cellMinLon + lonStep),
                        ]
                        let center = CLLocationCoordinate2D(
                            latitude: cellMinLat + latStep / 2,
                            longitude: cellMinLon + lonStep / 2
                        )

                        do {
                            let snapshot = try await service.fetchCurrentPollen(for: center)
                            return PollenGridCell(corners: corners, riskLevel: snapshot.overallRiskLevel)
                        } catch is CancellationError {
                            return nil
                        } catch {
                            return PollenGridCell(corners: corners, riskLevel: .none)
                        }
                    }
                }
            }

            for await cell in group {
                if let cell { cells.append(cell) }
            }
        }

        guard !Task.isCancelled else { return }
        gridCells = cells
        isLoading = false
        logger.info("Heatmap updated: \(cells.count) cells")
    }
}

// MARK: - Default Region

extension MKCoordinateRegion {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
}
