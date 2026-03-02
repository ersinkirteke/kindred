import ComposableArchitecture
import DesignSystem
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
                    RecipeDetailView(store: detailStore)
                        .navigationTransition(.zoom(sourceID: detailStore.recipeId, in: heroNamespace))
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
        .refreshable {
            await store.send(.refreshFeed).finish()
        }
        .onShake {
            store.send(.undoLastSwipe)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            loadingView
        } else if store.error != nil {
            ErrorStateView.networkError {
                store.send(.onAppear)
            }
        } else if store.cardStack.isEmpty {
            EndOfStackCard {
                store.send(.toggleLocationPicker)
            }
        } else {
            mainFeedView
        }
    }

    private var mainFeedView: some View {
        VStack(spacing: KindredSpacing.lg) {
            Spacer()
                .frame(height: KindredSpacing.md)

            // Card count indicator
            CardCountIndicator(
                current: 1,
                total: store.cardStack.count
            )

            // Card stack
            SwipeCardStack(
                cards: store.cardStack,
                heroNamespace: heroNamespace,
                onSwipe: { recipeId, direction in
                    store.send(.swipeCard(recipeId, direction))
                },
                onTap: { recipeId in
                    store.send(.openRecipeDetail(recipeId))
                }
            )

            // Action buttons
            actionButtons

            Spacer()
        }
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

            // Listen button (disabled - Phase 7)
            Button {
                // Phase 7 implementation
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.kindredAccent)
                    .frame(width: 56, height: 56)
                    .background(Color.kindredCardSurface)
                    .clipShape(Circle())
            }
            .disabled(true)
            .opacity(0.5)
            .accessibilityLabel("Listen")
            .accessibilityHint("Available in a future update")

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

    private var loadingView: some View {
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
