import SwiftUI
import ComposableArchitecture
import DesignSystem
import VoicePlaybackFeature
import MonetizationFeature

// MARK: - Recipe Detail View

public struct RecipeDetailView: View {

    @Bindable var store: StoreOf<RecipeDetailReducer>

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
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: KindredSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
            Text("Loading recipe...")
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KindredSpacing.xxl)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: KindredSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.kindredError)
            Text("Error loading recipe")
                .font(.kindredHeading2())
                .foregroundColor(.kindredTextPrimary)
            Text(message)
                .font(.kindredBody())
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KindredSpacing.xxl)
    }

    // MARK: - Recipe Content View

    private func recipeContentView(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: KindredSpacing.lg) {
            // Recipe name
            Text(recipe.name)
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
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
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.leading)
            }

            // Ingredients section
            sectionHeader("Ingredients")

            IngredientChecklistView(
                ingredients: recipe.ingredients,
                checkedIngredients: store.checkedIngredients,
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
            sectionHeader("Instructions")

            StepTimelineView(steps: recipe.steps)
        }
    }

    // MARK: - Dietary Tags View

    private func dietaryTagsView(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KindredSpacing.sm) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(.kindredCaption())
                        .foregroundColor(.white)
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
        .accessibilityLabel("Dietary tags: \(tags.joined(separator: ", "))")
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
                .font(.system(size: 14))
            Text(text)
                .font(.kindredCaption())
        }
        .foregroundColor(.kindredTextSecondary)
    }

    private func metadataAccessibilityLabel(_ recipe: RecipeDetail) -> String {
        var parts: [String] = []
        if let totalTime = recipe.totalTime {
            parts.append("\(totalTime) minutes")
        }
        if let calories = recipe.calories {
            parts.append("\(calories) calories")
        }
        parts.append("\(recipe.formattedLoves) loves")
        return parts.joined(separator: ", ")
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.kindredHeading3())
            .foregroundColor(.kindredTextPrimary)
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
                            Text("Loading...")
                                .font(.kindredBodyBold())
                        case .playing:
                            Image(systemName: "pause.fill")
                                .font(.system(size: 18))
                            Text("Pause")
                                .font(.kindredBodyBold())
                        case .paused:
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                            Text("Resume")
                                .font(.kindredBodyBold())
                        default:
                            Image(systemName: "headphones")
                                .font(.system(size: 18))
                            Text("Listen")
                                .font(.kindredBodyBold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .foregroundColor(.kindredAccent)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.kindredAccent, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
                .disabled(store.playbackStatus == .loading || store.playbackStatus == .buffering)
                .accessibilityLabel(store.playbackStatus == .playing ? "Pause narration" : "Listen to this recipe")
                .accessibilityHint(store.playbackStatus == .playing ? "Double tap to pause" : "Double tap to listen to this recipe narrated")

                // Bookmark button
                Button(action: {
                    store.send(.toggleBookmark)
                    HapticFeedback.success()
                }) {
                    HStack(spacing: KindredSpacing.sm) {
                        Image(systemName: store.isBookmarked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                        Text("Bookmark")
                            .font(.kindredBodyBold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .foregroundColor(.white)
                    .background(Color.kindredAccent)
                    .cornerRadius(12)
                }
                .accessibilityLabel(store.isBookmarked ? "Remove bookmark" : "Bookmark recipe")
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
