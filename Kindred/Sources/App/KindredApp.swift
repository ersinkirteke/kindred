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
                                    // Push onboarding preferences into feed BEFORE dismissing
                                    let dietaryPrefs = onboardingStore.selectedDietaryPrefs
                                    if !dietaryPrefs.isEmpty {
                                        store.send(.feed(.dietaryFilterChanged(dietaryPrefs)))
                                    }
                                    if let city = onboardingStore.selectedCity {
                                        // changeLocation triggers re-fetch with new location
                                        store.send(.feed(.changeLocation(city)))
                                    } else {
                                        // No city selected — refresh with defaults + new filters
                                        store.send(.feed(.refreshFeed))
                                    }

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
