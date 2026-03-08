import DesignSystem
import MonetizationFeature
import SwiftUI
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    fileprivate static let swipeStack = Logger(subsystem: subsystem, category: "swipe-stack")
}

struct SwipeCardStack: View {
    let cards: [RecipeCard]
    let heroNamespace: Namespace.ID
    let isPersonalized: (RecipeCard) -> Bool
    let onSwipe: (String, SwipeDirection) -> Void
    let onTap: (String) -> Void
    let adFrequency: Int?
    let onAdUpgradeTapped: () -> Void

    @State private var swipeCount: Int = 0
    @State private var showingAd: Bool = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        ZStack {
            // Show next card/ad behind current for smooth transition (single card mode at AX sizes)
            if showingAd {
                // Next card shows behind ad
                if let nextCard = cards.first {
                    RecipeCardView(
                        recipe: nextCard,
                        heroNamespace: heroNamespace,
                        isPersonalized: isPersonalized(nextCard),
                        onSwipe: { _ in },
                        onTap: { }
                    )
                    .id(nextCard.id)
                    .allowsHitTesting(false)
                    .opacity(dynamicTypeSize.isAccessibilitySize ? 0 : 1) // Hide peeking card at AX sizes
                }
            } else if cards.count > 1 && !dynamicTypeSize.isAccessibilitySize {
                // Only show peeking card at non-AX sizes (single card mode at AX1+)
                let nextCard = cards[1]
                RecipeCardView(
                    recipe: nextCard,
                    heroNamespace: heroNamespace,
                    isPersonalized: isPersonalized(nextCard),
                    onSwipe: { _ in },
                    onTap: { }
                )
                .id(nextCard.id)
                .allowsHitTesting(false)
            }

            // Top card: either ad or recipe
            if showingAd {
                AdCardView(onUpgradeTapped: onAdUpgradeTapped)
                    .frame(width: 340, height: 400)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                // Only dismiss ad on left swipe
                                if value.translation.width < -100 {
                                    withAnimation {
                                        showingAd = false
                                    }
                                }
                            }
                    )
            } else if let card = cards.first {
                RecipeCardView(
                    recipe: card,
                    heroNamespace: heroNamespace,
                    isPersonalized: isPersonalized(card),
                    onSwipe: { direction in
                        Logger.swipeStack.debug("onSwipe received: \(card.id, privacy: .private) \(String(describing: direction), privacy: .public)")
                        // Increment swipe count after recipe card swipe
                        swipeCount += 1
                        // Check if we should show ad after this swipe
                        if let frequency = adFrequency, swipeCount > 0, swipeCount % frequency == 0 {
                            withAnimation {
                                showingAd = true
                            }
                        }
                        onSwipe(card.id, direction)
                    },
                    onTap: {
                        onTap(card.id)
                    }
                )
                .id(card.id)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(height: 400)
    }
}
