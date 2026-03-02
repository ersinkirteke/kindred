import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct ProfileView: View {
    let store: StoreOf<ProfileReducer>

    public init(store: StoreOf<ProfileReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: KindredSpacing.xl) {
                switch store.authState {
                case .guest:
                    guestSignInGate
                case .authenticated:
                    // Placeholder - authenticated profile in Phase 8
                    Text("Profile")
                        .font(.kindredHeading1())
                        .foregroundColor(.kindredTextPrimary)
                }

                // Dietary Preferences section (available for both guest and authenticated)
                dietaryPreferencesSection
                    .padding(.horizontal, KindredSpacing.lg)
            }
            .padding(.vertical, KindredSpacing.lg)
        }
        .background(Color.kindredBackground)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var guestSignInGate: some View {
        VStack(spacing: KindredSpacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.kindredAccentDecorative)

            // Message
            VStack(spacing: KindredSpacing.sm) {
                Text("Sign in to access your profile")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Save recipes, customize voice settings, and more")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Sign In button
            VStack(spacing: KindredSpacing.md) {
                KindredButton("Sign In", style: .primary) {
                    store.send(.signInTapped)
                }

                Button {
                    store.send(.continueAsGuestTapped)
                } label: {
                    Text("Continue as Guest")
                        .font(.kindredBody())
                        .foregroundColor(.kindredAccent)
                }
            }
            .padding(.horizontal, KindredSpacing.xl)

            Spacer()
        }
        .padding(.horizontal, KindredSpacing.lg)
    }

    private var dietaryPreferencesSection: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            Text("Dietary Preferences")
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)

            // Dietary chips
            DietaryChipsGrid(
                activeFilters: store.dietaryPreferences,
                onFilterChanged: { preferences in
                    store.send(.dietaryPreferencesChanged(preferences))
                }
            )

            // Reset button (only visible when preferences are non-empty)
            if !store.dietaryPreferences.isEmpty {
                Button {
                    store.send(.resetDietaryPreferences)
                } label: {
                    Text("Reset Dietary Preferences")
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

    private let dietaryTags = ["Vegan", "Vegetarian", "Gluten-free", "Dairy-free", "Keto", "Halal", "Nut-free"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stride(from: 0, to: dietaryTags.count, by: 2)), id: \.self) { index in
                HStack(spacing: 8) {
                    DietaryChipView(
                        title: dietaryTags[index],
                        isSelected: activeFilters.contains(dietaryTags[index]),
                        onTap: {
                            toggleFilter(dietaryTags[index])
                        }
                    )

                    if index + 1 < dietaryTags.count {
                        DietaryChipView(
                            title: dietaryTags[index + 1],
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
            .accessibilityHint("Double tap to \(isSelected ? "remove" : "add") \(title) filter")
    }
}
