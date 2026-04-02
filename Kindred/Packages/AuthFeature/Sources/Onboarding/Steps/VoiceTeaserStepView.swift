import SwiftUI
import ComposableArchitecture
import DesignSystem

struct VoiceTeaserStepView: View {
    let store: StoreOf<OnboardingReducer>

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Voice icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.kindredAccent)
                .padding(.bottom, KindredSpacing.lg)

            // Heading
            Text(String(localized: "onboarding.voice_teaser.title", bundle: .main))
                .font(.kindredHeading1())
                .foregroundStyle(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.sm)
                .padding(.horizontal, KindredSpacing.lg)

            // Body text
            Text(String(localized: "onboarding.voice_teaser.subtitle", bundle: .main))
                .font(.kindredBody())
                .foregroundStyle(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KindredSpacing.xl)

            Spacer()

            // CTA buttons
            VStack(spacing: KindredSpacing.md) {
                // Try it now button
                KindredButton(String(localized: "onboarding.voice_teaser.try_now", bundle: .main), style: .primary) {
                    store.send(.tryVoiceNowTapped)
                }
                .accessibilityLabel(String(localized: "accessibility.onboarding_voice.try_now", bundle: .main))

                // Set up later button
                KindredButton(String(localized: "onboarding.voice_teaser.setup_later", bundle: .main), style: .secondary) {
                    store.send(.setupVoiceLaterTapped)
                }
                .accessibilityLabel(String(localized: "accessibility.onboarding_voice.setup_later", bundle: .main))
            }
            .padding(.horizontal, KindredSpacing.lg)
            .padding(.bottom, KindredSpacing.xl)
        }
        .background(Color.kindredBackground)
    }
}
