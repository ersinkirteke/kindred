import ComposableArchitecture
import Foundation

@Reducer
public struct FeedReducer {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = true
        public var location: String = "Istanbul" // Default per locked decision when location denied

        public init() {}
    }

    public enum Action {
        case onAppear
        case locationChanged(String)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Placeholder - actual data loading in Phase 5
                return .none

            case .locationChanged(let newLocation):
                state.location = newLocation
                return .none
            }
        }
    }
}
