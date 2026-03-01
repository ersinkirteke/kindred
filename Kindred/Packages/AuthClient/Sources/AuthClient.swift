import Foundation
import ClerkKit

/// Clerk SDK wrapper for authentication
public final class ClerkAuthClient {
    public init() {}

    /// Get current JWT token (nil if not authenticated)
    public func getToken() async -> String? {
        try? await Clerk.shared.session?.getToken()?.jwt
    }

    /// Check if user is authenticated
    public var isAuthenticated: Bool {
        Clerk.shared.session != nil
    }

    /// Current user info (nil if guest)
    public var currentUser: ClerkUser? {
        guard let user = Clerk.shared.user else { return nil }
        return ClerkUser(
            id: user.id,
            email: user.emailAddresses.first?.emailAddress ?? "",
            displayName: user.firstName ?? user.username ?? ""
        )
    }
}
