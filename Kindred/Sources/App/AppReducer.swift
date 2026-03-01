import ComposableArchitecture
import FeedFeature
import Foundation
import ProfileFeature

@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        var feedState = FeedReducer.State()
        var profileState = ProfileReducer.State()
        var selectedTab: Tab = .feed
    }

    enum Tab: Int, Equatable {
        case feed = 0
        case me = 1
    }

    enum Action {
        case feed(FeedReducer.Action)
        case profile(ProfileReducer.Action)
        case tabSelected(Tab)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.feedState, action: \.feed) {
            FeedReducer()
        }
        Scope(state: \.profileState, action: \.profile) {
            ProfileReducer()
        }
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
            case .feed, .profile:
                return .none
            }
        }
    }
}
