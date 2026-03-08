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
                    Text(String(localized: "signin_gate.tagline", bundle: .main))
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
                                Text(String(localized: "signin_gate.sign_in_apple", bundle: .main))
                                    .font(.kindredBodyBold())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundColor(.white)
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel(String(localized: "accessibility.signin_gate.apple_button", bundle: .main))

                        // Google Sign In Button
                        KindredButton(
                            String(localized: "signin_gate.sign_in_google", bundle: .main),
                            style: .secondary
                        ) {
                            viewStore.send(.googleSignInTapped)
                        }
                        .accessibilityLabel(String(localized: "accessibility.signin_gate.google_button", bundle: .main))

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
                        Text(String(localized: "signin_gate.continue_guest", bundle: .main))
                            .font(.kindredCaption())
                            .foregroundColor(.kindredTextSecondary)
                            .underline()
                    }
                    .disabled(viewStore.isSigningIn)
                    .accessibilityLabel(String(localized: "accessibility.signin_gate.continue_guest", bundle: .main))

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
