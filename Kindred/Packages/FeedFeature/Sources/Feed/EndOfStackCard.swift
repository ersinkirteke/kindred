import DesignSystem
import SwiftUI

struct EndOfStackCard: View {
    let onChangeLocation: () -> Void

    var body: some View {
        CardSurface {
            VStack(spacing: KindredSpacing.lg) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.kindredAccentDecorative)

                Text(String(localized: "You've seen all nearby recipes!", bundle: .main))
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "Change location to explore more", bundle: .main))
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)

                KindredButton(String(localized: "Change Location", bundle: .main), style: .primary) {
                    onChangeLocation()
                }
            }
            .padding(KindredSpacing.xl)
        }
    }
}
