import Foundation

/// Single source of truth for the backend API base URL.
/// Value is injected at build time via `API_BASE_URL` in xcconfig → `KindredAPIBaseURL` in Info.plist.
public enum APIEnvironment {
    /// Base URL (e.g. `http://192.168.0.162:3000` in Debug, `https://api.kindredcook.app` in Release).
    public static let baseURL: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "KindredAPIBaseURL") as? String,
              !value.isEmpty else {
            assertionFailure("KindredAPIBaseURL missing from Info.plist — check Debug.xcconfig/Release.xcconfig")
            return "https://api.kindredcook.app"
        }
        return value
    }()

    /// GraphQL endpoint URL (`{baseURL}/v1/graphql`).
    public static var graphQLURL: URL {
        URL(string: "\(baseURL)/v1/graphql")!
    }
}
