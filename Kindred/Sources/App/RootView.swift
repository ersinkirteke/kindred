import ComposableArchitecture
import DesignSystem
import FeedFeature
import ProfileFeature
import SwiftUI
import VoicePlaybackFeature
import AuthFeature

struct RootView: View {
    @Bindable var store: StoreOf<AppReducer>

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
                FeedView(
                    store: store.scope(
                        state: \.feedState,
                        action: \.feed
                    )
                )
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(AppReducer.Tab.feed)

                ProfileView(
                    store: store.scope(
                        state: \.profileState,
                        action: \.profile
                    )
                )
                .tabItem {
                    Label("Me", systemImage: "person.fill")
                }
                .tag(AppReducer.Tab.me)
                .badge(store.feedState.bookmarkCount > 0 ? store.feedState.bookmarkCount : 0)
            }
            .tint(.kindredAccent)
            .toolbarBackground(Color.kindredCardSurface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)

            // Mini-player overlay (only visible when playing)
            if store.voicePlaybackState.currentPlayback != nil {
                MiniPlayerView(
                    store: store.scope(state: \.voicePlaybackState, action: \.voicePlayback)
                )
                .padding(.bottom, 49) // Standard tab bar height
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
                onSelect: { voiceId in
                    store.send(.voicePlayback(.selectVoice(voiceId)))
                },
                onPreview: { voiceId in
                    store.send(.voicePlayback(.previewVoiceSample(voiceId)))
                },
                onCreateProfile: {
                    store.send(.voicePlayback(.showVoiceUpload))
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
        .onAppear {
            store.send(.observeAuth)
        }
    }
}
