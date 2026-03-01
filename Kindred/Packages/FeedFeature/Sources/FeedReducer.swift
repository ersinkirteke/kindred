import ComposableArchitecture
import Foundation

@Reducer
public struct FeedReducer {
    @ObservableState
    public struct State: Equatable {
        // Placeholder — populated in Phase 5
        public var isLoading = false

        public init() {}
    }

    public enum Action {
        case onAppear
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
