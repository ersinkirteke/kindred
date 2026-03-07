import ComposableArchitecture
import FeedFeature
import Foundation
import MonetizationFeature
import StoreKit

// Resolve SubscriptionStatus ambiguity between FeedFeature and MonetizationFeature
public typealias SubscriptionStatus = MonetizationFeature.SubscriptionStatus

public enum AuthState: Equatable {
    case guest
    case authenticated(userId: String)
}

@Reducer
public struct ProfileReducer {
    @ObservableState
    public struct State: Equatable {
        public var authState: AuthState = .guest
        public var dietaryPreferences: Set<String> = []

        // Culinary DNA
        public var culinaryDNAAffinities: [AffinityScore] = []
        public var interactionCount: Int = 0
        public var isDNAActivated: Bool = false

        // Subscription
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var displayPrice: String = "$9.99"
        public var subscriptionProducts: [Product] = []

        public init() {}
    }

    public enum Action {
        case onAppear
        case signInTapped
        case continueAsGuestTapped
        case loadDietaryPreferences
        case dietaryPreferencesChanged(Set<String>)
        case resetDietaryPreferences
        case loadCulinaryDNA
        case culinaryDNALoaded([AffinityScore], Int, Bool)
        case loadSubscriptionStatus
        case subscriptionStatusLoaded(SubscriptionStatus)
        case subscriptionProductsLoaded([Product])
        case subscribeTapped
        case purchaseCompleted(SubscriptionStatus)
        case purchaseFailed(String)
        case manageSubscriptionTapped
        case restorePurchasesTapped
        case restoreCompleted(SubscriptionStatus)
    }

    @Dependency(\.guestSessionClient) var guestSession
    @Dependency(\.personalizationClient) var personalization
    @Dependency(\.subscriptionClient) var subscriptionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load dietary preferences, culinary DNA, and subscription status on appear
                return .merge(
                    .send(.loadDietaryPreferences),
                    .send(.loadCulinaryDNA),
                    .send(.loadSubscriptionStatus)
                )

            case .loadDietaryPreferences:
                // Load from UserDefaults
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let preferences = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    state.dietaryPreferences = preferences
                }
                return .none

            case let .dietaryPreferencesChanged(preferences):
                state.dietaryPreferences = preferences
                // Save to UserDefaults
                if let encoded = try? JSONEncoder().encode(preferences) {
                    UserDefaults.standard.set(encoded, forKey: "dietaryPreferences")
                }
                return .none

            case .resetDietaryPreferences:
                state.dietaryPreferences = []
                UserDefaults.standard.removeObject(forKey: "dietaryPreferences")
                return .none

            case .loadCulinaryDNA:
                return .run { send in
                    let bookmarks = await guestSession.allBookmarks()
                    let skips = await guestSession.allSkips()
                    let affinities = await personalization.computeAffinities(bookmarks, skips)
                    let count = await personalization.interactionCount(bookmarks, skips)
                    let activated = await personalization.isActivated(bookmarks, skips)
                    await send(.culinaryDNALoaded(affinities, count, activated))
                }

            case let .culinaryDNALoaded(affinities, count, activated):
                state.culinaryDNAAffinities = affinities
                state.interactionCount = count
                state.isDNAActivated = activated
                return .none

            case .signInTapped:
                // Placeholder - auth flow in Phase 8
                return .none

            case .continueAsGuestTapped:
                // Placeholder - guest flow in Phase 8
                return .none

            case .loadSubscriptionStatus:
                return .run { send in
                    // Load products and check entitlement in parallel
                    async let products = try subscriptionClient.loadProducts()
                    async let status = subscriptionClient.currentEntitlement()

                    let loadedProducts = try await products
                    await send(.subscriptionProductsLoaded(loadedProducts))

                    let loadedStatus = await status
                    await send(.subscriptionStatusLoaded(loadedStatus))
                } catch: { error, send in
                    // If loading fails, default to free tier
                    await send(.subscriptionStatusLoaded(.free))
                }

            case let .subscriptionStatusLoaded(status):
                state.subscriptionStatus = status
                return .none

            case let .subscriptionProductsLoaded(products):
                state.subscriptionProducts = products
                // Extract display price from first product
                if let firstProduct = products.first {
                    state.displayPrice = firstProduct.displayPrice
                }
                return .none

            case .subscribeTapped:
                guard let product = state.subscriptionProducts.first else {
                    return .send(.purchaseFailed("No subscription product available"))
                }

                return .run { send in
                    do {
                        _ = try await subscriptionClient.purchase(product)
                        // Re-check entitlement after purchase
                        let status = await subscriptionClient.currentEntitlement()
                        await send(.purchaseCompleted(status))
                    } catch {
                        await send(.purchaseFailed(error.localizedDescription))
                    }
                }

            case let .purchaseCompleted(status):
                state.subscriptionStatus = status
                return .none

            case let .purchaseFailed(message):
                // TODO: Show error alert in Phase 9 Plan 5 (error handling)
                print("Purchase failed: \(message)")
                return .none

            case .manageSubscriptionTapped:
                // Open iOS Settings subscription management
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
                return .none

            case .restorePurchasesTapped:
                return .run { send in
                    do {
                        try await subscriptionClient.restorePurchases()
                        // Re-check entitlement after restore
                        let status = await subscriptionClient.currentEntitlement()
                        await send(.restoreCompleted(status))
                    } catch {
                        // Restore failed, keep current status
                        print("Restore failed: \(error.localizedDescription)")
                    }
                }

            case let .restoreCompleted(status):
                state.subscriptionStatus = status
                return .none
            }
        }
    }
}
