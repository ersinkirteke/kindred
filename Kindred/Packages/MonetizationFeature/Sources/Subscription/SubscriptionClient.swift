import Foundation
import StoreKit
import Dependencies
import ClerkKit

public struct SubscriptionClient: Sendable {
    /// Loads available subscription products from the App Store
    public var loadProducts: @Sendable () async throws -> [Product] = { [] }

    /// Purchases a subscription product
    public var purchase: @Sendable (Product) async throws -> StoreKit.Transaction = { _ in
        struct UnimplementedError: Error {}
        throw UnimplementedError()
    }

    /// Restores previous purchases
    public var restorePurchases: @Sendable () async throws -> Void = {
        struct UnimplementedError: Error {}
        throw UnimplementedError()
    }

    /// Checks current subscription entitlement status
    public var currentEntitlement: @Sendable () async -> SubscriptionStatus = { .unknown }

    /// Observes transaction updates
    public var observeTransactionUpdates: @Sendable () async -> AsyncStream<StoreKit.Transaction> = {
        AsyncStream { _ in }
    }

    /// Gets JWS representation of a transaction for backend verification
    public var jwsRepresentation: @Sendable (StoreKit.Transaction) async -> String? = { _ in nil }

    /// Syncs subscription to backend for verification
    public var syncSubscriptionToBackend: @Sendable (String) async throws -> Bool = { _ in false }
}

// MARK: - Dependency Key

extension SubscriptionClient: DependencyKey {
    public static let liveValue: SubscriptionClient = {
        let client = SubscriptionClient(
            loadProducts: {
                let products = try await Product.products(for: [SubscriptionProduct.proMonthlyID])
                return products
            },
            purchase: { product in
                let result = try await product.purchase()

                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        // Successfully verified transaction
                        await transaction.finish()
                        return transaction
                    case .unverified(let transaction, let error):
                        // Transaction failed verification
                        await transaction.finish()
                        throw SubscriptionError.verificationFailed
                    }
                case .userCancelled:
                    throw SubscriptionError.purchaseCancelled
                case .pending:
                    throw SubscriptionError.purchaseFailed
                @unknown default:
                    throw SubscriptionError.purchaseFailed
                }
            },
            restorePurchases: {
                try await AppStore.sync()
            },
            currentEntitlement: {
                // Check for current entitlements
                for await result in Transaction.currentEntitlements {
                    switch result {
                    case .verified(let transaction):
                        // Found a verified transaction for the Pro subscription
                        if transaction.productID == SubscriptionProduct.proMonthlyID {
                            // Check if subscription is active or in grace period
                            if let expirationDate = transaction.expirationDate {
                                // Check subscription status for grace period
                                if let product = try? await Product.products(for: [transaction.productID]).first,
                                   let subscription = product.subscription,
                                   let status = try? await subscription.status.first {

                                    let isInGracePeriod = status.state == .inGracePeriod
                                    return .pro(expiresDate: expirationDate, isInGracePeriod: isInGracePeriod)
                                } else {
                                    // No status available, check if expired
                                    let isExpired = expirationDate < Date()
                                    return isExpired ? .free : .pro(expiresDate: expirationDate, isInGracePeriod: false)
                                }
                            }
                        }
                    case .unverified:
                        // Skip unverified transactions
                        continue
                    }
                }

                // No valid Pro subscription found
                return .free
            },
            observeTransactionUpdates: {
                AsyncStream { continuation in
                    let task = Task {
                        for await result in Transaction.updates {
                            switch result {
                            case .verified(let transaction):
                                continuation.yield(transaction)
                                await transaction.finish()
                            case .unverified:
                                // Skip unverified transactions
                                continue
                            }
                        }
                    }

                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            },
            jwsRepresentation: { transaction in
                // jsonRepresentation returns Data, convert to base64 String
                return transaction.jsonRepresentation.base64EncodedString()
            },
            syncSubscriptionToBackend: { jws in
                // Backend URL matches Apollo client configuration
                let baseURL = (Bundle.main.object(forInfoDictionaryKey: "KindredAPIBaseURL") as? String) ?? "https://api.kindredcook.app"
                let urlString = "\(baseURL)/v1/graphql"
                guard let url = URL(string: urlString) else {
                    throw SubscriptionError.networkError("Invalid backend URL")
                }

                // Build GraphQL mutation with variables to prevent injection
                let mutation = "mutation VerifySubscription($jws: String!) { verifySubscription(jwsRepresentation: $jws) }"
                let variables: [String: Any] = ["jws": jws]

                let body: [String: Any] = ["query": mutation, "variables": variables]

                guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
                    throw SubscriptionError.networkError("Failed to serialize request")
                }

                // Create request with auth header
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = bodyData

                // Add Authorization header from Clerk session
                if let session = await Clerk.shared.session,
                   let token = try? await session.getToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                // Send request
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw SubscriptionError.networkError("HTTP error")
                }

                // Parse response
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataDict = json["data"] as? [String: Any],
                      let result = dataDict["verifySubscription"] as? Bool else {
                    throw SubscriptionError.networkError("Failed to parse response")
                }

                return result
            }
        )
        return client
    }()
}

// MARK: - Dependency Values

extension DependencyValues {
    public var subscriptionClient: SubscriptionClient {
        get { self[SubscriptionClient.self] }
        set { self[SubscriptionClient.self] = newValue }
    }
}
