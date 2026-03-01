# Kindred — Android Architecture & Feasibility Assessment

> **Author:** Senior Android Engineer
> **Date:** 2026-02-28
> **Status:** Research Complete

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Module Structure](#2-module-structure)
3. [Key Libraries & Versions](#3-key-libraries--versions)
4. [Data Layer](#4-data-layer)
5. [API Integration Patterns](#5-api-integration-patterns)
6. [Camera Pipeline](#6-camera-pipeline)
7. [Location Services](#7-location-services)
8. [Push Notifications](#8-push-notifications)
9. [Accessibility](#9-accessibility)
10. [Performance Optimization](#10-performance-optimization)
11. [Feasibility Assessment](#11-feasibility-assessment)
12. [Feature Parity with iOS](#12-feature-parity-with-ios)

---

## 1. Architecture Overview

### Recommended: MVVM + Clean Architecture + Hilt DI

**Pattern:** Model-View-ViewModel with Clean Architecture layering
**DI Framework:** Hilt (Google-recommended, built on Dagger)
**Async:** Kotlin Coroutines + Flow (StateFlow/SharedFlow)
**UI:** Jetpack Compose (fully declarative)

```
┌──────────────────────────────────────────────────────┐
│                   Presentation Layer                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Composables  │  │  ViewModels  │  │  UI State  │ │
│  │  (Screens +   │◄─│  (StateFlow  │◄─│  (Sealed   │ │
│  │   Components) │  │   emitters)  │  │   Classes) │ │
│  └──────────────┘  └──────┬───────┘  └────────────┘ │
└──────────────────────────┬───────────────────────────┘
                           │ Use Cases
┌──────────────────────────▼───────────────────────────┐
│                    Domain Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Use Cases   │  │   Models     │  │ Repository │ │
│  │  (Business   │  │   (Domain    │  │ Interfaces │ │
│  │   Logic)     │  │    Entities) │  │            │ │
│  └──────────────┘  └──────────────┘  └────────────┘ │
└──────────────────────────┬───────────────────────────┘
                           │ Repository Impl
┌──────────────────────────▼───────────────────────────┐
│                     Data Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Repository   │  │  Remote      │  │  Local     │ │
│  │  Impls        │  │  (Retrofit/  │  │  (Room +   │ │
│  │  (Offline-    │  │   Ktor)      │  │  DataStore)│ │
│  │   first)      │  │              │  │            │ │
│  └──────────────┘  └──────────────┘  └────────────┘ │
└──────────────────────────────────────────────────────┘
```

### Rationale

- **MVVM** aligns natively with Compose's reactive, state-driven UI. ViewModels expose `StateFlow<UiState>`, Compose observes via `collectAsStateWithLifecycle()`.
- **Clean Architecture** enforces separation of concerns: Domain layer has zero Android dependencies, making business logic fully testable.
- **Hilt** is Google's recommended DI — compile-time safety, excellent IDE support, first-class ViewModel injection via `@HiltViewModel`.
- **Kotlin Coroutines/Flow** is the standard async model. StateFlow for UI state, SharedFlow for one-shot events, Flow for reactive data streams from Room.

### Why Not Alternatives?

| Alternative | Reason to Skip |
|---|---|
| MVI (Model-View-Intent) | More boilerplate for marginal benefit; MVVM with sealed UiState achieves same unidirectional flow |
| Koin | Runtime DI — no compile-time verification, slower in large apps |
| RxJava | Legacy; Coroutines/Flow is the Kotlin-native standard |
| Compose Multiplatform | Premature — native Android focus ensures best performance on budget devices and elderly accessibility |

---

## 2. Module Structure

Multi-module Gradle project using convention plugins for consistency.

```
:app                          ← Application module, Hilt entry point
│
├── :core
│   ├── :core:common          ← Shared utilities, extensions, Result wrapper
│   ├── :core:network         ← Retrofit/Ktor setup, interceptors, auth
│   ├── :core:database        ← Room database, DAOs, migrations
│   ├── :core:datastore       ← Proto DataStore for preferences/settings
│   ├── :core:designsystem    ← Kindred theme, colors, typography, components
│   ├── :core:ui              ← Shared Compose components (cards, buttons, etc.)
│   ├── :core:model           ← Domain models shared across features
│   ├── :core:media           ← Media3 ExoPlayer wrapper, audio session management
│   └── :core:testing         ← Shared test utilities, fakes, fixtures
│
├── :feature
│   ├── :feature:feed         ← Hyperlocal recipe feed (swipeable cards)
│   ├── :feature:recipe       ← Recipe detail, step-by-step, voice narration
│   ├── :feature:camera       ← CameraX + fridge scan + receipt OCR
│   ├── :feature:pantry       ← Smart pantry, inventory, expiry tracking
│   ├── :feature:profile      ← Culinary DNA, taste profile, preferences
│   ├── :feature:video        ← Veo video player, technique clips
│   ├── :feature:onboarding   ← First-run, voice clone, dietary preferences
│   └── :feature:settings     ← App settings, accessibility overrides
│
├── :data
│   ├── :data:recipe          ← Recipe repository impl, remote + local
│   ├── :data:user            ← User profile, preferences, Culinary DNA
│   ├── :data:pantry          ← Pantry items, expiry, shopping lists
│   ├── :data:location        ← Location provider, geofencing
│   └── :data:ai              ← ElevenLabs, Gemini, Veo API clients
│
└── :domain
    ├── :domain:recipe        ← Recipe use cases, domain models
    ├── :domain:user          ← User use cases
    ├── :domain:pantry        ← Pantry use cases
    └── :domain:ai            ← AI feature use cases
```

### Module Boundaries

- **Feature modules** depend on `:domain` and `:core`, never on each other
- **Data modules** implement `:domain` repository interfaces
- **Domain modules** have zero Android dependencies (pure Kotlin)
- **Navigation** handled in `:app` using Compose Navigation with type-safe routes

---

## 3. Key Libraries & Versions

### Build Configuration

| Config | Value |
|---|---|
| **Min SDK** | 26 (Android 8.0 Oreo) — ~98% device coverage |
| **Target SDK** | 35 (Android 15) |
| **Compile SDK** | 35 |
| **Kotlin** | 2.1.x |
| **Gradle** | 8.x with Kotlin DSL |
| **KSP** | Latest matching Kotlin (replaces kapt) |

### Core Dependencies

| Library | Version | Purpose |
|---|---|---|
| **Compose BOM** | 2026.02.01 | UI framework — declarative, reactive |
| **Compose Material 3** | 1.4.x (via BOM) | Material Design 3 components |
| **Compose Navigation** | 2.9.x | Type-safe navigation |
| **Hilt** | 2.57.x | Dependency injection |
| **Hilt Navigation Compose** | 1.2.x | ViewModel injection in Compose |
| **Room** | 2.7.x | Local SQLite database |
| **DataStore (Proto)** | 1.2.0 | Preferences & typed settings |
| **Media3 ExoPlayer** | 1.9.x (stable) / 1.10.x (beta) | Audio/video playback |
| **CameraX** | 1.5.x | Camera access, image analysis |
| **ML Kit** | Latest | Object detection, text recognition |
| **Coil 3** | 3.4.x | Image loading (Compose-native) |
| **Retrofit** | 2.11.x | HTTP client (primary) |
| **OkHttp** | 4.12.x | HTTP engine, interceptors, WebSocket |
| **Kotlinx Serialization** | 1.7.x | JSON serialization (replaces Gson/Moshi) |
| **Kotlin Coroutines** | 1.9.x | Async operations |
| **FusedLocationProvider** | 21.x | Location services |
| **Firebase BOM** | 33.x | FCM, Analytics, Crashlytics |
| **WorkManager** | 2.10.x | Background task scheduling |
| **Baseline Profiles** | 1.4.x | Startup & runtime optimization |
| **LeakCanary** | 2.14.x | Memory leak detection (debug) |

### Why Retrofit over Ktor?

For a native Android-only app, **Retrofit** is recommended:
- Larger ecosystem, more battle-tested on Android
- Excellent OkHttp interceptor chain for auth, logging, retries
- Superior integration with streaming (OkHttp WebSocket for ElevenLabs)
- 73% Android developer adoption (2024 Android Arsenal survey)
- No KMP requirement reduces complexity

If the project later requires Kotlin Multiplatform, Ktor can be evaluated. For now, simplicity and maturity win.

---

## 4. Data Layer

### 4.1 Room Database

Primary structured data storage for offline-first capability.

**Database Schema:**

```kotlin
@Database(
    entities = [
        RecipeEntity::class,
        IngredientEntity::class,
        PantryItemEntity::class,
        UserPreferenceEntity::class,
        CulinaryDnaEntity::class,
        ShoppingListItemEntity::class,
        CachedFeedItemEntity::class,
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class KindredDatabase : RoomDatabase() {
    abstract fun recipeDao(): RecipeDao
    abstract fun pantryDao(): PantryDao
    abstract fun feedDao(): FeedDao
    abstract fun userDao(): UserDao
}
```

**Key Tables:**

| Table | Purpose | Sync Strategy |
|---|---|---|
| `recipes` | Cached recipes with full details | Pull on view, cache 7 days |
| `pantry_items` | User's fridge/pantry inventory | Local-first, push on change |
| `feed_cache` | Hyperlocal feed cards | Pull-to-refresh, TTL 1 hour |
| `user_preferences` | Dietary restrictions, allergies | Local-first, push on change |
| `culinary_dna` | Taste profile from interactions | Local compute, periodic sync |
| `shopping_list` | Generated shopping items | Bidirectional sync |

### 4.2 Proto DataStore

For typed preferences and app settings:

```protobuf
message UserSettings {
    bool voice_narration_enabled = 1;
    float text_scale_factor = 2;         // 1.0 - 2.0 for elderly
    bool high_contrast_mode = 3;
    string preferred_voice_id = 4;
    int32 feed_radius_miles = 5;         // 5-10 mi default
    bool auto_play_video = 6;
    string dietary_profile = 7;          // JSON serialized
    bool push_notifications_enabled = 8;
    bool expiry_reminders_enabled = 9;
}
```

### 4.3 Offline-First Strategy

```
┌───────────┐     ┌──────────────┐     ┌───────────┐
│  UI Layer │◄────│  Repository  │────►│  Remote   │
│ (Compose) │     │  (Single     │     │  Data     │
│           │     │   Source of  │     │  Source   │
│           │     │   Truth)     │     │           │
└───────────┘     └──────┬───────┘     └───────────┘
                         │
                    ┌────▼────┐
                    │  Room   │
                    │  (Local │
                    │  Cache) │
                    └─────────┘
```

**Pattern:** Repository reads from Room first, fetches remote in background, updates Room. UI observes Room via Flow — always reactive.

```kotlin
class RecipeRepositoryImpl @Inject constructor(
    private val recipeDao: RecipeDao,
    private val recipeApi: RecipeApi,
    private val networkMonitor: NetworkMonitor,
) : RecipeRepository {

    override fun getRecipe(id: String): Flow<Recipe> =
        recipeDao.observeRecipe(id)
            .onStart {
                if (networkMonitor.isOnline.first()) {
                    try {
                        val remote = recipeApi.getRecipe(id)
                        recipeDao.upsert(remote.toEntity())
                    } catch (e: Exception) {
                        // Silently fail — cached data still flows
                    }
                }
            }
            .map { it.toDomain() }
}
```

**Sync Strategy:**
- **Feed:** TTL-based (1 hour), pull-to-refresh, paginated via Paging 3
- **Recipes:** Cache on first view, invalidate after 7 days
- **Pantry:** Local-first with optimistic updates, background sync via WorkManager
- **User Data:** Sync on app foreground, conflict resolution: last-write-wins

---

## 5. API Integration Patterns

### 5.1 ElevenLabs — Voice Narration

**Integration:** Official ElevenLabs Kotlin SDK (`io.elevenlabs:agents`) + REST API for TTS

**Architecture:**

```kotlin
// Voice cloning (one-time during onboarding)
interface VoiceCloneService {
    suspend fun cloneVoice(audioSample: ByteArray, name: String): VoiceId
    suspend fun listVoices(): List<Voice>
}

// Streaming TTS for recipe narration
interface VoiceNarrationService {
    fun streamNarration(
        text: String,
        voiceId: VoiceId,
    ): Flow<ByteArray>  // PCM audio chunks
}
```

**Streaming Audio Pipeline:**

```
ElevenLabs API (WebSocket/SSE)
        │
        ▼ chunked audio bytes
┌──────────────────┐
│ AudioBufferQueue │ ← Ring buffer, ~2s lookahead
└───────┬──────────┘
        │
        ▼
┌──────────────────┐
│ Media3 ExoPlayer │ ← Custom MediaSource for streaming
│ (AudioFocus +    │
│  Session)        │
└───────┬──────────┘
        │
        ▼
┌──────────────────┐
│ Notification     │ ← MediaSession + foreground service
│ Media Controls   │    for lock-screen playback controls
└──────────────────┘
```

**Key Considerations:**
- Use OkHttp WebSocket for low-latency streaming (< 500ms first-byte)
- Buffer 2 seconds of audio before playback to prevent stuttering on slow connections
- Implement `AudioFocusRequest` with `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` for cooking context
- Cache generated audio in Room BLOB or local file for offline replay
- Voice cloning requires 30s audio sample — use Media3 recorder during onboarding
- Foreground service for narration playback (continues while user is cooking)

**Costs & Rate Limits:**
- ElevenLabs charges per character (~$0.30/1000 chars at scale tier)
- Implement client-side sentence caching to avoid re-generating same instructions
- Queue narration by recipe step, not entire recipe at once

### 5.2 Gemini 3 Flash — Vision (Fridge Scan + Receipt OCR)

**Integration:** Google AI SDK for Android (`com.google.ai.client.generativeai`)

**Architecture:**

```kotlin
interface FridgeAnalysisService {
    suspend fun analyzeFridgePhoto(image: Bitmap): FridgeContents
}

interface ReceiptOcrService {
    suspend fun parseReceipt(image: Bitmap): List<GroceryItem>
}

// Implementation using Gemini 3 Flash
class GeminiFridgeAnalysis @Inject constructor(
    private val generativeModel: GenerativeModel,
) : FridgeAnalysisService {

    override suspend fun analyzeFridgePhoto(image: Bitmap): FridgeContents {
        val response = generativeModel.generateContent(
            content {
                image(image)
                text(FRIDGE_ANALYSIS_PROMPT)
            }
        )
        return parseFridgeResponse(response.text)
    }
}
```

**Prompt Engineering:**
- Fridge scan: Structured JSON output with `{items: [{name, quantity_estimate, condition, category}]}`
- Receipt OCR: Extract `{store_name, items: [{name, price, quantity}], total, date}`
- Use Gemini 3 Flash's "Agentic Vision" for multi-step analysis (zoom, crop, re-analyze)

**Optimization:**
- Compress images to 1024px max dimension before upload (reduce bandwidth, sufficient for recognition)
- Local ML Kit object detection as pre-filter — only send frames with detected food objects to Gemini
- Cache results by image hash to prevent duplicate API calls
- Estimated latency: 1-3 seconds per image

### 5.3 Google Veo — AI Video Generation

**Integration:** Gemini API / Vertex AI REST endpoint

**Architecture:**

```kotlin
interface VideoGenerationService {
    suspend fun generateTechniqueVideo(
        prompt: String,
        aspectRatio: AspectRatio = AspectRatio.PORTRAIT_9_16,
        duration: VideoDuration = VideoDuration.SECONDS_8,
    ): VideoGenerationResult

    fun observeVideoStatus(jobId: String): Flow<VideoJobStatus>
}

sealed class VideoGenerationResult {
    data class Success(val videoUrl: String, val thumbnailUrl: String) : VideoGenerationResult()
    data class Queued(val jobId: String, val estimatedWait: Duration) : VideoGenerationResult()
    data class Failed(val error: VideoError) : VideoGenerationResult()
}
```

**Pipeline:**
1. User taps "Watch technique" on recipe step
2. Check local cache (Room + file storage) for pre-generated video
3. If not cached: submit generation request to Veo API via backend proxy
4. Show skeleton loader with estimated wait time
5. Poll status or use WebSocket for completion notification
6. Stream video via Media3 ExoPlayer once ready
7. Cache video file locally for offline replay

**Key Constraints:**
- Veo generates 8-second 720p/1080p/4K clips — 720p recommended for mobile + budget devices
- Generation is NOT real-time (expect 30-120 seconds for generation)
- Must go through backend proxy — never expose API keys on client
- Pre-generate popular technique videos server-side, push to CDN
- Budget: ~$0.05-0.10 per 8-second clip at scale

### 5.4 API Client Architecture

```kotlin
// Unified API response wrapper
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val code: Int, val message: String) : ApiResult<Nothing>()
    data class NetworkError(val throwable: Throwable) : ApiResult<Nothing>()
}

// Auth interceptor
class AuthInterceptor @Inject constructor(
    private val tokenProvider: TokenProvider,
) : Interceptor {
    override fun intercept(chain: Chain): Response {
        val token = runBlocking { tokenProvider.getAccessToken() }
        return chain.proceed(
            chain.request().newBuilder()
                .addHeader("Authorization", "Bearer $token")
                .build()
        )
    }
}

// Retry policy with exponential backoff
class RetryInterceptor(
    private val maxRetries: Int = 3,
    private val initialDelayMs: Long = 1000,
) : Interceptor { ... }
```

---

## 6. Camera Pipeline

### CameraX + ML Kit Integration

```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│   CameraX   │────►│  ML Kit      │────►│  Gemini 3     │
│   Preview   │     │  Analyzer    │     │  Flash API    │
│   + Image   │     │  (on-device  │     │  (cloud       │
│   Analysis  │     │   pre-filter)│     │   analysis)   │
└─────────────┘     └──────────────┘     └───────────────┘
```

**Implementation:**

```kotlin
@Composable
fun FridgeScanScreen(viewModel: FridgeScanViewModel = hiltViewModel()) {
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }

    AndroidView(
        factory = { ctx ->
            PreviewView(ctx).apply {
                implementationMode = PreviewView.ImplementationMode.COMPATIBLE
            }
        },
        update = { previewView ->
            val cameraProvider = cameraProviderFuture.get()
            val preview = Preview.Builder().build()
            val imageAnalysis = ImageAnalysis.Builder()
                .setTargetResolution(Size(1280, 720))
                .setBackpressureStrategy(STRATEGY_KEEP_ONLY_LATEST)
                .build()

            imageAnalysis.setAnalyzer(executor, MlKitFoodDetector { foodItems ->
                if (foodItems.isNotEmpty()) {
                    viewModel.onFoodDetected(foodItems)
                }
            })

            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(
                lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA,
                preview, imageAnalysis
            )
            preview.surfaceProvider = previewView.surfaceProvider
        }
    )
}
```

**Two-Stage Pipeline:**

1. **Stage 1 — On-device (ML Kit):** Real-time food object detection. Runs at ~30fps, filters frames with food objects. Provides bounding boxes for UI overlay (highlight detected items). Uses `STREAM_MODE` for continuous detection with object tracking.

2. **Stage 2 — Cloud (Gemini 3 Flash):** Triggered by user tap ("Scan my fridge") or automatic after stable detection. Full image sent to Gemini for detailed item identification, quantity estimation, and condition assessment.

**Receipt OCR Pipeline:**
1. CameraX captures receipt image
2. ML Kit Text Recognition (on-device) provides raw text
3. Gemini 3 Flash structures raw text into grocery items with prices
4. Results populate pantry automatically

**Permissions:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera.any" android:required="false" />
```

---

## 7. Location Services

### FusedLocationProvider for Hyperlocal Feed

```kotlin
class LocationRepository @Inject constructor(
    private val fusedLocationClient: FusedLocationProviderClient,
    private val locationDataStore: LocationDataStore,
) {
    // Coarse location is sufficient for 5-10 mile radius
    @RequiresPermission(ACCESS_COARSE_LOCATION)
    fun getCurrentLocation(): Flow<Location> = callbackFlow {
        val request = LocationRequest.Builder(
            Priority.PRIORITY_BALANCED_POWER_ACCURACY,
            TimeUnit.MINUTES.toMillis(15)  // Update every 15 min
        ).setMinUpdateDistanceMeters(500f)  // Only if moved 500m
         .build()

        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { trySend(it) }
            }
        }
        fusedLocationClient.requestLocationUpdates(request, callback, Looper.getMainLooper())
        awaitClose { fusedLocationClient.removeLocationUpdates(callback) }
    }

    // Cache last known location for offline feed
    suspend fun getLastKnownLocation(): Location? {
        return fusedLocationClient.lastLocation.await()
            ?: locationDataStore.getCachedLocation()
    }
}
```

**Strategy:**
- Use `ACCESS_COARSE_LOCATION` (not fine) — sufficient for 5-10mi radius, less intrusive permission
- Cache last known location in DataStore for offline feed loading
- Low-frequency updates (15 min interval, 500m minimum distance) — battery friendly
- Feed server-side: pass lat/lng + radius, get trending recipes in area
- Graceful degradation: if location denied, show global trending feed

**Permission Flow (Compose):**
```kotlin
val locationPermissionState = rememberPermissionState(ACCESS_COARSE_LOCATION)

LaunchedEffect(locationPermissionState.status) {
    when {
        locationPermissionState.status.isGranted -> viewModel.startLocationUpdates()
        locationPermissionState.status.shouldShowRationale ->
            viewModel.showLocationRationale()
        else -> locationPermissionState.launchPermissionRequest()
    }
}
```

---

## 8. Push Notifications

### Firebase Cloud Messaging (FCM)

**Use Cases:**
- Pantry expiry reminders ("Your milk expires tomorrow!")
- Trending recipe alerts for user's area
- New recipe from followed creators
- Weekly Culinary DNA insights

**Implementation:**

```kotlin
class KindredMessagingService : FirebaseMessagingService() {

    @Inject lateinit var notificationManager: AuraNotificationManager
    @Inject lateinit var pantryRepository: PantryRepository

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        when (data["type"]) {
            "expiry_reminder" -> notificationManager.showExpiryReminder(data)
            "trending_recipe" -> notificationManager.showTrendingRecipe(data)
            "new_recipe" -> notificationManager.showNewRecipe(data)
            "weekly_insight" -> notificationManager.showWeeklyInsight(data)
        }
    }

    override fun onNewToken(token: String) {
        // Register token with backend
        CoroutineScope(Dispatchers.IO).launch {
            userRepository.updateFcmToken(token)
        }
    }
}
```

**Notification Channels (Android 8.0+):**

```kotlin
object NotificationChannels {
    val EXPIRY_REMINDERS = Channel(
        id = "expiry_reminders",
        name = "Expiry Reminders",
        importance = NotificationManager.IMPORTANCE_HIGH
    )
    val TRENDING_RECIPES = Channel(
        id = "trending_recipes",
        name = "Trending Recipes",
        importance = NotificationManager.IMPORTANCE_DEFAULT
    )
    val WEEKLY_INSIGHTS = Channel(
        id = "weekly_insights",
        name = "Weekly Insights",
        importance = NotificationManager.IMPORTANCE_LOW
    )
}
```

**POST_NOTIFICATIONS Permission (Android 13+):**
- For SDK 33+, must request `POST_NOTIFICATIONS` at runtime
- For min SDK 26 (our target), notifications work without permission on Android 8-12
- Show permission dialog on first meaningful moment (after first recipe save)

---

## 9. Accessibility

### Critical: Designed for Users 75+

**9.1 Touch Targets**

```kotlin
// Kindred minimum touch target: 56dp (exceeds Material 48dp minimum)
val AuraMinTouchTarget = 56.dp

@Composable
fun AuraButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit,
) {
    Button(
        onClick = onClick,
        modifier = modifier.defaultMinSize(
            minWidth = AuraMinTouchTarget,
            minHeight = AuraMinTouchTarget,
        ),
        content = content,
    )
}
```

**9.2 Text Scaling**

```kotlin
// Support system font scaling up to 200%
// Use sp units exclusively for text
// Test at 200% scale on smallest supported screen

@Composable
fun KindredTheme(
    userTextScale: Float = 1.0f, // 1.0 - 2.0 from settings
    content: @Composable () -> Unit,
) {
    val scaledTypography = MaterialTheme.typography.copy(
        bodyLarge = MaterialTheme.typography.bodyLarge.copy(
            fontSize = (18 * userTextScale).sp,
            lineHeight = (26 * userTextScale).sp,
        ),
        titleLarge = MaterialTheme.typography.titleLarge.copy(
            fontSize = (24 * userTextScale).sp,
        ),
    )
    MaterialTheme(
        typography = scaledTypography,
        content = content,
    )
}
```

**9.3 TalkBack Support**

```kotlin
// Semantic grouping for recipe cards
@Composable
fun RecipeCard(recipe: Recipe) {
    Card(
        modifier = Modifier
            .semantics(mergeDescendants = true) {
                contentDescription = buildString {
                    append("${recipe.title}. ")
                    append("${recipe.cookTime} minutes. ")
                    append("${recipe.difficulty} difficulty. ")
                    append("By ${recipe.author}. ")
                }
                customActions = listOf(
                    CustomAccessibilityAction("Listen to recipe") { /* ... */ true },
                    CustomAccessibilityAction("Watch technique") { /* ... */ true },
                    CustomAccessibilityAction("Save recipe") { /* ... */ true },
                )
            }
    ) { /* Card content */ }
}
```

**9.4 High Contrast Mode**

```kotlin
// Kindred supports forced high contrast
// Minimum contrast ratio: 4.5:1 for normal text, 3:1 for large text (WCAG AA)
// High contrast mode: 7:1 for all text (WCAG AAA)

val AuraHighContrastColors = lightColorScheme(
    primary = Color(0xFF1A1A1A),
    onPrimary = Color(0xFFFFFFFF),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF000000),
    // ...
)
```

**9.5 Navigation Simplification**

- Maximum 4 bottom navigation destinations (Feed, Pantry, Camera, Profile)
- No nested navigation deeper than 2 levels
- Persistent back button with clear labels
- Voice narration as primary interaction — reduces need for reading

**9.6 Min SDK 26 Considerations**

- Notification channels required (Android 8.0) — already supported
- Adaptive icons supported
- Background execution limits — use WorkManager for all background tasks
- No Picture-in-Picture for video (requires SDK 26, but complex UX for elderly)
- AutoFill framework available for login forms

---

## 10. Performance Optimization

### 10.1 Budget Device Strategy

**Target:** Devices with 2-3GB RAM, mid-range SoC (Snapdragon 400-600 series)

| Technique | Impact | Implementation |
|---|---|---|
| **Baseline Profiles** | 30% faster startup | Generate via Macrobenchmark, include in release APK |
| **Lazy Layouts** | 73% less memory for lists | `LazyColumn` for feed, recipe lists |
| **Image Optimization** | Reduce OOM crashes | Coil with 256px thumbnails, WEBP format |
| **R8 Full Mode** | 15-20% smaller APK | Aggressive shrinking + optimization |
| **Compose Stability** | Reduce recompositions | `@Stable`/`@Immutable` annotations, `derivedStateOf` |
| **Module-level Proguard** | Faster builds | Per-module R8 rules |

### 10.2 Memory Management

```kotlin
// Image loading with budget device awareness
val imageLoader = ImageLoader.Builder(context)
    .memoryCache {
        MemoryCache.Builder()
            .maxSizePercent(context, 0.15) // 15% of available RAM (vs default 25%)
            .build()
    }
    .diskCache {
        DiskCache.Builder()
            .directory(context.cacheDir.resolve("image_cache"))
            .maxSizeBytes(100 * 1024 * 1024) // 100MB disk cache
            .build()
    }
    .crossfade(true)
    .build()
```

### 10.3 Battery Optimization for AI Features

| Feature | Strategy |
|---|---|
| **Voice Narration** | Stream only active step, stop on screen off (unless in cooking mode) |
| **Fridge Scan** | ML Kit runs only when camera is active, 30fps cap |
| **Video Playback** | Download once, cache locally, no re-streaming |
| **Location** | 15-minute intervals, balanced power accuracy |
| **Background Sync** | WorkManager with battery constraints, defer when low |
| **Expiry Checks** | Daily WorkManager job, not real-time |

### 10.4 APK Size

Target: < 25MB base APK with App Bundle dynamic delivery

- Use Android App Bundle (AAB) — reduces per-device APK size by ~35%
- Dynamic feature modules for Camera and Video (downloaded on first use)
- Compress all assets (WEBP images, ProGuard for code)
- Exclude unused ML Kit models — only include object detection + text recognition

### 10.5 Startup Performance

```kotlin
// App Startup library for ordered initialization
class KindredInitializer : Initializer<Unit> {
    override fun create(context: Context) {
        // Initialize in order: Hilt → Room → Coil → Firebase
        // Defer: ML Kit, CameraX, Location (lazy init on first use)
    }
    override fun dependencies(): List<Class<out Initializer<*>>> = emptyList()
}
```

---

## 11. Feasibility Assessment

### Feature-by-Feature Analysis

#### 11.1 Voice Narration (ElevenLabs)

| Aspect | Assessment |
|---|---|
| **Feasibility** | HIGH |
| **Risk** | MEDIUM |
| **Complexity** | MEDIUM |

**Details:**
- ElevenLabs Kotlin SDK exists (v0.1.0) but is Agents-focused, not TTS
- TTS streaming via REST API is mature and well-documented
- Voice cloning from 30s sample is production-ready (Instant Voice Clone)
- Media3 ExoPlayer handles audio streaming well
- **Risk:** SDK is early-stage; may need custom OkHttp-based streaming client
- **Risk:** Audio latency on slow mobile networks — need 2s buffer strategy
- **Mitigation:** Fall back to pre-built voices if clone quality is insufficient
- **Cost:** ~$0.30/1000 chars — a full recipe narration (~2000 chars) costs ~$0.60

#### 11.2 AI Video Generation (Google Veo)

| Aspect | Assessment |
|---|---|
| **Feasibility** | MEDIUM |
| **Risk** | HIGH |
| **Complexity** | HIGH |

**Details:**
- Veo 3.1 supports 9:16 vertical video — perfect for mobile
- Video generation is NOT real-time (30-120 second wait)
- Available via Gemini API and Vertex AI — requires backend proxy
- Quality is high (720p-4K), but generation is expensive
- **Risk:** User experience of waiting 30-120s for a video is poor
- **Risk:** Cost at scale (~$0.05-0.10/clip) could be significant with many users
- **Risk:** API availability and rate limits may constrain usage
- **Mitigation:** Pre-generate popular technique videos, cache aggressively, show estimated wait time
- **Recommendation:** V1 should use pre-generated video library + on-demand for premium users only

#### 11.3 Fridge Scanning (Gemini 3 Flash)

| Aspect | Assessment |
|---|---|
| **Feasibility** | HIGH |
| **Risk** | LOW-MEDIUM |
| **Complexity** | MEDIUM |

**Details:**
- Gemini 3 Flash excels at image understanding with "Agentic Vision"
- CameraX + ML Kit pre-filtering is a proven pipeline
- Food recognition accuracy is high for common items
- API response time: 1-3 seconds (acceptable for single-shot scan)
- **Risk:** Accuracy drops for unusual/regional ingredients
- **Risk:** Poor lighting in refrigerators can reduce quality
- **Mitigation:** Allow manual correction of detected items, learn from corrections
- **Cost:** Gemini 3 Flash is cost-effective (~$0.01-0.02 per image analysis)

#### 11.4 Receipt OCR (Gemini 3 Flash)

| Aspect | Assessment |
|---|---|
| **Feasibility** | HIGH |
| **Risk** | LOW |
| **Complexity** | LOW |

**Details:**
- Text recognition (ML Kit on-device) + Gemini structuring is well-proven
- Receipts have structured format — high accuracy expected
- Two-stage pipeline (ML Kit → Gemini) is cost-efficient
- **Risk:** Faded/crumpled receipts reduce accuracy
- **Mitigation:** Image enhancement before processing, manual edit option

#### 11.5 Hyperlocal Feed

| Aspect | Assessment |
|---|---|
| **Feasibility** | HIGH |
| **Risk** | LOW |
| **Complexity** | LOW-MEDIUM |

**Details:**
- FusedLocationProvider is mature, reliable
- Compose `LazyColumn`/`HorizontalPager` handles card-based swipeable UI well
- Coarse location is sufficient, low battery impact
- **Risk:** Low user density in rural areas → empty feed
- **Mitigation:** Fall back to regional/national trending when local data is sparse

#### 11.6 Smart Pantry with Expiry Tracking

| Aspect | Assessment |
|---|---|
| **Feasibility** | HIGH |
| **Risk** | LOW |
| **Complexity** | MEDIUM |

**Details:**
- Room + WorkManager for local storage and background checks
- FCM for push notifications
- Expiry estimation is the hard part — need heuristic database per item category
- **Risk:** Users may not keep pantry updated manually
- **Mitigation:** Auto-add from receipt scans, gentle reminders to update

#### 11.7 Culinary DNA (Personalization)

| Aspect | Assessment |
|---|---|
| **Feasibility** | HIGH |
| **Risk** | LOW |
| **Complexity** | MEDIUM |

**Details:**
- Track skip/bookmark/listen/watch interactions locally
- Build taste vector from ingredient preferences, cuisine types, difficulty
- Pure algorithmic — no external API needed for basic version
- Can enhance with Gemini for "explain my taste profile" feature later

### Overall Feasibility Summary

| Feature | V1 Ready? | Notes |
|---|---|---|
| Voice Narration | YES | Use REST API, not SDK; pre-built voices for launch |
| AI Video | PARTIAL | Pre-generated library only; on-demand for V2 |
| Fridge Scan | YES | Two-stage pipeline works well |
| Receipt OCR | YES | High accuracy, low cost |
| Hyperlocal Feed | YES | Needs critical mass of recipes/users |
| Smart Pantry | YES | Core CRUD + receipt auto-import |
| Culinary DNA | YES | Basic tracking; advanced insights for V2 |

---

## 12. Feature Parity with iOS

### Parity Matrix

| Feature | iOS | Android | Parity Notes |
|---|---|---|---|
| UI Framework | SwiftUI | Jetpack Compose | Both declarative, equivalent capability |
| Voice Narration | AVFoundation | Media3 ExoPlayer | Full parity — both stream ElevenLabs API |
| Camera | AVFoundation | CameraX | Full parity — CameraX is mature |
| ML Kit | Core ML + Vision | ML Kit (Google) | Full parity — ML Kit has Android advantage |
| Location | Core Location | FusedLocationProvider | Full parity |
| Push | APNs | FCM | Full parity — FCM supports both platforms |
| Offline Storage | Core Data / SwiftData | Room + DataStore | Full parity |
| Video Playback | AVPlayer | Media3 ExoPlayer | Full parity |
| Accessibility | VoiceOver | TalkBack | Full parity — both well-supported |
| Background Tasks | BGTaskScheduler | WorkManager | Full parity |
| App Size | ~20-25MB | ~20-25MB (AAB) | Comparable with App Bundle |
| Min OS | iOS 16 | Android 8.0 (SDK 26) | Android covers ~98%, iOS 16 covers ~95% |

### Android-Specific Advantages

1. **ML Kit** is Google-native — better integration, on-device processing is faster
2. **FusedLocationProvider** is more power-efficient than iOS Core Location
3. **Dynamic Feature Modules** — can defer camera/video module download (reduce initial install size)
4. **Widget Support** — Glance framework for home screen recipe widget (future V2 feature)

### Android-Specific Challenges

1. **Device Fragmentation** — must test on many screen sizes, RAM configs, SoC variants
2. **Battery Behavior** — OEM battery optimizations (Samsung, Xiaomi) may kill background services; need `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` guidance
3. **Camera Quality Variance** — budget device cameras produce noisier images; ML Kit pre-filtering must be robust
4. **Memory Constraints** — 2GB RAM devices need careful Coil/Compose tuning

### Shared Backend

Both platforms should share:
- Recipe API (REST/GraphQL)
- ElevenLabs voice generation (server-side proxy)
- Veo video generation (server-side, cached to CDN)
- User authentication (Firebase Auth or Supabase Auth)
- Analytics events schema

---

## Appendix A: Gradle Version Catalog

```toml
# gradle/libs.versions.toml

[versions]
kotlin = "2.1.10"
agp = "8.8.0"
compose-bom = "2026.02.01"
hilt = "2.57.1"
room = "2.7.0"
datastore = "1.2.0"
media3 = "1.9.2"
camerax = "1.5.0"
coil = "3.4.0"
retrofit = "2.11.0"
okhttp = "4.12.0"
kotlinx-serialization = "1.7.3"
kotlinx-coroutines = "1.9.0"
firebase-bom = "33.8.0"
work-manager = "2.10.0"
paging = "3.3.5"
navigation = "2.9.0"
accompanist = "0.36.0"
baseline-profiles = "1.4.0"
leakcanary = "2.14"

[libraries]
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
compose-foundation = { group = "androidx.compose.foundation", name = "foundation" }

hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-compiler", version.ref = "hilt" }
hilt-navigation-compose = { group = "androidx.hilt", name = "hilt-navigation-compose", version = "1.2.0" }

room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }
room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
room-paging = { group = "androidx.room", name = "room-paging", version.ref = "room" }

datastore-proto = { group = "androidx.datastore", name = "datastore", version.ref = "datastore" }

media3-exoplayer = { group = "androidx.media3", name = "media3-exoplayer", version.ref = "media3" }
media3-session = { group = "androidx.media3", name = "media3-session", version.ref = "media3" }
media3-ui = { group = "androidx.media3", name = "media3-ui", version.ref = "media3" }

camerax-core = { group = "androidx.camera", name = "camera-core", version.ref = "camerax" }
camerax-camera2 = { group = "androidx.camera", name = "camera-camera2", version.ref = "camerax" }
camerax-lifecycle = { group = "androidx.camera", name = "camera-lifecycle", version.ref = "camerax" }
camerax-view = { group = "androidx.camera", name = "camera-view", version.ref = "camerax" }
camerax-mlkit = { group = "androidx.camera", name = "camera-mlkit-vision", version.ref = "camerax" }

coil-compose = { group = "io.coil-kt.coil3", name = "coil-compose", version.ref = "coil" }
coil-network = { group = "io.coil-kt.coil3", name = "coil-network-okhttp", version.ref = "coil" }

retrofit = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }
retrofit-kotlinx-serialization = { group = "com.squareup.retrofit2", name = "converter-kotlinx-serialization", version.ref = "retrofit" }
okhttp = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp" }
okhttp-logging = { group = "com.squareup.okhttp3", name = "logging-interceptor", version.ref = "okhttp" }

firebase-bom = { group = "com.google.firebase", name = "firebase-bom", version.ref = "firebase-bom" }
firebase-messaging = { group = "com.google.firebase", name = "firebase-messaging-ktx" }
firebase-analytics = { group = "com.google.firebase", name = "firebase-analytics-ktx" }
firebase-crashlytics = { group = "com.google.firebase", name = "firebase-crashlytics-ktx" }

work-runtime = { group = "androidx.work", name = "work-runtime-ktx", version.ref = "work-manager" }

navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigation" }

paging-runtime = { group = "androidx.paging", name = "paging-runtime-ktx", version.ref = "paging" }
paging-compose = { group = "androidx.paging", name = "paging-compose", version.ref = "paging" }

kotlinx-serialization-json = { group = "org.jetbrains.kotlinx", name = "kotlinx-serialization-json", version.ref = "kotlinx-serialization" }
kotlinx-coroutines-android = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-android", version.ref = "kotlinx-coroutines" }

leakcanary = { group = "com.squareup.leakcanary", name = "leakcanary-android", version.ref = "leakcanary" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version = "2.1.10-1.0.31" }
```

---

## Appendix B: Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| 1 | ElevenLabs Kotlin SDK too immature for TTS streaming | Medium | High | Use direct REST + OkHttp WebSocket; SDK for Agents only |
| 2 | Veo video generation latency frustrates users | High | Medium | Pre-generate popular videos; show as "loading" with ETA |
| 3 | Budget device OOM with Compose + Camera + ML Kit | Medium | High | Aggressive memory caps, dynamic feature modules, profiling |
| 4 | OEM battery optimization kills background services | Medium | Medium | Guide users to whitelist app; use exact alarms for expiry |
| 5 | Gemini 3 Flash accuracy on regional food items | Low | Medium | Allow manual correction; build correction feedback loop |
| 6 | Device fragmentation (screen sizes, API quirks) | Medium | Medium | Test matrix: 10 devices, Samsung/Pixel/Xiaomi/budget tier |
| 7 | API cost scaling with user growth | Medium | High | Implement aggressive caching, rate limiting, tiered usage |
| 8 | Voice clone quality inconsistent across accents | Medium | Medium | Offer pre-built voice library as fallback |

---

## Appendix C: Testing Strategy

| Layer | Tool | Scope |
|---|---|---|
| Unit Tests | JUnit 5 + MockK + Turbine | ViewModels, Use Cases, Repositories |
| UI Tests | Compose Testing | Composables, Navigation, Accessibility |
| Integration | Hilt Test + Room In-Memory | Data layer, API ↔ DB flow |
| E2E | Maestro / UI Automator | Critical user flows on real devices |
| Performance | Macrobenchmark + Baseline Profiles | Startup, scroll jank, memory |
| Accessibility | Accessibility Scanner + Manual TalkBack | All screens, all text scales |

**Minimum Coverage Target:** 80% for domain + data layers, 60% for presentation layer.
