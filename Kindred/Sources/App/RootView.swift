import ComposableArchitecture
import DesignSystem
import FeedFeature
import ProfileFeature
import SwiftUI

struct RootView: View {
    @Bindable var store: StoreOf<AppReducer>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            FeedView(
                store: store.scope(
                    state: \.feedState,
                    action: \.feed
                )
            )
            .tabItem {
                Label("Feed", systemImage: "house.fill")
            }
            .tag(AppReducer.Tab.feed)

            ProfileView(
                store: store.scope(
                    state: \.profileState,
                    action: \.profile
                )
            )
            .tabItem {
                Label("Me", systemImage: "person.fill")
            }
            .tag(AppReducer.Tab.me)
        }
        .tint(.kindredAccent)
        .toolbarBackground(.kindredCardSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
