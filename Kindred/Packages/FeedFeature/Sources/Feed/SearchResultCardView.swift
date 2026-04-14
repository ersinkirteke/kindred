import DesignSystem
import Kingfisher
import SwiftUI

struct SearchResultCardView: View {
    let recipe: RecipeCard
    let heroNamespace: Namespace.ID
    let onTap: (String) -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var imageLoadFailed = false

    var body: some View {
        if !imageLoadFailed {
            Button {
                onTap(recipe.id)
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabelText)
            .accessibilityAddTraits(.isButton)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image area
            Color.clear
                .frame(height: 200)
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
                    if let popularityScore = recipe.popularityScore, popularityScore >= 50 {
                        PopularityBadge(percentage: popularityScore)
                            .padding(KindredSpacing.sm)
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let matchPercentage = recipe.matchPercentage, matchPercentage >= 50 {
                        MatchBadge(percentage: matchPercentage)
                            .padding(KindredSpacing.sm)
                    }
                }

            // Recipe details
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                Text(recipe.name)
                    .font(.kindredHeading2())
                    .foregroundStyle(.kindredTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let description = recipe.description, !description.isEmpty {
                    Text(description)
                        .font(.kindredBody())
                        .foregroundStyle(.kindredTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                metadataRow

                // Dietary tag badges
                if !recipe.dietaryTags.isEmpty {
                    dietaryTagsRow(tags: recipe.dietaryTags)
                }
            }
            .padding(KindredSpacing.md)
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
        if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl), !imageLoadFailed {
            KFImage(url)
                .placeholder {
                    Rectangle()
                        .fill(Color.kindredDivider)
                        .overlay(
                            ProgressView()
                                .tint(.kindredTextSecondary)
                        )
                }
                .onFailure { _ in imageLoadFailed = true }
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibilityLabel(String(localized: "Photo of \(recipe.name)", bundle: .main))
        } else {
            noImagePlaceholder
        }
    }

    private var noImagePlaceholder: some View {
        Rectangle()
            .fill(Color.kindredDivider)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.system(size: 40))
                    .foregroundStyle(.kindredTextSecondary)
            )
            .accessibilityLabel(String(localized: "Photo of \(recipe.name)", bundle: .main))
    }

    private var metadataRow: some View {
        HStack(spacing: KindredSpacing.sm) {
            if let totalTime = recipe.totalTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                    Text(String(localized: "\(totalTime) min", bundle: .main))
                }
            }

            if let calories = recipe.calories {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: 13))
                    Text(String(localized: "\(calories) cal", bundle: .main))
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                Text(recipe.formattedLoves)
            }
        }
        .font(.kindredCaption())
        .foregroundStyle(.kindredTextSecondary)
    }

    @ViewBuilder
    private func dietaryTagsRow(tags: [String]) -> some View {
        let displayTags = Array(tags.prefix(4)) // show max 4 tags to avoid overflow
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(displayTags, id: \.self) { tag in
                    Text(localizedTagName(for: tag))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.kindredAccent)
                        )
                        .accessibilityLabel(localizedTagName(for: tag))
                }
            }
        }
        .scrollDisabled(displayTags.count <= 3)
    }

    private func localizedTagName(for tag: String) -> String {
        switch tag {
        case "Vegan": return String(localized: "dietary.vegan", bundle: .main)
        case "Vegetarian": return String(localized: "dietary.vegetarian", bundle: .main)
        case "Gluten-Free": return String(localized: "dietary.gluten_free", bundle: .main)
        case "Dairy-Free": return String(localized: "dietary.dairy_free", bundle: .main)
        case "Keto": return String(localized: "dietary.keto", bundle: .main)
        case "Halal": return String(localized: "dietary.halal", bundle: .main)
        case "Nut-Free": return String(localized: "dietary.nut_free", bundle: .main)
        case "Kosher": return String(localized: "dietary.kosher", bundle: .main)
        case "Low-Carb": return String(localized: "dietary.low_carb", bundle: .main)
        case "Pescatarian": return String(localized: "dietary.pescatarian", bundle: .main)
        default: return tag
        }
    }

    private var accessibilityLabelText: String {
        var label = recipe.name

        if let time = recipe.totalTime {
            label += String(localized: ", \(time) minutes", bundle: .main)
        }

        if let calories = recipe.calories {
            label += String(localized: ", \(calories) calories", bundle: .main)
        }

        if !recipe.dietaryTags.isEmpty {
            let tagList = recipe.dietaryTags.prefix(4).map { localizedTagName(for: $0) }.joined(separator: ", ")
            label += ", \(tagList)"
        }

        return label
    }
}
