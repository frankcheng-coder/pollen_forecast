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

    /// Target geographic size per cell in degrees.
    private let targetCellSpan: Double = 0.03
    private let minGridSize = 3
    private let maxGridSize = 6

    // MARK: - Sample Cache

    /// Coordinate-snapped cache: "snappedLat,snappedLon" → (risk, timestamp).
    /// Nearby sample points that snap to the same grid key reuse cached results.
    private var sampleCache: [String: (risk: PollenRiskLevel, timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    private let snapResolution: Double = 0.005 // ~500 m — coarse enough for cache hits on small pans
    private let maxCacheEntries = 500

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

        // Zoom-aware grid: keep cell size ~targetCellSpan degrees
        let largerSpan = max(region.span.latitudeDelta, region.span.longitudeDelta)
        let gridSize = max(minGridSize, min(maxGridSize, Int(largerSpan / targetCellSpan)))

        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let latStep = region.span.latitudeDelta / Double(gridSize)
        let lonStep = region.span.longitudeDelta / Double(gridSize)

        let sampleRows = gridSize + 1
        let sampleCols = gridSize + 1
        let service = pollenService

        // Phase 1: check cache, collect points that need fetching
        var sampleResults: [Int: PollenRiskLevel] = [:]
        var toFetch: [(index: Int, lat: Double, lon: Double)] = []

        for row in 0..<sampleRows {
            for col in 0..<sampleCols {
                let index = row * sampleCols + col
                let lat = minLat + Double(row) * latStep
                let lon = minLon + Double(col) * lonStep

                if let cached = cachedRisk(lat: lat, lon: lon) {
                    sampleResults[index] = cached
                } else {
                    toFetch.append((index, lat, lon))
                }
            }
        }

        let cacheHits = sampleResults.count
        let totalPoints = sampleRows * sampleCols

        // Phase 2: fetch only uncached points
        if !toFetch.isEmpty {
            await withTaskGroup(of: (Int, Double, Double, PollenRiskLevel?).self) { group in
                for point in toFetch {
                    let pLat = point.lat
                    let pLon = point.lon
                    let pIdx = point.index
                    group.addTask {
                        do {
                            let coord = CLLocationCoordinate2D(latitude: pLat, longitude: pLon)
                            let snapshot = try await service.fetchCurrentPollen(for: coord)
                            return (pIdx, pLat, pLon, snapshot.overallRiskLevel)
                        } catch is CancellationError {
                            return (pIdx, pLat, pLon, nil)
                        } catch {
                            return (pIdx, pLat, pLon, nil)
                        }
                    }
                }

                for await (index, lat, lon, risk) in group {
                    if let risk {
                        sampleResults[index] = risk
                        storeCache(risk, lat: lat, lon: lon)
                    }
                }
            }
        }

        guard !Task.isCancelled else { return }

        // Build display cells — MAX of 4 corner samples per cell
        var cells: [PollenGridCell] = []
        cells.reserveCapacity(gridSize * gridSize)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let tl = row * sampleCols + col
                let tr = row * sampleCols + (col + 1)
                let bl = (row + 1) * sampleCols + col
                let br = (row + 1) * sampleCols + (col + 1)

                let cornerRisks = [tl, tr, bl, br].compactMap { sampleResults[$0] }
                guard let maxRisk = cornerRisks.max() else { continue }

                let cellMinLat = minLat + Double(row) * latStep
                let cellMinLon = minLon + Double(col) * lonStep
                let corners = [
                    CLLocationCoordinate2D(latitude: cellMinLat, longitude: cellMinLon),
                    CLLocationCoordinate2D(latitude: cellMinLat + latStep, longitude: cellMinLon),
                    CLLocationCoordinate2D(latitude: cellMinLat + latStep, longitude: cellMinLon + lonStep),
                    CLLocationCoordinate2D(latitude: cellMinLat, longitude: cellMinLon + lonStep),
                ]

                cells.append(PollenGridCell(corners: corners, riskLevel: maxRisk))
            }
        }

        gridCells = cells
        isLoading = false

        let fetched = toFetch.count - (totalPoints - cacheHits - sampleResults.count + cacheHits)
        logger.info("Heatmap: \(gridSize)×\(gridSize) grid, \(cacheHits)/\(totalPoints) cache hits, \(toFetch.count) fetched, \(cells.count) cells drawn")

        pruneCache()
    }

    // MARK: - Cache Helpers

    private func cacheKey(lat: Double, lon: Double) -> String {
        let snappedLat = (lat / snapResolution).rounded() * snapResolution
        let snappedLon = (lon / snapResolution).rounded() * snapResolution
        return "\(snappedLat),\(snappedLon)"
    }

    private func cachedRisk(lat: Double, lon: Double) -> PollenRiskLevel? {
        let key = cacheKey(lat: lat, lon: lon)
        guard let entry = sampleCache[key],
              Date().timeIntervalSince(entry.timestamp) < cacheTTL else {
            return nil
        }
        return entry.risk
    }

    private func storeCache(_ risk: PollenRiskLevel, lat: Double, lon: Double) {
        let key = cacheKey(lat: lat, lon: lon)
        sampleCache[key] = (risk, Date())
    }

    private func pruneCache() {
        guard sampleCache.count > maxCacheEntries else { return }
        let now = Date()
        sampleCache = sampleCache.filter { now.timeIntervalSince($0.value.timestamp) < cacheTTL }
    }
}

// MARK: - Default Region

extension MKCoordinateRegion {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
}
