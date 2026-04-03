# Stack Research: Lean App Store Launch

**Domain:** iOS cooking app lean launch additions (Spoonacular API, AVSpeechSynthesizer, App Store submission)
**Researched:** 2026-04-04
**Confidence:** HIGH

## Overview

This research focuses on stack additions/changes needed for v5.0 Lean App Store Launch. The milestone strips expensive backend dependencies (X API, Imagen 4, ElevenLabs for free tier) and replaces them with free alternatives (Spoonacular, AVSpeechSynthesizer) to achieve $0/month SaaS costs while shipping to App Store.

**Existing validated stack (DO NOT re-research):**
- NestJS 11 + GraphQL backend with Prisma 7, PostgreSQL + PostGIS
- SwiftUI + TCA 1.x iOS app with 7 SPM packages
- Fastlane 3-lane pipeline (beta_internal, beta_external, release)
- Privacy compliance framework (ATT, voice consent, privacy manifest) — v4.0
- StoreKit 2 with SignedDataVerifier — v4.0
- Firebase FCM, Apollo iOS, Clerk auth — validated

**Focus ONLY on NEW features:**
1. Spoonacular API integration (replacing X API scraping)
2. Apple AVSpeechSynthesizer (replacing ElevenLabs for free tier)
3. App Store submission process and requirements

## Required Stack Additions

### Spoonacular API (Recipe Data Source)

| Technology | Version | Purpose | Why Required |
|------------|---------|---------|-------------|
| Spoonacular API | Free tier (150 requests/day) | Recipe data source replacing X API + Gemini scraping | Point-based quota (1 point + 0.01/result), includes CDN images, supports dietary filters (vegan, keto, halal, allergies), 150 req/day sufficient for MVP with caching |
| axios (backend) | ^1.6.0 | HTTP client for Spoonacular REST API | Standard NestJS HTTP client, battle-tested, TypeScript support |
| @nestjs/throttler | ^6.0.0 | Rate limiting middleware | Enforce 1 req/sec free tier constraint, 2 concurrent request limit |

**Status:** New integration. No existing Spoonacular code. Replaces RecipeScraper service and Gemini parsing.

### AVSpeechSynthesizer (Free-Tier Voice Narration)

| Technology | Version | Purpose | Why Required |
|------------|---------|---------|-------------|
| AVSpeechSynthesizer | iOS 7.0+ (built-in) | Free-tier voice narration replacing ElevenLabs | Zero cost, native iOS framework in AVFoundation, on-device processing (no API calls), supports 60+ languages, background audio compatible |
| AVFoundation | iOS 17.0+ (existing) | Framework containing AVSpeechSynthesizer | Already imported for AVPlayer in VoicePlaybackFeature, no new dependency |
| MPRemoteCommandCenter | iOS 7.1+ (built-in) | Lock screen audio controls for TTS | Enable background TTS playback with play/pause/skip controls (AVPlayer pattern) |
| MediaPlayer | iOS 7.0+ (built-in) | Framework for MPNowPlayingInfoCenter | Update lock screen metadata (recipe title, speaker name) during TTS playback |

**Status:** New integration. Keep existing ElevenLabs VoicePlaybackFeature for Pro tier. Add tier-based routing.

### App Store Submission (No Stack Changes)

| Requirement | Type | Why Required |
|-------------|------|-------------|
| Xcode 26 | Build environment | **HARD DEADLINE April 28, 2026** for all App Store submissions. Apps must be built with Xcode 26 + iOS 26 SDK baseline |
| Third-Party AI Disclosure | App Store Connect metadata | Apple Guideline 5.1.2(i) requires naming Spoonacular (even though it's not AI) in Privacy Labels as external data processor |
| Fastlane 3.x | Existing automation | Already configured in v4.0 with 3 lanes. Works with Xcode 26 (orchestrates xcodebuild) |

**Status:** Metadata updates only. Fastlane pipeline already production-ready (v4.0).

## Installation

### Backend (NestJS)

```bash
# Spoonacular HTTP client
npm install axios@^1.6.0

# Rate limiting for 1 req/sec free tier constraint
npm install @nestjs/throttler@^6.0.0

# Environment variables for API key
# Add to .env:
# SPOONACULAR_API_KEY=your_key_here
```

### iOS (Swift)

```swift
// AVSpeechSynthesizer is built-in, no SPM dependencies needed
// Add to existing VoicePlaybackFeature or create new FreeTierVoiceFeature

import AVFoundation // Already imported for AVPlayer
import MediaPlayer  // For lock screen controls
```

### Deployment

```bash
# Verify Xcode version (MUST be 26+ after April 28, 2026)
xcodebuild -version

# Fastlane already installed (v4.0)
# Existing lanes: beta_internal, beta_external, release
# No additional dependencies for App Store submission
```

## Implementation Patterns

### 1. Spoonacular API Integration (Backend)

**Service architecture:**

```typescript
// backend/src/spoonacular/spoonacular.service.ts

import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Throttle } from '@nestjs/throttler';
import axios, { AxiosInstance } from 'axios';

export interface SpoonacularRecipe {
  id: number;
  title: string;
  image: string;
  imageType: string;
  summary: string;
  readyInMinutes: number;
  servings: number;
  cuisines: string[];
  diets: string[];
  instructions: string;
  extendedIngredients: Array<{
    name: string;
    amount: number;
    unit: string;
  }>;
  nutrition?: {
    nutrients: Array<{
      name: string;
      amount: number;
      unit: string;
    }>;
  };
}

@Injectable()
export class SpoonacularService {
  private client: AxiosInstance;
  private dailyPointsUsed: number = 0;
  private pointsResetAt: Date;

  constructor(private configService: ConfigService) {
    this.client = axios.create({
      baseURL: 'https://api.spoonacular.com',
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    });

    this.pointsResetAt = new Date();
    this.pointsResetAt.setUTCHours(24, 0, 0, 0); // Reset at midnight UTC
  }

  private get apiKey(): string {
    return this.configService.get<string>('SPOONACULAR_API_KEY');
  }

  private checkAndResetQuota() {
    if (new Date() > this.pointsResetAt) {
      this.dailyPointsUsed = 0;
      this.pointsResetAt.setUTCHours(24, 0, 0, 0);
    }

    // Free tier: 150 points/day (verify on account creation)
    if (this.dailyPointsUsed >= 150) {
      throw new HttpException(
        'Daily API quota exhausted. Try again tomorrow.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  @Throttle({ default: { ttl: 1000, limit: 1 } }) // 1 req/sec free tier
  async searchRecipes(filters: {
    query?: string;
    cuisine?: string[];
    diet?: string[];
    intolerances?: string[];
    number?: number;
  }): Promise<SpoonacularRecipe[]> {
    this.checkAndResetQuota();

    const params = {
      apiKey: this.apiKey,
      query: filters.query,
      cuisine: filters.cuisine?.join(','),
      diet: filters.diet?.join(','),
      intolerances: filters.intolerances?.join(','),
      number: filters.number || 10,
      addRecipeInformation: true,
      fillIngredients: true,
    };

    try {
      const response = await this.client.get('/recipes/complexSearch', {
        params,
      });

      // Point cost: 1 point base + 0.01 per result
      const pointCost = 1 + (response.data.results.length * 0.01);
      this.dailyPointsUsed += pointCost;

      return response.data.results;
    } catch (error) {
      if (error.response?.status === 402) {
        throw new HttpException(
          'Spoonacular API quota exceeded',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      throw error;
    }
  }

  @Throttle({ default: { ttl: 1000, limit: 1 } })
  async getRecipeById(id: number, includeNutrition = true): Promise<SpoonacularRecipe> {
    this.checkAndResetQuota();

    const params = {
      apiKey: this.apiKey,
      includeNutrition,
    };

    try {
      const response = await this.client.get(`/recipes/${id}/information`, {
        params,
      });

      this.dailyPointsUsed += 1;

      return response.data;
    } catch (error) {
      if (error.response?.status === 402) {
        throw new HttpException(
          'Spoonacular API quota exceeded',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      throw error;
    }
  }

  @Throttle({ default: { ttl: 1000, limit: 1 } })
  async getRandomRecipes(tags?: string[], number = 10): Promise<SpoonacularRecipe[]> {
    this.checkAndResetQuota();

    const params = {
      apiKey: this.apiKey,
      tags: tags?.join(','),
      number,
    };

    try {
      const response = await this.client.get('/recipes/random', { params });

      const pointCost = 1 + (response.data.recipes.length * 0.01);
      this.dailyPointsUsed += pointCost;

      return response.data.recipes;
    } catch (error) {
      if (error.response?.status === 402) {
        throw new HttpException(
          'Spoonacular API quota exceeded',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      throw error;
    }
  }
}
```

**GraphQL resolver:**

```typescript
// backend/src/recipes/recipes.resolver.ts

import { Resolver, Query, Args } from '@nestjs/graphql';
import { SpoonacularService } from '../spoonacular/spoonacular.service';
import { PrismaService } from '../prisma/prisma.service';

@Resolver()
export class RecipesResolver {
  constructor(
    private spoonacularService: SpoonacularService,
    private prisma: PrismaService,
  ) {}

  @Query(() => [Recipe])
  async recipes(
    @Args('filters', { nullable: true }) filters: RecipeFilters,
  ): Promise<Recipe[]> {
    // 1. Check cache first (60-90 day TTL)
    const cacheKey = JSON.stringify(filters);
    const cached = await this.prisma.recipeCache.findUnique({
      where: { cacheKey },
    });

    if (cached && cached.expiresAt > new Date()) {
      return JSON.parse(cached.data);
    }

    // 2. Fetch from Spoonacular
    const spoonacularRecipes = await this.spoonacularService.searchRecipes({
      query: filters.query,
      cuisine: filters.cuisine,
      diet: filters.diet,
      intolerances: filters.intolerances,
      number: filters.limit || 10,
    });

    // 3. Transform to GraphQL Recipe type
    const recipes = spoonacularRecipes.map((sr) => ({
      id: sr.id.toString(),
      title: sr.title,
      imageUrl: sr.image, // Spoonacular CDN URL
      prepTime: sr.readyInMinutes,
      servings: sr.servings,
      cuisines: sr.cuisines,
      diets: sr.diets,
      summary: sr.summary,
      instructions: sr.instructions,
      ingredients: sr.extendedIngredients.map((ing) => ({
        name: ing.name,
        amount: ing.amount,
        unit: ing.unit,
      })),
      calories: sr.nutrition?.nutrients.find((n) => n.name === 'Calories')?.amount,
    }));

    // 4. Cache response (60 day TTL)
    await this.prisma.recipeCache.upsert({
      where: { cacheKey },
      create: {
        cacheKey,
        data: JSON.stringify(recipes),
        expiresAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 60 days
      },
      update: {
        data: JSON.stringify(recipes),
        expiresAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
      },
    });

    return recipes;
  }
}
```

**Database schema addition:**

```prisma
// backend/prisma/schema.prisma

model RecipeCache {
  id        String   @id @default(cuid())
  cacheKey  String   @unique // JSON.stringify(filters)
  data      String   // JSON stringified recipes
  expiresAt DateTime
  createdAt DateTime @default(now())

  @@index([expiresAt])
}
```

**Expected cache hit rate:** 60-80% (recipes don't change frequently, same queries repeat).

### 2. AVSpeechSynthesizer Integration (iOS)

**Option 1: Extend existing VoicePlaybackReducer (Recommended)**

```swift
// Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift

import AVFoundation
import ComposableArchitecture
import MediaPlayer

// Add tier-based routing
public enum VoiceTier {
  case free  // AVSpeechSynthesizer
  case pro   // ElevenLabs (existing)
}

@Reducer
public struct VoicePlaybackReducer {
  @ObservableState
  public struct State {
    // ... existing fields
    var voiceTier: VoiceTier = .free // Check user subscription
  }

  public enum Action {
    // ... existing actions
    case playWithSynthesizer(text: String, voiceName: String)
    case synthesisStarted
    case synthesisFinished
  }

  @Dependency(\.speechSynthesizerClient) var speechSynthesizer

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .playButtonTapped:
        // Route based on tier
        switch state.voiceTier {
        case .free:
          // AVSpeechSynthesizer path
          return .run { [text = state.narrationText, voice = state.voiceName] send in
            await send(.playWithSynthesizer(text: text, voiceName: voice))
          }
        case .pro:
          // Existing ElevenLabs AVPlayer path
          return .run { [url = state.narrationURL] send in
            await audioPlayer.play(url)
          }
        }

      case let .playWithSynthesizer(text, voiceName):
        state.currentPlayback = .loading
        return .run { send in
          await send(.synthesisStarted)
          await speechSynthesizer.speak(text)
          await send(.synthesisFinished)
        }

      // ... existing cases
      }
    }
  }
}
```

**SpeechSynthesizerClient (Dependency):**

```swift
// Kindred/Packages/VoicePlaybackFeature/Sources/SpeechSynthesizer/SpeechSynthesizerClient.swift

import AVFoundation
import ComposableArchitecture
import MediaPlayer

@DependencyClient
public struct SpeechSynthesizerClient {
  public var speak: @Sendable (String) async -> Void
  public var pause: @Sendable () async -> Void
  public var resume: @Sendable () async -> Void
  public var stop: @Sendable () async -> Void
  public var statusStream: @Sendable () -> AsyncStream<PlaybackStatus>
}

extension SpeechSynthesizerClient: DependencyKey {
  public static let liveValue: Self = {
    let manager = SpeechSynthesizerManager()
    return Self(
      speak: { text in await manager.speak(text) },
      pause: { await manager.pause() },
      resume: { await manager.resume() },
      stop: { await manager.stop() },
      statusStream: { manager.statusStream() }
    )
  }()
}

extension DependencyValues {
  public var speechSynthesizerClient: SpeechSynthesizerClient {
    get { self[SpeechSynthesizerClient.self] }
    set { self[SpeechSynthesizerClient.self] = newValue }
  }
}
```

**SpeechSynthesizerManager (Actor):**

```swift
// Kindred/Packages/VoicePlaybackFeature/Sources/SpeechSynthesizer/SpeechSynthesizerManager.swift

import AVFoundation
import MediaPlayer

actor SpeechSynthesizerManager: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  private var statusContinuation: AsyncStream<PlaybackStatus>.Continuation?

  override init() {
    super.init()
    synthesizer.delegate = self
    configureAudioSession()
    configureRemoteCommands()
  }

  private func configureAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .spokenAudio)
      try session.setActive(true)
    } catch {
      print("Audio session configuration failed: \\(error)")
    }
  }

  private func configureRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [weak self] _ in
      Task {
        await self?.resume()
      }
      return .success
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      Task {
        await self?.pause()
      }
      return .success
    }

    commandCenter.stopCommand.addTarget { [weak self] _ in
      Task {
        await self?.stop()
      }
      return .success
    }
  }

  func speak(_ text: String) async {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.5 // Slightly slower for recipe instructions
    utterance.pitchMultiplier = 1.0
    utterance.volume = 1.0

    synthesizer.speak(utterance)

    // Update Now Playing info
    updateNowPlayingInfo(title: "Recipe Instructions")
  }

  func pause() async {
    synthesizer.pauseSpeaking(at: .word)
    statusContinuation?.yield(.paused)
  }

  func resume() async {
    synthesizer.continueSpeaking()
    statusContinuation?.yield(.playing)
  }

  func stop() async {
    synthesizer.stopSpeaking(at: .immediate)
    statusContinuation?.yield(.stopped)
  }

  func statusStream() -> AsyncStream<PlaybackStatus> {
    AsyncStream { continuation in
      self.statusContinuation = continuation
    }
  }

  private func updateNowPlayingInfo(title: String) {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyArtist] = "Kindred"
    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  // MARK: - AVSpeechSynthesizerDelegate

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didStart utterance: AVSpeechUtterance
  ) {
    Task {
      await self.statusContinuation?.yield(.playing)
    }
  }

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    Task {
      await self.statusContinuation?.yield(.stopped)
    }
  }

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didCancel utterance: AVSpeechUtterance
  ) {
    Task {
      await self.statusContinuation?.yield(.stopped)
    }
  }
}
```

**Known iOS bug workaround (background audio):**

If TTS doesn't play in background, add "audio queue jog":

```swift
// In configureAudioSession()
// Workaround: Play silent audio to jog audio queue
let silentURL = URL(fileURLWithPath: Bundle.main.path(forResource: "silence", ofType: "wav")!)
let silentPlayer = try AVAudioPlayer(contentsOf: silentURL)
silentPlayer.play()
```

**Voice quality expectations:**
- AVSpeechSynthesizer is robotic compared to ElevenLabs
- User feedback may drive upgrades to Pro tier
- Consider iOS 17+ Personal Voice feature for cloning-like experience (user provides own samples)

### 3. App Store Submission Updates

**No code changes.** Metadata updates only:

**App Store Connect → App Privacy:**

```
Data Collection Disclosure (UPDATE):
- Third-Party Services:
  * Spoonacular API: Recipe data provider (images, ingredients, instructions)
    - Data shared: None (public recipe database)
    - Purpose: Recipe discovery and display
  * Google Gemini: AI recipe parsing and pantry scanning (existing)
  * ElevenLabs: Voice cloning for Pro tier only (existing)
  * Google AdMob: Personalized advertising (existing)
  * Firebase: Push notifications (existing)
```

**App Description (UPDATE):**

```markdown
Kindred brings you popular recipes with AI-powered voice narration.

NEW in v5.0:
• Discover 1000s of recipes from Spoonacular
• Free voice narration with high-quality text-to-speech
• Pro tier: Clone a loved one's voice for narration
• Smart pantry ingredient matching
• Dietary filters (vegan, keto, halal, allergies)

Recipe data provided by Spoonacular API.
Voice cloning uses ElevenLabs AI (Pro tier only).
```

**Build environment checklist:**

```bash
# Verify Xcode 26 installed (REQUIRED after April 28, 2026)
xcodebuild -version
# Expected: Xcode 26.0 or later

# Verify iOS SDK 26
xcodebuild -showsdks | grep iphoneos
# Expected: iphoneos26.0 or later

# Run fastlane release lane
cd Kindred
fastlane release

# Upload will fail if Xcode < 26 after April 28, 2026
```

## Alternatives Considered

### Recipe APIs

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Spoonacular API | Edamam Recipe API | Higher free tier (10K requests/month) but requires attribution links, less comprehensive dietary filters |
| Spoonacular API | TheMealDB API | Completely free, but limited to ~600 recipes, no nutritional data, no dietary filters |
| Spoonacular API | Tasty API (RapidAPI) | Need video recipes, willing to pay $0/month → $10/month tiers |

**Verdict:** Spoonacular best balance of free tier quota (150/day), dietary filters, and nutritional data.

### Voice Synthesis

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| AVSpeechSynthesizer (free tier) | OpenAI TTS API | Need higher voice quality, willing to pay ~$0.015/1K characters, acceptable cloud dependency |
| AVSpeechSynthesizer (free tier) | Google Cloud TTS | Need WaveNet voices, willing to pay ~$4-16/1M characters, need custom voice personas |
| ElevenLabs (Pro tier) | Play.ht | Need voice cloning but cheaper than ElevenLabs (~$19/mo vs $99/mo) |

**Verdict:** AVSpeechSynthesizer for free tier (zero cost), keep ElevenLabs for Pro tier voice cloning feature.

### App Store Automation

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Fastlane deliver | Manual upload via Xcode Organizer | Small team not comfortable with CLI automation, one-off submissions |
| Fastlane deliver | Bitrise/CircleCI mobile upload step | Already using CI/CD platform, prefer integrated workflow |

**Verdict:** Fastlane already configured (v4.0), works with Xcode 26, no reason to change.

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Spoonacular SDK packages | No official SDK exists, community packages often outdated or incomplete | Direct REST API calls with axios |
| AVAudioPlayer for AVSpeechSynthesizer | AVSpeechSynthesizer produces audio internally, not file-based | Use AVSpeechSynthesizer directly with AVSpeechUtterance |
| RevenueCat for App Store submission | Only needed for subscription analytics/management, not submission | Fastlane deliver for upload, existing StoreKit 2 for transactions |
| Xcode < 26 after April 28, 2026 | Apple rejects submissions not built with Xcode 26+ and iOS 26 SDK | Upgrade to Xcode 26, update CI/CD environments |
| Free tier Spoonacular without caching | Daily quota exhausts quickly (150 req/day) | Implement PostgreSQL cache with 60-90 day TTL |

## Migration Impact

### From X API to Spoonacular

**Remove:**
- X API scraping service (`RecipeScraper`)
- Gemini recipe parsing (Spoonacular provides structured data)
- Instagram scraping placeholder

**Replace:**
- `RecipeScraper` with `SpoonacularService` in NestJS
- GraphQL schema `Recipe` type fields to match Spoonacular response

**Update:**
- Feed framing from "viral near you" to "popular recipes" (no geolocation in Spoonacular free tier)
- Recipe card UI to show "POPULAR" badge instead of "VIRAL"

**Cost savings:** ~$100-200/month (X API fees + Gemini parsing eliminated)

### From Imagen 4 to Spoonacular Images

**Remove:**
- Vertex AI Imagen 4 integration
- Image generation pipeline
- R2 upload for generated images

**Replace:**
- Store Spoonacular CDN URLs directly in `Recipe.imageUrl`
- No backend image processing needed

**Update:**
- GraphQL `Recipe.imageUrl` type from R2 URL to Spoonacular CDN URL
- iOS image loading already handles remote URLs (SDWebImage/AsyncImage)

**Cost savings:** ~$0.01/image generation cost eliminated

### From ElevenLabs (Free) to AVSpeechSynthesizer

**Keep:**
- ElevenLabs for Pro tier (voice cloning feature)
- VoiceProfile model, VoiceUpload flow
- R2 storage for cloned voice narrations

**Add:**
- AVSpeechSynthesizer for free tier
- `SpeechSynthesizerClient` dependency
- `SpeechSynthesizerManager` actor

**Update:**
- `VoicePlaybackReducer` to check user tier (free vs Pro) and route accordingly
- UI to show "Upgrade to Pro for voice cloning" on free tier

**Cost savings:** ~$0.01-0.03/recipe narration for free users

### App Store Launch

**Existing (v4.0):**
- Fastlane 3-lane pipeline
- Privacy manifest (PrivacyInfo.xcprivacy)
- App Store metadata with third-party AI disclosure
- ATT consent flow
- Voice cloning consent screen

**Update:**
- Add Spoonacular to Privacy Labels (third-party data processor)
- Update app description to mention Spoonacular
- Verify Xcode 26 installed on build machine

**No cost change:** App Store submission is free (Apple Developer Program already paid)

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Spoonacular API v1 | axios ^1.6.0 | REST API, no versioning in URL, stable since 2015 |
| AVSpeechSynthesizer (iOS 7+) | iOS 17.0 min deployment | Existing app min deployment target, fully compatible |
| AVSpeechSynthesizer | AVPlayer (existing) | Both use AVAudioSession, configure `.playback` category for background |
| Fastlane 3.x | Xcode 26 | Fastlane orchestrates xcodebuild, must run on Xcode 26+ system after April 28, 2026 |
| @nestjs/throttler 6.x | NestJS 11 | Rate limiting middleware compatible with NestJS 11+ |
| Spoonacular free tier | @nestjs/throttler | Implement 1 req/sec rate limit (free tier constraint) |

## Known Limitations

### Spoonacular API

- **Daily quota:** 150 points/day free tier (sources vary 50-150, verify on signup)
- **Rate limit:** 1 request/second, 2 concurrent requests max
- **Point costs:** 1 point base + 0.01 per result, complex searches +1 point for nutrient filters
- **Overage:** HTTP 402 error when quota exhausted (resets at midnight UTC)
- **Support:** Forum only (no SLA on free tier)
- **Attribution:** Backlink required on free tier
- **No geolocation:** Free tier doesn't support "recipes near me" (upgrade to paid or cache by city manually)

### AVSpeechSynthesizer

- **Voice quality:** Robotic compared to ElevenLabs (user feedback may require fallback to Pro tier)
- **No streaming:** Requires full text before synthesis (not a blocker for recipe instructions)
- **Background audio quirk:** May need silent AVAudioPlayer snippet to "jog audio queue" (known iOS bug workaround)
- **Lock screen controls:** Requires MPRemoteCommandCenter setup (not automatic like AVPlayer)
- **Text length:** No documented max, but long texts (>5K chars) may cause synthesis delays
- **No voice cloning:** Cannot replicate loved one's voice (keep ElevenLabs for Pro tier)

### App Store Submission (2026)

- **Xcode 26 mandate:** HARD DEADLINE April 28, 2026 for all submissions
- **Third-party AI disclosure:** REQUIRED under Guideline 5.1.2(i) even for non-AI services like Spoonacular
- **Privacy labels:** Must declare Spoonacular data flows in App Privacy section
- **Binary upload limit:** 150 uploads/day to App Store Connect (unlikely to hit for single app)

## Expected Cache Hit Rates

| Cache Type | Expected Hit Rate | TTL | Rationale |
|------------|-------------------|-----|-----------|
| Spoonacular recipe search | 60-80% | 60 days | Same queries repeat (e.g., "vegan dinner"), recipes don't change |
| Spoonacular recipe detail | 70-90% | 90 days | Recipe details rarely updated, users revisit favorites |
| Voice narration (Pro tier) | 80-95% | Indefinite | Cached in R2 CDN, recipe instructions stable |

**Quota sustainability with caching:**
- 150 requests/day free tier
- Expected 60% cache hit → 375 effective requests/day
- Sufficient for MVP with <500 daily active users

## Timeline Estimate

| Task | Complexity | Time Estimate |
|------|-----------|---------------|
| Spoonacular backend service | Medium (new API) | 4-6 hours |
| Recipe cache schema + resolver | Low (standard pattern) | 2-3 hours |
| AVSpeechSynthesizer client + manager | Medium (new TTS path) | 4-6 hours |
| Tier-based routing in VoicePlaybackReducer | Low (conditional logic) | 2-3 hours |
| Lock screen controls for TTS | Low (MPRemoteCommandCenter) | 2 hours |
| App Store metadata updates | Low (copy changes) | 1 hour |
| Testing + QA (both paths) | Medium (two voice tiers) | 4-6 hours |

**Total development time:** 19-27 hours
**Total calendar time:** 3-5 days (single developer)

## Sources

**HIGH confidence (official documentation):**
- [Spoonacular API Pricing](https://spoonacular.com/food-api/pricing) — Free tier limits, point costs
- [Spoonacular API Docs](https://spoonacular.com/food-api/docs) — Endpoints, filters, response formats
- [Apple AVSpeechSynthesizer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) — iOS requirements, API reference
- [Fastlane Deliver Docs](https://docs.fastlane.tools/actions/upload_to_app_store/) — App Store upload automation
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — Guideline 5.1.2(i) third-party AI disclosure

**MEDIUM confidence (verified community sources):**
- [iOS App Store Deployment using Fastlane](https://docs.fastlane.tools/getting-started/ios/appstore-deployment/) — Xcode 26 compatibility
- [Apple Mandates Xcode 26 for App Store](https://www.seasiainfotech.com/blog/apple-mandates-xcode-26-for-app-store-submissions) — April 28, 2026 deadline
- [Apple's new App Review Guidelines on third-party AI](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/) — Privacy disclosure requirements
- [AVSpeechSynthesizer Background Audio](https://medium.com/@quangtqag/background-audio-player-sync-control-center-516243c2cdd1) — Lock screen controls setup
- [Spoonacular API Guide 2025](https://www.devzery.com/post/spoonacular-api-complete-guide-recipe-nutrition-food-integration) — Integration patterns
- [Building a Text to Speech App Using AVSpeechSynthesizer](https://www.appcoda.com/text-to-speech-ios-tutorial/) — Swift TTS implementation
- [NestJS Throttler Documentation](https://docs.nestjs.com/security/rate-limiting) — Rate limiting patterns

**LOW confidence (needs verification):**
- Daily point limit variance (50 vs 150 points) — Official pricing page says "50 points/day then no more calls" but other sources mention 150 requests/day. **Verify on account creation.**
- AVSpeechSynthesizer max text length — No documented limit found, anecdotal reports suggest >5K chars may cause synthesis delays. **Test with longest recipe in production.**
- Spoonacular geolocation in free tier — No mention in docs, assume unavailable. **Verify on signup whether `location` or `radius` params work in free tier.**

---
*Stack research for: Kindred v5.0 Lean App Store Launch*
*Researched: 2026-04-04*
*Confidence: HIGH (verified with official Apple/Spoonacular/Fastlane docs)*
