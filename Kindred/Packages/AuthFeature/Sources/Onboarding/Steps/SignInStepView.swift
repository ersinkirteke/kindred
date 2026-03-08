import SwiftUI
import ComposableArchitecture
import DesignSystem

struct SignInStepView: View {
    let store: StoreOf<OnboardingReducer>
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    stepContent
                }
                .overlay(alignment: .bottom) {
                    // Gradient fade indicator for scroll-for-more
                    LinearGradient(
                        colors: [Color.kindredBackground.opacity(0), Color.kindredBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                }
            } else {
                stepContent
            }
        }
        .background(Color.kindredBackground)
        .accessibilityHint(String(localized: "accessibility.onboarding_signin.hint", bundle: .main))
    }

    private var stepContent: some View {
        VStack(spacing: 0) {
            // Skip button at top-right
            HStack {
                Spacer()
                Button {
                    store.send(.skipStep)
                } label: {
                    Text(String(localized: "Skip", bundle: .main))
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.top, KindredSpacing.md)
                .accessibilityLabel(String(localized: "accessibility.onboarding_signin.skip", bundle: .main))
            }

            Spacer(minLength: 80)

            // App logo
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.kindredAccent)
                .padding(.bottom, KindredSpacing.lg)

            // Welcome heading
            Text(String(localized: "onboarding.signin.welcome_heading", bundle: .main))
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.sm)

            // Tagline
            Text(String(localized: "onboarding.signin.tagline", bundle: .main))
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KindredSpacing.xl)

            Spacer()

            // Sign-in buttons
            VStack(spacing: KindredSpacing.md) {
                // Apple Sign In button (custom styled — Clerk SDK handles its own ASAuthorization flow)
                Button {
                    store.send(.appleSignInTapped)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                        Text(String(localized: "onboarding.signin.sign_in_apple", bundle: .main))
                            .font(.kindredBodyBold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .accessibilityLabel(String(localized: "accessibility.onboarding_signin.apple_button", bundle: .main))

                // Google Sign In button
                KindredButton(String(localized: "onboarding.signin.sign_in_google", bundle: .main), style: .secondary) {
                    store.send(.googleSignInTapped)
                }
                .accessibilityLabel(String(localized: "accessibility.onboarding_signin.google_button", bundle: .main))

                // Error text
                if let error = store.signInError, !error.isEmpty {
                    Text(error)
                        .font(.kindredBody())
                        .foregroundColor(.kindredError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KindredSpacing.lg)
                        .accessibilityAddTraits(.isStaticText)
                        .onAppear {
                            // VoiceOver announcement for errors
                            UIAccessibility.post(notification: .announcement, argument: error)
                        }
                }

                // Continue as guest link
                Button {
                    store.send(.continueAsGuestTapped)
                } label: {
                    Text(String(localized: "onboarding.signin.continue_guest", bundle: .main))
                        .font(.kindredCaption())
                        .foregroundColor(.kindredTextSecondary)
                        .underline()
                }
                .padding(.top, KindredSpacing.sm)
                .accessibilityLabel(String(localized: "accessibility.onboarding_signin.continue_guest_button", bundle: .main))
            }
            .padding(.horizontal, KindredSpacing.lg)

            Spacer(minLength: 40)
        }
    }
}
