import ComposableArchitecture
import AuthFeature
import FeedFeature
import SwiftData
import SwiftUI

@main
struct KindredApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App state
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let store = Store(initialState: AppReducer.State()) {
        AppReducer()
    }

    let onboardingStore = Store(initialState: OnboardingReducer.State()) {
        OnboardingReducer()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                } else {
                    RootView(store: store)

                    if !hasCompletedOnboarding {
                        OnboardingView(store: onboardingStore)
                            .transition(.opacity)
                            .onChange(of: onboardingStore.currentStep) { _, newStep in
                                if newStep >= onboardingStore.totalSteps {
                                    withAnimation {
                                        hasCompletedOnboarding = true
                                    }
                                }
                            }
                    }
                }
            }
        }
        .modelContainer(for: [GuestBookmark.self, GuestSkip.self])
    }
}
