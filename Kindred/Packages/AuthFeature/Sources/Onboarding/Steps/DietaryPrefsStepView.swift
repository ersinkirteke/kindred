import SwiftUI
import ComposableArchitecture
import DesignSystem

struct DietaryPrefsStepView: View {
    let store: StoreOf<OnboardingReducer>

    // Dietary preference options
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

    var body: some View {
        VStack(spacing: 0) {
            // Skip button at top-right
            HStack {
                Spacer()
                Button {
                    store.send(.skipStep)
                } label: {
                    Text(String(localized: "Skip"))
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.top, KindredSpacing.md)
                .accessibilityLabel(String(localized: "accessibility.onboarding_dietary.skip"))
            }

            Spacer(minLength: 60)

            // Heading
            Text(String(localized: "onboarding.dietary.title"))
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.xs)

            // Subheading
            Text(String(localized: "onboarding.dietary.subtitle"))
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
                            label: option,
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
            KindredButton(String(localized: "Next"), style: .primary) {
                store.send(.nextStep)
            }
            .padding(.horizontal, KindredSpacing.lg)
            .padding(.bottom, KindredSpacing.xl)
            .accessibilityLabel(String(localized: "accessibility.onboarding_dietary.next"))
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
        .accessibilityLabel("\(label), \(isSelected ? String(localized: "accessibility.state.selected") : String(localized: "accessibility.state.not_selected"))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(String(localized: isSelected ? "accessibility.hint.deselect" : "accessibility.hint.select"))
    }
}
