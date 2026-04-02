import SwiftUI
import ComposableArchitecture
import DesignSystem

struct DietaryPrefsStepView: View {
    let store: StoreOf<OnboardingReducer>

    // Dietary preference options (English keys used as identifiers)
    private let dietaryOptions = [
        "Vegetarian",
        "Vegan",
        "Gluten-Free",
        "Keto",
        "Halal",
        "Kosher",
        "Dairy-Free",
        "Nut-Free",
        "Low-Carb",
        "Pescatarian"
    ]

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
        VStack(spacing: 0) {
            // Skip button at top-right
            HStack {
                Spacer()
                Button {
                    store.send(.skipStep)
                } label: {
                    Text(String(localized: "Skip", bundle: .main))
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.top, KindredSpacing.md)
                .accessibilityLabel(String(localized: "accessibility.onboarding_dietary.skip", bundle: .main))
            }

            Spacer(minLength: 60)

            // Personalized greeting
            Group {
                if let firstName = store.firstName, !firstName.isEmpty {
                    Text("Welcome, \(firstName)! Let's personalize your feed")
                } else {
                    Text("Welcome! Let's personalize your feed")
                }
            }
            .font(.kindredHeading1())
            .foregroundColor(.kindredTextPrimary)
            .multilineTextAlignment(.center)
            .padding(.bottom, KindredSpacing.xs)

            // Subheading
            Text(String(localized: "onboarding.dietary.subtitle", bundle: .main))
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.xl)

            // Chip grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: KindredSpacing.md),
                    GridItem(.flexible(), spacing: KindredSpacing.md)
                ], spacing: KindredSpacing.md) {
                    ForEach(dietaryOptions, id: \.self) { option in
                        DietaryChip(
                            label: localizedName(for: option),
                            isSelected: store.selectedDietaryPrefs.contains(option)
                        ) {
                            store.send(.toggleDietaryPref(option))
                        }
                    }
                }
                .padding(.horizontal, KindredSpacing.lg)
            }

            Spacer()

            // Next button
            KindredButton(String(localized: "Next", bundle: .main), style: .primary) {
                store.send(.nextStep)
            }
            .padding(.horizontal, KindredSpacing.lg)
            .padding(.bottom, KindredSpacing.xl)
            .accessibilityLabel(String(localized: "accessibility.onboarding_dietary.next", bundle: .main))
        }
        .background(Color.kindredBackground)
    }
}

// MARK: - Dietary Chip Component

struct DietaryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.kindredBody())
                .foregroundColor(isSelected ? .white : .kindredAccent)
                .padding(.horizontal, KindredSpacing.md)
                .frame(minWidth: 56, minHeight: 56) // WCAG AAA touch target
                .background(isSelected ? Color.kindredAccent : Color.clear)
                .cornerRadius(28) // Pill shape
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.kindredAccent, lineWidth: 2)
                )
        }
        .accessibilityLabel("\(label), \(isSelected ? String(localized: "accessibility.state.selected", bundle: .main) : String(localized: "accessibility.state.not_selected", bundle: .main))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(String(localized: isSelected ? "accessibility.hint.deselect" : "accessibility.hint.select"))
    }
}
