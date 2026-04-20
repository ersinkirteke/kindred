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
    let onDelete: (String) -> Void

    public init(
        voiceProfiles: [VoiceProfile],
        selectedVoiceId: String?,
        subscriptionStatus: SubscriptionStatus = .unknown,
        onSelect: @escaping (String) -> Void,
        onPreview: @escaping (String) -> Void,
        onCreateProfile: @escaping () -> Void = {},
        onUpgradeTapped: @escaping () -> Void = {},
        onDelete: @escaping (String) -> Void = { _ in }
    ) {
        self.voiceProfiles = voiceProfiles
        self.selectedVoiceId = selectedVoiceId
        self.subscriptionStatus = subscriptionStatus
        self.onSelect = onSelect
        self.onPreview = onPreview
        self.onCreateProfile = onCreateProfile
        self.onUpgradeTapped = onUpgradeTapped
        self.onDelete = onDelete
    }

    /// Whether free user has hit voice profile limit
    private var isAtVoiceLimit: Bool {
        if case .free = subscriptionStatus {
            return voiceProfiles.count >= 1
        }
        return false
    }

    /// Split profiles into Free section (kindred-default) and Pro section (all others)
    private var freeProfiles: [VoiceProfile] {
        voiceProfiles.filter { $0.id == "kindred-default" }
    }

    private var sortedProProfiles: [VoiceProfile] {
        voiceProfiles
            .filter { $0.id != "kindred-default" }
            .sorted { lhs, rhs in
                if lhs.isOwnVoice && !rhs.isOwnVoice { return true }
                if !lhs.isOwnVoice && rhs.isOwnVoice { return false }
                return lhs.name < rhs.name
            }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(String(localized: "Choose a Voice", bundle: .main))
                .font(.kindredHeading3())
                .foregroundStyle(.kindredTextPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if voiceProfiles.isEmpty {
                // Empty state
                EmptyStateView(onCreateProfile: onCreateProfile)
            } else {
                List {
                    // MARK: Free Section
                    if !freeProfiles.isEmpty {
                        Section {
                            ForEach(freeProfiles) { profile in
                                VoiceCardView(
                                    profile: profile,
                                    isSelected: profile.id == selectedVoiceId,
                                    subscriptionStatus: subscriptionStatus,
                                    isKindredVoice: true,
                                    onSelect: {
                                        onSelect(profile.id)
                                    },
                                    onPreview: { onPreview(profile.id) }
                                )
                                .accessibilityAddTraits(AccessibilityTraits())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        } header: {
                            sectionHeader("Free")
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }

                    // MARK: Pro Voices Section
                    Section {
                        ForEach(sortedProProfiles) { profile in
                            VoiceCardView(
                                profile: profile,
                                isSelected: profile.id == selectedVoiceId,
                                subscriptionStatus: subscriptionStatus,
                                isKindredVoice: false,
                                onSelect: {
                                    if isVoiceLocked(profile) {
                                        onUpgradeTapped()
                                    } else {
                                        onSelect(profile.id)
                                    }
                                },
                                onPreview: { onPreview(profile.id) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onDelete(profile.id)
                                } label: {
                                    Label(String(localized: "Delete", bundle: .main), systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        sectionHeader("Pro Voices")
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }

                    // Bottom of Pro section: upgrade CTA or create voice profile button
                    Section {
                        if isAtVoiceLimit {
                            // Upgrade CTA for free users at voice limit
                            Button {
                                onUpgradeTapped()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.kindredAccent)
                                        .font(.system(size: 20, weight: .semibold))

                                    Text(String(localized: "Upgrade to Pro for more voices", bundle: .main))
                                        .font(.kindredBodyBold())
                                        .foregroundStyle(.kindredAccent)

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.kindredCardSurface)
                                .clipShape(.rect(cornerRadius: 12))
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
                                                .foregroundStyle(.kindredAccent)
                                                .font(.system(size: 20, weight: .semibold))
                                        )

                                    Text(String(localized: "Create Voice Profile", bundle: .main))
                                        .font(.kindredBodyBold())
                                        .foregroundStyle(.kindredAccent)

                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                        )
                                        .foregroundStyle(.kindredAccent.opacity(0.4))
                                )
                            }
                            .accessibilityLabel(String(localized: "accessibility.voice_picker.create_profile_label", bundle: .main))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.kindredBackground)
            }
        }
        .background(Color.kindredBackground)
    }

    // MARK: - Helpers

    /// Renders a section header in caption style
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.kindredCaption())
            .foregroundStyle(.kindredTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }

    /// Check if voice is locked for current user
    private func isVoiceLocked(_ profile: VoiceProfile) -> Bool {
        // Default "Kindred Voice" always unlocked
        if profile.id == "kindred-default" {
            return false
        }

        // Free users: only default voice unlocked, all others locked
        if case .free = subscriptionStatus {
            return true
        }

        // Pro users: all voices unlocked
        if case .pro = subscriptionStatus {
            return false
        }

        // Unknown/guest: lock non-default voices
        return true
    }
}

// MARK: - VoiceCardView

struct VoiceCardView: View {
    let profile: VoiceProfile
    let isSelected: Bool
    let subscriptionStatus: SubscriptionStatus
    let isKindredVoice: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    init(
        profile: VoiceProfile,
        isSelected: Bool,
        subscriptionStatus: SubscriptionStatus,
        isKindredVoice: Bool = false,
        onSelect: @escaping () -> Void,
        onPreview: @escaping () -> Void
    ) {
        self.profile = profile
        self.isSelected = isSelected
        self.subscriptionStatus = subscriptionStatus
        self.isKindredVoice = isKindredVoice
        self.onSelect = onSelect
        self.onPreview = onPreview
    }

    private var isLocked: Bool {
        // Default "Kindred Voice" always unlocked
        if profile.id == "kindred-default" {
            return false
        }

        // Free users: lock all non-default voices
        if case .free = subscriptionStatus {
            return true
        }

        // Pro users: all unlocked
        if case .pro = subscriptionStatus {
            return false
        }

        // Unknown/guest: lock non-default
        return true
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 12) {
                // Avatar — Kindred Voice gets special treatment
                if isKindredVoice {
                    // Try app icon image first, fallback to waveform system icon
                    kindredVoiceAvatar
                } else if let avatarURL = profile.avatarURL, let url = URL(string: avatarURL) {
                    KFImage(url)
                        .placeholder {
                            Circle()
                                .fill(Color.kindredDivider)
                                .overlay(
                                    Image(systemName: "person.crop.circle")
                                        .foregroundStyle(.kindredTextSecondary)
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
                                .foregroundStyle(.kindredTextSecondary)
                                .font(.system(size: 24))
                        )
                }

                // Name and metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.kindredBodyBold())
                        .foregroundStyle(.kindredTextPrimary)

                    if isKindredVoice {
                        Text(String(localized: "On-device narration", bundle: .main))
                            .font(.kindredCaption())
                            .foregroundStyle(.kindredTextSecondary)
                    } else if profile.isOwnVoice {
                        Text(String(localized: "Your Voice", bundle: .main))
                            .font(.kindredCaption())
                            .foregroundStyle(.kindredAccent)
                    }
                }

                Spacer()

                // Lock icon for Pro voices (free users)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.kindredTextSecondary)
                        .accessibilityLabel(String(localized: "Pro feature", bundle: .main))
                }

                // Preview button
                if profile.sampleAudioURL != nil && !isLocked {
                    Button {
                        onPreview()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundStyle(.kindredAccent)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel(String(localized: "Preview \(profile.name)'s voice", bundle: .main))
                    .accessibilityHint(String(localized: "accessibility.voice_picker.preview_hint", bundle: .main))
                }

                // Checkmark for selected
                if isSelected && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.kindredAccent)
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
        .accessibilityLabel(kindredVoiceAccessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Kindred Voice Avatar

    @ViewBuilder
    private var kindredVoiceAvatar: some View {
        // Try to use app icon from assets (named "AppIcon")
        if UIImage(named: "AppIcon") != nil {
            Image("AppIcon")
                .resizable()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            // Fallback: waveform system icon in accent color
            Circle()
                .fill(Color.kindredAccent.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "waveform.circle.fill")
                        .foregroundStyle(.kindredAccent)
                        .font(.system(size: 28))
                )
        }
    }

    // MARK: - Accessibility

    private var kindredVoiceAccessibilityLabel: String {
        if isKindredVoice {
            return "\(profile.name), Free voice"
        } else if isLocked {
            return "\(profile.name), Pro voice, locked"
        } else if profile.isOwnVoice {
            return "\(profile.name), Your Voice"
        } else {
            return profile.name
        }
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let onCreateProfile: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundStyle(.kindredTextSecondary)

            Text(String(localized: "No Voice Profiles", bundle: .main))
                .font(.kindredHeading3())
                .foregroundStyle(.kindredTextPrimary)

            Text(String(localized: "Create a voice profile to hear recipes narrated in your voice or a loved one's voice.", bundle: .main))
                .font(.kindredBody())
                .foregroundStyle(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(String(localized: "Create Voice Profile", bundle: .main)) {
                onCreateProfile()
            }
            .font(.kindredBodyBold())
            .foregroundStyle(.white)
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

#Preview("Voice Picker - Free User") {
    VoicePickerView(
        voiceProfiles: [
            VoiceProfile(
                id: "kindred-default",
                name: "Kindred Voice",
                avatarURL: nil,
                sampleAudioURL: nil,
                isOwnVoice: false,
                createdAt: Date()
            ),
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
            )
        ],
        selectedVoiceId: "kindred-default",
        subscriptionStatus: .free,
        onSelect: { _ in },
        onPreview: { _ in }
    )
}

#Preview("Voice Picker - Pro User") {
    VoicePickerView(
        voiceProfiles: [
            VoiceProfile(
                id: "kindred-default",
                name: "Kindred Voice",
                avatarURL: nil,
                sampleAudioURL: nil,
                isOwnVoice: false,
                createdAt: Date()
            ),
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
                sampleAudioURL: nil,
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
        subscriptionStatus: .pro(expiresDate: Date().addingTimeInterval(86400), isInGracePeriod: false),
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
