import Apollo
import ApolloAPI
import ApolloSQLite
import Foundation

/// Factory for creating configured ApolloClient instances with SQLite cache and authentication
public final class ApolloClientFactory {
    /// Create an ApolloClient configured with:
    /// - SQLite offline cache
    /// - Authentication interceptor for JWT injection
    /// - Retry and error handling interceptors
    ///
    /// - Parameter tokenProvider: Async closure that returns JWT token (nil if guest)
    /// - Returns: Configured ApolloClient instance
    public static func create(tokenProvider: @escaping () async -> String?) -> ApolloClient {
        // 1. SQLite cache for offline-first data persistence
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sqliteFileURL = documentsURL.appendingPathComponent("kindred_apollo_cache.sqlite")

        let sqliteCache = try! SQLiteNormalizedCache(fileURL: sqliteFileURL)
        let store = ApolloStore(cache: sqliteCache)

        // 2. Custom interceptor provider with auth interceptor
        let interceptorProvider = CustomInterceptorProvider(
            store: store,
            tokenProvider: tokenProvider
        )

        // 3. Network transport with GraphQL endpoint
        // TODO: Make URL configurable per environment (dev/staging/prod)
        let url = URL(string: "https://api.kindred.app/graphql")!
        let transport = RequestChainNetworkTransport(
            interceptorProvider: interceptorProvider,
            endpointURL: url
        )

        return ApolloClient(networkTransport: transport, store: store)
    }
}

/// Custom interceptor provider that injects AuthInterceptor into the request chain
private class CustomInterceptorProvider: DefaultInterceptorProvider {
    private let tokenProvider: () async -> String?

    init(store: ApolloStore, tokenProvider: @escaping () async -> String?) {
        self.tokenProvider = tokenProvider
        super.init(store: store)
    }

    override func interceptors<Operation>(
        for operation: Operation
    ) -> [any ApolloInterceptor] where Operation: GraphQLOperation {
        var interceptors = super.interceptors(for: operation)

        // Insert auth interceptor before network fetch
        // Order: Cache read -> Auth -> Network -> Parse -> Cache write
        if let networkFetchIndex = interceptors.firstIndex(where: { $0 is NetworkFetchInterceptor }) {
            interceptors.insert(AuthInterceptor(tokenProvider: tokenProvider), at: networkFetchIndex)
        }

        return interceptors
    }
}
