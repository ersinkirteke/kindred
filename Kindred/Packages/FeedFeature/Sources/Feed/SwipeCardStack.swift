import DesignSystem
import SwiftUI

struct SwipeCardStack: View {
    let cards: [RecipeCard]
    let onSwipe: (String, SwipeDirection) -> Void
    let onTap: (String) -> Void
    var body: some View {
        ZStack {
            // Only render top 3 cards for performance
            ForEach(Array(cards.prefix(3).enumerated()), id: \.element.id) { index, card in
                RecipeCardView(
                    recipe: card,
                    onSwipe: { direction in
                        onSwipe(card.id, direction)
                    },
                    onTap: {
                        onTap(card.id)
                    }
                )
                .scaleEffect(scaleForCard(at: index))
                .offset(y: offsetForCard(at: index))
                .zIndex(Double(cards.count - index))
                .allowsHitTesting(index == 0) // Only top card is interactive
                .id(card.id)
            }
        }
    }

    private func scaleForCard(at index: Int) -> CGFloat {
        switch index {
        case 0:
            return 1.0
        case 1:
            return 0.95
        case 2:
            return 0.9
        default:
            return 0.85
        }
    }

    private func offsetForCard(at index: Int) -> CGFloat {
        switch index {
        case 0:
            return 0
        case 1:
            return 10
        case 2:
            return 20
        default:
            return 30
        }
    }
}
