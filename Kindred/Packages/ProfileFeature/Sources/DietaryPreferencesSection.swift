import DesignSystem
import SwiftUI

/// Section displaying dietary preference chips with reset functionality.
///
/// Chips use the same styling as the feed chip bar:
/// - Active: filled terracotta background with white text
/// - Inactive: clear background with terracotta outline and text
///
/// The "Reset Dietary Preferences" button only appears when preferences are non-empty.
public struct DietaryPreferencesSection: View {
    let activePreferences: Set<String>
    let onPreferencesChanged: (Set<String>) -> Void
    let onReset: () -> Void

    public init(
        activePreferences: Set<String>,
        onPreferencesChanged: @escaping (Set<String>) -> Void,
        onReset: @escaping () -> Void
    ) {
        self.activePreferences = activePreferences
        self.onPreferencesChanged = onPreferencesChanged
        self.onReset = onReset
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            Text(String(localized: "profile.dietary_prefs.title", bundle: .main))
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)

            // Dietary chips
            DietaryChipsGrid(
                activeFilters: activePreferences,
                onFilterChanged: onPreferencesChanged
            )

            // Reset button (only visible when preferences are non-empty)
            if !activePreferences.isEmpty {
                Button {
                    onReset()
                } label: {
                    Text(String(localized: "profile.dietary_prefs.reset", bundle: .main))
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(.top, KindredSpacing.xs)
            }
        }
        .padding(KindredSpacing.md)
        .background(Color.kindredCardSurface)
        .cornerRadius(12)
    }
}

// MARK: - DietaryChipsGrid Component

private struct DietaryChipsGrid: View {
    let activeFilters: Set<String>
    let onFilterChanged: (Set<String>) -> Void

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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stride(from: 0, to: dietaryTags.count, by: 2)), id: \.self) { index in
                HStack(spacing: 8) {
                    DietaryChipView(
                        title: localizedName(for: dietaryTags[index]),
                        isSelected: activeFilters.contains(dietaryTags[index]),
                        onTap: {
                            toggleFilter(dietaryTags[index])
                        }
                    )

                    if index + 1 < dietaryTags.count {
                        DietaryChipView(
                            title: localizedName(for: dietaryTags[index + 1]),
                            isSelected: activeFilters.contains(dietaryTags[index + 1]),
                            onTap: {
                                toggleFilter(dietaryTags[index + 1])
                            }
                        )
                    }

                    Spacer()
                }
            }
        }
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
}

// MARK: - DietaryChipView (Profile-specific)

private struct DietaryChipView: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .kindredAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 44) // Ensure 44pt tappable height
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.kindredAccent : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.kindredAccent, lineWidth: isSelected ? 0 : 1.5)
                    )
            )
            .onTapGesture(perform: onTap)
            .accessibilityLabel(title)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(String(localized: isSelected ? "accessibility.hint.remove_filter \(title)" : "accessibility.hint.add_filter \(title)"))
    }
}
