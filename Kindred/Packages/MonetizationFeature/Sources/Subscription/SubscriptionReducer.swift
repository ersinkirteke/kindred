import Foundation
import StoreKit
import ComposableArchitecture
import OSLog

private let logger = Logger(subsystem: "com.kindred", category: "Subscription")

@Reducer
public struct SubscriptionReducer {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var products: [Product] = []
        public var isLoadingProducts: Bool = true
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
        case simulatedPurchaseCompleted
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
                    // Load products with timeout (StoreKit hangs without sandbox)
                    .run { send in
                        do {
                            let products = try await withThrowingTaskGroup(of: [Product].self) { group in
                                group.addTask {
                                    try await subscriptionClient.loadProducts()
                                }
                                group.addTask {
                                    try await Task.sleep(for: .seconds(5))
                                    throw CancellationError()
                                }
                                let result = try await group.next() ?? []
                                group.cancelAll()
                                return result
                            }
                            await send(.productsLoaded(products))
                        } catch {
                            await send(.productsLoaded([]))
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
                logger.info("Products loaded: \(products.count) products")
                state.products = products
                state.isLoadingProducts = false
                // Extract display price from first product
                if let product = products.first {
                    state.displayPrice = product.displayPrice
                    logger.info("Product: \(product.id), price: \(product.displayPrice)")
                }
                return .none

            case .entitlementChecked(let status):
                logger.info("Entitlement checked: \(String(describing: status))")
                state.subscriptionStatus = status
                return .none

            case .subscribeTapped:
                let productCount = state.products.count
                logger.info("Subscribe tapped! products.count=\(productCount)")
                state.isPurchasing = true
                state.error = nil

                if let product = state.products.first {
                    logger.info("Attempting real StoreKit purchase for \(product.id)")
                    // Real StoreKit purchase
                    return .run { send in
                        do {
                            let transaction = try await subscriptionClient.purchase(product)
                            let status = await subscriptionClient.currentEntitlement()
                            await send(.purchaseCompleted(status, transaction))
                        } catch let error as SubscriptionError {
                            logger.error("Purchase SubscriptionError: \(error.localizedDescription)")
                            switch error {
                            case .purchaseCancelled:
                                await send(.purchaseFailed(""))
                            default:
                                await send(.purchaseFailed(error.localizedDescription))
                            }
                        } catch {
                            logger.error("Purchase error: \(error.localizedDescription)")
                            await send(.purchaseFailed(error.localizedDescription))
                        }
                    }
                } else {
                    logger.info("No products — using simulated purchase path")
                    #if DEBUG
                    // Simulated purchase when StoreKit Testing is not available (CLI install)
                    return .run { send in
                        try await Task.sleep(for: .seconds(1))
                        await send(.simulatedPurchaseCompleted)
                    }
                    #else
                    return .send(.purchaseFailed("Product not available"))
                    #endif
                }

            case .simulatedPurchaseCompleted:
                let expiresDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                state.subscriptionStatus = .pro(expiresDate: expiresDate, isInGracePeriod: false)
                state.isPurchasing = false
                state.showPaywall = false
                return .none

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
