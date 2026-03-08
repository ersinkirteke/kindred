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
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // @ScaledMetric for Dynamic Type support
    @ScaledMetric(relativeTo: .title2) private var heading2Size: CGFloat = 22
    @ScaledMetric(relativeTo: .headline) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = 14
    @ScaledMetric(relativeTo: .headline) private var buttonSize: CGFloat = 56

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Scrollable card for accessibility sizes
                ScrollView {
                    cardContent
                }
                .frame(width: 340, height: 400)
            } else {
                // Fixed height for normal sizes
                cardContent
                    .frame(width: 340, height: 400)
            }
        }
        .padding(.horizontal, KindredSpacing.xl)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onTap()
                }
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { gesture in
                    offset = CGSize(
                        width: gesture.translation.width,
                        height: gesture.translation.height * 0.4
                    )
                    rotation = Double(gesture.translation.width) / 10.0
                }
                .onEnded { gesture in
                    let actualWidth = abs(gesture.translation.width)
                    let predictedWidth = abs(gesture.predictedEndTranslation.width)
                    let swipeDetected = actualWidth > 80 || predictedWidth > 150

                    if swipeDetected {
                        let direction: SwipeDirection = gesture.translation.width > 0 ? .right : .left
                        // Animate the card off-screen, then call onSwipe
                        let flyOutX: CGFloat = direction == .right ? 500 : -500
                        withAnimation(.easeIn(duration: 0.2)) {
                            offset = CGSize(width: flyOutX, height: 0)
                            rotation = Double(flyOutX) / 10.0
                        }
                        // Fire the swipe action after the animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            onSwipe(direction)
                        }
                    } else {
                        // Reduce Motion: use linear animation instead of spring
                        let animation: Animation = reduceMotion ? .linear(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.6)
                        withAnimation(animation) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAction(named: String(localized: "Bookmark", bundle: .main)) {
            onSwipe(.right)
        }
        .accessibilityAction(named: String(localized: "Skip", bundle: .main)) {
            onSwipe(.left)
        }
        .accessibilityAction(named: String(localized: "View details", bundle: .main)) {
            onTap()
        }
    }

    private var cardContent: some View {
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

            // Recipe details with padding (no fixed height - grows to fit)
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                Text(recipe.name)
                    .font(.kindredHeading2Scaled(size: heading2Size))
                    .foregroundColor(.kindredTextPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                Text(recipe.description ?? " ")
                    .font(.kindredBodyScaled(size: bodySize))
                    .foregroundColor(.kindredTextSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                metadataRow
            }
            .padding(KindredSpacing.md)
            .frame(minHeight: 120, alignment: .top)
        }
        .background(Color.kindredCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.kindredTextSecondary.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
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
                .accessibilityLabel(String(localized: "Photo of \(recipe.name)", bundle: .main))
        } else {
            Rectangle()
                .fill(Color.kindredDivider)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48))
                        .foregroundColor(.kindredTextSecondary)
                )
                .accessibilityLabel(String(localized: "Photo of \(recipe.name)", bundle: .main))
        }
    }

    private var metadataRow: some View {
        HStack(spacing: KindredSpacing.sm) {
            // Time
            if let totalTime = recipe.totalTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: iconSize))
                    Text(String(localized: "\(totalTime) min", bundle: .main))
                }
            }

            // Calories
            if let calories = recipe.calories {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: iconSize))
                    Text(String(localized: "\(calories) cal", bundle: .main))
                }
            }

            // Loves count
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: iconSize))
                Text(recipe.formattedLoves)
            }
        }
        .font(.kindredCaptionScaled(size: captionSize))
        .foregroundColor(.kindredTextSecondary)
    }

    private var accessibilityLabelText: String {
        var label = recipe.name

        if let time = recipe.totalTime {
            label += String(localized: ", \(time) minutes", bundle: .main)
        }

        if let calories = recipe.calories {
            label += String(localized: ", \(calories) calories", bundle: .main)
        }

        if recipe.isViral {
            label += String(localized: ", Viral recipe", bundle: .main)
        }

        if isPersonalized {
            label += String(localized: ", Personalized for you", bundle: .main)
        }

        return label
    }
}
