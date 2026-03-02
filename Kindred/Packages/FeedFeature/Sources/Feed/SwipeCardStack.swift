import DesignSystem
import SwiftUI

struct SwipeCardStack: View {
    let cards: [RecipeCard]
    let heroNamespace: Namespace.ID
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
                    onSwipe: { direction in
                        onSwipe(card.id, direction)
                    },
                    onTap: {
                        onTap(card.id)
                    }
                )
                .id(card.id)
            }
        }
        .frame(height: 400)
    }
}
