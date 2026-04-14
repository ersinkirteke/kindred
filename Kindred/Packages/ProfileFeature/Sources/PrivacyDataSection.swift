import ComposableArchitecture
import DesignSystem
import SwiftUI

struct PrivacyDataSection: View {
    let voiceProfile: VoiceProfileInfo?
    let isDeleting: Bool
    let onDelete: () -> Void
    let onPrivacyPolicyTapped: () -> Void
    let onTrackingSettingsTapped: () -> Void

    @ScaledMetric(relativeTo: .title2) private var heading2Size: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            // Section title
            Text(String(localized: "profile.privacy_data.title", bundle: .main))
                .font(.kindredHeading2Scaled(size: heading2Size))
                .foregroundStyle(.kindredTextPrimary)

            // Voice profile card (if exists)
            if let profile = voiceProfile {
                VoiceProfileCardView(
                    profile: profile,
                    isDeleting: isDeleting,
                    onDelete: onDelete
                )
            }

            // Tracking Permission row
            Button {
                onTrackingSettingsTapped()
            } label: {
                HStack {
                    Text(String(localized: "profile.privacy_data.tracking_permission", bundle: .main))
                        .font(.kindredBodyScaled(size: bodySize))
                        .foregroundStyle(.kindredTextPrimary)

                    Spacer()

                    Image(systemName: "gear")
                        .foregroundStyle(.kindredAccent)
                }
                .padding(.vertical, KindredSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "profile.privacy_data.tracking_permission", bundle: .main))
            .accessibilityHint(String(localized: "accessibility.profile.tracking_hint", bundle: .main))

            // Privacy Policy link
            Button {
                onPrivacyPolicyTapped()
            } label: {
                HStack {
                    Text(String(localized: "profile.privacy_data.privacy_policy", bundle: .main))
                        .font(.kindredBodyScaled(size: bodySize))
                        .foregroundStyle(.kindredTextPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.kindredAccent)
                }
                .padding(.vertical, KindredSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
