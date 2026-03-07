import DesignSystem
import MonetizationFeature
import SwiftUI

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

    var body: some View {
        ZStack {
            // Show next card/ad behind current for smooth transition
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
                }
            } else if cards.count > 1 {
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
                    .transition(.asymmetric(
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
                        print("🃏 [Stack] onSwipe received: \(card.id) \(direction)")
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
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(height: 400)
    }
}
