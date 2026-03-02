import DesignSystem
import Kingfisher
import SwiftUI

struct RecipeCardView: View {
    let recipe: RecipeCard
    let heroNamespace: Namespace.ID
    let isPersonalized: Bool
    let onSwipe: (SwipeDirection) -> Void
    let onTap: () -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image using overlay pattern to prevent fill image layout overflow
            Color.clear
                .frame(height: 280)
                .overlay {
                    if #available(iOS 18.0, *) {
                        heroImageView
                            .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                    } else {
                        heroImageView
                    }
                }
                .clipped()
                .overlay(alignment: .topTrailing) {
                    if recipe.isViral {
                        ViralBadge()
                            .padding(KindredSpacing.md)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if isPersonalized {
                        ForYouBadge()
                            .padding(KindredSpacing.md)
                    }
                }

            // Recipe details with padding
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                Text(recipe.name)
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)
                    .lineLimit(2)

                Text(recipe.description ?? " ")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .lineLimit(2)

                metadataRow
            }
            .padding(KindredSpacing.md)
            .frame(height: 120, alignment: .top)
        }
        .background(Color.kindredCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.kindredTextSecondary.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        .frame(width: 340, height: 400)
        .padding(.horizontal, KindredSpacing.xl)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = CGSize(
                        width: gesture.translation.width,
                        height: gesture.translation.height * 0.4 // Dampened vertical
                    )
                    rotation = Double(gesture.translation.width) / 10.0
                }
                .onEnded { gesture in
                    let threshold: CGFloat = 200
                    let swipeDistance = abs(gesture.translation.width)

                    if swipeDistance > threshold {
                        // Swipe successful - animate off screen
                        let direction: SwipeDirection = gesture.translation.width > 0 ? .right : .left
                        let finalOffset = gesture.translation.width > 0 ? 500.0 : -500.0

                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = CGSize(width: finalOffset, height: offset.height)
                        } completion: {
                            onSwipe(direction)
                        }
                    } else {
                        // Snap back with spring animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAction(named: "Bookmark") {
            onSwipe(.right)
        }
        .accessibilityAction(named: "Skip") {
            onSwipe(.left)
        }
        .accessibilityAction(named: "View details") {
            onTap()
        }
    }

    @ViewBuilder
    private var heroImageView: some View {
        if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl) {
            KFImage(url)
                .placeholder {
                    Rectangle()
                        .fill(Color.kindredDivider)
                        .overlay(
                            ProgressView()
                                .tint(.kindredTextSecondary)
                        )
                }
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color.kindredDivider)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48))
                        .foregroundColor(.kindredTextSecondary)
                )
        }
    }

    private var metadataRow: some View {
        HStack(spacing: KindredSpacing.sm) {
            // Time
            if let totalTime = recipe.totalTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("\(totalTime) min")
                }
            }

            // Calories
            if let calories = recipe.calories {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                    Text("\(calories) cal")
                }
            }

            // Loves count
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                Text(recipe.formattedLoves)
            }
        }
        .font(.kindredCaption())
        .foregroundColor(.kindredTextSecondary)
    }

    private var accessibilityLabelText: String {
        var label = recipe.name

        if let time = recipe.totalTime {
            label += ", \(time) minutes"
        }

        if let calories = recipe.calories {
            label += ", \(calories) calories"
        }

        if recipe.isViral {
            label += ", Viral recipe"
        }

        if isPersonalized {
            label += ", Personalized for you"
        }

        return label
    }
}
