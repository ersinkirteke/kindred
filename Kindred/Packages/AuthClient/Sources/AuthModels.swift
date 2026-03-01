import Foundation

/// User model from Clerk authentication
public struct ClerkUser: Equatable, Sendable {
    public let id: String
    public let email: String
    public let displayName: String

    public init(id: String, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}

/// Authentication state for the app
public enum AuthState: Equatable, Sendable {
    case guest
    case authenticated(ClerkUser)
    case loading
}
