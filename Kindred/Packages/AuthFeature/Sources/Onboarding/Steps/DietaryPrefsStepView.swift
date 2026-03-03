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
                    Text("Skip")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.top, KindredSpacing.md)
                .accessibilityLabel("Skip dietary preferences")
            }

            Spacer(minLength: 60)

            // Heading
            Text("What do you eat?")
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.xs)

            // Subheading
            Text("Select any that apply")
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
            KindredButton("Next", style: .primary) {
                store.send(.nextStep)
            }
            .padding(.horizontal, KindredSpacing.lg)
            .padding(.bottom, KindredSpacing.xl)
            .accessibilityLabel("Continue to next step")
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
        .accessibilityLabel("\(label), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }
}
