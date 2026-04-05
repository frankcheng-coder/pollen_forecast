import Foundation
import MapKit

// MARK: - Location Search Service

@MainActor
final class LocationSearchService: NSObject, ObservableObject {

    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false

    private var searchCompleter = MKLocalSearchCompleter()
    private var completionResults: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    // MARK: - Search

    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchCompleter.queryFragment = query
    }

    func selectCompletion(_ completion: MKLocalSearchCompletion) async -> LocationItem? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard let item = response.mapItems.first,
                  let coordinate = item.placemark.location?.coordinate else {
                return nil
            }

            return LocationItem(
                name: item.name ?? completion.title,
                locality: item.placemark.locality,
                administrativeArea: item.placemark.administrativeArea,
                country: item.placemark.country,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return nil
        }
    }

    func searchCoordinate(query: String) async -> LocationItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard let item = response.mapItems.first,
                  let coordinate = item.placemark.location?.coordinate else {
                return nil
            }

            return LocationItem(
                name: item.name ?? query,
                locality: item.placemark.locality,
                administrativeArea: item.placemark.administrativeArea,
                country: item.placemark.country,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return nil
        }
    }

    func clear() {
        searchResults = []
        completionResults = []
        isSearching = false
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchService: MKLocalSearchCompleterDelegate {

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            completionResults = completer.results
            // Convert completions to map items for display
            await performSearchFromCompletions()
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            isSearching = false
        }
    }

    private func performSearchFromCompletions() async {
        var items: [MKMapItem] = []

        // Take first 5 completions to avoid too many requests
        for completion in completionResults.prefix(5) {
            let request = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: request)
            if let response = try? await search.start() {
                items.append(contentsOf: response.mapItems)
            }
        }

        searchResults = items
        isSearching = false
    }
}
