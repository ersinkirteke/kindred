import ComposableArchitecture
import FeedFeature
import Foundation

public enum AuthState: Equatable {
    case guest
    case authenticated(userId: String)
}

@Reducer
public struct ProfileReducer {
    @ObservableState
    public struct State: Equatable {
        public var authState: AuthState = .guest
        public var dietaryPreferences: Set<String> = []

        // Culinary DNA
        public var culinaryDNAAffinities: [AffinityScore] = []
        public var interactionCount: Int = 0
        public var isDNAActivated: Bool = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case signInTapped
        case continueAsGuestTapped
        case loadDietaryPreferences
        case dietaryPreferencesChanged(Set<String>)
        case resetDietaryPreferences
        case loadCulinaryDNA
        case culinaryDNALoaded([AffinityScore], Int, Bool)
    }

    @Dependency(\.guestSessionClient) var guestSession
    @Dependency(\.personalizationClient) var personalization

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load dietary preferences and culinary DNA on appear
                return .merge(
                    .send(.loadDietaryPreferences),
                    .send(.loadCulinaryDNA)
                )

            case .loadDietaryPreferences:
                // Load from UserDefaults
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let preferences = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    state.dietaryPreferences = preferences
                }
                return .none

            case let .dietaryPreferencesChanged(preferences):
                state.dietaryPreferences = preferences
                // Save to UserDefaults
                if let encoded = try? JSONEncoder().encode(preferences) {
                    UserDefaults.standard.set(encoded, forKey: "dietaryPreferences")
                }
                return .none

            case .resetDietaryPreferences:
                state.dietaryPreferences = []
                UserDefaults.standard.removeObject(forKey: "dietaryPreferences")
                return .none

            case .loadCulinaryDNA:
                return .run { send in
                    let bookmarks = await guestSession.allBookmarks()
                    let skips = await guestSession.allSkips()
                    let affinities = await personalization.computeAffinities(bookmarks, skips)
                    let count = await personalization.interactionCount(bookmarks, skips)
                    let activated = await personalization.isActivated(bookmarks, skips)
                    await send(.culinaryDNALoaded(affinities, count, activated))
                }

            case let .culinaryDNALoaded(affinities, count, activated):
                state.culinaryDNAAffinities = affinities
                state.interactionCount = count
                state.isDNAActivated = activated
                return .none

            case .signInTapped:
                // Placeholder - auth flow in Phase 8
                return .none

            case .continueAsGuestTapped:
                // Placeholder - guest flow in Phase 8
                return .none
            }
        }
    }
}
