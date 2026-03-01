import ComposableArchitecture
import SwiftUI

public struct FeedView: View {
    let store: StoreOf<FeedReducer>

    public init(store: StoreOf<FeedReducer>) {
        self.store = store
    }

    public var body: some View {
        Text("Feed")
            .font(.largeTitle)
            .onAppear {
                store.send(.onAppear)
            }
    }
}
