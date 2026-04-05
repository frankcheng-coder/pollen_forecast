import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationService: LocationService
    @AppStorage("useMetricUnits") private var useMetricUnits = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    var body: some View {
        NavigationStack {
            List {
                // Location
                Section("Location") {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(locationStatusText)
                            .foregroundStyle(locationStatusColor)
                    }

                    if locationService.authorizationStatus == .denied {
                        Button("Open Location Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }

                    Toggle("Use Current Location", isOn: .constant(locationService.authorizationStatus.canAccessLocation))
                        .disabled(true)
                        .tint(.blue)
                }

                // Units
                Section("Units") {
                    Toggle("Metric Units (Celsius, km/h)", isOn: $useMetricUnits)
                        .tint(.blue)
                }

                // Notifications (placeholder)
                Section("Notifications") {
                    Toggle("Daily Pollen Alert", isOn: $notificationsEnabled)
                        .tint(.blue)

                    if notificationsEnabled {
                        Text("Notification support coming soon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Data Sources
                Section("Data Sources") {
                    Link(destination: URL(string: "https://developers.google.com/maps/documentation/pollen")!) {
                        HStack {
                            Text("Google Pollen API")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }

                    HStack {
                        Text("Apple WeatherKit")
                        Spacer()
                        Image(systemName: "cloud.sun")
                            .foregroundStyle(.secondary)
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Pollen data")
                        Spacer()
                        Text("Google Pollen API")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Weather data")
                        Spacer()
                        Text("Apple WeatherKit")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Asked"
        }
    }

    private var locationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorized: return .green
        case .denied: return .red
        case .restricted: return .orange
        case .notDetermined: return .secondary
        }
    }
}

#Preview {
    SettingsView(locationService: LocationService())
}
