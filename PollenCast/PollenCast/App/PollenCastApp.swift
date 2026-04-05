import SwiftUI

@main
struct PollenCastApp: App {
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
        }
    }
}
