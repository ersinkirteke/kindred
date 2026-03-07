import SwiftUI
import ComposableArchitecture
import DesignSystem

struct SignInStepView: View {
    let store: StoreOf<OnboardingReducer>

    var body: some View {
        VStack(spacing: 0) {
            // Skip button at top-right
            HStack {
                Spacer()
                Button {
                    store.send(.skipStep)
                } label: {
                    Text("Skip")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.top, KindredSpacing.md)
                .accessibilityLabel("Skip sign-in")
            }

            Spacer(minLength: 80)

            // App logo
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.kindredAccent)
                .padding(.bottom, KindredSpacing.lg)

            // Welcome heading
            Text("Welcome to Kindred")
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.sm)

            // Tagline
            Text("Save recipes, hear them narrated, make them yours")
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
                        Text("Sign in with Apple")
                            .font(.kindredBodyBold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Sign in with Apple")

                // Google Sign In button
                KindredButton("Sign in with Google", style: .secondary) {
                    store.send(.googleSignInTapped)
                }
                .accessibilityLabel("Sign in with Google")

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
                    Text("Continue as guest")
                        .font(.kindredCaption())
                        .foregroundColor(.kindredTextSecondary)
                        .underline()
                }
                .padding(.top, KindredSpacing.sm)
                .accessibilityLabel("Continue browsing as guest")
            }
            .padding(.horizontal, KindredSpacing.lg)

            Spacer(minLength: 40)
        }
        .background(Color.kindredBackground)
    }
}
