import DesignSystem
import SwiftUI

/// Badge displayed on personalized recipe cards (bottom-left placement)
struct ForYouBadge: View {
    var body: some View {
        Text(String(localized: "For You", bundle: .main))
            .font(.kindredCaption())
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.kindredAccent.opacity(0.9))
            )
            .accessibilityHidden(true)  // Conveyed in card's accessibility label
    }
}

#Preview {
    ForYouBadge()
        .padding()
}
