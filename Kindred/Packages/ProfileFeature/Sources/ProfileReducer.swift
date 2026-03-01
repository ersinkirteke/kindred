import ComposableArchitecture
import Foundation

@Reducer
public struct ProfileReducer {
    @ObservableState
    public struct State: Equatable {
        // Placeholder — populated in Phase 6-8
        // Guest state placeholder (no auth logic yet — comes in Plan 03)
        public var isGuest = true

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
