import ComposableArchitecture
import FeedFeature
import SwiftData
import SwiftUI

@main
struct KindredApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App state
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // TODO: Replace WelcomeCardView with OnboardingView when Plan 08-02 is complete

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
                    // TODO: Replace with OnboardingView when Plan 08-02 is complete
                    if !hasCompletedOnboarding {
                        WelcomeCardView {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
        }
        .modelContainer(for: [GuestBookmark.self, GuestSkip.self])
    }
}
