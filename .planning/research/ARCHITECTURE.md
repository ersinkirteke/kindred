# Architecture Research: Lean App Store Launch Integration

**Domain:** iOS cooking app migration to free-tier APIs
**Researched:** 2026-04-04
**Confidence:** HIGH

## Executive Summary

The v5.0 Lean App Store Launch milestone requires integrating three major components into existing architecture: Spoonacular recipe API (replacing X API scraping), AVSpeechSynthesizer (free-tier voice alternative to ElevenLabs), and fastlane App Store submission automation. These changes affect backend recipe ingestion, iOS voice playback, and deployment pipelines while maintaining existing TCA architecture and GraphQL API contracts.

**Critical finding:** All three integrations can occur in parallel layers without breaking existing features. Spoonacular replaces the scraping service, AVSpeechSynthesizer sits alongside existing AudioPlayerManager, and fastlane extends the build system. Feature flags enable gradual rollout with zero-downtime migration.

## System Overview: Current State

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS App (SwiftUI + TCA)                      │
├─────────────────────────────────────────────────────────────────────┤
│  FeedFeature  │  VoicePlayback  │  PantryFeature  │  MonetizationF │
│               │  (AVPlayer)      │                 │  (StoreKit 2)  │
└───────┬───────┴────────┬─────────┴────────┬────────┴────────┬───────┘
        │                │                  │                 │
        │ Apollo iOS     │ R2 CDN (audio)   │ GraphQL         │ AdMob
        │ GraphQL        │                  │ mutations       │
        │                │                  │                 │
┌───────┴────────────────┴──────────────────┴─────────────────┴───────┐
│              NestJS Backend + GraphQL (Apollo Server 5)              │
├─────────────────────────────────────────────────────────────────────┤
│  ScrapingService  │  VoiceService      │  PantryService │  AuthServ │
│  ├─ XApiService   │  ├─ ElevenLabs     │                │           │
│  └─ RecipeParser  │  └─ R2Storage      │                │           │
├─────────────────────────────────────────────────────────────────────┤
│  ImagesService    │  NarrationService  │  GeocodingService          │
│  └─ Imagen 4      │  └─ Gemini 2.0 F   │  └─ Mapbox                │
├─────────────────────────────────────────────────────────────────────┤
│                   Prisma 7 + PostgreSQL 15 + PostGIS                 │
│  Recipe | VoiceProfile | NarrationScript | User | PantryItem        │
└─────────────────────────────────────────────────────────────────────┘
```

## System Overview: Target State (v5.0)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS App (SwiftUI + TCA)                      │
├─────────────────────────────────────────────────────────────────────┤
│  FeedFeature  │  VoicePlayback  │  PantryFeature  │  MonetizationF │
│               │  ├─ AVPlayer     │                 │  (StoreKit 2)  │
│               │  └─ AVSpeech*    │                 │                │
└───────┬───────┴────────┬─────────┴────────┬────────┴────────┬───────┘
        │                │                  │                 │
        │ Apollo iOS     │ R2 CDN (Pro)     │ GraphQL         │ AdMob
        │ GraphQL        │ AVSpeech (Free)  │ mutations       │
        │                │                  │                 │
┌───────┴────────────────┴──────────────────┴─────────────────┴───────┐
│              NestJS Backend + GraphQL (Apollo Server 5)              │
├─────────────────────────────────────────────────────────────────────┤
│  RecipeService    │  VoiceService      │  PantryService │  AuthServ │
│  └─ Spoonacular*  │  ├─ ElevenLabs†    │                │           │
│                   │  └─ R2Storage      │                │           │
├─────────────────────────────────────────────────────────────────────┤
│  NarrationService │  GeocodingService (Mapbox)                      │
│  └─ Gemini 2.0 F  │                                                 │
├─────────────────────────────────────────────────────────────────────┤
│                   Prisma 7 + PostgreSQL 15 + PostGIS                 │
│  Recipe | VoiceProfile | NarrationScript | User | PantryItem        │
└─────────────────────────────────────────────────────────────────────┘
│
└─ Fastlane (beta_internal, beta_external, release lanes)

* New component
† Pro-tier only (behind paywall)
```

**Key changes:**
1. **Spoonacular replaces X API scraping** - no more ScrapingService, no Instagram placeholder
2. **AVSpeechSynthesizer added for free-tier** - ElevenLabs becomes Pro-only
3. **Imagen 4 removed** - Spoonacular provides images
4. **Fastlane automates deployment** - TestFlight and App Store submission
5. **"Viral near you" → "Popular recipes"** - framing shift (no location-based viral detection)

## Integration Point 1: Spoonacular API

### Architecture Pattern: REST-to-GraphQL Proxy Service

**Implementation:**
```typescript
// backend/src/recipes/spoonacular.service.ts
@Injectable()
export class SpoonacularService {
  private readonly apiKey: string = process.env.SPOONACULAR_API_KEY;
  private readonly baseUrl = 'https://api.spoonacular.com';

  // Proxy pattern - wrap REST API with typed methods
  async searchRecipes(query: string, number: number = 20): Promise<SpoonacularRecipe[]> {
    const response = await axios.get(`${this.baseUrl}/recipes/complexSearch`, {
      params: {
        apiKey: this.apiKey,
        query,
        number,
        addRecipeInformation: true,
        fillIngredients: true,
      },
    });
    return response.data.results;
  }

  async getRecipeById(id: number): Promise<SpoonacularRecipe> {
    const response = await axios.get(`${this.baseUrl}/recipes/${id}/information`, {
      params: { apiKey: this.apiKey },
    });
    return response.data;
  }

  async getRandomRecipes(number: number = 20): Promise<SpoonacularRecipe[]> {
    const response = await axios.get(`${this.baseUrl}/recipes/random`, {
      params: {
        apiKey: this.apiKey,
        number,
      },
    });
    return response.data.recipes;
  }
}
```

**Replaces:** `ScrapingService`, `XApiService`, `InstagramService`, `ImageGenerationProcessor`

**GraphQL Schema Changes:**

```graphql
# NEW fields (backward compatible additions)
type Recipe {
  # ... existing fields
  sourceType: RecipeSource!  # NEW: SCRAPED | SPOONACULAR
  spoonacularId: Int         # NEW: nullable for backward compat
  spoonacularScore: Float    # NEW: replaces viral score
}

enum RecipeSource {
  SCRAPED      # Legacy X API recipes
  SPOONACULAR  # New Spoonacular recipes
}

# MODIFIED query
type Query {
  # Before: viralRecipes(location: String!): [Recipe!]!
  # After:  popularRecipes(limit: Int = 20): [Recipe!]!
  popularRecipes(limit: Int = 20): [Recipe!]!
}
```

**Migration strategy:**
1. Add `SpoonacularService` alongside existing `ScrapingService`
2. Add `sourceType` and `spoonacularId` columns to `Recipe` table (nullable, default null)
3. Feature flag: `ENABLE_SPOONACULAR_FEED` (default: false)
4. When flag enabled, `FeedResolver.popularRecipes` calls SpoonacularService
5. Deprecate but don't remove `viralRecipes` query (iOS still calls it during migration)
6. iOS updates to call `popularRecipes` instead of `viralRecipes`
7. After iOS rollout complete, remove ScrapingService and related code

**Data model mapping:**

| Spoonacular Field | Prisma Recipe Field | Transform |
|-------------------|---------------------|-----------|
| `id` | `spoonacularId` | Store as Int |
| `title` | `name` | Direct copy |
| `image` | `imageUrl` | Direct URL (no generation needed) |
| `readyInMinutes` | `prepTime` | Direct copy |
| `servings` | Store in JSON | No dedicated column |
| `extendedIngredients` | `ingredients` (JSON) | Parse to array of strings |
| `instructions` | `instructions` | Parse HTML/text |
| `cuisines` | Map to `CuisineType` enum | Match to existing enum |
| `dishTypes` | Map to `MealType` enum | Match to existing enum |
| `vegetarian`, `vegan`, etc. | `dietary` (JSON) | Combine into array |
| `spoonacularScore` | NEW column `popularityScore` | Direct copy |
| `pricePerServing` | Store in JSON | No dedicated column |
| `healthScore` | Store in JSON | No dedicated column |

**Free tier management (150 req/day):**
```typescript
// Caching strategy to stay under 150 req/day limit
@Injectable()
export class RecipesFeedService {
  async getPopularFeed(limit: number = 20): Promise<Recipe[]> {
    // 1. Check database cache first
    const cachedRecipes = await this.prisma.recipe.findMany({
      where: {
        sourceType: 'SPOONACULAR',
        updatedAt: { gte: subHours(new Date(), 6) }, // 6-hour cache
      },
      take: limit,
      orderBy: { popularityScore: 'desc' },
    });

    if (cachedRecipes.length >= limit) {
      return cachedRecipes;
    }

    // 2. Fetch from Spoonacular (counts against 150/day quota)
    const recipes = await this.spoonacular.getRandomRecipes(limit);

    // 3. Store in database for future cache hits
    await this.storeSpoonacularRecipes(recipes);

    return recipes;
  }

  // Daily batch job (runs once at 2 AM UTC) - 100 requests to refresh popular feed
  @Cron('0 2 * * *')
  async refreshPopularRecipes() {
    const recipes = await this.spoonacular.getRandomRecipes(100);
    await this.storeSpoonacularRecipes(recipes);
  }
}
```

**Estimation:** 1 daily batch job (100 req) + ~30 cache misses/day = ~130 req/day (under 150 limit)

### Data Flow: Recipe Ingestion

**Before (X API scraping):**
```
X API → ScrapingService → RecipeParser (Gemini) → ImageProcessor (Imagen) → DB
  ↓                                                      ↓
Manual scrape trigger                            Queue + R2 upload
```

**After (Spoonacular):**
```
Daily cron (2 AM UTC) → SpoonacularService → RecipesFeedService → DB
                               ↓                                    ↓
                    API returns images                 Cache for 6h
```

**Latency comparison:**
- X API flow: 5-10 seconds/recipe (Gemini parse + Imagen generate)
- Spoonacular flow: ~200ms/recipe (REST API call only)

**Cost comparison:**
- X API: $100/mo (API access) + ~$0.01/recipe (Imagen) + ~$0.001/recipe (Gemini)
- Spoonacular: $0/mo (free tier)

## Integration Point 2: AVSpeechSynthesizer

### Architecture Pattern: Strategy Pattern with Tier-Based Voice Provider

**Implementation:**

```swift
// VoicePlaybackFeature/Sources/AudioPlayer/VoiceProvider.swift
public protocol VoiceProvider {
    func synthesize(text: String, voiceId: String?) async throws -> VoicePlaybackResult
}

public enum VoicePlaybackResult {
    case streaming(url: URL)        // ElevenLabs R2 CDN URL
    case synthesized(utterance: AVSpeechUtterance)  // AVSpeechSynthesizer
}

// Pro-tier: ElevenLabs voice cloning
public struct ElevenLabsVoiceProvider: VoiceProvider {
    public func synthesize(text: String, voiceId: String?) async throws -> VoicePlaybackResult {
        // Existing logic - fetch narration URL from GraphQL
        let url = try await networkClient.fetchNarrationURL(recipeId: recipeId, voiceId: voiceId)
        return .streaming(url: url)
    }
}

// Free-tier: AVSpeechSynthesizer
public struct AppleVoiceProvider: VoiceProvider {
    private let synthesizer = AVSpeechSynthesizer()

    public func synthesize(text: String, voiceId: String?) async throws -> VoicePlaybackResult {
        let utterance = AVSpeechUtterance(string: text)

        // Configure natural-sounding voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9  // Slightly slower
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        return .synthesized(utterance: utterance)
    }
}
```

**TCA Integration (using swift-tts pattern):**

```swift
// VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift
@Reducer
public struct VoicePlaybackReducer {
    @Dependency(\.voiceProvider) var voiceProvider
    @Dependency(\.audioPlayerManager) var audioPlayer
    @Dependency(\.speechSynthesizer) var speechSynthesizer  // NEW

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .playButtonTapped:
            return .run { [recipe = state.recipe, userTier = state.userTier] send in
                await send(.setPlaybackState(.loading))

                do {
                    let result = try await voiceProvider.synthesize(
                        text: recipe.instructions,
                        voiceId: userTier == .pro ? recipe.voiceId : nil
                    )

                    switch result {
                    case .streaming(let url):
                        // Existing AVPlayer path (Pro tier)
                        try await audioPlayer.play(url: url)
                        await send(.playbackStarted(.streaming))

                    case .synthesized(let utterance):
                        // NEW AVSpeechSynthesizer path (Free tier)
                        try await speechSynthesizer.speak(utterance)
                        await send(.playbackStarted(.synthesized))
                    }
                } catch {
                    await send(.playbackFailed(error))
                }
            }
        }
    }
}
```

**Dependency injection:**

```swift
// Dependencies.swift
extension DependencyValues {
    var voiceProvider: VoiceProvider {
        get {
            // Tier-based selection
            if self.userTier == .pro {
                return ElevenLabsVoiceProvider(networkClient: self.networkClient)
            } else {
                return AppleVoiceProvider()
            }
        }
        set { self[VoiceProviderKey.self] = newValue }
    }

    var speechSynthesizer: SpeechSynthesizer {
        get { self[SpeechSynthesizerKey.self] }
        set { self[SpeechSynthesizerKey.self] = newValue }
    }
}
```

**Audio session configuration for AVSpeechSynthesizer:**

```swift
// AppDelegate.swift (existing audio session setup)
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    // MODIFY existing session to support both AVPlayer and AVSpeechSynthesizer
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
    try? session.setActive(true)

    // Register for remote transport controls (Now Playing)
    UIApplication.shared.beginReceivingRemoteControlEvents()
}
```

**Background audio support:**

```swift
// Configure capabilities: Audio, AirPlay, and Picture in Picture
// project.yml already has this for AVPlayer - no changes needed

// AVSpeechSynthesizer respects audio session automatically
// Set usesApplicationAudioSession = true (default) to share session with AVPlayer
let synthesizer = AVSpeechSynthesizer()
synthesizer.usesApplicationAudioSession = true  // Uses shared session
```

**Integration with existing AudioPlayerManager:**

Option 1: Parallel managers (RECOMMENDED)
```swift
// Keep AudioPlayerManager for Pro tier (AVPlayer streaming)
// Add SpeechSynthesizerManager for Free tier (AVSpeechSynthesizer)
// VoicePlaybackReducer chooses based on tier
```

Option 2: Unified manager (more complex)
```swift
// Extend AudioPlayerManager to handle both AVPlayer and AVSpeechSynthesizer
// Increases complexity, harder to test, not recommended
```

**GraphQL schema changes:**

```graphql
# MODIFY VoiceProfile type
type VoiceProfile {
  id: ID!
  speakerName: String!
  # ... existing fields
  tier: UserTier!  # NEW: determines which voice system to use
}

enum UserTier {
  FREE   # Uses AVSpeechSynthesizer
  PRO    # Uses ElevenLabs + R2 CDN
}

# MODIFY NarrationAudio query
type Query {
  narrationAudio(recipeId: ID!, voiceId: ID): NarrationAudio
}

type NarrationAudio {
  url: String        # nullable - only for Pro tier
  plainText: String  # NEW - instructions text for AVSpeechSynthesizer
  tier: UserTier!
}
```

**Migration strategy:**
1. Add `SpeechSynthesizerManager` to VoicePlaybackFeature
2. Add `UserTier` to User model (default: FREE)
3. Modify `VoicePlaybackReducer` to check tier before playback
4. Update GraphQL schema to return `plainText` in `narrationAudio` query
5. iOS fetches both `url` (Pro) and `plainText` (Free) in query
6. Tier check happens in reducer, not resolver
7. Free tier users never hit ElevenLabs API (cost = $0)

**Cost impact:**
- Before: All users call ElevenLabs (~$0.01-0.03/recipe/user)
- After: Only Pro users call ElevenLabs (Free tier = $0)
- Estimated savings: ~90% voice costs (assuming 90% free users)

## Integration Point 3: Fastlane App Store Submission

### Architecture Pattern: Multi-Lane CI/CD Pipeline

**Implementation:**

```ruby
# Kindred/fastlane/Fastfile (already exists, extend with release lane)
default_platform(:ios)

platform :ios do
  # Existing lanes
  lane :beta_internal do
    setup_ci if ENV['CI']
    match(type: "appstore", readonly: true)
    increment_build_number(xcodeproj: "Kindred.xcodeproj")
    build_app(
      scheme: "Kindred",
      configuration: "Release",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      distribute_external: false
    )
  end

  lane :beta_external do
    setup_ci if ENV['CI']
    match(type: "appstore", readonly: true)
    increment_build_number(xcodeproj: "Kindred.xcodeproj")
    build_app(
      scheme: "Kindred",
      configuration: "Release",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: false,
      distribute_external: true,
      groups: ["Beta Testers"],
      changelog: File.read("../CHANGELOG.md")
    )
  end

  # NEW: App Store submission lane
  lane :release do
    setup_ci if ENV['CI']
    match(type: "appstore", readonly: true)

    # Increment version (manual - requires PROJECT.md update)
    version = get_version_number(xcodeproj: "Kindred.xcodeproj")

    # Auto-increment build number
    increment_build_number(xcodeproj: "Kindred.xcodeproj")

    # Build IPA
    build_app(
      scheme: "Kindred",
      configuration: "Release",
      export_method: "app-store",
      output_directory: "./build"
    )

    # Upload metadata + screenshots (uses fastlane/metadata/ directory)
    upload_to_app_store(
      force: true,  # Skip HTML verification
      submit_for_review: true,
      automatic_release: false,  # Manual release after approval
      submission_information: {
        add_id_info_uses_idfa: true,  # AdMob uses IDFA
        add_id_info_serves_ads: true,
        add_id_info_tracks_action: true,
        add_id_info_tracks_install: false,
        export_compliance_uses_encryption: false
      },
      precheck_include_in_app_purchases: true,
      app_version: version
    )

    # Post to Slack (optional)
    slack(
      message: "Kindred #{version} submitted to App Store! 🚀",
      channel: "#releases"
    )
  end
end
```

**Metadata management:**

```
Kindred/fastlane/
├── metadata/
│   ├── en-US/
│   │   ├── name.txt                      # "Kindred"
│   │   ├── subtitle.txt                  # "Recipes in your loved one's voice"
│   │   ├── description.txt               # Full app description
│   │   ├── keywords.txt                  # "recipe,cooking,voice,AI,pantry"
│   │   ├── marketing_url.txt             # https://kindred.app
│   │   ├── privacy_url.txt               # https://kindred.app/privacy
│   │   ├── support_url.txt               # https://kindred.app/support
│   │   └── release_notes.txt             # "What's new in this version"
│   ├── tr/                                # Turkish localization
│   │   ├── name.txt
│   │   ├── description.txt
│   │   └── release_notes.txt
│   └── review_information/
│       ├── first_name.txt                # "Ersin"
│       ├── last_name.txt                 # "Kirteke"
│       ├── email_address.txt             # Contact email
│       ├── phone_number.txt              # Contact phone
│       ├── demo_user.txt                 # Test account username
│       ├── demo_password.txt             # Test account password
│       └── notes.txt                     # Review notes (AI disclosure)
├── screenshots/
│   ├── en-US/
│   │   ├── 01-voice-narration.png        # 6.7" display (iPhone 16 Pro Max)
│   │   ├── 02-recipe-feed.png
│   │   ├── 03-pantry-scan.png
│   │   ├── 04-dietary-filters.png
│   │   └── 05-recipe-detail.png
│   └── tr/                                # Turkish screenshots
│       ├── 01-voice-narration.png
│       └── ...
└── Fastfile
```

**Automation level:**

| Task | Automated? | Notes |
|------|-----------|-------|
| Build IPA | ✅ Yes | fastlane build_app |
| Increment build number | ✅ Yes | Git commit count |
| Upload binary | ✅ Yes | fastlane upload_to_app_store |
| Upload screenshots | ✅ Yes | From fastlane/screenshots/ |
| Upload metadata | ✅ Yes | From fastlane/metadata/ |
| Submit for review | ✅ Yes | submit_for_review: true |
| Auto-release after approval | ❌ No | Requires manual "Release" button (safety) |
| Version increment | ❌ Manual | Requires PROJECT.md update + git tag |

**Integration with existing build system:**

```yaml
# .github/workflows/release.yml (NEW)
name: App Store Release
on:
  push:
    tags:
      - 'v*.*.*'  # Trigger on version tags (e.g., v5.0.0)

jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
          working-directory: Kindred/fastlane

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.2'

      - name: Install dependencies
        run: |
          cd Kindred
          bundle install

      - name: Run fastlane release
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          FASTLANE_APPLE_ID: ${{ secrets.APPLE_ID }}
          FASTLANE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_API_KEY }}
        run: |
          cd Kindred
          bundle exec fastlane release
```

**Manual release process (until GitHub Actions configured):**

```bash
# 1. Update PROJECT.md with new version
# 2. Update CHANGELOG.md with release notes
# 3. Commit and tag
git add .planning/PROJECT.md CHANGELOG.md
git commit -m "chore: bump version to v5.0.0"
git tag v5.0.0
git push origin main --tags

# 4. Run fastlane
cd Kindred
bundle exec fastlane release

# 5. Monitor App Store Connect for review status
# 6. After approval, manually click "Release this version" in ASC
```

## Component Boundaries: Modified

### Backend Services (NestJS)

| Service | Before v5.0 | After v5.0 | Status |
|---------|-------------|------------|--------|
| ScrapingService | X API + Instagram | REMOVED | Delete |
| RecipeParserService | Gemini parser | REMOVED | Delete |
| ImageGenerationProcessor | Imagen 4 queue | REMOVED | Delete |
| SpoonacularService | N/A | NEW - REST proxy | Add |
| RecipesFeedService | Viral scoring | Modified - popularity | Modify |
| VoiceService | ElevenLabs all users | ElevenLabs Pro only | Modify |
| NarrationService | Gemini rewrite | Gemini rewrite (Pro) | Keep |
| FeedResolver | viralRecipes query | popularRecipes query | Modify |

### iOS SPM Packages

| Package | Before v5.0 | After v5.0 | Status |
|---------|-------------|------------|--------|
| VoicePlaybackFeature | AVPlayer only | AVPlayer + AVSpeech | Modify |
| FeedFeature | Viral badge | Popularity badge | Modify |
| MonetizationFeature | Pro = unlimited voices | Pro = ElevenLabs | Modify |
| NetworkClient | viralRecipes query | popularRecipes query | Modify |

### New Components

| Component | Layer | Purpose |
|-----------|-------|---------|
| SpoonacularService | Backend | REST-to-GraphQL proxy for recipes |
| SpeechSynthesizerManager | iOS | AVSpeechSynthesizer wrapper for TCA |
| AppleVoiceProvider | iOS | Free-tier voice strategy |
| Fastlane release lane | Build | App Store submission automation |

## Data Flow Changes

### Recipe Feed Flow

**Before:**
```
User opens app
  ↓
FeedFeature.onAppear
  ↓
Apollo: query viralRecipes(location: "Vilnius")
  ↓
FeedResolver.viralRecipes()
  ↓
RecipesService.findViral(location)
  ↓
Prisma: SELECT * FROM Recipe WHERE city = "Vilnius" ORDER BY viralScore DESC
  ↓
Return recipes with VIRAL badge
```

**After:**
```
User opens app
  ↓
FeedFeature.onAppear
  ↓
Apollo: query popularRecipes(limit: 20)
  ↓
FeedResolver.popularRecipes()
  ↓
RecipesFeedService.getPopularFeed(limit)
  ↓
Check cache (updatedAt > 6 hours ago)
  ├─ Cache hit: Return from DB
  └─ Cache miss: Spoonacular API → Store in DB → Return
  ↓
Return recipes with popularity score (no viral badge)
```

### Voice Narration Flow (Free Tier)

**Before:**
```
User taps Play
  ↓
VoicePlaybackReducer.playButtonTapped
  ↓
Apollo: query narrationAudio(recipeId, voiceId)
  ↓
VoiceResolver.narrationAudio()
  ↓
NarrationService.getOrCreateNarration()
  ↓
Gemini: Rewrite instructions → ElevenLabs TTS → R2 upload
  ↓
Return R2 CDN URL
  ↓
AudioPlayerManager.play(url)
  ↓
AVPlayer streams from R2
```

**After (Free tier):**
```
User taps Play
  ↓
VoicePlaybackReducer.playButtonTapped
  ↓
Check userTier → FREE
  ↓
Apollo: query narrationAudio(recipeId, voiceId: null)
  ↓
VoiceResolver.narrationAudio()
  ↓
Return { url: null, plainText: recipe.instructions, tier: FREE }
  ↓
AppleVoiceProvider.synthesize(plainText)
  ↓
SpeechSynthesizerManager.speak(utterance)
  ↓
AVSpeechSynthesizer speaks inline (no streaming, no network)
```

**After (Pro tier):**
```
User taps Play
  ↓
VoicePlaybackReducer.playButtonTapped
  ↓
Check userTier → PRO
  ↓
Apollo: query narrationAudio(recipeId, voiceId)
  ↓
VoiceResolver.narrationAudio()
  ↓
NarrationService.getOrCreateNarration()
  ↓
Gemini: Rewrite instructions → ElevenLabs TTS → R2 upload
  ↓
Return { url: "https://r2.cdn/...", plainText: null, tier: PRO }
  ↓
ElevenLabsVoiceProvider.synthesize()
  ↓
AudioPlayerManager.play(url)
  ↓
AVPlayer streams from R2 (existing flow - unchanged)
```

### App Store Submission Flow

**Before (manual):**
```
Developer → Xcode Archive → Organizer → Upload to App Store Connect
  ↓
App Store Connect web UI → Upload screenshots manually
  ↓
Fill metadata forms
  ↓
Click "Submit for Review"
  ↓
Wait for approval
  ↓
Click "Release this version"
```

**After (automated):**
```
Developer → git tag v5.0.0 → git push --tags
  ↓
GitHub Actions (or local) → bundle exec fastlane release
  ↓
Fastlane: Build IPA + Upload binary + Upload screenshots + Upload metadata + Submit for review
  ↓
Wait for approval (automated email notification)
  ↓
Developer clicks "Release this version" in App Store Connect (manual safety gate)
```

## Architectural Patterns Applied

### Pattern 1: REST-to-GraphQL Proxy

**What:** Wrap external REST API (Spoonacular) with internal NestJS service, expose via GraphQL schema.

**When to use:** External API doesn't support GraphQL, want to unify client interface, need caching layer.

**Trade-offs:**
- ✅ Pro: Client sees consistent GraphQL interface
- ✅ Pro: Easy to add caching, rate limiting, transformation
- ❌ Con: Extra hop adds latency (~50-100ms)
- ❌ Con: Must maintain mapping between REST and GraphQL schemas

**Example:**
```typescript
// Spoonacular returns REST JSON
GET /recipes/complexSearch?query=pasta
{
  "results": [
    { "id": 123, "title": "Pasta Carbonara", "image": "..." }
  ]
}

// SpoonacularService transforms to GraphQL
@Query(() => [Recipe])
async popularRecipes(@Args('limit') limit: number): Promise<Recipe[]> {
  const results = await this.spoonacular.searchRecipes('pasta', limit);
  return results.map(r => this.mapToRecipe(r));  // Transform
}
```

### Pattern 2: Strategy Pattern for Tier-Based Features

**What:** Define interface (VoiceProvider), implement multiple strategies (ElevenLabsVoiceProvider, AppleVoiceProvider), select at runtime based on user tier.

**When to use:** Feature has multiple implementations, selection depends on user context (tier, location, A/B test).

**Trade-offs:**
- ✅ Pro: Clean separation of concerns
- ✅ Pro: Easy to add new providers (e.g., Google Cloud TTS)
- ✅ Pro: Testable (mock provider in tests)
- ❌ Con: Requires dependency injection setup
- ❌ Con: More files/types to maintain

**Example:**
```swift
protocol VoiceProvider {
    func synthesize(text: String, voiceId: String?) async throws -> VoicePlaybackResult
}

// Dependency injection selects provider based on tier
extension DependencyValues {
    var voiceProvider: VoiceProvider {
        if userTier == .pro {
            return ElevenLabsVoiceProvider()
        } else {
            return AppleVoiceProvider()
        }
    }
}
```

### Pattern 3: Feature Flag Migration

**What:** Deploy new code path alongside old path, control via boolean flag, gradually roll out, remove old path.

**When to use:** Replacing critical service (Spoonacular replaces X API), need zero-downtime migration, want rollback option.

**Trade-offs:**
- ✅ Pro: Safe gradual rollout
- ✅ Pro: Instant rollback if issues detected
- ✅ Pro: A/B test new vs old
- ❌ Con: Temporary code duplication
- ❌ Con: Must remember to remove flag after migration

**Example:**
```typescript
@Query(() => [Recipe])
async feed(): Promise<Recipe[]> {
  if (process.env.ENABLE_SPOONACULAR_FEED === 'true') {
    return this.recipesFeedService.getPopularFeed();  // NEW
  } else {
    return this.recipesService.findViral('Vilnius');  // OLD
  }
}

// Rollout:
// 1. Deploy with flag=false (default to old path)
// 2. Enable for internal users (flag=true for userId in whitelist)
// 3. Enable for 10% of users (random sampling)
// 4. Enable for 100% of users
// 5. Remove old path + flag
```

### Pattern 4: Caching Layer for Rate-Limited APIs

**What:** Check database cache before calling external API, return cached data if fresh, fetch + store if stale.

**When to use:** External API has strict rate limits (Spoonacular: 150 req/day), data changes slowly (recipes are static).

**Trade-offs:**
- ✅ Pro: Stays under rate limit
- ✅ Pro: Faster response (DB query vs HTTP call)
- ❌ Con: Stale data (6-hour window)
- ❌ Con: Cold start is slow (first user after cache expiry)

**Example:**
```typescript
async getPopularFeed(limit: number): Promise<Recipe[]> {
  // Check cache first
  const cached = await this.prisma.recipe.findMany({
    where: { updatedAt: { gte: subHours(new Date(), 6) } },
    take: limit,
  });

  if (cached.length >= limit) {
    return cached;  // Cache hit - 0 API calls
  }

  // Cache miss - call Spoonacular (counts against quota)
  const fresh = await this.spoonacular.getRandomRecipes(limit);
  await this.prisma.recipe.createMany({ data: fresh });  // Store
  return fresh;
}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Breaking GraphQL Schema Without Deprecation

**What people do:**
```graphql
# WRONG - breaking change
type Query {
  # viralRecipes(location: String!): [Recipe!]!  ← REMOVED
  popularRecipes(limit: Int): [Recipe!]!
}
```

**Why it's wrong:** iOS app crashes when calling `viralRecipes` query (query not found error).

**Do this instead:**
```graphql
# RIGHT - deprecate first, remove later
type Query {
  viralRecipes(location: String!): [Recipe!]! @deprecated(reason: "Use popularRecipes instead")
  popularRecipes(limit: Int): [Recipe!]!
}
```

**Migration steps:**
1. Add `popularRecipes` query (iOS still calls `viralRecipes`)
2. Deploy backend
3. Update iOS to call `popularRecipes`
4. Deploy iOS app
5. After 100% rollout, remove `viralRecipes` query

### Anti-Pattern 2: Sharing Audio Session State Across Actors

**What people do:**
```swift
// WRONG - AVAudioSession is not Sendable, race conditions
actor AudioPlayerManager {
    func play() {
        let session = AVAudioSession.sharedInstance()  // ⚠️ Main actor isolation
        try session.setActive(true)
    }
}
```

**Why it's wrong:** `AVAudioSession` must be configured on main thread, but actor may run on background thread → crash or silent failure.

**Do this instead:**
```swift
// RIGHT - configure session once in AppDelegate (main thread)
@MainActor
class AppDelegate: UIApplicationDelegate {
    func application(...) -> Bool {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
        return true
    }
}

// Actor just uses pre-configured session
actor AudioPlayerManager {
    func play() {
        // Session already active - just create player
        let player = AVPlayer(url: url)
        player.play()
    }
}
```

### Anti-Pattern 3: Hardcoding Tier Logic in Multiple Places

**What people do:**
```swift
// WRONG - tier check duplicated everywhere
func playRecipe() {
    if user.tier == .pro {
        useElevenLabs()
    } else {
        useAppleSpeech()
    }
}

func uploadVoice() {
    if user.tier == .pro {
        allowUpload()
    } else {
        showPaywall()
    }
}
```

**Why it's wrong:** Tier logic scattered, hard to change, easy to miss spots, testing requires mocking user tier in 20 places.

**Do this instead:**
```swift
// RIGHT - dependency injection selects implementation once
extension DependencyValues {
    var voiceProvider: VoiceProvider {
        userTier == .pro ? ElevenLabsVoiceProvider() : AppleVoiceProvider()
    }
}

// Reducers just call .voiceProvider - no tier checks
func reduce(into state: inout State, action: Action) -> Effect<Action> {
    case .playButtonTapped:
        return .run { send in
            try await voiceProvider.synthesize(...)  // Tier-agnostic
        }
}
```

### Anti-Pattern 4: Blocking API Calls Without Caching

**What people do:**
```typescript
// WRONG - every feed request hits Spoonacular API (150 req/day limit blown in 1 hour)
@Query(() => [Recipe])
async popularRecipes() {
  return this.spoonacular.getRandomRecipes(20);  // External API call
}
```

**Why it's wrong:** 100 users opening app = 100 API calls → 150 req/day limit exhausted by 10 AM.

**Do this instead:**
```typescript
// RIGHT - cache with TTL
@Query(() => [Recipe])
async popularRecipes() {
  // Check cache first
  const cached = await this.redis.get('popular:recipes');
  if (cached) return JSON.parse(cached);

  // Fetch from API
  const fresh = await this.spoonacular.getRandomRecipes(20);

  // Store with 6-hour TTL
  await this.redis.setex('popular:recipes', 21600, JSON.stringify(fresh));

  return fresh;
}
```

## Scaling Considerations

| Component | 0-1k users | 1k-10k users | 10k-100k users |
|-----------|------------|--------------|----------------|
| Spoonacular API | Daily cron (100 req) + cache | Same (cache hit rate >95%) | Same (free tier sufficient) |
| AVSpeechSynthesizer | Client-side (no backend) | Client-side (no backend) | Client-side (no backend) |
| ElevenLabs (Pro only) | Pay-per-use (~10 Pro users) | Monitor costs, set budget caps | May need ElevenLabs Pro plan |
| PostgreSQL | Single instance | Connection pooling (Prisma) | Read replicas for feed queries |
| R2 Storage | Free tier (10 GB) | Free tier (up to 100 GB) | Paid tier ($0.015/GB/month) |

### Scaling Priorities

**First bottleneck:** Spoonacular 150 req/day limit
- **When:** If cache hit rate drops below 90% (more than 150 unique feed requests/day)
- **Fix:** Increase cache TTL from 6h → 24h, or upgrade to Spoonacular Pro ($29/mo for 1500 req/day)

**Second bottleneck:** PostgreSQL feed queries
- **When:** Feed query latency > 500ms (10k+ users)
- **Fix:** Add Redis cache layer (Redis Cloud free tier: 30 MB), cache feed results in Redis with 1-hour TTL

**Third bottleneck:** ElevenLabs API costs (Pro users only)
- **When:** >100 Pro users playing voices regularly
- **Fix:** Aggressive narration caching (already implemented in NarrationScript table), pre-generate narrations for popular recipes during batch job

## Integration Points Summary

### External Services Modified

| Service | Before v5.0 | After v5.0 | Integration Pattern |
|---------|-------------|------------|---------------------|
| X API | Recipe scraping | REMOVED | N/A |
| Imagen 4 | Image generation | REMOVED | N/A |
| Spoonacular | N/A | Recipe data + images | REST proxy → GraphQL |
| ElevenLabs | All users | Pro users only | Conditional via tier check |
| AVSpeechSynthesizer | N/A | Free users only | TCA dependency injection |

### Internal Boundaries Modified

| Boundary | Before v5.0 | After v5.0 | Communication |
|----------|-------------|------------|---------------|
| FeedFeature ↔ Backend | viralRecipes query | popularRecipes query | GraphQL (Apollo) |
| VoicePlayback ↔ Backend | narrationAudio query | narrationAudio query (modified schema) | GraphQL (Apollo) |
| VoicePlayback ↔ AudioPlayer | AVPlayer only | AVPlayer OR AVSpeechSynthesizer | TCA effects |
| Backend ↔ Spoonacular | N/A | REST API calls | Axios HTTP client |
| Fastlane ↔ App Store Connect | Manual upload | Automated upload | App Store Connect API |

## Build Order Recommendation

**Phase 1: Backend Spoonacular Integration** (Non-breaking)
1. Add `SpoonacularService` with REST client
2. Add `sourceType` and `spoonacularId` columns to Recipe table (nullable, default null)
3. Add `popularRecipes` query to GraphQL schema (keep `viralRecipes` deprecated)
4. Add feature flag `ENABLE_SPOONACULAR_FEED`
5. Test with flag=true internally
6. Deploy to production with flag=false

**Phase 2: iOS Voice Tier Split** (Requires backend deploy first)
1. Add `SpeechSynthesizerManager` wrapper around AVSpeechSynthesizer
2. Add `AppleVoiceProvider` and `ElevenLabsVoiceProvider` strategies
3. Modify `VoicePlaybackReducer` to check tier before playback
4. Update GraphQL query to fetch `plainText` field
5. Test with FREE and PRO mock users
6. Deploy iOS app (backward compatible - still calls old narrationAudio schema)

**Phase 3: Backend Voice Schema Update** (Breaking change)
1. Add `UserTier` enum to User model (default: FREE)
2. Modify `narrationAudio` query to return `{ url, plainText, tier }`
3. Update resolver to skip ElevenLabs for FREE tier
4. Deploy backend
5. iOS app gracefully handles both old and new schema (Apollo cache)

**Phase 4: iOS Feed Update** (Non-breaking)
1. Replace `viralRecipes` query with `popularRecipes` in FeedFeature
2. Remove "VIRAL" badge UI, show popularity score instead
3. Test feed rendering
4. Deploy iOS app
5. Monitor for GraphQL errors (should be zero - both queries exist)

**Phase 5: Backend Cleanup** (After iOS rollout complete)
1. Remove `viralRecipes` query from GraphQL schema
2. Remove `ScrapingService`, `XApiService`, `InstagramService`
3. Remove `ImageGenerationProcessor` and Imagen 4 dependencies
4. Enable `ENABLE_SPOONACULAR_FEED` flag for 100% of users
5. Remove feature flag code
6. Deploy backend

**Phase 6: Fastlane Release Lane** (Independent - can happen anytime)
1. Add `release` lane to Fastfile
2. Configure App Store Connect API key
3. Test `bundle exec fastlane release` locally
4. Optionally configure GitHub Actions for automated releases

**Dependencies:**
- Phase 2 requires Phase 1 (iOS needs backend with `plainText` field)
- Phase 3 requires Phase 2 (backend assumes iOS knows how to handle tier-based responses)
- Phase 5 requires Phase 4 (can't remove `viralRecipes` while iOS still calls it)
- Phase 6 independent (build system changes don't affect runtime)

## Risk Mitigation

### Risk 1: Spoonacular API 150 req/day limit exhausted

**Likelihood:** MEDIUM (cache hit rate depends on user behavior)
**Impact:** HIGH (app shows stale recipes or errors)

**Mitigation:**
- 6-hour cache TTL (expected 95%+ cache hit rate)
- Daily batch job at 2 AM UTC (off-peak) to pre-warm cache
- Monitor API usage with CloudWatch alert at 120 req/day threshold
- Fallback: If quota exhausted, return cached recipes (even if stale)

### Risk 2: AVSpeechSynthesizer quality gap vs ElevenLabs

**Likelihood:** HIGH (robotic voice vs natural cloned voice)
**Impact:** MEDIUM (free users churn, don't convert to Pro)

**Mitigation:**
- Clear messaging: "Upgrade to Pro for [loved one]'s voice"
- Preview both voices in onboarding (side-by-side comparison)
- Optimize AVSpeech parameters (rate, pitch, voice selection)
- A/B test: Free tier sees upgrade prompt after 3 recipe plays

### Risk 3: GraphQL schema changes break iOS app

**Likelihood:** LOW (if deprecation process followed)
**Impact:** HIGH (app crashes for all users)

**Mitigation:**
- Never remove queries without deprecation period
- Add new queries first, remove old queries after iOS rollout
- Apollo cache handles both old and new schema gracefully
- Automated GraphQL schema compatibility checks (Apollo Studio)

### Risk 4: Fastlane submission fails App Store review

**Likelihood:** MEDIUM (metadata errors, missing info)
**Impact:** MEDIUM (manual resubmission required)

**Mitigation:**
- Test with `fastlane precheck` before submission (validates metadata)
- Review notes.txt includes third-party AI disclosure (Spoonacular, Gemini)
- Demo account credentials in review_information/ directory
- Monitor submission status via App Store Connect webhook

## Sources

**Spoonacular API:**
- [Spoonacular API Documentation](https://spoonacular.com/food-api/docs) - Official API reference
- [Spoonacular API Pricing](https://spoonacular.com/food-api/pricing) - Free tier limits (150 req/day)
- [Spoonacular Recipe Data Model](https://www.allthingsdev.co/apimarketplace/documentation/Spoonacular%20API/66750a5670009c3ab417c4ed) - Recipe schema

**AVSpeechSynthesizer:**
- [swift-tts GitHub](https://github.com/renaudjenny/swift-tts) - TCA integration library
- [AVSpeechSynthesizer Apple Docs](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) - Official API reference
- [AVSpeechSynthesizer Background Audio](https://gist.github.com/hashaam/3f5968a54184fef4cc556f3aa7221baa) - Audio session configuration
- [WWDC 2020: Seamless Speech](https://developer.apple.com/videos/play/wwdc2020/10022/) - usesApplicationAudioSession pattern

**NestJS GraphQL:**
- [NestJS GraphQL REST Proxy Example](https://github.com/rajinwonderland/nest-graphql-newsapi) - Pattern reference
- [NestJS GraphQL Code-First Guide](https://medium.com/@pratikkumar2210/nestjs-graphql-a-comprehensive-guide-to-code-first-api-design-9064a581fc10) - Architecture patterns

**Apollo Client Migration:**
- [Apollo iOS 2.0 Migration Guide](https://www.apollographql.com/docs/ios/migrations/2.0) - Schema compatibility
- [GraphQL Schema Versioning](https://oneuptime.com/blog/post/2026-01-24-graphql-api-versioning/view) - Backward compatibility

**Feature Flags:**
- [Feature Flags in NestJS](https://configcat.com/blog/2022/08/19/how-to-use-feature-flags-in-nestjs/) - Implementation patterns
- [Gradual Rollouts](https://dev.to/kodus/feature-flags-and-gradual-rollouts-releasing-software-safely-at-scale-5h00) - Deployment strategies

**Fastlane:**
- [Fastlane App Store Deployment](https://docs.fastlane.tools/getting-started/ios/appstore-deployment/) - Official guide
- [Fastlane Deliver](https://medium.com/@fepersembe/mastering-app-store-submissions-with-fastlane-deliver-27e47e920d84) - Metadata automation
- [Mobile CI/CD with Fastlane](https://calmops.com/mobile/mobile-ci-cd-fastlane-github-actions/) - 2026 guide

---
*Architecture research for: Kindred v5.0 Lean App Store Launch*
*Researched: 2026-04-04*
*Confidence: HIGH - All integration patterns verified with official documentation and existing codebase structure*
