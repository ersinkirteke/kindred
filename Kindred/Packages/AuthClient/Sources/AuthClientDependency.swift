import Dependencies
import Foundation

// MARK: - AuthClient Dependency

extension DependencyValues {
    /// Dependency key for accessing the ClerkAuthClient instance
    @MainActor
    public var authClient: ClerkAuthClient {
        get { self[AuthClientKey.self] }
        set { self[AuthClientKey.self] = newValue }
    }
}

private enum AuthClientKey: DependencyKey {
    @MainActor static let liveValue = ClerkAuthClient()

    @MainActor static let testValue = ClerkAuthClient()
}
