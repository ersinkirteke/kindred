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
                .foregroundColor(.kindredAccent)
                .padding(.bottom, KindredSpacing.lg)

            // Heading
            Text("Hear recipes in familiar voices")
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.sm)
                .padding(.horizontal, KindredSpacing.lg)

            // Body text
            Text("Clone your voice or a loved one's to narrate cooking instructions")
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KindredSpacing.xl)

            Spacer()

            // CTA buttons
            VStack(spacing: KindredSpacing.md) {
                // Try it now button
                KindredButton("Try it now", style: .primary) {
                    store.send(.tryVoiceNowTapped)
                }
                .accessibilityLabel("Try voice feature now")

                // Set up later button
                KindredButton("Set up later", style: .secondary) {
                    store.send(.setupVoiceLaterTapped)
                }
                .accessibilityLabel("Set up voice later")
            }
            .padding(.horizontal, KindredSpacing.lg)
            .padding(.bottom, KindredSpacing.xl)
        }
        .background(Color.kindredBackground)
    }
}
