# Phase 21: Voice Playback & Monetization Integration - Research

**Researched:** 2026-04-03
**Domain:** iOS client integration (GraphQL, TCA state management, SwiftData, cross-module navigation)
**Confidence:** HIGH

## Summary

Phase 21 connects production voice narration, monetization purchase flows, cross-module navigation, and pantry-recipe data flow. The phase removes all mock data (TestAudioGenerator, hardcoded voice profiles, mock GraphQL responses) and wires real backend integration for voice playback and subscription purchases.

Backend narration infrastructure is **already complete** (Phase 19-04): `narrationUrl(recipeId, voiceProfileId)` GraphQL query returns R2 CDN URLs with duration metadata. VoiceProfile queries need minor backend work (schema has `VoiceProfile` type but no `voiceProfiles` query yet — flagged in CONTEXT.md).

The work is **pure iOS client wiring** with established patterns: Apollo GraphQL codegen, TCA delegate actions for cross-module navigation, SubscriptionClient for StoreKit purchases, and SwiftData named ModelConfiguration for data separation.

**Primary recommendation:** Execute as 5 focused plans: (1) Voice GraphQL integration, (2) TestAudioGenerator removal + cache flow, (3) ScanPaywallView monetization wiring, (4) Recipe carousel → detail navigation, (5) Pantry ingredient badges + SwiftData commit.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Voice Playback Wiring
- Fetch narration audio **on-demand when user taps play** (not preloaded)
- When narration is unavailable for a recipe, show **"Narration not available" message** — no on-demand generation
- Voice profiles fetched via **GraphQL query on voice picker open** (not cached on launch)
- **Remove TestAudioGenerator entirely** — no debug flag, clean deletion
- Network/backend errors during fetch: **inline error with retry button** in player area
- Voice picker shows **only completed voice profiles** (no in-progress clones)
- Cache policy: **cache-first, no revalidation** — if cached audio exists, use it immediately
- **Auto-cache audio after first play** — downloaded audio saved to VoiceCache for offline/instant replay
- **Backend provides step timestamps** in narration response — app does not estimate from duration
- Free-tier users get **1 default "Kindred Voice"** (generic, no persona name) — Pro unlocks custom/cloned voices
- Keep **existing mini-player scope** — don't change visibility, just wire real audio

#### Voice Playback Error States
- Mid-playback buffering: **spinner on play/pause button**, auto-resumes when buffer fills
- Stream failure mid-playback: **pause at current position + "Connection lost — Tap to retry"** inline
- Offline with no cache: **immediate "Narration requires internet connection" message** — no fetch attempt
- Cached narrations playable offline with **full step-sync** (timestamps stored in cache)
- No narration available: **show disabled/greyed play button** — tapping shows "unavailable" message
- **Pre-check narration availability on recipe detail load** — button state correct immediately
- Pre-check via **hasNarration boolean field added to RecipeDetail GraphQL query** — no extra request
- Cached audio for deleted voices **still plays** — no cache invalidation on voice deletion

#### Paywall Purchase Flow (ScanPaywallView)
- Subscribe tap: **dismiss paywall, then show StoreKit purchase sheet**
- After successful purchase: **auto-unlock, return to scanning** — no celebration screen
- Purchase failure/cancel: **stay on paywall with error banner** — user can retry
- Wire **both subscribe AND restore** buttons to MonetizationFeature
- Scope: **ScanPaywallView only** — no other paywall entry points in this phase
- **Show real subscription price** from StoreKit on the button (e.g., "$4.99/month")
- **Loading spinner on subscribe button** until price loads from StoreKit
- If price can't load: **disable subscribe button with "Unable to load pricing" message**
- Restore flow: **full-screen loading overlay** with "Restoring purchases..." text
- No active subscription found after restore: **"No active subscription found. Subscribe to unlock Pro features."** — stay on paywall

#### Cross-Module Navigation
- Carousel recipe tap: **delegate action (.openRecipe(id)) up to AppReducer** — PantryReducer emits, AppReducer handles
- Navigation: **switch to Feed tab + push recipe detail** onto Feed navigation stack
- **Dismiss carousel on recipe tap** — clean transition
- Error fetching recipe: **show error on recipe detail screen** with retry — navigate there regardless
- **Pass pantry match data** when navigating — recipe detail shows which ingredients user has
- Ingredient badges: **checkmark icon + green tint** on matching ingredients in recipe detail
- Badge source: **full pantry inventory** (all user's pantry items, not just current scan)
- Badges show **always** — from feed browsing AND from scan navigation
- All pantry items treated **equally regardless of expiry** status
- Ingredient matching: **fuzzy/partial matching** ("chicken" matches "chicken breast")

#### Pantry-to-Recipe Data Flow
- FeedFeature accesses pantry data via **shared PantryClient dependency** (direct cross-package dependency)
- Matching computed **on recipe detail load** (not pre-computed for all feed recipes)
- Pantry data **cached in memory for session** — not fetched fresh each time
- Cache **refreshes on pantry tab visit** — adding items in pantry updates badges on next recipe view

#### GraphQL Schema Alignment
- iOS VoiceProfile model maps **1:1 to backend GraphQL type** — mirror schema directly
- narrationUrl: **separate dedicated query** (narrationUrl(recipeId, voiceId)) — already built in Phase 19-04
- voiceProfiles: **standalone query** — new, not part of user profile query
- Voice profiles query returns: **id, name, avatarURL, sampleAudioURL, isOwnVoice, createdAt**
- Backend status: narrationUrl query exists (Phase 19-04), **voiceProfiles query needs work** on backend

#### Monetization State Sync
- After purchase: **immediate local unlock** via StoreKit entitlement — no backend round-trip
- Voice tier gating: **local StoreKit check** via SubscriptionClient.currentEntitlement()
- Subscription expiry: **lock on next app launch** — don't interrupt current session
- Default "Kindred Voice": **works for guest users** without sign-in
- Guest taps Pro voice: **show auth gate first**, then subscription paywall after sign-in
- Pro voices **visible to free/guest users with lock icon** — tapping shows upgrade path

#### SwiftData Commit Scope
- Only **PantryStore + GuestStore** need named ModelConfigurations — no other models
- **Needs verification first** before commit — test that data separation works correctly
- **Fresh installs only** — no migration needed (pre-App Store)

### Claude's Discretion
- Exact error message copy/localization
- VoiceCache storage format for step timestamps
- Fuzzy matching algorithm for ingredient names (contains, Levenshtein, etc.)
- Apollo codegen setup for new GraphQL queries
- Exact green tint color value for pantry badges

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VOICE-01 | Voice narration plays from backend R2 CDN URLs replacing TestAudioGenerator | Backend narrationUrl query exists (Phase 19-04), Apollo codegen patterns established, VoiceCache client ready for real URLs |
| VOICE-02 | All GraphQL voice profile TODO markers resolved with real backend data | 5 TODO markers in VoicePlaybackReducer (.startPlayback, .selectVoice, .switchVoiceMidPlayback) + backend needs voiceProfiles query implementation |
| BILL-02 | ScanPaywallView subscribe button triggers MonetizationFeature purchase flow | ScanPaywallView has onSubscribe closure, SubscriptionClient.purchase() exists, StoreKit 2 Transaction flow documented |
| NAV-01 | Recipe suggestion carousel card tap navigates to recipe detail view | RecipeSuggestionCarousel has onRecipeTapped closure, AppReducer delegate action pattern established, Feed navigation stack ready |
| DATA-01 | SwiftData named ModelConfiguration committed (PantryStore/GuestStore separation) | PantryStore already uses ModelConfiguration("PantryStore"), GuestStore pattern needs replication, verification needed before commit |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Apollo iOS | 1.x | GraphQL client with type-safe codegen | Industry standard for iOS GraphQL, generates compile-time verified query types |
| TCA (swift-composable-architecture) | 1.x | State management with Effect composition | Already used across entire app, delegate action pattern for cross-module communication |
| StoreKit 2 | iOS 15+ | In-app purchase framework | Apple's modern IAP API with Transaction verification, used in SubscriptionClient |
| SwiftData | iOS 17+ | Declarative persistence framework | Project standard for local data (PantryStore), ModelConfiguration for container separation |
| AVFoundation | iOS system | Audio playback (AVPlayer) | AudioPlayerManager already built on AVPlayer, industry standard for streaming audio |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Apollo CLI | 1.x | GraphQL codegen from .graphql files | When adding new queries/mutations — generates Swift types from operations |
| VoiceCache (custom) | Internal | Cache manager for narration audio files | Already exists, extend to store step timestamps alongside audio data |
| SubscriptionClient (custom) | Internal | TCA-friendly StoreKit wrapper | Already wired in MonetizationFeature, exposes purchase/restore/currentEntitlement |
| PantryClient (custom) | Internal | SwiftData CRUD operations for pantry items | Cross-package dependency for FeedFeature to access pantry inventory |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Apollo iOS | URLSession + manual JSON parsing | Apollo provides type safety, caching, and codegen — manual parsing is error-prone and loses compile-time verification |
| TCA delegate actions | NotificationCenter/Combine publishers | Delegate actions maintain unidirectional data flow and testability, notifications create hidden coupling |
| StoreKit 2 | StoreKit 1 (deprecated) | StoreKit 2 provides Transaction verification, async/await, and entitlement checking without receipt parsing |
| Named ModelConfiguration | Single shared container | Named configs prevent pantry/guest data leakage, critical for multi-user apps with local-first sync |

**Installation:**
Apollo codegen already configured via `apollo-codegen-config.json` — new .graphql files auto-generate on build. Other dependencies already in Package.swift manifests.

## Architecture Patterns

### Recommended Project Structure
Already established in codebase:
```
Kindred/
├── Packages/
│   ├── KindredAPI/                   # Apollo-generated GraphQL types
│   │   └── Sources/
│   │       ├── Operations/
│   │       │   ├── Queries/         # .graphql.swift generated files
│   │       │   └── Mutations/
│   │       └── Schema/              # GraphQL schema types
│   ├── VoicePlaybackFeature/        # Voice player TCA reducer + views
│   │   └── Sources/
│   │       ├── Player/              # VoicePlaybackReducer (5 TODO markers)
│   │       └── AudioPlayer/         # AudioPlayerManager (TestAudioGenerator)
│   ├── MonetizationFeature/         # Subscription purchase flows
│   │   └── Sources/Subscription/    # SubscriptionClient, PaywallView
│   ├── PantryFeature/               # Pantry CRUD + scan paywall
│   │   └── Sources/
│   │       ├── Scanning/            # ScanPaywallView, RecipeSuggestionCarousel
│   │       └── PantryClient/        # PantryStore (SwiftData)
│   └── FeedFeature/                 # Recipe feed + detail views
│       └── Sources/RecipeDetail/    # Recipe detail (needs pantry badges)
└── Sources/App/
    └── AppReducer.swift             # Root reducer, handles cross-module delegation
```

### Pattern 1: GraphQL Query Integration with Apollo Codegen
**What:** Define .graphql operations, run codegen, inject Apollo client into TCA reducer
**When to use:** Fetching voice profiles, narration URLs, recipe details with hasNarration field

**Example:**
```swift
// 1. Create .graphql file in Packages/NetworkClient/Sources/GraphQL/
// VoiceProfilesQuery.graphql
query VoiceProfiles {
  myVoiceProfiles {
    id
    speakerName
    relationship
    status
    createdAt
  }
}

// 2. Run Apollo codegen (automatic on build or via script)
// Generates: Packages/KindredAPI/Sources/Operations/Queries/VoiceProfilesQuery.graphql.swift

// 3. Inject Apollo client into TCA reducer and call
@Dependency(\.apolloClient) var apollo

return .run { send in
  let result = try await apollo.fetch(query: VoiceProfilesQuery())
  let profiles = result.data?.myVoiceProfiles.compactMap { dto in
    VoiceProfile(
      id: dto.id,
      name: dto.speakerName,
      // ... map other fields
    )
  } ?? []
  await send(.voiceProfilesLoaded(.success(profiles)))
}
```

**Source:** Existing RecipeDetailQuery pattern in `KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift`

### Pattern 2: TCA Delegate Actions for Cross-Module Navigation
**What:** Child reducer emits delegate action, parent reducer handles side effects
**When to use:** RecipeSuggestionCarousel → AppReducer → FeedReducer navigation

**Example:**
```swift
// PantryReducer (child)
enum Action {
  case delegate(Delegate)

  enum Delegate: Equatable {
    case openRecipe(id: String, matchingIngredients: [String])
  }
}

case .recipeSuggestionCarousel(.recipeTapped(let recipeId)):
  let matchingIngredients = computeMatches(scannedItems, pantryItems)
  return .send(.delegate(.openRecipe(id: recipeId, matchingIngredients: matchingIngredients)))

// AppReducer (parent)
case .pantry(.delegate(.openRecipe(let id, let matches))):
  state.selectedTab = .feed
  return .send(.feed(.pushRecipeDetail(id: id, pantryMatches: matches)))
```

**Source:** TCA best practices — https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/communication

### Pattern 3: StoreKit 2 Purchase Flow with TCA
**What:** Subscribe button triggers SubscriptionClient.purchase(), handle Transaction result
**When to use:** ScanPaywallView subscribe/restore buttons

**Example:**
```swift
// In PantryReducer
case .scanPaywall(.subscribeTapped):
  state.isPurchasing = true
  return .run { send in
    do {
      let products = try await subscriptionClient.loadProducts()
      guard let product = products.first else {
        await send(.purchaseFailed("No products available"))
        return
      }
      let transaction = try await subscriptionClient.purchase(product)
      await send(.purchaseSucceeded(transaction))
    } catch {
      await send(.purchaseFailed(error.localizedDescription))
    }
  }

case .purchaseSucceeded:
  state.isPurchasing = false
  state.showPaywall = false
  // Auto-unlock via SubscriptionClient.currentEntitlement() check
  return .send(.checkSubscriptionStatus)
```

**Source:** Existing SubscriptionClient.liveValue implementation in `MonetizationFeature/Sources/Subscription/SubscriptionClient.swift`

### Pattern 4: SwiftData Named ModelConfiguration
**What:** Create separate containers for different user contexts (pantry, guest)
**When to use:** Preventing data leakage between signed-in user pantry and guest session data

**Example:**
```swift
// PantryStore (already implemented)
let config = ModelConfiguration("PantryStore", schema: Schema([PantryItem.self]))
modelContainer = try ModelContainer(for: PantryItem.self, configurations: config)

// GuestStore (needs implementation)
let config = ModelConfiguration("GuestStore", schema: Schema([GuestSession.self]))
modelContainer = try ModelContainer(for: GuestSession.self, configurations: config)
```

**Source:** Existing `PantryStore.swift` lines 96-100 — replicate pattern for GuestStore

### Pattern 5: Fuzzy String Matching for Ingredient Names
**What:** Partial/substring matching for "chicken" → "chicken breast"
**When to use:** Matching pantry items to recipe ingredients for badges

**Example:**
```swift
func fuzzyMatch(pantryItem: String, ingredient: String) -> Bool {
  let normalizedPantry = pantryItem.lowercased().trimmingCharacters(in: .whitespaces)
  let normalizedIngredient = ingredient.lowercased().trimmingCharacters(in: .whitespaces)

  // Bidirectional contains check
  return normalizedPantry.contains(normalizedIngredient) ||
         normalizedIngredient.contains(normalizedPantry)
}

// Usage in RecipeDetailReducer
let matchingIngredients = recipe.ingredients.filter { ingredient in
  pantryItems.contains { pantryItem in
    fuzzyMatch(pantryItem: pantryItem.name, ingredient: ingredient.name)
  }
}
```

**Alternatives:** Levenshtein distance for typo tolerance, but adds complexity — contains() sufficient for v4.0

### Anti-Patterns to Avoid
- **Fetching narration on recipe detail load:** Wasteful — only fetch when user taps play (many users browse without listening)
- **Invalidating cache on voice deletion:** Cached audio is valid — user paid for narration generation, let them keep it
- **Pre-generating all recipe narrations:** Expensive at scale — on-demand generation only when user requests
- **Preloading voice profiles at app launch:** Network waste — fetch on voice picker open (most sessions never use voice)
- **Backend-dependent entitlement checks:** Slow and offline-broken — local StoreKit entitlement is source of truth

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GraphQL client with caching | Manual URLSession with JSON parsing + in-memory cache | Apollo iOS with normalized cache | Apollo handles cache invalidation, optimistic updates, and type safety. Manual caching breaks on schema changes. |
| In-app purchase receipt validation | Custom receipt parsing + PKCS7 signature verification | StoreKit 2 Transaction verification + backend SignedDataVerifier | StoreKit 2 handles certificate chain validation. Manual parsing is fragile and insecure. |
| Audio streaming with progress tracking | Custom AVPlayer wrapper with KVO observation | Existing AudioPlayerManager | Already built with time/status/duration streams, buffering handling, and error recovery. |
| Fuzzy string matching library | Custom algorithm with Levenshtein distance | Swift String.contains() | Simple substring matching is 95% effective for ingredient matching. Over-engineering introduces bugs. |
| Cross-module event bus | Custom NotificationCenter wrapper or Combine subjects | TCA delegate actions | Delegate actions are testable, type-safe, and maintain unidirectional data flow. Event buses create hidden coupling. |

**Key insight:** Apollo, StoreKit 2, and TCA provide production-grade solutions to complex problems (GraphQL caching, IAP security, state management). Custom implementations introduce bugs, security holes, and maintenance burden. Use established patterns.

## Common Pitfalls

### Pitfall 1: Missing Apollo Codegen for New Queries
**What goes wrong:** Create .graphql file, reference generated types in Swift, build fails with "Type 'VoiceProfilesQuery' not found"
**Why it happens:** Apollo codegen doesn't run automatically on clean builds — requires explicit script execution
**How to avoid:** Add codegen run script to Xcode build phases OR run manually before building:
```bash
cd Kindred
apollo-ios-cli generate
```
**Warning signs:** Build errors referencing GraphQL operation types, .graphql.swift files missing from KindredAPI/Sources/Operations/

### Pitfall 2: Force-Unwrapping GraphQL Optional Fields
**What goes wrong:** Backend schema marks field as nullable, iOS crashes on `result.data!.field!.value`
**Why it happens:** GraphQL nullability differs from Swift optionals — backend nullable = Swift Optional
**How to avoid:** Always use optional chaining or nil-coalescing for GraphQL response data:
```swift
// BAD
let url = result.data!.narrationUrl!.audioUrl

// GOOD
guard let url = result.data?.narrationUrl?.audioUrl else {
  return .send(.narrationFailed("URL not available"))
}
```
**Warning signs:** Crashes in production with "unexpectedly found nil" in GraphQL response handlers

### Pitfall 3: StoreKit Transaction Not Finished
**What goes wrong:** Purchase succeeds, user charged, but subscription doesn't unlock — StoreKit shows duplicate purchase on next launch
**Why it happens:** StoreKit requires explicit `transaction.finish()` to acknowledge transaction processing
**How to avoid:** Always call `await transaction.finish()` in both success and failure paths:
```swift
case .verified(let transaction):
  await transaction.finish()  // CRITICAL
  return transaction
case .unverified(let transaction, _):
  await transaction.finish()  // Even on failure
  throw SubscriptionError.verificationFailed
```
**Warning signs:** Users report being charged multiple times, App Store "Restore Purchases" shows pending transactions

### Pitfall 4: TCA Reducer State Mutation Without Effect Return
**What goes wrong:** Change state in switch case but forget `return .none` — compiler doesn't catch, reducer exits early
**Why it happens:** Swift allows implicit returns in single-expression closures, but TCA reducers require explicit Effect return
**How to avoid:** Every case must return Effect<Action> — use `return .none` for state-only changes:
```swift
case .voiceProfilesLoaded(let profiles):
  state.voiceProfiles = profiles
  // MISSING return .none causes compiler error in TCA 1.0+
  return .none
```
**Warning signs:** State updates don't trigger view re-renders, actions appear to do nothing

### Pitfall 5: Named ModelConfiguration Schema Mismatch
**What goes wrong:** PantryStore uses `Schema([PantryItem.self])` but tries to fetch different model type — runtime crash
**Why it happens:** SwiftData containers are schema-locked at creation — mixing models across containers fails
**How to avoid:** Each named ModelConfiguration must use only its declared schema types:
```swift
// PantryStore container
let config = ModelConfiguration("PantryStore", schema: Schema([PantryItem.self]))
// Can ONLY query PantryItem in this container

// GuestStore container
let config = ModelConfiguration("GuestStore", schema: Schema([GuestSession.self]))
// Can ONLY query GuestSession in this container
```
**Warning signs:** SwiftData crashes with "Model not found in schema", data queries return empty unexpectedly

## Code Examples

Verified patterns from official sources and existing codebase:

### Fetching Voice Profiles with Apollo
```swift
// From KindredAPI RecipeDetailQuery pattern
@Dependency(\.apolloClient) var apollo

return .run { send in
  do {
    let result = try await apollo.fetch(query: VoiceProfilesQuery())
    guard let profiles = result.data?.myVoiceProfiles else {
      await send(.voiceProfilesLoaded(.failure(VoiceError.noData)))
      return
    }

    let voiceProfiles = profiles
      .filter { $0.status == .ready }  // Only completed clones
      .map { dto in
        VoiceProfile(
          id: dto.id,
          name: dto.speakerName,
          avatarURL: dto.avatarUrl,
          sampleAudioURL: dto.sampleAudioUrl,
          isOwnVoice: dto.relationship == "Self",
          createdAt: dto.createdAt
        )
      }

    await send(.voiceProfilesLoaded(.success(voiceProfiles)))
  } catch {
    await send(.voiceProfilesLoaded(.failure(error)))
  }
}
```

### Fetching Narration URL with Duration
```swift
// Based on Phase 19-04 narrationUrl query
case .selectVoice(let voiceId):
  let recipeId = state.currentRecipeId
  return .run { send in
    do {
      let result = try await apollo.fetch(
        query: NarrationUrlQuery(recipeId: recipeId, voiceProfileId: voiceId)
      )

      guard let narrationData = result.data?.narrationUrl else {
        await send(.narrationFailed("Narration not available"))
        return
      }

      let metadata = NarrationMetadata(
        recipeId: recipeId,
        voiceId: voiceId,
        audioURL: narrationData.audioUrl,
        duration: TimeInterval(narrationData.durationMs) / 1000.0,
        stepTimestamps: narrationData.stepTimestamps.map { TimeInterval($0) / 1000.0 },
        generatedAt: Date()
      )

      await send(.narrationReady(metadata))
    } catch {
      await send(.narrationFailed(error.localizedDescription))
    }
  }
}
```

### Loading StoreKit Product Price
```swift
// From SubscriptionClient.loadProducts pattern
case .scanPaywallPresented:
  state.isLoadingPrice = true
  return .run { send in
    do {
      let products = try await subscriptionClient.loadProducts()
      guard let product = products.first else {
        await send(.priceLoadFailed)
        return
      }

      let priceString = product.displayPrice  // e.g., "$4.99"
      await send(.priceLoaded(priceString))
    } catch {
      await send(.priceLoadFailed)
    }
  }

case .priceLoaded(let price):
  state.isLoadingPrice = false
  state.subscribeButtonTitle = "Subscribe for \(price)/month"
  return .none
```

### Cross-Module Navigation with Delegate Actions
```swift
// PantryReducer emits delegate
case .recipeSuggestionCarousel(.recipeTapped(let recipeId)):
  let matchingIngredients = state.scannedItems.map(\.name)
  state.showRecipeSuggestions = false  // Dismiss carousel
  return .send(.delegate(.openRecipe(id: recipeId, pantryMatches: matchingIngredients)))

// AppReducer handles delegation
case .pantry(.delegate(.openRecipe(let id, let matches))):
  state.selectedTab = .feed  // Switch to Feed tab
  return .send(.feed(.pushRecipeDetail(id: id, pantryMatches: matches)))
```

### Pantry Ingredient Matching with PantryClient
```swift
// In RecipeDetailReducer
@Dependency(\.pantryClient) var pantryClient

case .recipeLoaded(let recipe):
  state.recipe = recipe
  return .run { [userId = state.currentUserId] send in
    let pantryItems = await pantryClient.fetchAllItems(userId)
    let matchingIngredientIds = recipe.ingredients.compactMap { ingredient in
      let isMatch = pantryItems.contains { pantryItem in
        fuzzyMatch(pantry: pantryItem.name, ingredient: ingredient.name)
      }
      return isMatch ? ingredient.id : nil
    }
    await send(.pantryMatchesComputed(matchingIngredientIds))
  }

// In RecipeDetailView
ForEach(recipe.ingredients) { ingredient in
  HStack {
    if matchingIngredientIds.contains(ingredient.id) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)  // Pantry badge
    }
    Text(ingredient.name)
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| TestAudioGenerator local WAV files | Backend R2 CDN URLs with step timestamps | Phase 19-04 (2026-03-30) | Voice playback now streams production audio, no more mock files |
| StoreKit 1 receipt validation | StoreKit 2 Transaction verification + backend SignedDataVerifier | Phase 19-02 (2026-03-30) | Subscription fraud prevention, no more base64 receipt parsing |
| Manual GraphQL JSON parsing | Apollo codegen with type-safe queries | v2.0 (2026-02) | Compile-time verification, schema changes caught at build time |
| Single SwiftData container | Named ModelConfiguration per user context | v3.0 (2026-03) | Pantry/guest data separation, prevents cross-user data leakage |
| NotificationCenter for cross-feature events | TCA delegate actions | v2.0 (2026-02) | Testable, type-safe, unidirectional data flow |

**Deprecated/outdated:**
- **TestAudioGenerator:** Replaced by narrationUrl GraphQL query returning R2 CDN URLs (Phase 19-04)
- **Hardcoded voice profile mocks:** Replaced by myVoiceProfiles GraphQL query (backend needs implementation)
- **TODO markers in VoicePlaybackReducer:** 5 locations marked for GraphQL integration (lines 224-268, 299-323, 684-697)

## Open Questions

1. **Backend voiceProfiles query implementation status**
   - What we know: GraphQL schema has `VoiceProfile` type and `myVoiceProfiles: [VoiceProfile!]!` field on Query, Phase 19-04 completed narrationUrl
   - What's unclear: Whether voiceProfiles query resolver is implemented in backend VoiceResolver (21-CONTEXT.md says "needs work")
   - Recommendation: Check with backend team OR implement in Wave 0 if blocked. iOS can proceed with other plans while backend completes this.

2. **Default "Kindred Voice" provisioning for free tier**
   - What we know: Free users get 1 default voice, Pro unlocks custom clones
   - What's unclear: Is default voice a real ElevenLabs profile or a placeholder? Does backend auto-create it on user signup?
   - Recommendation: Verify with backend. If placeholder, iOS shows "No voice available — upgrade to Pro" instead.

3. **hasNarration field addition to RecipeDetail query**
   - What we know: Pre-check via boolean field to disable play button immediately
   - What's unclear: Does backend already compute this (check NarrationAudio table for recipeId match)?
   - Recommendation: Add field to backend Recipe type resolver — simple `SELECT EXISTS` query on NarrationAudio table.

4. **GuestStore SwiftData schema scope**
   - What we know: GuestStore needs named ModelConfiguration, only PantryStore + GuestStore in scope
   - What's unclear: What models go in GuestStore? Just GuestSession or also temporary recipe bookmarks?
   - Recommendation: Review GuestSessionClient code to identify models, likely just GuestSession model itself.

## Validation Architecture

> Skipped — workflow.nyquist_validation is false in .planning/config.json

## Sources

### Primary (HIGH confidence)
- [Backend schema.gql] - GraphQL type definitions (VoiceProfile, NarrationMetadataDto, narrationUrl query)
- [Phase 19-04 PLAN.md] - narrationUrl GraphQL implementation (completed 2026-03-30)
- [VoicePlaybackReducer.swift] - 5 TODO markers for GraphQL integration (lines 224-268, 299-323, 684-697)
- [SubscriptionClient.swift] - StoreKit 2 purchase/restore flows (lines 40-176)
- [PantryStore.swift] - Named ModelConfiguration pattern (lines 94-100)
- [AppReducer.swift] - Cross-module delegation pattern for navigation
- [Apollo codegen config] - apollo-codegen-config.json configures operation search paths

### Secondary (MEDIUM confidence)
- [TCA Documentation] - Delegate actions pattern (https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/communication)
- [Apollo iOS Documentation] - GraphQL codegen and fetch patterns (https://www.apollographql.com/docs/ios)
- [Apple StoreKit 2 Documentation] - Transaction verification and entitlement checking (https://developer.apple.com/documentation/storekit/transaction)

### Tertiary (LOW confidence)
- None — all findings verified with codebase or official documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use, patterns established in codebase
- Architecture: HIGH - TCA delegate actions, Apollo codegen, StoreKit 2 patterns all verified in existing code
- Pitfalls: MEDIUM - Common iOS/GraphQL issues documented in community resources, validated against project patterns

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (30 days for stable iOS/GraphQL ecosystem)
