import DesignSystem
import SwiftUI

// MARK: - VoiceConsentView

/// Full-screen consent modal for voice cloning with ElevenLabs disclosure
/// Implements GDPR-compliant explicit consent flow (PRIV-04, PRIV-05)
public struct VoiceConsentView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    public init(onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) {
        self.onAccept = onAccept
        self.onDecline = onDecline
    }

    public var body: some View {
        ZStack {
            Color.kindredBackground
                .ignoresSafeArea()

            VStack(spacing: KindredSpacing.xl) {
                // Icon
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.kindredAccent)
                    .padding(.top, KindredSpacing.xl)

                // Title
                Text(String(localized: "voice.consent.title", bundle: .main))
                    .font(.kindredHeading1())
                    .foregroundStyle(.kindredTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KindredSpacing.md)

                // ElevenLabs disclosure
                Text(String(localized: "voice.consent.elevenlabs_disclosure", bundle: .main))
                    .font(.kindredBody())
                    .foregroundStyle(.kindredTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KindredSpacing.lg)
                    .fixedSize(horizontal: false, vertical: true)

                // Bullet points
                VStack(alignment: .leading, spacing: KindredSpacing.md) {
                    ConsentBullet(text: String(localized: "voice.consent.bullet_sent_to_elevenlabs", bundle: .main))
                    ConsentBullet(text: String(localized: "voice.consent.bullet_recipe_narration_only", bundle: .main))
                    ConsentBullet(text: String(localized: "voice.consent.bullet_deletable_anytime", bundle: .main))
                    ConsentBullet(text: String(localized: "voice.consent.bullet_never_shared", bundle: .main))
                }
                .padding(.horizontal, KindredSpacing.lg)

                Spacer()

                // Buttons
                VStack(spacing: KindredSpacing.sm) {
                    KindredButton(
                        String(localized: "voice.consent.accept_button", bundle: .main),
                        style: .primary,
                        action: onAccept
                    )

                    KindredButton(
                        String(localized: "voice.consent.decline_button", bundle: .main),
                        style: .secondary,
                        action: onDecline
                    )
                }
                .padding(.horizontal, KindredSpacing.md)
                .padding(.bottom, KindredSpacing.lg)
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - ConsentBullet

private struct ConsentBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: KindredSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.kindredAccent)
                .frame(width: 20, height: 20)

            Text(text)
                .font(.kindredBody())
                .foregroundStyle(.kindredTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceConsentView(
        onAccept: { print("Accepted") },
        onDecline: { print("Declined") }
    )
}
