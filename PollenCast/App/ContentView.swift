import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationService: LocationService
    @State private var selectedTab = 0

    // Detail navigation
    @State private var showDetail = false
    @State private var detailViewModel: DetailViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            homeTab
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Map Tab
            MapScreenView(
                viewModel: MapViewModel(locationService: locationService),
                locationService: locationService
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(1)

            // Locations Tab
            locationsTab
                .tabItem {
                    Label("Locations", systemImage: "bookmark.fill")
                }
                .tag(2)

            // Settings Tab
            SettingsView(locationService: locationService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.blue)
        .sheet(isPresented: $showDetail) {
            if let detailVM = detailViewModel {
                NavigationStack {
                    DetailView(viewModel: detailVM)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showDetail = false }
                            }
                        }
                }
            }
        }
    }

    private var homeTab: some View {
        HomeTabWrapper(
            locationService: locationService,
            onDaySelected: { day, weather, locationName in
                let vm = DetailViewModel(locationName: locationName)
                vm.loadDetail(for: day, weather: weather)
                detailViewModel = vm
                showDetail = true
            }
        )
    }

    private var locationsTab: some View {
        LocationsTabWrapper(
            locationService: locationService,
            onSelectTab: { selectedTab = $0 }
        )
    }
}

// MARK: - Home Tab Wrapper (owns its own view model)

private struct HomeTabWrapper: View {
    let locationService: LocationService
    let onDaySelected: (PollenDay, DailyWeather?, String) -> Void

    @StateObject private var viewModel: HomeViewModel

    init(locationService: LocationService, onDaySelected: @escaping (PollenDay, DailyWeather?, String) -> Void) {
        self.locationService = locationService
        self.onDaySelected = onDaySelected
        _viewModel = StateObject(wrappedValue: HomeViewModel(locationService: locationService))
    }

    var body: some View {
        HomeView(
            viewModel: viewModel,
            locationService: locationService,
            onDaySelected: { day, weather in
                onDaySelected(day, weather, viewModel.locationName)
            }
        )
    }
}

// MARK: - Locations Tab Wrapper

private struct LocationsTabWrapper: View {
    let locationService: LocationService
    let onSelectTab: (Int) -> Void

    @StateObject private var viewModel = SavedLocationsViewModel()

    var body: some View {
        SavedLocationsView(
            viewModel: viewModel,
            onLocationSelected: { location in
                // Switch to home tab when a location is selected
                onSelectTab(0)
            }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationService())
}
