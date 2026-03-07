import Foundation
import StoreKit
import ComposableArchitecture

@Reducer
public struct SubscriptionReducer {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var products: [Product] = []
        public var isPurchasing: Bool = false
        public var isRestoring: Bool = false
        public var showPaywall: Bool = false
        public var error: String?
        public var displayPrice: String = "$9.99"

        public init() {}
    }

    // MARK: - Action

    public enum Action: Equatable {
        case onAppear
        case productsLoaded([Product])
        case entitlementChecked(SubscriptionStatus)
        case subscribeTapped
        case purchaseCompleted(SubscriptionStatus, StoreKit.Transaction)
        case purchaseFailed(String)
        case restoreTapped
        case restoreCompleted(SubscriptionStatus)
        case showPaywall
        case dismissPaywall
        case transactionUpdated(SubscriptionStatus)
        case clearError
    }

    // MARK: - Dependencies

    @Dependency(\.subscriptionClient) var subscriptionClient

    // MARK: - Reducer

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    // Load products
                    .run { send in
                        do {
                            let products = try await subscriptionClient.loadProducts()
                            await send(.productsLoaded(products))
                        } catch {
                            await send(.purchaseFailed(error.localizedDescription))
                        }
                    },
                    // Check current entitlement
                    .run { send in
                        let status = await subscriptionClient.currentEntitlement()
                        await send(.entitlementChecked(status))
                    },
                    // Start transaction updates stream
                    .run { send in
                        let updates = await subscriptionClient.observeTransactionUpdates()
                        for await _ in updates {
                            // Re-check entitlement when transaction updates
                            let status = await subscriptionClient.currentEntitlement()
                            await send(.transactionUpdated(status))
                        }
                    }
                )

            case .productsLoaded(let products):
                state.products = products
                // Extract display price from first product
                if let product = products.first {
                    state.displayPrice = product.displayPrice
                }
                return .none

            case .entitlementChecked(let status):
                state.subscriptionStatus = status
                return .none

            case .subscribeTapped:
                guard let product = state.products.first else {
                    return .send(.purchaseFailed("Product not available"))
                }

                state.isPurchasing = true
                state.error = nil

                return .run { send in
                    do {
                        let transaction = try await subscriptionClient.purchase(product)
                        let status = await subscriptionClient.currentEntitlement()
                        await send(.purchaseCompleted(status, transaction))
                    } catch let error as SubscriptionError {
                        switch error {
                        case .purchaseCancelled:
                            // User cancelled - don't show error
                            await send(.purchaseFailed(""))
                        default:
                            await send(.purchaseFailed(error.localizedDescription))
                        }
                    } catch {
                        await send(.purchaseFailed(error.localizedDescription))
                    }
                }

            case .purchaseCompleted(let status, let transaction):
                state.subscriptionStatus = status
                state.isPurchasing = false
                state.showPaywall = false

                // Sync purchase to backend - fire and forget
                return .run { _ in
                    if let jws = await subscriptionClient.jwsRepresentation(transaction) {
                        _ = try? await subscriptionClient.syncSubscriptionToBackend(jws)
                    }
                }

            case .purchaseFailed(let message):
                state.isPurchasing = false
                if !message.isEmpty {
                    state.error = message
                }
                return .none

            case .restoreTapped:
                state.isRestoring = true
                state.error = nil

                return .run { send in
                    do {
                        try await subscriptionClient.restorePurchases()
                        let status = await subscriptionClient.currentEntitlement()
                        await send(.restoreCompleted(status))
                    } catch {
                        await send(.purchaseFailed("Failed to restore purchases"))
                    }
                }

            case .restoreCompleted(let status):
                state.subscriptionStatus = status
                state.isRestoring = false
                state.showPaywall = false
                return .none

            case .showPaywall:
                state.showPaywall = true
                return .none

            case .dismissPaywall:
                state.showPaywall = false
                state.error = nil
                return .none

            case .transactionUpdated(let status):
                state.subscriptionStatus = status
                return .none

            case .clearError:
                state.error = nil
                return .none
            }
        }
    }
}

// MARK: - Product Equatable

extension Product: Equatable {
    public static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Transaction Equatable

extension StoreKit.Transaction: Equatable {
    public static func == (lhs: StoreKit.Transaction, rhs: StoreKit.Transaction) -> Bool {
        lhs.id == rhs.id
    }
}
