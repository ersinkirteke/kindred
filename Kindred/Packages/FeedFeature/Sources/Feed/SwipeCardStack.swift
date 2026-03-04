import DesignSystem
import SwiftUI

struct SwipeCardStack: View {
    let cards: [RecipeCard]
    let heroNamespace: Namespace.ID
    let isPersonalized: (RecipeCard) -> Bool
    let onSwipe: (String, SwipeDirection) -> Void
    let onTap: (String) -> Void

    var body: some View {
        ZStack {
            // Show next card behind current for smooth transition
            if cards.count > 1 {
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

            if let card = cards.first {
                RecipeCardView(
                    recipe: card,
                    heroNamespace: heroNamespace,
                    isPersonalized: isPersonalized(card),
                    onSwipe: { direction in
                        print("🃏 [Stack] onSwipe received: \(card.id) \(direction)")
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
