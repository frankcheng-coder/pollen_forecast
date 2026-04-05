import SwiftUI
import MapKit

struct SavedLocationsView: View {
    @ObservedObject var viewModel: SavedLocationsViewModel
    var onLocationSelected: ((LocationItem) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                // Search section
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search city or place", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                    }
                }

                // Search results
                if !viewModel.searchResults.isEmpty {
                    Section("Search Results") {
                        ForEach(viewModel.searchResults, id: \.self) { item in
                            Button {
                                Task {
                                    if let location = await viewModel.addLocation(from: item) {
                                        onLocationSelected?(location)
                                    }
                                }
                                viewModel.searchQuery = ""
                            } label: {
                                LocationSearchRow(mapItem: item)
                            }
                        }
                    }
                } else if viewModel.isSearching {
                    Section {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Searching...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Saved locations
                Section("Saved Locations") {
                    if viewModel.savedLocations.isEmpty {
                        Text("No saved locations yet. Search for a city above to add one.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(viewModel.savedLocations) { location in
                            Button {
                                onLocationSelected?(location)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        if let subtitle = location.subtitle {
                                            Text(subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: viewModel.removeLocations)
                    }
                }
            }
            .navigationTitle("Locations")
            .toolbar {
                if !viewModel.savedLocations.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

// MARK: - Location Search Row

struct LocationSearchRow: View {
    let mapItem: MKMapItem

    var body: some View {
        HStack {
            Image(systemName: "mappin.circle")
                .foregroundStyle(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(mapItem.name ?? "Unknown")
                    .font(.body)
                    .foregroundStyle(.primary)
                if let locality = mapItem.placemark.locality,
                   let area = mapItem.placemark.administrativeArea {
                    Text("\(locality), \(area)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "plus.circle")
                .foregroundStyle(.blue)
        }
    }
}

#Preview {
    SavedLocationsView(viewModel: SavedLocationsViewModel())
}
