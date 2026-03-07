import SwiftUI
import ComposableArchitecture
import DesignSystem

/// Full-screen sign-in gate with Apple and Google OAuth
public struct SignInGateView: View {
    let store: StoreOf<SignInGateReducer>

    public init(store: StoreOf<SignInGateReducer>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color.kindredBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // App Logo/Icon
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.kindredAccent)
                        .padding(.bottom, 24)

                    // Tagline
                    Text("Save recipes, hear them narrated,\nmake them yours")
                        .font(.kindredHeading2())
                        .foregroundColor(.kindredTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KindredSpacing.lg)

                    Spacer()

                    // Sign-in buttons section
                    VStack(spacing: 16) {
                        // Apple Sign In Button (custom styled — Clerk SDK handles its own ASAuthorization flow)
                        Button {
                            viewStore.send(.appleSignInTapped)
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

                        // Google Sign In Button
                        KindredButton(
                            "Continue with Google",
                            style: .secondary
                        ) {
                            viewStore.send(.googleSignInTapped)
                        }
                        .accessibilityLabel("Sign in with Google")

                        // Error text
                        if let error = viewStore.signInError, !error.isEmpty {
                            Text(error)
                                .font(.kindredBody())
                                .foregroundColor(.kindredError)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, KindredSpacing.md)
                                .padding(.top, 8)
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(.isStaticText)
                                .onAppear {
                                    // Announce error for VoiceOver users
                                    UIAccessibility.post(notification: .announcement, argument: error)
                                }
                        }
                    }
                    .padding(.horizontal, KindredSpacing.lg)

                    Spacer()
                        .frame(height: 24)

                    // Continue as guest button
                    Button {
                        viewStore.send(.continueAsGuestTapped)
                    } label: {
                        Text("Continue as guest")
                            .font(.kindredCaption())
                            .foregroundColor(.kindredTextSecondary)
                            .underline()
                    }
                    .disabled(viewStore.isSigningIn)
                    .accessibilityLabel("Continue browsing as guest")

                    Spacer()
                        .frame(height: 40)
                }
            }
            // Allow swipe-down dismissal
            .interactiveDismissDisabled(false)
        }
    }
}

#if DEBUG
struct SignInGateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            SignInGateView(
                store: Store(
                    initialState: SignInGateReducer.State()
                ) {
                    SignInGateReducer()
                }
            )
            .previewDisplayName("Default")

            // Loading state
            SignInGateView(
                store: Store(
                    initialState: SignInGateReducer.State(
                        isSigningIn: true
                    )
                ) {
                    SignInGateReducer()
                }
            )
            .previewDisplayName("Loading")

            // Error state
            SignInGateView(
                store: Store(
                    initialState: SignInGateReducer.State(
                        signInError: "Connection failed. Please try again."
                    )
                ) {
                    SignInGateReducer()
                }
            )
            .previewDisplayName("Error")
        }
    }
}
#endif
