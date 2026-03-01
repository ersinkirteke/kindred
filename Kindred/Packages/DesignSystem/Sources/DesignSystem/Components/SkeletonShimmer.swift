import SwiftUI

// MARK: - SkeletonShimmer
// Shimmer animation modifier for loading states
// Pairs with SwiftUI .redacted(reason: .placeholder)

public struct SkeletonShimmer: ViewModifier {

    // MARK: - Properties

    @State private var isAnimating = false

    // MARK: - Body

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Applies shimmer animation effect to the view
    /// Use with .redacted(reason: .placeholder) for skeleton loading states
    ///
    /// Example:
    /// ```swift
    /// RecipeCardView(recipe: .placeholder)
    ///     .redacted(reason: .placeholder)
    ///     .shimmer()
    /// ```
    func shimmer() -> some View {
        modifier(SkeletonShimmer())
    }
}

// MARK: - Preview Providers
// SwiftUI previews are available in Xcode only

#if DEBUG
struct SkeletonShimmer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: KindredSpacing.lg) {
            // Skeleton card with shimmer
            CardSurface {
                VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                    Text("Recipe Title Placeholder")
                        .font(.kindredHeading2())
                        .foregroundColor(.kindredTextPrimary)

                    Text("This is a placeholder description that shows how the shimmer animation looks on loading content.")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)

                    HStack {
                        Text("30 min")
                            .font(.kindredCaption())
                        Text("•")
                            .font(.kindredCaption())
                        Text("Medium")
                            .font(.kindredCaption())
                    }
                    .foregroundColor(.kindredTextSecondary)
                }
            }
            .redacted(reason: .placeholder)
            .shimmer()

            // Normal card for comparison
            CardSurface {
                VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                    Text("Loaded Recipe")
                        .font(.kindredHeading2())
                        .foregroundColor(.kindredTextPrimary)

                    Text("This card has finished loading and shows real content.")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.kindredBackground)
    }
}
#endif
