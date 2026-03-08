import DesignSystem
import SwiftUI

struct DietaryChipBar: View {
    let activeFilters: Set<String>
    let onFilterChanged: (Set<String>) -> Void
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private let dietaryTags = ["Vegan", "Vegetarian", "Gluten-Free", "Dairy-Free", "Keto", "Halal", "Nut-Free", "Kosher", "Low-Carb", "Pescatarian"]

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.xs) {
            // At AX sizes: wrapping layout; otherwise: horizontal scroll
            if dynamicTypeSize.isAccessibilitySize {
                // Wrapping vertical flow layout for accessibility sizes
                FlowLayout(spacing: 8) {
                    ForEach(dietaryTags, id: \.self) { tag in
                        DietaryChip(
                            title: tag,
                            isSelected: activeFilters.contains(tag),
                            onTap: {
                                toggleFilter(tag)
                            }
                        )
                    }

                    // Clear-all "X" chip when filters are active
                    if !activeFilters.isEmpty {
                        Button {
                            onFilterChanged([])
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Clear all dietary filters")
                    }
                }
                .padding(.horizontal, 16)
            } else {
                // Horizontal scrollable chip bar for normal sizes
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dietaryTags, id: \.self) { tag in
                            DietaryChip(
                                title: tag,
                                isSelected: activeFilters.contains(tag),
                                onTap: {
                                    toggleFilter(tag)
                                }
                            )
                        }

                        // Clear-all "X" chip when filters are active
                        if !activeFilters.isEmpty {
                            Button {
                                onFilterChanged([])
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Clear all dietary filters")
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Filter count text below chips (when filters active)
            if !activeFilters.isEmpty {
                Text("Showing \(chipDescription) recipes")
                    .font(.kindredCaption())
                    .foregroundColor(.kindredTextSecondary)
                    .padding(.horizontal, 16)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func toggleFilter(_ tag: String) {
        var newFilters = activeFilters
        if newFilters.contains(tag) {
            newFilters.remove(tag)
        } else {
            newFilters.insert(tag)
        }
        onFilterChanged(newFilters)
    }

    private var chipDescription: String {
        let sortedFilters = activeFilters.sorted()
        if sortedFilters.count == 1 {
            return sortedFilters[0]
        } else if sortedFilters.count == 2 {
            return "\(sortedFilters[0]) and \(sortedFilters[1])"
        } else {
            let allButLast = sortedFilters.dropLast().joined(separator: ", ")
            let last = sortedFilters.last!
            return "\(allButLast), and \(last)"
        }
    }
}

// MARK: - FlowLayout for wrapping chips at AX sizes

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
