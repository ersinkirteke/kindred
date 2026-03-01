import ComposableArchitecture
import SwiftUI

public struct ProfileView: View {
    let store: StoreOf<ProfileReducer>

    public init(store: StoreOf<ProfileReducer>) {
        self.store = store
    }

    public var body: some View {
        Text("Me")
            .font(.largeTitle)
            .onAppear {
                store.send(.onAppear)
            }
    }
}
