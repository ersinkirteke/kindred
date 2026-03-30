import ComposableArchitecture
import DesignSystem
import SwiftUI

struct PrivacyDataSection: View {
    let voiceProfile: ProfileReducer.VoiceProfileInfo?
    let isDeleting: Bool
    let onDelete: () -> Void
    let onPrivacyPolicyTapped: () -> Void

    @ScaledMetric(relativeTo: .title2) private var heading2Size: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            // Section title
            Text(String(localized: "profile.privacy_data.title", bundle: .main))
                .font(.kindredHeading2Scaled(size: heading2Size))
                .foregroundColor(.kindredTextPrimary)

            // Voice profile card (if exists)
            if let profile = voiceProfile {
                VoiceProfileCardView(
                    profile: profile,
                    isDeleting: isDeleting,
                    onDelete: onDelete
                )
            }

            // Privacy Policy link
            Button {
                onPrivacyPolicyTapped()
            } label: {
                HStack {
                    Text(String(localized: "profile.privacy_data.privacy_policy", bundle: .main))
                        .font(.kindredBodyScaled(size: bodySize))
                        .foregroundColor(.kindredTextPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.kindredAccent)
                }
                .padding(.vertical, KindredSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
