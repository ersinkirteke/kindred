import DesignSystem
import SwiftUI

struct ViralBadge: View {
    var body: some View {
        Text(String(localized: "VIRAL", bundle: .main))
            .font(.kindredCaption())
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(Color.kindredAccent)
            .clipShape(.rect(cornerRadius: 4))
            .rotationEffect(.degrees(-15))
            .accessibilityHidden(true) // Conveyed in card's accessibility label
    }
}
