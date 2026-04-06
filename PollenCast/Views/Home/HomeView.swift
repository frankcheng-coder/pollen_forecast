import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var locationService: LocationService
    var onDaySelected: ((PollenDay, DailyWeather?) -> Void)?

    #if DEBUG
    @State private var showDebugPanel = false
    #endif

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
                    HStack(spacing: 8) {
                        #if DEBUG
                        Button {
                            showDebugPanel.toggle()
                        } label: {
                            Image(systemName: "ladybug")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        #endif

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
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Location header
                locationHeader

                // Error banner at TOP so it's visible
                if let error = viewModel.pollenError {
                    ErrorBanner(message: error)
                }

                // Debug panel
                #if DEBUG
                if showDebugPanel {
                    PollenDebugPanel(debugInfo: viewModel.debugInfo)
                }
                #endif

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

                // Health guidance — only shown when we have real data
                if let recommendation = viewModel.recommendation {
                    HealthGuidanceSection(recommendation: recommendation)
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
            Image(systemName: viewModel.isShowingPinnedLocation ? "mappin.circle.fill" : "location.fill")
                .font(.caption)
                .foregroundStyle(viewModel.isShowingPinnedLocation ? .orange : .blue)
            Text(viewModel.locationName)
                .font(.subheadline.weight(.medium))
            Spacer()
            if viewModel.isShowingPinnedLocation {
                Button {
                    viewModel.switchToCurrentLocation()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text("My Location")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1), in: Capsule())
                }
                .foregroundStyle(.blue)
                .accessibilityLabel("Switch back to current location")
            }
        }
        .accessibilityLabel("Location: \(viewModel.locationName)")
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pollen Data Unavailable")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Debug Panel

struct PollenDebugPanel: View {
    let debugInfo: PollenDebugInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pollen API Debug")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)

            if let info = debugInfo {
                debugRow("Status", value: info.httpStatusCode.map { "\($0)" } ?? "N/A")
                debugRow("Decoded", value: info.decodingSucceeded ? "Yes" : "No")
                debugRow("Days parsed", value: "\(info.forecastDaysParsed)")
                debugRow("Time", value: info.timestamp.mediumDateString)

                if let error = info.error {
                    debugRow("Error", value: error)
                        .foregroundStyle(.red)
                }

                Text("URL: \(info.requestURL)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !info.responseBodyPreview.isEmpty {
                    Text("Body: \(info.responseBodyPreview.prefix(200))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            } else {
                Text("No request made yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func debugRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2.weight(.medium))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption2)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    let locationService = LocationService()
    let viewModel = HomeViewModel(locationService: locationService)
    HomeView(viewModel: viewModel, locationService: locationService)
}
