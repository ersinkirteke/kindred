import ComposableArchitecture
import DesignSystem
import FeedFeature
import MonetizationFeature
import SwiftUI

public struct ProfileView: View {
    let store: StoreOf<ProfileReducer>

    // @ScaledMetric for Dynamic Type support
    @ScaledMetric(relativeTo: .largeTitle) private var heading1Size: CGFloat = 34
    @ScaledMetric(relativeTo: .title2) private var heading2Size: CGFloat = 22
    @ScaledMetric(relativeTo: .headline) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14

    #if DEBUG
    @State private var showDebugMenu = false
    #endif

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

                // Privacy & Data section (only when authenticated)
                if case .authenticated = store.authState {
                    PrivacyDataSection(
                        voiceProfile: store.voiceProfile,
                        isDeleting: store.isDeletingVoice,
                        onDelete: { store.send(.deleteVoiceTapped) },
                        onPrivacyPolicyTapped: { store.send(.privacyPolicyTapped) },
                        onTrackingSettingsTapped: { store.send(.trackingSettingsTapped) }
                    )
                    .padding(.horizontal, KindredSpacing.md)
                }

                // App version label at bottom
                versionLabel
                    .padding(.top, KindredSpacing.xl)
            }
            .padding(.vertical, KindredSpacing.lg)
        }
        .background(Color.kindredBackground)
        .onAppear {
            store.send(.onAppear)
        }
        .confirmationDialog(
            String(localized: "profile.privacy_data.delete_confirmation_title", bundle: .main),
            isPresented: Binding(
                get: { store.showDeleteConfirmation },
                set: { _ in store.send(.cancelDeleteVoice) }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "profile.privacy_data.delete_confirmation_action", bundle: .main), role: .destructive) {
                store.send(.confirmDeleteVoice)
            }
            Button(String(localized: "profile.privacy_data.delete_confirmation_cancel", bundle: .main), role: .cancel) {
                store.send(.cancelDeleteVoice)
            }
        } message: {
            Text(String(localized: "profile.privacy_data.delete_confirmation_message", bundle: .main))
        }
        .sheet(isPresented: Binding(
            get: { store.showPrivacyPolicy },
            set: { _ in store.send(.dismissPrivacyPolicy) }
        )) {
            SafariView(url: URL(string: "https://api.kindred.app/privacy")!)
        }
        #if DEBUG
        .sheet(isPresented: $showDebugMenu) {
            ConsentDebugMenu()
                .presentationDetents([.medium])
        }
        #endif
        .overlay(alignment: .top) {
            if store.showDeleteSuccessToast {
                Text(String(localized: "profile.privacy_data.voice_deleted_success", bundle: .main))
                    .font(.kindredBodyScaled(size: bodySize))
                    .foregroundStyle(.white)
                    .padding(.horizontal, KindredSpacing.lg)
                    .padding(.vertical, KindredSpacing.sm)
                    .background(Color.kindredAccent)
                    .clipShape(.rect(cornerRadius: 8))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Auto-dismiss after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.send(.dismissDeleteSuccessToast)
                        }
                    }
                    .padding(.top, KindredSpacing.md)
            }
        }
        .animation(.easeInOut, value: store.showDeleteSuccessToast)
    }

    private func authenticatedHeader(userId: String) -> some View {
        HStack(spacing: KindredSpacing.sm) {
            Text(String(localized: "profile.title", bundle: .main))
                .font(.kindredHeading1Scaled(size: heading1Size))
                .foregroundStyle(.kindredTextPrimary)

            // PRO badge (only shown if user has Pro subscription)
            if case .pro = store.subscriptionStatus {
                Text(String(localized: "profile.pro_badge", bundle: .main))
                    .font(.kindredCaptionScaled(size: captionSize))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, KindredSpacing.sm)
                    .padding(.vertical, KindredSpacing.xs)
                    .background(Color.kindredAccent)
                    .clipShape(Capsule())
                    .accessibilityLabel(String(localized: "accessibility.profile.pro_badge", bundle: .main))
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
                .foregroundStyle(.kindredAccentDecorative)

            // Message
            VStack(spacing: KindredSpacing.sm) {
                Text(String(localized: "profile.guest_gate.title", bundle: .main))
                    .font(.kindredHeading2Scaled(size: heading2Size))
                    .foregroundStyle(.kindredTextPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "profile.guest_gate.subtitle", bundle: .main))
                    .font(.kindredBodyScaled(size: bodySize))
                    .foregroundStyle(.kindredTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Sign In button
            VStack(spacing: KindredSpacing.md) {
                KindredButton(String(localized: "profile.guest_gate.sign_in", bundle: .main), style: .primary) {
                    store.send(.signInTapped)
                }

                Button {
                    store.send(.continueAsGuestTapped)
                } label: {
                    Text(String(localized: "profile.guest_gate.continue_guest", bundle: .main))
                        .font(.kindredBodyScaled(size: bodySize))
                        .foregroundStyle(.kindredAccent)
                }
            }
            .padding(.horizontal, KindredSpacing.xl)
        }
        .padding(.horizontal, KindredSpacing.lg)
    }

    private var versionLabel: some View {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"

        return Text("Version \(version) (\(build))")
            .font(.kindredCaptionScaled(size: captionSize))
            .foregroundStyle(.kindredTextSecondary)
            #if DEBUG
            .onLongPressGesture(minimumDuration: 1.0) {
                showDebugMenu = true
            }
            #endif
    }
}
