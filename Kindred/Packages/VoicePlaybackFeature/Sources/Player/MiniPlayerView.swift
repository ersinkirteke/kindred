import ComposableArchitecture
import DesignSystem
import Kingfisher
import SwiftUI

// MARK: - MiniPlayerView

public struct MiniPlayerView: View {
    @Bindable var store: StoreOf<VoicePlaybackReducer>

    public init(store: StoreOf<VoicePlaybackReducer>) {
        self.store = store
    }

    public var body: some View {
        if let playback = store.currentPlayback {
            playerContainer(playback: playback)
        }
    }

    private func playerContainer(playback: CurrentPlayback) -> some View {
        VStack(spacing: 0) {
            progressBar(playback: playback)
            playerBar(playback: playback)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: store.currentPlayback != nil)
        .sheet(isPresented: Binding(
            get: { store.isExpanded },
            set: { _ in store.send(.toggleExpanded) }
        )) {
            ExpandedPlayerView(store: store)
                .presentationDetents([.fraction(0.6), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }

    private func progressBar(playback: CurrentPlayback) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.kindredAccent)
                .frame(
                    width: geometry.size.width * CGFloat(playback.currentTime / max(playback.duration, 1)),
                    height: 3
                )
                .animation(.linear(duration: 0.5), value: playback.currentTime)
        }
        .frame(height: 3)
    }

    private func playerBar(playback: CurrentPlayback) -> some View {
        HStack(spacing: 12) {
            artworkThumbnail(playback: playback)
            trackInfo(playback: playback)
            Spacer()
            playPauseButton(playback: playback)
            Button {
                store.send(.dismiss)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.kindredTextSecondary)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel(String(localized: "Close player", bundle: .main))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.kindredCardSurface)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.toggleExpanded)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(miniPlayerAccessibilityLabel(playback: playback))
        .accessibilityAction(named: playback.status == .playing ? String(localized: "Pause", bundle: .main) : String(localized: "Play", bundle: .main)) {
            if playback.status == .playing || playback.status == .buffering {
                store.send(.pause)
            } else {
                store.send(.play)
            }
        }
        .accessibilityAction(named: String(localized: "Expand player", bundle: .main)) {
            store.send(.toggleExpanded)
        }
        .accessibilityAction(named: String(localized: "Dismiss", bundle: .main)) {
            store.send(.dismiss)
        }
    }

    private func miniPlayerAccessibilityLabel(playback: CurrentPlayback) -> String {
        playback.status == .playing
            ? String(localized: "Now playing \(playback.recipeName) by \(playback.speakerName)", bundle: .main)
            : String(localized: "Paused: \(playback.recipeName) by \(playback.speakerName)", bundle: .main)
    }

    @ViewBuilder
    private func artworkThumbnail(playback: CurrentPlayback) -> some View {
        if let artworkURL = playback.artworkURL, let url = URL(string: artworkURL) {
            KFImage(url)
                .placeholder {
                    Rectangle()
                        .fill(Color.kindredDivider)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.kindredTextSecondary)
                        )
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.kindredDivider)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.kindredTextSecondary)
                )
        }
    }

    @ViewBuilder
    private func trackInfo(playback: CurrentPlayback) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if case let .error(message) = playback.status {
                Text(String(localized: "Error", bundle: .main))
                    .font(.kindredBodyBold())
                    .foregroundStyle(.red)
                    .lineLimit(1)
                Text(message)
                    .font(.kindredCaption())
                    .foregroundStyle(.red)
                    .lineLimit(2)
            } else {
                Text(playback.recipeName)
                    .font(.kindredBodyBold())
                    .foregroundStyle(.kindredTextPrimary)
                    .lineLimit(1)
                Text(playback.speakerName)
                    .font(.kindredBody())
                    .foregroundStyle(.kindredTextSecondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func playPauseButton(playback: CurrentPlayback) -> some View {
        Button {
            if playback.status == .playing || playback.status == .buffering {
                store.send(.pause)
            } else {
                store.send(.play)
            }
        } label: {
            if case .error = playback.status {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
            } else if store.isLoadingNarration || playback.status == .loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: (playback.status == .playing || playback.status == .buffering) ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.kindredAccent)
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityLabel(playback.status == .playing ? String(localized: "Pause", bundle: .main) : String(localized: "Play", bundle: .main))
        .accessibilityHint(playback.status == .playing ? String(localized: "accessibility.mini_player.pause_hint", bundle: .main) : String(localized: "accessibility.mini_player.play_hint", bundle: .main))
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        MiniPlayerView(
            store: Store(
                initialState: VoicePlaybackReducer.State(
                    currentPlayback: CurrentPlayback(
                        recipeId: "1",
                        recipeName: "Grandma's Chocolate Chip Cookies",
                        voiceId: "voice-1",
                        speakerName: "Grandma Sarah",
                        artworkURL: nil,
                        duration: 300,
                        currentTime: 120,
                        speed: .normal,
                        status: .playing,
                        currentStepIndex: 2
                    )
                )
            ) {
                VoicePlaybackReducer()
            }
        )
    }
    .background(Color.kindredBackground)
}
