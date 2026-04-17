import ComposableArchitecture
import DesignSystem
import FeedFeature
import PantryFeature
import ProfileFeature
import SwiftUI
import VoicePlaybackFeature
import AuthFeature
import MonetizationFeature

struct RootView: View {
    @Bindable var store: StoreOf<AppReducer>
    var body: some View {
        VStack(spacing: 0) {
            if store.isOffline {
                OfflineBanner()
            }

            TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            FeedView(
                store: store.scope(
                    state: \.feedState,
                    action: \.feed
                )
            )
            .tabItem {
                Label(String(localized: "tab.feed"), systemImage: "house.fill")
            }
            .tag(AppReducer.Tab.feed)

            PantryView(
                store: store.scope(
                    state: \.pantryState,
                    action: \.pantry
                )
            )
            .tabItem {
                Label(String(localized: "tab.pantry"), systemImage: "refrigerator.fill")
            }
            .tag(AppReducer.Tab.pantry)
            .badge(store.pantryState.expiringCount > 0 ? store.pantryState.expiringCount : 0)

            ProfileView(
                store: store.scope(
                    state: \.profileState,
                    action: \.profile
                )
            )
            .tabItem {
                Label(String(localized: "tab.me"), systemImage: "person.fill")
            }
            .tag(AppReducer.Tab.me)
            .badge(store.feedState.bookmarkCount > 0 ? store.feedState.bookmarkCount : 0)
            }
        }
        .tint(.kindredAccent)
        .toolbarBackground(Color.kindredCardSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Mini-player above tab bar — pushes content up so buttons aren't hidden
            if store.voicePlaybackState.currentPlayback != nil {
                MiniPlayerView(
                    store: store.scope(state: \.voicePlaybackState, action: \.voicePlayback)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.voicePlaybackState.currentPlayback != nil)
            }
        }
        .sheet(isPresented: Binding(
            get: { store.voicePlaybackState.showVoicePicker },
            set: { newValue in
                if !newValue {
                    store.send(.voicePlayback(.dismissVoicePicker))
                }
            }
        )) {
            VoicePickerView(
                voiceProfiles: store.voicePlaybackState.voiceProfiles,
                selectedVoiceId: store.voicePlaybackState.selectedVoiceId,
                subscriptionStatus: store.voicePlaybackState.subscriptionStatus,
                onSelect: { voiceId in
                    store.send(.voicePlayback(.selectVoice(voiceId)))
                },
                onPreview: { voiceId in
                    store.send(.voicePlayback(.previewVoiceSample(voiceId)))
                },
                onCreateProfile: {
                    store.send(.voicePlayback(.showVoiceUpload))
                },
                onUpgradeTapped: {
                    store.send(.voicePlayback(.upgradeTapped))
                },
                onDelete: { voiceId in
                    store.send(.voicePlayback(.deleteVoiceProfile(voiceId)))
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { store.voicePlaybackState.voiceUpload != nil },
            set: { newValue in
                if !newValue {
                    store.send(.voicePlayback(.voiceUpload(.dismiss)))
                }
            }
        )) {
            let voicePlaybackStore = store.scope(state: \.voicePlaybackState, action: \.voicePlayback)
            if let uploadStore = voicePlaybackStore.scope(state: \.voiceUpload, action: \.voiceUpload) {
                VoiceUploadView(store: uploadStore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(item: $store.scope(state: \.authGate, action: \.authGate)) { gateStore in
            SignInGateView(store: gateStore)
        }
        .fullScreenCover(item: $store.scope(state: \.onboarding, action: \.onboarding)) { onboardingStore in
            OnboardingView(store: onboardingStore)
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.voicePlaybackState.showPaywall },
            set: { newValue in
                if !newValue {
                    store.send(.voicePlayback(.dismissPaywall))
                }
            }
        )) {
            PaywallView(
                store: Store(initialState: SubscriptionReducer.State()) {
                    SubscriptionReducer()
                },
                onPurchaseCompleted: {
                    let proStatus = SubscriptionStatus.pro(
                        expiresDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                        isInGracePeriod: false
                    )
                    store.send(.profile(.simulatedPurchaseCompleted))
                    store.send(.feed(.subscriptionStatusUpdated(proStatus)))
                    store.send(.voicePlayback(.subscriptionStatusUpdated(proStatus)))
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { store.consentState.isShowingPrePrompt },
            set: { _ in } // Reducer controls dismissal
        )) {
            PrePromptView {
                store.send(.consent(.prePromptContinueTapped))
            }
        }
        .onAppear {
            store.send(.observeAuth)
            store.send(.startConnectivityMonitor)
            // Set up NowPlaying remote commands — MPRemoteCommandCenter is a singleton, safe to call once
            NowPlayingManager.shared.setupRemoteCommands(
                onPlay: { store.send(.voicePlayback(.play)) },
                onPause: { store.send(.voicePlayback(.pause)) },
                onSkipForward: { _ in store.send(.voicePlayback(.skipForward)) },
                onSkipBackward: { _ in store.send(.voicePlayback(.skipBackward)) },
                onSeek: { time in store.send(.voicePlayback(.seekTo(time))) }
            )
        }
    }
}
