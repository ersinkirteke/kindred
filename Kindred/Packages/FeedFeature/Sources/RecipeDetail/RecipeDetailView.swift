import SwiftUI
import ComposableArchitecture
import DesignSystem
import VoicePlaybackFeature
import MonetizationFeature

// MARK: - Recipe Detail View

public struct RecipeDetailView: View {

    @Bindable var store: StoreOf<RecipeDetailReducer>

    // @ScaledMetric for Dynamic Type support
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 34
    @ScaledMetric(relativeTo: .title3) private var heading3Size: CGFloat = 20
    @ScaledMetric(relativeTo: .headline) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    /// Whether banner ad should be shown (hidden during active narration)
    private var shouldShowBannerAd: Bool {
        let isNarrationActive = [.playing, .loading, .buffering].contains(store.playbackStatus)
        return store.shouldShowAds && !isNarrationActive
    }

    public init(store: StoreOf<RecipeDetailReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Parallax hero image
                    if let recipe = store.recipe {
                        ParallaxHeader(
                            imageUrl: recipe.imageUrl,
                            recipeName: recipe.name,
                            isViral: recipe.isViral
                        )
                    }

                    // Recipe content
                    VStack(alignment: .leading, spacing: KindredSpacing.md) {
                        if store.isLoading {
                            loadingView
                        } else if let error = store.error {
                            errorView(error)
                        } else if let recipe = store.recipe {
                            recipeContentView(recipe)
                        }
                    }
                    .padding(.horizontal, KindredSpacing.md)
                    .padding(.top, KindredSpacing.lg)
                    .background(Color.kindredBackground)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 20,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 20
                        )
                    )
                    .offset(y: -20)
                }
            }
            .background(Color.kindredBackground)

            // Sticky bottom bar - VStack ensures it sits above mini player
            if store.recipe != nil {
                bottomBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.shoppingList, action: \.shoppingList)) { shoppingStore in
            ShoppingListView(store: shoppingStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: KindredSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
            Text(String(localized: "Loading recipe...", bundle: .main))
                .font(.kindredBodyScaled(size: bodySize))
                .foregroundStyle(.kindredTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KindredSpacing.xxl)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        ErrorStateView(
            title: String(localized: "Error loading recipe", bundle: .main),
            message: message,
            icon: "exclamationmark.triangle",
            retryAction: {
                store.send(.onAppear)
            }
        )
        .padding(.top, KindredSpacing.xxl)
    }

    // MARK: - Recipe Content View

    private func recipeContentView(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: KindredSpacing.lg) {
            // Recipe name
            Text(recipe.name)
                .font(.kindredLargeTitleScaled(size: titleSize))
                .foregroundStyle(.kindredTextPrimary)
                .accessibilityAddTraits(.isHeader)

            // Dietary tag pills
            if !recipe.dietaryTags.isEmpty {
                dietaryTagsView(recipe.dietaryTags)
            }

            // Metadata bar
            metadataBar(recipe)

            Divider()
                .background(Color.kindredDivider)

            // Description
            if let description = recipe.description {
                Text(description)
                    .font(.kindredBodyScaled(size: bodySize))
                    .foregroundStyle(.kindredTextSecondary)
                    .multilineTextAlignment(.leading)
            }

            // Ingredients section
            sectionHeader(String(localized: "Ingredients", bundle: .main))

            // Match summary
            if let matchPct = store.matchPercentage, store.eligibleCount > 0 {
                VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                    Text("You have \(store.matchedCount) of \(store.eligibleCount) ingredients (\(matchPct)%)")
                        .font(.kindredBodyScaled(size: bodySize))
                        .foregroundStyle(.kindredTextSecondary)

                    if store.matchedCount < store.eligibleCount {
                        Button {
                            store.send(.showShoppingList)
                        } label: {
                            Label(
                                String(localized: "Missing ingredients", bundle: .main),
                                systemImage: "cart"
                            )
                            .font(.kindredBodyBoldScaled(size: bodySize))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.kindredAccent)
                        .accessibilityHint(String(localized: "Opens shopping list for missing ingredients", bundle: .main))
                    }
                }
                .padding(.bottom, KindredSpacing.sm)
            }

            IngredientChecklistView(
                ingredients: recipe.ingredients,
                checkedIngredients: store.checkedIngredients,
                ingredientMatchStatuses: store.ingredientMatchStatuses,
                onToggle: { ingredientId in
                    store.send(.toggleIngredient(ingredientId))
                }
            )

            // Banner ad (between ingredients and instructions, hidden during narration)
            if shouldShowBannerAd {
                BannerAdView()
                    .padding(.vertical, KindredSpacing.sm)
            }

            // Instructions section
            sectionHeader(String(localized: "Instructions", bundle: .main))

            StepTimelineView(steps: recipe.steps)
        }
    }

    // MARK: - Dietary Tags View

    private func dietaryTagsView(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KindredSpacing.sm) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(.kindredCaptionScaled(size: captionSize))
                        .foregroundStyle(.white)
                        .padding(.horizontal, KindredSpacing.md)
                        .padding(.vertical, KindredSpacing.xs)
                        .background(
                            Capsule()
                                .fill(tag.dietaryTagColor)
                        )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Dietary tags: \(tags.joined(separator: ", "))"))
    }

    // MARK: - Metadata Bar

    private func metadataBar(_ recipe: RecipeDetail) -> some View {
        HStack(spacing: KindredSpacing.md) {
            // Total time
            if let totalTime = recipe.totalTime {
                metadataItem(icon: "clock", text: "\(totalTime) min")
            }

            // Calories
            if let calories = recipe.calories {
                metadataItem(icon: "flame", text: "\(calories) cal")
            }

            // Loves
            metadataItem(icon: "heart", text: recipe.formattedLoves)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(metadataAccessibilityLabel(recipe))
    }

    private func metadataItem(icon: String, text: String) -> some View {
        HStack(spacing: KindredSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: captionSize))
            Text(text)
                .font(.kindredCaptionScaled(size: captionSize))
        }
        .foregroundStyle(.kindredTextSecondary)
    }

    private func metadataAccessibilityLabel(_ recipe: RecipeDetail) -> String {
        var parts: [String] = []
        if let totalTime = recipe.totalTime {
            parts.append(String(localized: "\(totalTime) minutes", bundle: .main))
        }
        if let calories = recipe.calories {
            parts.append(String(localized: "\(calories) calories", bundle: .main))
        }
        parts.append(String(localized: "\(recipe.formattedLoves) loves", bundle: .main))
        return parts.joined(separator: ", ")
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.kindredHeading3Scaled(size: heading3Size))
            .foregroundStyle(.kindredTextPrimary)
            .padding(.top, KindredSpacing.sm)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.kindredDivider)

            HStack(spacing: KindredSpacing.md) {
                // Listen button
                Button(action: {
                    store.send(.listenTapped)
                }) {
                    HStack(spacing: KindredSpacing.sm) {
                        switch store.playbackStatus {
                        case .loading, .buffering:
                            ProgressView()
                                .tint(.kindredAccent)
                            Text(String(localized: "Loading...", bundle: .main))
                                .font(.kindredBodyBoldScaled(size: bodySize))
                        case .playing:
                            Image(systemName: "pause.fill")
                                .font(.system(size: 18))
                            Text(String(localized: "Pause", bundle: .main))
                                .font(.kindredBodyBoldScaled(size: bodySize))
                        case .paused:
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                            Text(String(localized: "Resume", bundle: .main))
                                .font(.kindredBodyBoldScaled(size: bodySize))
                        default:
                            Image(systemName: "headphones")
                                .font(.system(size: 18))
                            Text(String(localized: "Listen", bundle: .main))
                                .font(.kindredBodyBoldScaled(size: bodySize))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .foregroundStyle(.kindredAccent)
                    .background(Color.clear)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.kindredAccent, lineWidth: 2)
                    )
                }
                .disabled(store.playbackStatus == .loading || store.playbackStatus == .buffering)
                .accessibilityLabel(store.playbackStatus == .playing ? String(localized: "Pause narration", bundle: .main) : String(localized: "Listen to this recipe", bundle: .main))
                .accessibilityHint(store.playbackStatus == .playing ? String(localized: "accessibility.recipe_detail.pause_hint", bundle: .main) : String(localized: "accessibility.recipe_detail.listen_hint", bundle: .main))

                // Bookmark button
                Button(action: {
                    store.send(.toggleBookmark)
                    HapticFeedback.success()
                }) {
                    HStack(spacing: KindredSpacing.sm) {
                        Image(systemName: store.isBookmarked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                        Text(String(localized: "Bookmark", bundle: .main))
                            .font(.kindredBodyBoldScaled(size: bodySize))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .foregroundStyle(.white)
                    .background(Color.kindredAccent)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .accessibilityLabel(store.isBookmarked ? String(localized: "Remove bookmark", bundle: .main) : String(localized: "Bookmark recipe", bundle: .main))
            }
            .padding(.horizontal, KindredSpacing.md)
            .padding(.vertical, KindredSpacing.md)

            // Space for mini player when it's visible
            if store.isMiniPlayerVisible {
                Spacer()
                    .frame(height: 67)
            }
        }
        .background(Color.kindredCardSurface)
    }
}

// MARK: - Preview

#if DEBUG
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecipeDetailView(
                store: Store(
                    initialState: RecipeDetailReducer.State(recipeId: "test-recipe-1")
                ) {
                    RecipeDetailReducer()
                }
            )
        }
    }
}
#endif
