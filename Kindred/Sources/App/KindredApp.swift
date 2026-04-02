import ComposableArchitecture
import FeedFeature
import SwiftData
import SwiftUI

@main
struct KindredApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App state
    @State private var showSplash = true

    let store = Store(initialState: AppReducer.State()) {
        AppReducer()
    }

    let guestContainer: ModelContainer = {
        let config = ModelConfiguration("GuestStore", schema: Schema([GuestBookmark.self, GuestSkip.self]))
        return try! ModelContainer(for: GuestBookmark.self, GuestSkip.self, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                } else {
                    RootView(store: store)
                }
            }
        }
        .modelContainer(guestContainer)
    }
}
