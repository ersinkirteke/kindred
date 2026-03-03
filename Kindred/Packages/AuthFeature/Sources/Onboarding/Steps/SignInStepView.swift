import SwiftUI
import ComposableArchitecture
import AuthenticationServices
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
                // Apple Sign In button
                ZStack {
                    SignInWithAppleButton(.signIn) { _ in
                        store.send(.appleSignInTapped)
                    } onCompletion: { _ in
                        // Handled via SignInClient
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(12)
                    .accessibilityLabel("Sign in with Apple")

                    // Loading overlay for Apple button
                    if store.isSigningIn {
                        ProgressView()
                            .tint(.white)
                            .allowsHitTesting(false)
                    }
                }

                // Google Sign In button
                KindredButton("Sign in with Google", style: .secondary, isLoading: store.isSigningIn) {
                    store.send(.googleSignInTapped)
                }
                .accessibilityLabel("Sign in with Google")

                // Error text
                if let error = store.signInError, !error.isEmpty {
                    Text(error)
                        .font(.kindredCaption())
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
            .disabled(store.isSigningIn)

            Spacer(minLength: 40)
        }
        .background(Color.kindredBackground)
    }
}
