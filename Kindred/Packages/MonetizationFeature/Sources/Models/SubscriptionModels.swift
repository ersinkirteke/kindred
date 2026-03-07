import Foundation
import StoreKit

// MARK: - Subscription Tier

public enum SubscriptionTier: Equatable, Sendable {
    case free
    case pro
}

// MARK: - Subscription Status

public enum SubscriptionStatus: Equatable, Sendable {
    case unknown
    case free
    case pro(expiresDate: Date, isInGracePeriod: Bool)
}

// MARK: - Subscription Error

public enum SubscriptionError: LocalizedError, Equatable, Sendable {
    case productNotFound
    case purchaseFailed
    case purchaseCancelled
    case verificationFailed
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .verificationFailed:
            return "Could not verify purchase"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Product ID

public struct SubscriptionProduct {
    public static let proMonthlyID = "com.kindred.pro.monthly"
}
