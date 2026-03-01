import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct FeedView: View {
    @Bindable var store: StoreOf<FeedReducer>

    public init(store: StoreOf<FeedReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.kindredBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Offline banner
                    if store.isOffline {
                        offlineBanner
                    }

                    // New recipes banner
                    if store.hasNewRecipes {
                        newRecipesBanner
                    }

                    // Main content
                    contentView
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    locationPill
                }
            }
            .refreshable {
                await store.send(.refreshFeed).finish()
            }
            .onShake {
                store.send(.undoLastSwipe)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.cardStack) { _, newStack in
            // Post VoiceOver announcement on card transitions
            if !newStack.isEmpty {
                let currentIndex = 1
                let total = newStack.count
                let recipeName = newStack.first?.name ?? ""
                let announcement = "Recipe \(currentIndex) of \(total), \(recipeName)"
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
        .onChange(of: store.location) { _, newLocation in
            // Post VoiceOver notification on location change
            let announcement = "Now showing recipes near \(newLocation)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            loadingView
        } else if let error = store.error {
            ErrorStateView.networkError(
                message: error,
                retryAction: {
                    store.send(.onAppear)
                }
            )
        } else if store.cardStack.isEmpty {
            EndOfStackCard {
                // Location picker will be implemented in Plan 04
                // For now, just reload with same location
                store.send(.changeLocation(store.location))
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
                onSwipe: { recipeId, direction in
                    store.send(.swipeCard(recipeId, direction))
                },
                onTap: { recipeId in
                    // Recipe detail navigation will be implemented in Plan 04
                    // For now, no action
                }
            )
            .padding(.horizontal, KindredSpacing.md)

            // Action buttons
            actionButtons

            Spacer()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: KindredSpacing.lg) {
            // Skip button
            KindredButton(
                icon: "xmark",
                style: .secondary,
                size: .large
            ) {
                if let topCard = store.cardStack.first {
                    store.send(.swipeCard(topCard.id, .left))
                }
            }
            .accessibilityLabel("Skip")
            .accessibilityHint("Skip this recipe - or swipe left")

            // Listen button (disabled - Phase 7)
            KindredButton(
                icon: "headphones",
                style: .secondary,
                size: .large
            ) {
                // Phase 7 implementation
            }
            .disabled(true)
            .opacity(0.5)
            .accessibilityLabel("Listen")
            .accessibilityHint("Available in a future update")

            // Bookmark button
            KindredButton(
                icon: "heart.fill",
                style: .primary,
                size: .large
            ) {
                if let topCard = store.cardStack.first {
                    store.send(.swipeCard(topCard.id, .right))
                }
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
            // Location picker will be implemented in Plan 04
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
