import ComposableArchitecture
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

        public init() {}
    }

    public enum Action {
        case onAppear
        case signInTapped
        case continueAsGuestTapped
        case loadDietaryPreferences
        case dietaryPreferencesChanged(Set<String>)
        case resetDietaryPreferences
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load dietary preferences on appear
                return .send(.loadDietaryPreferences)

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
