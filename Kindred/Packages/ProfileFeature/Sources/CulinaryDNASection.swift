import DesignSystem
import FeedFeature
import SwiftUI

/// Section displaying the user's Culinary DNA progress or affinity scores.
///
/// Before activation (< 50 interactions):
/// - Shows progress indicator with "Learning... (X/50 interactions)" message
///
/// After activation (>= 50 interactions):
/// - Shows top 3-5 cuisine affinity bars with percentages
public struct CulinaryDNASection: View {
    let interactionCount: Int
    let affinities: [AffinityScore]
    let threshold: Int

    public init(
        interactionCount: Int,
        affinities: [AffinityScore],
        threshold: Int = 50
    ) {
        self.interactionCount = interactionCount
        self.affinities = affinities
        self.threshold = threshold
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            Text(String(localized: "profile.culinary_dna.title"))
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)

            if interactionCount < threshold {
                // Before activation: progress indicator
                VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                    ProgressView(value: Double(interactionCount), total: Double(threshold))
                        .tint(.kindredAccent)

                    Text(String(localized: "profile.culinary_dna.learning \(interactionCount) \(threshold)"))
                        .font(.kindredCaption())
                        .foregroundColor(.kindredTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "accessibility.profile.culinary_dna_learning \(interactionCount) \(threshold)"))
            } else {
                // After activation: affinity bars
                VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                    ForEach(affinities.prefix(5)) { affinity in
                        AffinityBar(
                            cuisineType: affinity.cuisineType,
                            score: affinity.score
                        )
                    }
                }
            }
        }
        .padding(KindredSpacing.md)
        .background(Color.kindredCardSurface)
        .cornerRadius(12)
    }
}

// MARK: - AffinityBar Component

private struct AffinityBar: View {
    let cuisineType: String
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cuisineType.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.kindredTextPrimary)

                Spacer()

                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .foregroundColor(.kindredTextSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.kindredAccent)
                        .frame(width: geometry.size.width * score, height: 8)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cuisineType.capitalized), \(Int(score * 100)) percent")
    }
}
