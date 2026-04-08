import SwiftUI

/// Shown in place of the Map screen when the user is not subscribed.
struct MapPaywallView: View {
    @ObservedObject var subscriptionService: SubscriptionService

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 56))
                .foregroundColor(.blue)

            Text("Map is a Premium Feature")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("Upgrade to PollenCast Premium to view the live pollen intensity heatmap for your area.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                // TODO: hook into real purchase flow.
                subscriptionService.isSubscribed = true
            } label: {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding()
    }
}
