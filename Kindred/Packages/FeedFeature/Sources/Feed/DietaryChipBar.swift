import DesignSystem
import SwiftUI

struct DietaryChipBar: View {
    let activeFilters: Set<String>
    let onFilterChanged: (Set<String>) -> Void
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private let dietaryTags = ["Vegan", "Vegetarian", "Gluten-Free", "Dairy-Free", "Keto", "Halal", "Nut-Free", "Kosher", "Low-Carb", "Pescatarian"]

    private func localizedName(for tag: String) -> String {
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

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.xs) {
            // At AX sizes: wrapping layout; otherwise: horizontal scroll
            if dynamicTypeSize.isAccessibilitySize {
                // Wrapping vertical flow layout for accessibility sizes
                FlowLayout(spacing: 8) {
                    ForEach(dietaryTags, id: \.self) { tag in
                        DietaryChip(
                            title: localizedName(for: tag),
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
                        .accessibilityLabel(String(localized: "accessibility.dietary_filter.clear_all", bundle: .main))
                    }
                }
                .padding(.horizontal, 16)
            } else {
                // Horizontal scrollable chip bar for normal sizes
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dietaryTags, id: \.self) { tag in
                            DietaryChip(
                                title: localizedName(for: tag),
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
                            .accessibilityLabel(String(localized: "accessibility.dietary_filter.clear_all", bundle: .main))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Filter count text below chips (when filters active)
            if !activeFilters.isEmpty {
                Text(String(localized: "feed.showing_filtered_recipes \(chipDescription)", bundle: .main))
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
        let connector = String(localized: "feed.list_connector", bundle: .main)
        let sortedFilters = activeFilters.sorted().map { localizedName(for: $0) }
        if sortedFilters.count == 1 {
            return sortedFilters[0]
        } else if sortedFilters.count == 2 {
            return "\(sortedFilters[0]) \(connector) \(sortedFilters[1])"
        } else {
            let allButLast = sortedFilters.dropLast().joined(separator: ", ")
            let last = sortedFilters.last!
            return "\(allButLast), \(connector) \(last)"
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
