import ComposableArchitecture
import DesignSystem
import Kingfisher
import SwiftUI

// MARK: - ExpandedPlayerView

public struct ExpandedPlayerView: View {
    @Bindable var store: StoreOf<VoicePlaybackReducer>

    // @ScaledMetric for Dynamic Type support
    @ScaledMetric(relativeTo: .title3) private var heading3Size: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) private var heading2Size: CGFloat = 22
    @ScaledMetric(relativeTo: .headline) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14
    @ScaledMetric(relativeTo: .title) private var playButtonSize: CGFloat = 64

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    public init(store: StoreOf<VoicePlaybackReducer>) {
        self.store = store
    }

    public var body: some View {
        if let playback = store.currentPlayback {
            VStack(spacing: 16) {
                // Speaker section with artwork (top)
                HStack(spacing: 16) {
                    // Recipe artwork (compact)
                    if let artworkURL = playback.artworkURL, let url = URL(string: artworkURL) {
                        KFImage(url)
                            .placeholder {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.kindredDivider)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(.kindredTextSecondary)
                                    )
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Speaker avatar (no artwork)
                        Circle()
                            .fill(Color.kindredDivider)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .foregroundStyle(.kindredTextSecondary)
                                    .font(.system(size: 40))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Recipe name
                        Text(playback.recipeName)
                            .font(.kindredHeading3Scaled(size: heading3Size))
                            .foregroundStyle(.kindredTextPrimary)
                            .lineLimit(2)

                        // Speaker name (prominently displayed)
                        Text(playback.speakerName)
                            .font(.kindredHeading2Scaled(size: heading2Size))
                            .foregroundStyle(.kindredAccent)

                        Text(String(localized: "Narrating", bundle: .main))
                            .font(.kindredCaptionScaled(size: captionSize))
                            .foregroundStyle(.kindredTextSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Current step text
                if let stepIndex = playback.currentStepIndex,
                   stepIndex < store.recipeSteps.count {
                    ScrollView {
                        Text(String(localized: "Step \(stepIndex + 1): \(store.recipeSteps[stepIndex])", bundle: .main))
                            .font(.kindredBodyScaled(size: bodySize))
                            .foregroundStyle(.kindredTextSecondary)
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
                    .accessibilityLabel(String(localized: "Playback position", bundle: .main))
                    .accessibilityValue(String(localized: "\(formatTime(playback.currentTime)) of \(formatTime(playback.duration))", bundle: .main))

                    HStack {
                        Text(formatTime(playback.currentTime))
                            .font(.kindredCaptionScaled(size: captionSize))
                            .foregroundStyle(.kindredTextSecondary)

                        Spacer()

                        Text("-\(formatTime(playback.duration - playback.currentTime))")
                            .font(.kindredCaptionScaled(size: captionSize))
                            .foregroundStyle(.kindredTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                // Transport controls (vertical stack at AX sizes)
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 24) {
                            transportControlButtons(playback: playback)
                        }
                    } else {
                        HStack(spacing: 40) {
                            transportControlButtons(playback: playback)
                        }
                    }
                }

                // Speed control + voice switch
                HStack(spacing: 16) {
                    // Speed control
                    Button {
                        store.send(.cycleSpeed)
                        HapticFeedback.light()
                    } label: {
                        Text("\(String(format: "%.2g", playback.speed.rawValue))×")
                            .font(.kindredBodyBoldScaled(size: bodySize))
                            .foregroundStyle(.kindredAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.kindredAccent, lineWidth: 1.5)
                            )
                    }
                    .accessibilityLabel(String(localized: "Playback speed \(String(format: "%.2g", playback.speed.rawValue)) times"))
                    .accessibilityHint(String(localized: "accessibility.expanded_player.cycle_speed_hint", bundle: .main))

                    // Voice switch button (if multiple voices available)
                    if store.voiceProfiles.count > 1 {
                        Button {
                            store.send(.showVoiceSwitcher)
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 14))
                                Text(String(localized: "Voice", bundle: .main))
                                    .font(.kindredBodyBoldScaled(size: bodySize))
                            }
                            .foregroundStyle(.kindredAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.kindredAccent, lineWidth: 1.5)
                            )
                        }
                        .accessibilityLabel(String(localized: "Switch narrator voice", bundle: .main))
                        .accessibilityHint(String(localized: "accessibility.expanded_player.switch_voice_hint", bundle: .main))
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .background(Color.kindredBackground)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func transportControlButtons(playback: CurrentPlayback) -> some View {
        // Skip back 15s
        Button {
            store.send(.skipBackward)
            HapticFeedback.light()
        } label: {
            Image(systemName: "gobackward.15")
                .font(.title2)
                .foregroundStyle(.kindredAccent)
                .frame(width: 56, height: 56)
        }
        .accessibilityLabel(String(localized: "Skip back 15 seconds", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.expanded_player.skip_back_hint", bundle: .main))

        // Play/pause (64dp per VOICE-02 requirement, scaled)
        Button {
            if playback.status == .playing || playback.status == .buffering {
                store.send(.pause)
            } else {
                store.send(.play)
            }
            HapticFeedback.medium()
        } label: {
            if store.isLoadingNarration || playback.status == .loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
                    .scaleEffect(2.0)
                    .frame(width: playButtonSize, height: playButtonSize)
            } else {
                Image(systemName: (playback.status == .playing || playback.status == .buffering) ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: playButtonSize))
                    .foregroundStyle(.kindredAccent)
            }
        }
        .frame(width: playButtonSize, height: playButtonSize)
        .accessibilityLabel(playback.status == .playing ? String(localized: "Pause", bundle: .main) : String(localized: "Play", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.expanded_player.playback_hint", bundle: .main))

        // Skip forward 30s
        Button {
            store.send(.skipForward)
            HapticFeedback.light()
        } label: {
            Image(systemName: "goforward.30")
                .font(.title2)
                .foregroundStyle(.kindredAccent)
                .frame(width: 56, height: 56)
        }
        .accessibilityLabel(String(localized: "Skip forward 30 seconds", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.expanded_player.skip_forward_hint", bundle: .main))
    }

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

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
