import ComposableArchitecture
import DesignSystem
import FeedFeature
import MonetizationFeature
import SwiftUI

public struct ProfileView: View {
    let store: StoreOf<ProfileReducer>

    public init(store: StoreOf<ProfileReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: KindredSpacing.lg) {
                switch store.authState {
                case .guest:
                    guestSignInGate
                case .authenticated(let userId):
                    authenticatedHeader(userId: userId)
                }

                // Subscription status section (available for both guest and authenticated)
                SubscriptionStatusView(
                    subscriptionStatus: store.subscriptionStatus,
                    displayPrice: store.displayPrice,
                    onSubscribe: { store.send(.subscribeTapped) },
                    onManage: { store.send(.manageSubscriptionTapped) }
                )
                .padding(.horizontal, KindredSpacing.md)

                // Dietary Preferences section (available for both guest and authenticated)
                DietaryPreferencesSection(
                    activePreferences: store.dietaryPreferences,
                    onPreferencesChanged: { preferences in
                        store.send(.dietaryPreferencesChanged(preferences))
                    },
                    onReset: {
                        store.send(.resetDietaryPreferences)
                    }
                )
                .padding(.horizontal, KindredSpacing.md)

                // Culinary DNA section (available for both guest and authenticated)
                CulinaryDNASection(
                    interactionCount: store.interactionCount,
                    affinities: store.culinaryDNAAffinities
                )
                .padding(.horizontal, KindredSpacing.md)
            }
            .padding(.vertical, KindredSpacing.lg)
        }
        .background(Color.kindredBackground)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func authenticatedHeader(userId: String) -> some View {
        HStack(spacing: KindredSpacing.sm) {
            Text("Profile")
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)

            // PRO badge (only shown if user has Pro subscription)
            if case .pro = store.subscriptionStatus {
                Text("PRO")
                    .font(.kindredCaption())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, KindredSpacing.sm)
                    .padding(.vertical, KindredSpacing.xs)
                    .background(Color.kindredAccent)
                    .clipShape(Capsule())
                    .accessibilityLabel("Pro subscriber")
            }

            Spacer()
        }
        .padding(.horizontal, KindredSpacing.md)
    }

    private var guestSignInGate: some View {
        VStack(spacing: KindredSpacing.md) {
            // Icon
            Image(systemName: "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.kindredAccentDecorative)

            // Message
            VStack(spacing: KindredSpacing.sm) {
                Text("Sign in to access your profile")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Save recipes, customize voice settings, and more")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Sign In button
            VStack(spacing: KindredSpacing.md) {
                KindredButton("Sign In", style: .primary) {
                    store.send(.signInTapped)
                }

                Button {
                    store.send(.continueAsGuestTapped)
                } label: {
                    Text("Continue as Guest")
                        .font(.kindredBody())
                        .foregroundColor(.kindredAccent)
                }
            }
            .padding(.horizontal, KindredSpacing.xl)
        }
        .padding(.horizontal, KindredSpacing.lg)
    }
}
