import DesignSystem
import SwiftUI

struct MatchBadge: View {
    let percentage: Int

    @State private var animationScale: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Text("\(percentage)%")
            .font(.kindredCaption())
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(badgeColor)
            )
            .scaleEffect(animationScale)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.spring(response: 0.3)) {
                        animationScale = 1.0
                    }
                } else {
                    animationScale = 1.0
                }
            }
            .accessibilityLabel("\(percentage) percent ingredients available")
            .allowsHitTesting(false)
    }

    private var badgeColor: Color {
        if percentage >= 70 {
            return .kindredSuccess
        } else {
            return .kindredAccent
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MatchBadge(percentage: 85)
        MatchBadge(percentage: 60)
        MatchBadge(percentage: 50)
    }
    .padding()
}
