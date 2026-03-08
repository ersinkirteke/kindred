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
            VStack(spacing: 0) {
                // Thin progress bar at top
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

                // Main player bar
                HStack(spacing: 12) {
                    // Recipe artwork thumbnail
                    if let artworkURL = playback.artworkURL, let url = URL(string: artworkURL) {
                        KFImage(url)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.kindredDivider)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.kindredTextSecondary)
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
                                    .foregroundColor(.kindredTextSecondary)
                            )
                    }

                    // Recipe name + speaker name / error
                    VStack(alignment: .leading, spacing: 2) {
                        if case let .error(message) = playback.status {
                            Text("Error")
                                .font(.kindredBodyBold())
                                .foregroundColor(.red)
                                .lineLimit(1)
                            Text(message)
                                .font(.kindredCaption())
                                .foregroundColor(.red)
                                .lineLimit(2)
                        } else {
                            Text(playback.recipeName)
                                .font(.kindredBodyBold())
                                .foregroundColor(.kindredTextPrimary)
                                .lineLimit(1)

                            Text(playback.speakerName)
                                .font(.kindredBody())
                                .foregroundColor(.kindredTextSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Play/pause button
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
                                .foregroundColor(.red)
                        } else if store.isLoadingNarration || playback.status == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: (playback.status == .playing || playback.status == .buffering) ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.kindredAccent)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel(playback.status == .playing ? "Pause" : "Play")
                    .accessibilityHint(playback.status == .playing ? "Double tap to pause narration" : "Double tap to play narration")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.kindredCardSurface)
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.toggleExpanded)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    playback.status == .playing
                        ? "Now playing \(playback.recipeName) by \(playback.speakerName)"
                        : "Paused: \(playback.recipeName) by \(playback.speakerName)"
                )
                .accessibilityAction(named: playback.status == .playing ? "Pause" : "Play") {
                    if playback.status == .playing || playback.status == .buffering {
                        store.send(.pause)
                    } else {
                        store.send(.play)
                    }
                }
                .accessibilityAction(named: "Expand player") {
                    store.send(.toggleExpanded)
                }
                .accessibilityAction(named: "Dismiss") {
                    store.send(.stop)
                }
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
