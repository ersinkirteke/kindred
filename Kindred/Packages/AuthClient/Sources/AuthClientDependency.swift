import Dependencies
import Foundation

// MARK: - AuthClient Dependency

extension DependencyValues {
    /// Dependency key for accessing the ClerkAuthClient instance
    public var authClient: ClerkAuthClient {
        get { self[AuthClientKey.self] }
        set { self[AuthClientKey.self] = newValue }
    }
}

private enum AuthClientKey: DependencyKey {
    static let liveValue = ClerkAuthClient()

    static let testValue: ClerkAuthClient = {
        // Test auth client with mock behavior
        ClerkAuthClient()
    }()
}
