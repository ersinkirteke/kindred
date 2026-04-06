import Apollo
import Dependencies
import Foundation

// MARK: - ApolloClient Dependency

extension DependencyValues {
    /// Dependency key for accessing the configured ApolloClient instance
    /// The client is configured with SQLite cache and JWT authentication
    public var apolloClient: ApolloClient {
        get { self[ApolloClientKey.self] }
        set { self[ApolloClientKey.self] = newValue }
    }
}

private enum ApolloClientKey: DependencyKey {
    static let liveValue: ApolloClient = {
        // In production, token provider should be injected from AuthClient
        // For now, create a basic client without auth
        ApolloClientFactory.create { nil }
    }()

    static let testValue: ApolloClient = {
        // Test client with in-memory cache
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: DefaultInterceptorProvider.shared,
            store: store,
            endpointURL: APIEnvironment.graphQLURL
        )
        return ApolloClient(networkTransport: transport, store: store)
    }()
}
