import ComposableArchitecture
import SwiftUI

@main
struct KindredApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App state
    @State private var showSplash = true
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    let store = Store(initialState: AppReducer.State()) {
        AppReducer()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                } else {
                    RootView(store: store)

                    // Welcome card overlay (first launch only)
                    if !hasSeenWelcome {
                        WelcomeCardView {
                            hasSeenWelcome = true
                        }
                    }
                }
            }
        }
    }
}
