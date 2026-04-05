import SwiftUI
import Kingfisher
import DesignSystem

// MARK: - Parallax Header

struct ParallaxHeader: View {

    let imageUrl: String?
    let recipeName: String
    let popularityScore: Int?
    let height: CGFloat = 300

    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let scaleFactor = max(1, 1 + (offset > 0 ? offset / height : 0))

            ZStack(alignment: .topLeading) {
                // Hero image with parallax effect
                if let urlString = imageUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            Rectangle()
                                .fill(Color.kindredCardSurface)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
                                )
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: height * scaleFactor
                        )
                        .offset(y: offset > 0 ? -offset : offset * 0.5)  // Parallax: move at 0.5x speed
                        .clipped()
                        .accessibilityLabel(String(localized: "Photo of \(recipeName)", bundle: .main))
                } else {
                    // Fallback if no image
                    Rectangle()
                        .fill(Color.kindredCardSurface)
                        .frame(width: geometry.size.width, height: height)
                        .accessibilityLabel(String(localized: "Photo of \(recipeName)", bundle: .main))
                }

                // Bottom gradient for readability
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.4), Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                }

                // Popularity badge overlay
                if let score = popularityScore, score >= 50 {
                    PopularityBadge(percentage: score)
                        .padding(KindredSpacing.md)
                }
            }
        }
        .frame(height: height)
    }
}

