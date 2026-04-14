import ComposableArchitecture
import DesignSystem
import MonetizationFeature
import SwiftUI

public struct FeedView: View {
    @Bindable var store: StoreOf<FeedReducer>
    @Namespace private var heroNamespace
    @Environment(\.accessibilityReduceMotion) var reduceMotion

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
                .sheet(item: $store.scope(state: \.paywall, action: \.paywall)) { paywallStore in
                    PaywallView(store: paywallStore)
                }
                .navigationDestination(item: $store.scope(state: \.recipeDetail, action: \.recipeDetail)) { detailStore in
                    recipeDetailDestination(store: detailStore)
                }
                .onChange(of: store.location) { oldValue, newValue in
                    // VoiceOver announcement on location change
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: String(localized: "Now showing recipes near \(newValue)", bundle: .main)
                    )
                }
                .onChange(of: store.cardStack) { oldStack, newStack in
                    // VoiceOver announcement on card transitions
                    if let topCard = newStack.first, !newStack.isEmpty {
                        let currentIndex = 1
                        let total = newStack.count
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: String(localized: "Recipe \(currentIndex) of \(total), \(topCard.name)", bundle: .main)
                        )
                    }
                }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private func recipeDetailDestination(store detailStore: StoreOf<RecipeDetailReducer>) -> some View {
        if #available(iOS 18.0, *) {
            if reduceMotion {
                RecipeDetailView(store: detailStore)
                    .navigationTransition(.automatic)
            } else {
                RecipeDetailView(store: detailStore)
                    .navigationTransition(.zoom(sourceID: detailStore.recipeId, in: heroNamespace))
            }
        } else {
            RecipeDetailView(store: detailStore)
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
        VStack(spacing: 0) {
            // DNA Activation Card (appears once when crossing 50 interactions)
            if store.showDNAActivationCard {
                DNAActivationCard {
                    store.send(.dismissDNAActivationCard)
                }
                .transition(.scale.combined(with: .opacity))
                .padding(.top, KindredSpacing.sm)
            }

            // Search bar
            searchBar
                .padding(.horizontal, KindredSpacing.md)
                .padding(.top, KindredSpacing.sm)
                .padding(.bottom, KindredSpacing.md)

            // Dietary chip bar (always visible)
            DietaryChipBar(
                activeFilters: store.activeDietaryFilters,
                onFilterChanged: { filters in
                    store.send(.dietaryFilterChanged(filters))
                },
                resultCountOverride: store.feedMode == .search ? searchResultCountText : nil
            )
            .contentShape(Rectangle())
            .zIndex(1)
            .padding(.bottom, KindredSpacing.sm)

            // Content area
            searchContentView
                .animation(.easeInOut(duration: 0.2), value: store.feedMode)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var searchContentView: some View {
        switch store.feedMode {
        case .browse:
            browseContentView
        case .search:
            searchModeContentView
        }
    }

    private var browseContentView: some View {
        VStack(spacing: KindredSpacing.sm) {
            // Popular Recipes heading with card count
            HStack {
                Text(String(localized: "Popular Recipes", bundle: .main))
                    .font(.kindredHeading2())
                    .foregroundStyle(.kindredTextPrimary)

                Spacer()

                CardCountIndicator(
                    current: 1,
                    total: store.cardStack.count
                )
            }
            .padding(.horizontal, KindredSpacing.lg)
            .padding(.top, KindredSpacing.xs)

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
                .padding(.bottom, KindredSpacing.lg)
        }
    }

    @ViewBuilder
    private var searchModeContentView: some View {
        if store.isOffline {
            // Offline state
            VStack(spacing: KindredSpacing.lg) {
                Spacer()
                EmptyStateView(
                    title: String(localized: "search.offline_title", bundle: .main),
                    message: String(localized: "search.offline_message", bundle: .main),
                    icon: "wifi.slash"
                )
                Spacer()
            }
        } else if store.isQuotaExhausted {
            // Quota exhausted state
            VStack(spacing: KindredSpacing.lg) {
                Spacer()
                VStack(spacing: KindredSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.kindredTextSecondary)
                    Text(String(localized: "search.quota_exhausted_message", bundle: .main))
                        .font(.kindredBody())
                        .foregroundStyle(.kindredTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KindredSpacing.xl)
                    Button(String(localized: "search.browse_instead", bundle: .main)) {
                        store.send(.clearSearch)
                    }
                    .font(.kindredBody())
                    .foregroundStyle(.kindredAccent)
                }
                Spacer()
            }
        } else if let searchError = store.searchError {
            // Search error state
            VStack(spacing: KindredSpacing.lg) {
                Spacer()
                EmptyStateView(
                    title: String(localized: "search.error_title", bundle: .main),
                    message: searchError,
                    icon: "exclamationmark.triangle"
                )
                Button(String(localized: "search.browse_instead", bundle: .main)) {
                    store.send(.clearSearch)
                }
                .font(.kindredBody())
                .foregroundStyle(.kindredAccent)
                Spacer()
            }
        } else if store.isSearching && store.searchResults.isEmpty {
            // Initial search loading
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Spacer()
            }
        } else if store.searchResults.isEmpty && !store.isSearching && store.searchQuery.count >= 3 {
            // Empty results state
            VStack(spacing: KindredSpacing.lg) {
                Spacer()
                EmptyStateView(
                    title: String(localized: "search.no_results_title", bundle: .main),
                    message: String(localized: "search.no_results_message \(store.searchQuery)", bundle: .main),
                    icon: "magnifyingglass"
                )
                if !store.activeDietaryFilters.isEmpty {
                    Button(String(localized: "feed.clear_filters", bundle: .main)) {
                        store.send(.dietaryFilterChanged([]))
                    }
                    .font(.kindredBody())
                    .foregroundStyle(.kindredAccent)
                }
                Spacer()
            }
        } else if store.searchQuery.count > 0 && store.searchQuery.count < 3 {
            // Query too short — show nothing (browse feed underneath conceptually)
            Color.clear
        } else {
            // Results available
            SearchResultsView(store: store, heroNamespace: heroNamespace)
        }
    }

    private var searchBar: some View {
        HStack(spacing: KindredSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(store.isQuotaExhausted ? .kindredTextSecondary.opacity(0.5) : .kindredTextSecondary)
                .font(.system(size: 16))

            TextField(
                String(localized: "search.placeholder", bundle: .main),
                text: Binding(
                    get: { store.searchQuery },
                    set: { newValue in store.send(.searchQueryChanged(newValue)) }
                )
            )
            .disabled(store.isQuotaExhausted)
            .foregroundStyle(store.isQuotaExhausted ? .kindredTextSecondary.opacity(0.5) : .kindredTextPrimary)
            .font(.kindredBody())
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)

            if !store.searchQuery.isEmpty {
                Button {
                    store.send(.clearSearch)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.kindredTextSecondary)
                        .font(.system(size: 16))
                }
                .accessibilityLabel(String(localized: "search.clear_button_label", bundle: .main))
            } else if store.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, KindredSpacing.sm)
        .padding(.vertical, KindredSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.kindredCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.kindredTextSecondary.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(store.isQuotaExhausted ? 0.6 : 1.0)
        .accessibilityLabel(String(localized: "search.bar_label", bundle: .main))
    }

    private var searchResultCountText: String? {
        guard store.feedMode == .search, !store.searchResults.isEmpty else { return nil }
        let count = store.searchTotalCount > 0 ? store.searchTotalCount : store.searchResults.count
        let activeFilterNames = store.activeDietaryFilters.sorted().map { localizedTagName(for: $0).lowercased() }
        if activeFilterNames.isEmpty {
            return String(localized: "search.result_count \(count)", bundle: .main)
        } else {
            let filterDesc = activeFilterNames.joined(separator: ", ")
            return String(localized: "search.result_count_filtered \(count) \(filterDesc)", bundle: .main)
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
                    .foregroundStyle(.kindredAccent)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredCardSurface)
                    .clipShape(Circle())
            }
            .accessibilityLabel(String(localized: "Skip", bundle: .main))
            .accessibilityHint(String(localized: "accessibility.feed.skip_hint", bundle: .main))

            // Listen button
            Button {
                if let topCard = store.cardStack.first {
                    store.send(.openRecipeDetail(topCard.id))
                }
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.kindredAccent)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredCardSurface)
                    .clipShape(Circle())
            }
            .accessibilityLabel(String(localized: "Listen", bundle: .main))
            .accessibilityHint(String(localized: "accessibility.feed.listen_hint", bundle: .main))

            // Bookmark button
            Button {
                if let topCard = store.cardStack.first {
                    store.send(.swipeCard(topCard.id, .right))
                }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredAccent)
                    .clipShape(Circle())
            }
            .accessibilityLabel(String(localized: "Bookmark", bundle: .main))
            .accessibilityHint(String(localized: "accessibility.feed.bookmark_hint", bundle: .main))
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
                        .foregroundStyle(.kindredTextSecondary)

                    Text(String(localized: "feed.no_filtered_recipes \(filterDescription)", bundle: .main))
                        .font(.kindredHeading2())
                        .foregroundStyle(.kindredTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "feed.try_removing_filter", bundle: .main))
                        .font(.kindredBody())
                        .foregroundStyle(.kindredTextSecondary)
                        .multilineTextAlignment(.center)

                    KindredButton(String(localized: "feed.clear_filters", bundle: .main), style: .secondary) {
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

    private func localizedTagName(for tag: String) -> String {
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

    private var filterDescription: String {
        let connector = String(localized: "feed.list_connector", bundle: .main)
        let sortedFilters = store.activeDietaryFilters.sorted().map { localizedTagName(for: $0).lowercased() }
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

    private var skeletonCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                // Image area placeholder (16:9 ratio)
                Rectangle()
                    .fill(Color.kindredDivider)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 8))

                // Title line
                Text(String(localized: "feed.skeleton.title", bundle: .main))
                    .font(.kindredHeading2())
                    .foregroundStyle(.kindredTextPrimary)

                // Subtitle line
                Text(String(localized: "feed.skeleton.description", bundle: .main))
                    .font(.kindredBody())
                    .foregroundStyle(.kindredTextSecondary)

                // Metadata row
                HStack {
                    Text(String(localized: "feed.skeleton.time", bundle: .main))
                        .font(.kindredCaption())
                    Text("•")
                        .font(.kindredCaption())
                    Text(String(localized: "feed.skeleton.difficulty", bundle: .main))
                        .font(.kindredCaption())
                }
                .foregroundStyle(.kindredTextSecondary)
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }

    private var locationPill: some View {
        Button {
            store.send(.toggleLocationPicker)
        } label: {
            HStack(spacing: KindredSpacing.xs) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))

                Text(store.location)
                    .font(.kindredBody())
                    .fontWeight(.medium)
            }
            .foregroundStyle(.kindredTextPrimary)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(
                Capsule()
                    .fill(Color.kindredCardSurface)
            )
        }
        .accessibilityLabel(String(localized: "Location: \(store.location)", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.feed.location_hint", bundle: .main))
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text(String(localized: "You're offline — showing cached recipes", bundle: .main))
                .font(.kindredCaption())
        }
        .foregroundStyle(.white)
        .padding(.vertical, KindredSpacing.xs)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }

    private var newRecipesBanner: some View {
        Button {
            store.send(.acknowledgeNewRecipes)
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                Text(String(localized: "New recipes available — pull to refresh", bundle: .main))
                    .font(.kindredCaption())
            }
            .foregroundStyle(.kindredTextPrimary)
            .padding(.vertical, KindredSpacing.xs)
            .frame(maxWidth: .infinity)
            .background(Color.kindredAccent.opacity(0.2))
        }
        .accessibilityLabel(String(localized: "New recipes available", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.feed.refresh_hint", bundle: .main))
    }
}
