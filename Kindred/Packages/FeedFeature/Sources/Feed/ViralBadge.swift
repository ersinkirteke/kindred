import DesignSystem
import SwiftUI

struct ViralBadge: View {
    var body: some View {
        Text("VIRAL")
            .font(.kindredCaption())
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(Color.kindredAccent)
            .cornerRadius(4)
            .rotationEffect(.degrees(-15))
            .accessibilityHidden(true) // Conveyed in card's accessibility label
    }
}
