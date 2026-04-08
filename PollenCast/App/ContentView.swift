import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationService: LocationService
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedTab = 0

    // Detail navigation
    @State private var showDetail = false
    @State private var detailViewModel: DetailViewModel?

    // Shared HomeViewModel so Locations tab can call loadDataForLocation
    @State private var homeViewModel: HomeViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            homeTab
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Map Tab — gated by subscription
            Group {
                if subscriptionService.isSubscribed {
                    MapScreenView(
                        viewModel: MapViewModel(locationService: locationService),
                        locationService: locationService
                    )
                } else {
                    MapPaywallView(subscriptionService: subscriptionService)
                }
            }
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
            onViewModelReady: { vm in
                homeViewModel = vm
            },
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
            onLocationSelected: { location in
                guard let homeVM = homeViewModel else { return }
                Task {
                    await homeVM.loadDataForLocation(location)
                }
                selectedTab = 0
            }
        )
    }
}

// MARK: - Home Tab Wrapper (owns its own view model)

private struct HomeTabWrapper: View {
    let locationService: LocationService
    let onViewModelReady: (HomeViewModel) -> Void
    let onDaySelected: (PollenDay, DailyWeather?, String) -> Void

    @StateObject private var viewModel: HomeViewModel

    init(
        locationService: LocationService,
        onViewModelReady: @escaping (HomeViewModel) -> Void,
        onDaySelected: @escaping (PollenDay, DailyWeather?, String) -> Void
    ) {
        self.locationService = locationService
        self.onViewModelReady = onViewModelReady
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
        .onAppear {
            onViewModelReady(viewModel)
        }
    }
}

// MARK: - Locations Tab Wrapper

private struct LocationsTabWrapper: View {
    let onLocationSelected: (LocationItem) -> Void

    @StateObject private var viewModel = SavedLocationsViewModel()

    var body: some View {
        SavedLocationsView(
            viewModel: viewModel,
            onLocationSelected: onLocationSelected
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationService())
}
