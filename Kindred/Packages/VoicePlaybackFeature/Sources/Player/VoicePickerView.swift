import DesignSystem
import Kingfisher
import SwiftUI

// MARK: - VoicePickerView

public struct VoicePickerView: View {
    let voiceProfiles: [VoiceProfile]
    let selectedVoiceId: String?
    let onSelect: (String) -> Void
    let onPreview: (String) -> Void

    public init(
        voiceProfiles: [VoiceProfile],
        selectedVoiceId: String?,
        onSelect: @escaping (String) -> Void,
        onPreview: @escaping (String) -> Void
    ) {
        self.voiceProfiles = voiceProfiles
        self.selectedVoiceId = selectedVoiceId
        self.onSelect = onSelect
        self.onPreview = onPreview
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Choose a Voice")
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if voiceProfiles.isEmpty {
                // Empty state
                EmptyStateView()
            } else {
                // Voice cards
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedVoiceProfiles) { profile in
                            VoiceCardView(
                                profile: profile,
                                isSelected: profile.id == selectedVoiceId,
                                onSelect: { onSelect(profile.id) },
                                onPreview: { onPreview(profile.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color.kindredBackground)
    }

    // MARK: - Helpers

    /// Sort voice profiles: user's own voice first, then alphabetically
    private var sortedVoiceProfiles: [VoiceProfile] {
        voiceProfiles.sorted { lhs, rhs in
            if lhs.isOwnVoice && !rhs.isOwnVoice {
                return true
            } else if !lhs.isOwnVoice && rhs.isOwnVoice {
                return false
            } else {
                return lhs.name < rhs.name
            }
        }
    }
}

// MARK: - VoiceCardView

struct VoiceCardView: View {
    let profile: VoiceProfile
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = profile.avatarURL, let url = URL(string: avatarURL) {
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
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.kindredDivider)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.kindredTextSecondary)
                                .font(.system(size: 24))
                        )
                }

                // Name and metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.kindredBodyBold())
                        .foregroundColor(.kindredTextPrimary)

                    if profile.isOwnVoice {
                        Text("Your Voice")
                            .font(.kindredCaption())
                            .foregroundColor(.kindredAccent)
                    }
                }

                Spacer()

                // Preview button
                if profile.sampleAudioURL != nil {
                    Button {
                        onPreview()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundColor(.kindredAccent)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Preview \(profile.name)'s voice")
                    .accessibilityHint("Double tap to hear a sample")
                }

                // Checkmark for selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.kindredAccent)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.kindredCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.kindredAccent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .accessibilityLabel("\(profile.name)\(profile.isOwnVoice ? ", Your Voice" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundColor(.kindredTextSecondary)

            Text("No Voice Profiles")
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)

            Text("Create a voice profile to hear recipes narrated in your voice or a loved one's voice.")
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // TODO: Add navigation to voice cloning flow in Phase 8+
            Button("Create Voice Profile") {
                // Navigation will be implemented in later phase
            }
            .font(.kindredBodyBold())
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.kindredAccent)
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Preview

#Preview("Voice Picker") {
    VoicePickerView(
        voiceProfiles: [
            VoiceProfile(
                id: "voice-1",
                name: "My Voice",
                avatarURL: nil,
                sampleAudioURL: "https://example.com/sample.m4a",
                isOwnVoice: true,
                createdAt: Date()
            ),
            VoiceProfile(
                id: "voice-2",
                name: "Mom",
                avatarURL: nil,
                sampleAudioURL: "https://example.com/sample2.m4a",
                isOwnVoice: false,
                createdAt: Date()
            ),
            VoiceProfile(
                id: "voice-3",
                name: "Dad",
                avatarURL: nil,
                sampleAudioURL: nil,
                isOwnVoice: false,
                createdAt: Date()
            )
        ],
        selectedVoiceId: "voice-1",
        onSelect: { _ in },
        onPreview: { _ in }
    )
}

#Preview("Empty State") {
    VoicePickerView(
        voiceProfiles: [],
        selectedVoiceId: nil,
        onSelect: { _ in },
        onPreview: { _ in }
    )
}
