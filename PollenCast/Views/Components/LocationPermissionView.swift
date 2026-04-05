import SwiftUI

struct LocationPermissionView: View {
    let status: LocationAuthStatus
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if status.needsRequest {
                Button(action: onRequestPermission) {
                    Text("Enable Location")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
            } else if status == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)

                Text("You can also search for a city manually")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
    }

    private var icon: String {
        switch status {
        case .notDetermined: return "location.circle"
        case .denied: return "location.slash"
        case .restricted: return "lock.circle"
        case .authorized: return "location.fill"
        }
    }

    private var title: String {
        switch status {
        case .notDetermined: return "See Pollen Near You"
        case .denied: return "Location Access Denied"
        case .restricted: return "Location Restricted"
        case .authorized: return "Location Enabled"
        }
    }

    private var message: String {
        switch status {
        case .notDetermined:
            return "PollenCast uses your location to show real-time pollen levels and forecasts for where you are right now."
        case .denied:
            return "Without location access, we can't show pollen data for your area. You can enable it in Settings or search for a city manually."
        case .restricted:
            return "Location access is restricted on this device. You can still search for cities to view pollen data."
        case .authorized:
            return "We're using your location to find pollen data nearby."
        }
    }
}

#Preview("Not Determined") {
    LocationPermissionView(status: .notDetermined, onRequestPermission: {})
}

#Preview("Denied") {
    LocationPermissionView(status: .denied, onRequestPermission: {})
}
