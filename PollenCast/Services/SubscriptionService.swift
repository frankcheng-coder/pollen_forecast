import Foundation
import Combine

/// Minimal subscription gate. Replace `isSubscribed` with a real
/// entitlement check (StoreKit, RevenueCat, server flag, etc.) later.
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var isSubscribed: Bool = false

    private init() {}
}
