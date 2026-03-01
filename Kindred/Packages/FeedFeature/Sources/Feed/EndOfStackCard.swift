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

                Text("You've seen all nearby recipes!")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Change location to explore more")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)

                KindredButton("Change Location", style: .primary) {
                    onChangeLocation()
                }
            }
            .padding(KindredSpacing.xl)
        }
    }
}
