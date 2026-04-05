import Foundation
import MapKit
import Combine

// MARK: - Saved Locations View Model

@MainActor
final class SavedLocationsViewModel: ObservableObject {

    @Published var savedLocations: [LocationItem] = []
    @Published var searchQuery = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false

    private let cacheService: CacheService
    private let searchService: LocationSearchService
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init(cacheService: CacheService = .shared) {
        self.cacheService = cacheService
        self.searchService = LocationSearchService()
        loadSavedLocations()
        setupSearchDebounce()
    }

    // MARK: - Search

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            searchService.search(query: query)
            // Wait briefly for results
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                searchResults = searchService.searchResults
                isSearching = false
            }
        }
    }

    // MARK: - Save / Remove

    func addLocation(from mapItem: MKMapItem) async -> LocationItem? {
        guard let coordinate = mapItem.placemark.location?.coordinate else { return nil }

        let item = LocationItem(
            name: mapItem.name ?? "Unknown",
            locality: mapItem.placemark.locality,
            administrativeArea: mapItem.placemark.administrativeArea,
            country: mapItem.placemark.country,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        // Avoid duplicates
        if !savedLocations.contains(where: { $0.name == item.name && $0.latitude == item.latitude }) {
            savedLocations.append(item)
            persistLocations()
        }

        return item
    }

    func removeLocation(_ location: LocationItem) {
        savedLocations.removeAll { $0.id == location.id }
        persistLocations()
    }

    func removeLocations(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        persistLocations()
    }

    // MARK: - Persistence

    func loadSavedLocations() {
        savedLocations = cacheService.loadSavedLocations()
    }

    private func persistLocations() {
        cacheService.saveSavedLocations(savedLocations)
    }
}
