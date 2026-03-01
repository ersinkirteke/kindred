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

        public init() {}
    }

    public enum Action {
        case onAppear
        case signInTapped
        case continueAsGuestTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Placeholder - auth check in Phase 8
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
