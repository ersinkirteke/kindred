import SwiftUI
import Kingfisher
import DesignSystem

// MARK: - Parallax Header

struct ParallaxHeader: View {

    let imageUrl: String?
    let isViral: Bool
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
                } else {
                    // Fallback if no image
                    Rectangle()
                        .fill(Color.kindredCardSurface)
                        .frame(width: geometry.size.width, height: height)
                }

                // Viral badge overlay
                if isViral {
                    ViralBadge()
                        .padding(KindredSpacing.md)
                }
            }
        }
        .frame(height: height)
    }
}

