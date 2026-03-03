import ComposableArchitecture
import FeedFeature
import Foundation
import ProfileFeature
import VoicePlaybackFeature

@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        var feedState = FeedReducer.State()
        var profileState = ProfileReducer.State()
        var voicePlaybackState = VoicePlaybackReducer.State()
        var selectedTab: Tab = .feed
    }

    enum Tab: Int, Equatable {
        case feed = 0
        case me = 1
    }

    enum Action {
        case feed(FeedReducer.Action)
        case profile(ProfileReducer.Action)
        case voicePlayback(VoicePlaybackReducer.Action)
        case tabSelected(Tab)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.feedState, action: \.feed) {
            FeedReducer()
        }
        Scope(state: \.profileState, action: \.profile) {
            ProfileReducer()
        }
        Scope(state: \.voicePlaybackState, action: \.voicePlayback) {
            VoicePlaybackReducer()
        }
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case let .feed(.recipeDetail(.presented(recipeDetailAction))):
                // Forward listenTapped to voice playback
                if case .listenTapped = recipeDetailAction,
                   let recipe = state.feedState.recipeDetail?.recipe {
                    return .send(.voicePlayback(.startPlayback(
                        recipeId: recipe.id,
                        recipeName: recipe.name,
                        artworkURL: recipe.imageUrl,
                        steps: recipe.steps.map(\.text)
                    )))
                }
                return .none

            case .feed, .profile, .voicePlayback:
                return .none
            }
        }
    }
}
