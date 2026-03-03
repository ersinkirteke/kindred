import ComposableArchitecture
import DesignSystem
import Kingfisher
import SwiftUI

// MARK: - ExpandedPlayerView

public struct ExpandedPlayerView: View {
    @Bindable var store: StoreOf<VoicePlaybackReducer>

    public init(store: StoreOf<VoicePlaybackReducer>) {
        self.store = store
    }

    public var body: some View {
        if let playback = store.currentPlayback {
            VStack(spacing: 20) {
                // Speaker section (top)
                VStack(spacing: 8) {
                    // Speaker avatar
                    if let voiceProfile = store.voiceProfiles.first(where: { $0.id == playback.voiceId }),
                       let avatarURL = voiceProfile.avatarURL,
                       let url = URL(string: avatarURL) {
                        KFImage(url)
                            .placeholder {
                                Circle()
                                    .fill(Color.kindredDivider)
                                    .overlay(
                                        Image(systemName: "person.crop.circle")
                                            .foregroundColor(.kindredTextSecondary)
                                    )
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.kindredDivider)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.kindredTextSecondary)
                                    .font(.system(size: 32))
                            )
                    }

                    // Speaker name (prominently displayed)
                    Text(playback.speakerName)
                        .font(.kindredHeading2())
                        .foregroundColor(.kindredTextPrimary)

                    Text("Narrating")
                        .font(.kindredCaption())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.top, 16)

                // Recipe artwork
                if let artworkURL = playback.artworkURL, let url = URL(string: artworkURL) {
                    KFImage(url)
                        .placeholder {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.kindredDivider)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.kindredTextSecondary)
                                        .font(.system(size: 40))
                                )
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .frame(maxWidth: 280)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.kindredDivider)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 280)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.kindredTextSecondary)
                                .font(.system(size: 40))
                        )
                }

                // Recipe name
                Text(playback.recipeName)
                    .font(.kindredHeading3())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)

                // Current step text
                if let stepIndex = playback.currentStepIndex,
                   stepIndex < store.recipeSteps.count {
                    ScrollView {
                        Text("Step \(stepIndex + 1): \(store.recipeSteps[stepIndex])")
                            .font(.kindredBody())
                            .foregroundColor(.kindredTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 60)
                }

                // Seek bar
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { playback.currentTime },
                            set: { store.send(.seekTo($0)) }
                        ),
                        in: 0...max(playback.duration, 1)
                    )
                    .tint(.kindredAccent)
                    .accessibilityLabel("Playback position")
                    .accessibilityValue("\(formatTime(playback.currentTime)) of \(formatTime(playback.duration))")

                    HStack {
                        Text(formatTime(playback.currentTime))
                            .font(.kindredCaption())
                            .foregroundColor(.kindredTextSecondary)

                        Spacer()

                        Text("-\(formatTime(playback.duration - playback.currentTime))")
                            .font(.kindredCaption())
                            .foregroundColor(.kindredTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                // Transport controls
                HStack(spacing: 40) {
                    // Skip back 15s
                    Button {
                        store.send(.skipBackward)
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title2)
                            .foregroundColor(.kindredAccent)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("Skip back 15 seconds")
                    .accessibilityHint("Double tap to go back 15 seconds")

                    // Play/pause (64dp per VOICE-02 requirement)
                    Button {
                        if playback.status == .playing {
                            store.send(.pause)
                        } else {
                            store.send(.play)
                        }
                        HapticFeedback.medium()
                    } label: {
                        if store.isLoadingNarration {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
                                .scaleEffect(2.0)
                                .frame(width: 64, height: 64)
                        } else {
                            Image(systemName: playback.status == .playing ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.kindredAccent)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .accessibilityLabel(playback.status == .playing ? "Pause" : "Play")
                    .accessibilityHint("Double tap to \(playback.status == .playing ? "pause" : "play") narration")

                    // Skip forward 30s
                    Button {
                        store.send(.skipForward)
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "goforward.30")
                            .font(.title2)
                            .foregroundColor(.kindredAccent)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("Skip forward 30 seconds")
                    .accessibilityHint("Double tap to skip ahead 30 seconds")
                }

                // Speed control + voice switch
                HStack(spacing: 16) {
                    // Speed control
                    Button {
                        store.send(.cycleSpeed)
                        HapticFeedback.light()
                    } label: {
                        Text("\(String(format: "%.2g", playback.speed.rawValue))×")
                            .font(.kindredBodyBold())
                            .foregroundColor(.kindredAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.kindredAccent, lineWidth: 1.5)
                            )
                    }
                    .accessibilityLabel("Playback speed \(String(format: "%.2g", playback.speed.rawValue)) times")
                    .accessibilityHint("Double tap to cycle through playback speeds")

                    // Voice switch button (if multiple voices available)
                    if store.voiceProfiles.count > 1 {
                        Button {
                            store.send(.toggleExpanded) // Show voice picker inline
                        } label: {
                            Image(systemName: "waveform.badge.person")
                                .font(.kindredBodyBold())
                                .foregroundColor(.kindredAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(Color.kindredAccent, lineWidth: 1.5)
                                )
                        }
                        .accessibilityLabel("Switch narrator voice")
                        .accessibilityHint("Double tap to choose a different voice")
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .background(Color.kindredBackground)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - HapticFeedback

struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    ExpandedPlayerView(
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
                ),
                voiceProfiles: [
                    VoiceProfile(
                        id: "voice-1",
                        name: "Grandma Sarah",
                        avatarURL: nil,
                        sampleAudioURL: nil,
                        isOwnVoice: false,
                        createdAt: Date()
                    )
                ],
                recipeSteps: [
                    "Preheat the oven to 375°F (190°C).",
                    "In a large bowl, mix butter and sugars until creamy.",
                    "Beat in eggs and vanilla extract.",
                    "Gradually blend in flour mixture.",
                    "Stir in chocolate chips."
                ]
            )
        ) {
            VoicePlaybackReducer()
        }
    )
}
