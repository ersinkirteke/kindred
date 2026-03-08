import DesignSystem
import Kingfisher
import MonetizationFeature
import SwiftUI

// MARK: - VoicePickerView

public struct VoicePickerView: View {
    let voiceProfiles: [VoiceProfile]
    let selectedVoiceId: String?
    let subscriptionStatus: SubscriptionStatus
    let onSelect: (String) -> Void
    let onPreview: (String) -> Void
    let onCreateProfile: () -> Void
    let onUpgradeTapped: () -> Void

    public init(
        voiceProfiles: [VoiceProfile],
        selectedVoiceId: String?,
        subscriptionStatus: SubscriptionStatus = .unknown,
        onSelect: @escaping (String) -> Void,
        onPreview: @escaping (String) -> Void,
        onCreateProfile: @escaping () -> Void = {},
        onUpgradeTapped: @escaping () -> Void = {}
    ) {
        self.voiceProfiles = voiceProfiles
        self.selectedVoiceId = selectedVoiceId
        self.subscriptionStatus = subscriptionStatus
        self.onSelect = onSelect
        self.onPreview = onPreview
        self.onCreateProfile = onCreateProfile
        self.onUpgradeTapped = onUpgradeTapped
    }

    /// Whether free user has hit voice profile limit
    private var isAtVoiceLimit: Bool {
        if case .free = subscriptionStatus {
            return voiceProfiles.count >= 1
        }
        return false
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(String(localized: "Choose a Voice", bundle: .main))
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if voiceProfiles.isEmpty {
                // Empty state
                EmptyStateView(onCreateProfile: onCreateProfile)
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

                        // Add new voice profile button OR upgrade CTA
                        if isAtVoiceLimit {
                            // Upgrade CTA for free users at voice limit
                            Button {
                                onUpgradeTapped()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.kindredAccent)
                                        .font(.system(size: 20, weight: .semibold))

                                    Text(String(localized: "Upgrade to Pro for more voices", bundle: .main))
                                        .font(.kindredBodyBold())
                                        .foregroundColor(.kindredAccent)

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.kindredCardSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.kindredAccent, lineWidth: 2)
                                )
                            }
                            .accessibilityLabel(String(localized: "accessibility.voice_picker.upgrade_label", bundle: .main))
                        } else {
                            // Create voice profile button (free users with 0 voices OR Pro users)
                            Button {
                                onCreateProfile()
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.kindredAccent.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.kindredAccent)
                                                .font(.system(size: 20, weight: .semibold))
                                        )

                                    Text(String(localized: "Create Voice Profile", bundle: .main))
                                        .font(.kindredBodyBold())
                                        .foregroundColor(.kindredAccent)

                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                        )
                                        .foregroundColor(.kindredAccent.opacity(0.4))
                                )
                            }
                            .accessibilityLabel(String(localized: "accessibility.voice_picker.create_profile_label", bundle: .main))
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
                        Text(String(localized: "Your Voice", bundle: .main))
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
                    .accessibilityLabel(String(localized: "Preview \(profile.name)'s voice", bundle: .main))
                    .accessibilityHint(String(localized: "accessibility.voice_picker.preview_hint", bundle: .main))
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
        .accessibilityLabel(String(localized: "\(profile.name)\(profile.isOwnVoice ? ", Your Voice" : "")"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let onCreateProfile: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundColor(.kindredTextSecondary)

            Text(String(localized: "No Voice Profiles", bundle: .main))
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)

            Text(String(localized: "Create a voice profile to hear recipes narrated in your voice or a loved one's voice.", bundle: .main))
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(String(localized: "Create Voice Profile", bundle: .main)) {
                onCreateProfile()
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
