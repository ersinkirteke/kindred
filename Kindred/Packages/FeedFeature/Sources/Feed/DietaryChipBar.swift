import DesignSystem
import SwiftUI

struct DietaryChipBar: View {
    let activeFilters: Set<String>
    let onFilterChanged: (Set<String>) -> Void

    private let dietaryTags = ["Vegan", "Vegetarian", "Gluten-Free", "Dairy-Free", "Keto", "Halal", "Nut-Free", "Kosher", "Low-Carb", "Pescatarian"]

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.xs) {
            // Horizontal scrollable chip bar
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
                                .frame(width: 44, height: 44) // 44pt tappable area
                        }
                        .accessibilityLabel("Clear all dietary filters")
                    }
                }
                .padding(.horizontal, 16)
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
