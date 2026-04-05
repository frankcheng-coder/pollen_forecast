import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var locationService: LocationService
    var onDaySelected: ((PollenDay, DailyWeather?) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if locationService.authorizationStatus.needsRequest {
                    LocationPermissionView(
                        status: locationService.authorizationStatus,
                        onRequestPermission: {
                            locationService.requestPermission()
                        }
                    )
                } else if locationService.authorizationStatus == .denied && viewModel.pollenSnapshot == nil {
                    LocationPermissionView(
                        status: .denied,
                        onRequestPermission: {}
                    )
                } else {
                    mainContent
                }
            }
            .navigationTitle("PollenCast")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let lastUpdated = viewModel.lastUpdated {
                        Text(lastUpdated.timeAgoDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Location header
                locationHeader

                // Pollen risk card
                PollenRiskCard(snapshot: viewModel.pollenSnapshot)

                // Weather context row
                WeatherContextRow(weather: viewModel.weatherContext)

                // 5-day forecast
                ForecastSection(
                    forecast: viewModel.pollenForecast,
                    onDayTap: { day in
                        onDaySelected?(day, nil)
                    }
                )

                // Pollen types
                if let breakdowns = viewModel.pollenSnapshot?.typeBreakdowns, !breakdowns.isEmpty {
                    PollenTypesSection(breakdowns: breakdowns)
                }

                // Health guidance
                HealthGuidanceSection(recommendation: viewModel.recommendation)

                // Error banner
                if let error = viewModel.error {
                    ErrorBanner(message: error)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(viewModel.locationName)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .accessibilityLabel("Location: \(viewModel.locationName)")
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.08))
        )
    }
}

#Preview {
    let locationService = LocationService()
    let viewModel = HomeViewModel(locationService: locationService)
    HomeView(viewModel: viewModel, locationService: locationService)
}
