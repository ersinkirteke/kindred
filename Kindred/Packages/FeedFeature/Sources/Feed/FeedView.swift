import ComposableArchitecture
import DesignSystem
import MonetizationFeature
import SwiftUI

public struct FeedView: View {
    @Bindable var store: StoreOf<FeedReducer>
    @Namespace private var heroNamespace

    public init(store: StoreOf<FeedReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            feedContent
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        locationPill
                    }
                }
                .sheet(isPresented: Binding(
                    get: { store.showLocationPicker },
                    set: { newValue in
                        if !newValue { store.send(.dismissLocationPicker) }
                    }
                )) {
                    LocationPickerView(store: store)
                }
                .navigationDestination(item: $store.scope(state: \.recipeDetail, action: \.recipeDetail)) { detailStore in
                    if #available(iOS 18.0, *) {
                        RecipeDetailView(store: detailStore)
                            .navigationTransition(.zoom(sourceID: detailStore.recipeId, in: heroNamespace))
                    } else {
                        RecipeDetailView(store: detailStore)
                    }
                }
                .onChange(of: store.location) { oldValue, newValue in
                    // VoiceOver announcement on location change
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Now showing recipes near \(newValue)"
                    )
                }
                .onChange(of: store.cardStack) { oldStack, newStack in
                    // VoiceOver announcement on card transitions
                    if let topCard = newStack.first, !newStack.isEmpty {
                        let currentIndex = 1
                        let total = newStack.count
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: "Recipe \(currentIndex) of \(total), \(topCard.name)"
                        )
                    }
                }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var feedContent: some View {
        ZStack {
            Color.kindredBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if store.isOffline {
                    offlineBanner
                }
                if store.hasNewRecipes {
                    newRecipesBanner
                }
                contentView
            }
        }
        .onShake {
            store.send(.undoLastSwipe)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            loadingViewWithChips
        } else if store.error != nil {
            ErrorStateView.networkError {
                store.send(.onAppear)
            }
        } else if store.cardStack.isEmpty {
            emptyStateView
        } else {
            mainFeedView
        }
    }

    private var mainFeedView: some View {
        VStack(spacing: KindredSpacing.lg) {
            Spacer()
                .frame(height: KindredSpacing.md)

            // DNA Activation Card (appears once when crossing 50 interactions)
            if store.showDNAActivationCard {
                DNAActivationCard {
                    store.send(.dismissDNAActivationCard)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Card count indicator
            CardCountIndicator(
                current: 1,
                total: store.cardStack.count
            )

            // Dietary chip bar
            DietaryChipBar(
                activeFilters: store.activeDietaryFilters,
                onFilterChanged: { filters in
                    store.send(.dietaryFilterChanged(filters))
                }
            )
            .contentShape(Rectangle())
            .zIndex(1)
            .padding(.bottom, KindredSpacing.sm)

            // Card stack
            SwipeCardStack(
                cards: store.cardStack,
                heroNamespace: heroNamespace,
                isPersonalized: isRecipePersonalized,
                onSwipe: { recipeId, direction in
                    store.send(.swipeCard(recipeId, direction))
                },
                onTap: { recipeId in
                    store.send(.openRecipeDetail(recipeId))
                },
                adFrequency: store.shouldShowAds ? 5 : nil,
                onAdUpgradeTapped: {
                    store.send(.showPaywall)
                }
            )

            // Action buttons
            actionButtons

            Spacer()
        }
    }

    private func isRecipePersonalized(_ recipe: RecipeCard) -> Bool {
        guard store.isDNAActivated else { return false }
        let topCuisines = Set(store.culinaryDNAAffinities.prefix(3).map(\.cuisineType))
        return recipe.cuisineType.map { topCuisines.contains($0) } ?? false
    }

    private var actionButtons: some View {
        HStack(spacing: KindredSpacing.lg) {
            // Skip button
            Button {
                if let topCard = store.cardStack.first {
                    store.send(.swipeCard(topCard.id, .left))
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.kindredAccent)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredCardSurface)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Skip")
            .accessibilityHint("Skip this recipe - or swipe left")

            // Listen button
            Button {
                if let topCard = store.cardStack.first {
                    store.send(.openRecipeDetail(topCard.id))
                }
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.kindredAccent)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredCardSurface)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Listen")
            .accessibilityHint("Double tap to listen to this recipe")

            // Bookmark button
            Button {
                if let topCard = store.cardStack.first {
                    store.send(.swipeCard(topCard.id, .right))
                }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredAccent)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Bookmark")
            .accessibilityHint("Save this recipe - or swipe right")
        }
        .padding(.horizontal, KindredSpacing.xl)
    }

    private var loadingViewWithChips: some View {
        VStack(spacing: KindredSpacing.lg) {
            // Show chip bar during loading so users see their active filters
            DietaryChipBar(
                activeFilters: store.activeDietaryFilters,
                onFilterChanged: { filters in
                    store.send(.dietaryFilterChanged(filters))
                }
            )
            .padding(.top, KindredSpacing.md)

            ScrollView {
                VStack(spacing: KindredSpacing.lg) {
                    ForEach(0..<3, id: \.self) { _ in
                        skeletonCard
                    }
                }
                .padding(.horizontal, KindredSpacing.md)
                .padding(.vertical, KindredSpacing.lg)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: KindredSpacing.lg) {
            // Show chip bar in empty state
            DietaryChipBar(
                activeFilters: store.activeDietaryFilters,
                onFilterChanged: { filters in
                    store.send(.dietaryFilterChanged(filters))
                }
            )
            .padding(.top, KindredSpacing.md)

            Spacer()

            // Empty state message
            if !store.activeDietaryFilters.isEmpty {
                // Filtered empty state
                VStack(spacing: KindredSpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.kindredTextSecondary)

                    Text("No \(filterDescription) recipes nearby")
                        .font(.kindredHeading2())
                        .foregroundColor(.kindredTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Try removing a filter or changing your location")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                        .multilineTextAlignment(.center)

                    KindredButton("Clear Filters", style: .secondary) {
                        store.send(.dietaryFilterChanged([]))
                    }
                    .padding(.top, KindredSpacing.sm)
                }
                .padding(.horizontal, KindredSpacing.xl)
            } else {
                // Default empty state (no recipes in location)
                EndOfStackCard {
                    store.send(.toggleLocationPicker)
                }
            }

            Spacer()
        }
    }

    private var filterDescription: String {
        let sortedFilters = store.activeDietaryFilters.sorted()
        if sortedFilters.count == 1 {
            return sortedFilters[0].lowercased()
        } else if sortedFilters.count == 2 {
            return "\(sortedFilters[0].lowercased()) and \(sortedFilters[1].lowercased())"
        } else {
            let allButLast = sortedFilters.dropLast().map { $0.lowercased() }.joined(separator: ", ")
            let last = sortedFilters.last!.lowercased()
            return "\(allButLast), and \(last)"
        }
    }

    private var skeletonCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                // Image area placeholder (16:9 ratio)
                Rectangle()
                    .fill(Color.kindredDivider)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)

                // Title line
                Text("Recipe Title Placeholder Text")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)

                // Subtitle line
                Text("Recipe description that shows placeholder content")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)

                // Metadata row
                HStack {
                    Text("30 min")
                        .font(.kindredCaption())
                    Text("•")
                        .font(.kindredCaption())
                    Text("Medium")
                        .font(.kindredCaption())
                }
                .foregroundColor(.kindredTextSecondary)
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }

    private var locationPill: some View {
        HStack(spacing: KindredSpacing.xs) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))

            Text(store.location)
                .font(.kindredBody())
                .fontWeight(.medium)
        }
        .foregroundColor(.kindredTextPrimary)
        .padding(.horizontal, KindredSpacing.sm)
        .padding(.vertical, KindredSpacing.xs)
        .background(
            Capsule()
                .fill(Color.kindredCardSurface)
        )
        .onTapGesture {
            store.send(.toggleLocationPicker)
        }
        .accessibilityLabel("Location: \(store.location)")
        .accessibilityHint("Tap to change location")
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("You're offline — showing cached recipes")
                .font(.kindredCaption())
        }
        .foregroundColor(.white)
        .padding(.vertical, KindredSpacing.xs)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }

    private var newRecipesBanner: some View {
        HStack {
            Image(systemName: "arrow.clockwise.circle.fill")
            Text("New recipes available — pull to refresh")
                .font(.kindredCaption())
        }
        .foregroundColor(.kindredTextPrimary)
        .padding(.vertical, KindredSpacing.xs)
        .frame(maxWidth: .infinity)
        .background(Color.kindredAccent.opacity(0.2))
        .onTapGesture {
            store.send(.acknowledgeNewRecipes)
        }
        .accessibilityLabel("New recipes available")
        .accessibilityHint("Pull down to refresh")
    }
}
