import ComposableArchitecture
import DesignSystem
import FeedFeature
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
                case .authenticated:
                    // Placeholder - authenticated profile in Phase 8
                    Text("Profile")
                        .font(.kindredHeading1())
                        .foregroundColor(.kindredTextPrimary)
                }

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
