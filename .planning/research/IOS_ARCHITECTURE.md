# Kindred — iOS Architecture & Feasibility Assessment

> **Author:** Senior iOS Engineer
> **Date:** 2026-02-28
> **Status:** v1.0 — Initial Architecture Proposal

---

## Table of Contents

1. [Architecture Pattern](#1-architecture-pattern)
2. [Module & Package Structure](#2-module--package-structure)
3. [Key Frameworks & SDKs](#3-key-frameworks--sdks)
4. [Data Layer Design](#4-data-layer-design)
5. [API Integration Patterns](#5-api-integration-patterns)
6. [Camera & Media Pipeline](#6-camera--media-pipeline)
7. [Location Services](#7-location-services)
8. [Push Notification Strategy](#8-push-notification-strategy)
9. [Accessibility Implementation Plan](#9-accessibility-implementation-plan)
10. [Performance Considerations](#10-performance-considerations)
11. [AI Feature Feasibility Assessment](#11-ai-feature-feasibility-assessment)

---

## 1. Architecture Pattern

### Recommendation: TCA (The Composable Architecture) with MVVM fallback for leaf screens

**Why TCA over MVVM+C or Clean Architecture:**

| Criterion | TCA | MVVM+C | Clean Architecture |
|---|---|---|---|
| SwiftUI alignment | Native fit — unidirectional data flow mirrors SwiftUI's declarative model | Good but requires Coordinator boilerplate | Over-engineered for mobile; too many layers |
| Testability | Best-in-class — `TestStore` enables exhaustive state/effect assertions | Moderate — requires DI and mock setup | Good but verbose |
| Side-effect management | `Effect` system handles async work (API calls, audio, location) predictably | Ad-hoc — Combine publishers or async/await scattered across ViewModels | Use-case layer helps but adds indirection |
| Composition | Feature modules compose via `Scope` — ideal for multi-module SPM | Navigation coordination is the weak spot | Good module boundaries but heavy protocol layer |
| Team scalability | Isolated `Reducer` per feature — parallel development with minimal merge conflicts | Moderate | Good |
| Learning curve | Steeper initially — pays off at scale | Lowest | Moderate |

**Rationale for Kindred specifically:**

- **Complex side effects**: Voice streaming (ElevenLabs), camera capture, location updates, video polling (Veo) — TCA's `Effect` system manages all of these in a testable, cancellable way.
- **State-driven UI**: Card-based recipe feed with Listen/Watch/Skip actions maps perfectly to `Action` → `Reducer` → `State` flow.
- **12,000+ GitHub stars**, 200+ contributors — mature, battle-tested, active community (Point-Free maintains it).
- **Offline-first**: TCA's `@Dependency` system makes swapping network vs. cached data sources trivial.

**Pragmatic concession**: For simple leaf screens (Settings, About, static content), use vanilla `@Observable` / `@State` — no need for TCA overhead on screens with trivial state.

### Core Architecture Layers

```
┌──────────────────────────────────────────────┐
│                   App Shell                   │
│         (App entry, DI, Navigation)           │
├──────────────────────────────────────────────┤
│               Feature Modules                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │  Feed    │ │  Pantry  │ │  Recipe      │ │
│  │  Feature │ │  Feature │ │  Detail      │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │  Camera  │ │  Profile │ │  Onboarding  │ │
│  │  Feature │ │  Feature │ │  Feature     │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
├──────────────────────────────────────────────┤
│              Shared / Domain                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │  Models  │ │  Design  │ │  Shared      │ │
│  │          │ │  System  │ │  Components  │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
├──────────────────────────────────────────────┤
│               Infrastructure                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ Network  │ │ Storage  │ │  Platform    │ │
│  │ Layer    │ │ Layer    │ │  Services    │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
└──────────────────────────────────────────────┘
```

---

## 2. Module & Package Structure

All modules delivered as **Swift Packages** via SPM (no CocoaPods, no Carthage). SPM is the 2026 standard — first-party Apple tool, integrated into Xcode, enables incremental builds per module (up to 40% faster builds).

```
Kindred/
├── KindredApp/                 # App target (thin shell)
│   ├── KindredApp.swift        # @main entry point
│   ├── AppFeature.swift            # Root TCA reducer, tab navigation
│   └── Info.plist
│
├── Packages/
│   ├── KNCore/                     # Core models, protocols, extensions
│   │   ├── Sources/
│   │   │   ├── Models/             # Recipe, Ingredient, PantryItem, UserProfile
│   │   │   ├── Protocols/          # Repository protocols, Service protocols
│   │   │   └── Extensions/         # Foundation/SwiftUI extensions
│   │   └── Package.swift
│   │
│   ├── KNDesignSystem/             # Design tokens, shared UI components
│   │   ├── Sources/
│   │   │   ├── Tokens/             # Colors, typography, spacing, shadows
│   │   │   ├── Components/         # KNButton, KNCard, KNTextField, KNBadge
│   │   │   └── Modifiers/          # Accessibility modifiers, haptic feedback
│   │   └── Package.swift
│   │
│   ├── KNNetworking/               # API client, interceptors, retry logic
│   │   ├── Sources/
│   │   │   ├── APIClient.swift     # Generic async/await API client
│   │   │   ├── Endpoints/          # Type-safe endpoint definitions
│   │   │   ├── Interceptors/       # Auth token injection, logging
│   │   │   └── WebSocket/          # Real-time connection for feed updates
│   │   └── Package.swift
│   │
│   ├── KNStorage/                  # Local persistence (SwiftData + Keychain)
│   │   ├── Sources/
│   │   │   ├── SwiftData/          # @Model definitions, migration plans
│   │   │   ├── Keychain/           # Secure credential storage
│   │   │   └── UserDefaults/       # Lightweight preferences
│   │   └── Package.swift
│   │
│   ├── KNAudioEngine/              # ElevenLabs integration + audio playback
│   │   ├── Sources/
│   │   │   ├── VoiceService.swift  # ElevenLabs API wrapper
│   │   │   ├── AudioPlayer.swift   # AVPlayer-based streaming playback
│   │   │   ├── VoiceCloning.swift  # Voice sample upload + clone management
│   │   │   └── AudioSession.swift  # AVAudioSession configuration
│   │   └── Package.swift
│   │
│   ├── KNVisionEngine/             # Camera, Gemini vision, OCR
│   │   ├── Sources/
│   │   │   ├── CameraService.swift # AVCaptureSession management
│   │   │   ├── GeminiClient.swift  # Firebase AI Logic / Gemini Flash API
│   │   │   ├── FridgeScanner.swift # Fridge photo → ingredient extraction
│   │   │   └── ReceiptScanner.swift# Receipt photo → item parsing
│   │   └── Package.swift
│   │
│   ├── KNVideoEngine/              # Veo API integration + video playback
│   │   ├── Sources/
│   │   │   ├── VeoClient.swift     # Async polling for video generation
│   │   │   ├── VideoCache.swift    # Local video caching (48h TTL)
│   │   │   └── VideoPlayer.swift   # AVPlayer video presentation
│   │   └── Package.swift
│   │
│   ├── KNLocationService/          # Core Location wrapper
│   │   ├── Sources/
│   │   │   ├── LocationManager.swift
│   │   │   └── GeofenceService.swift
│   │   └── Package.swift
│   │
│   ├── KNNotificationService/      # Push + local notifications
│   │   ├── Sources/
│   │   │   ├── PushManager.swift
│   │   │   ├── ExpiryAlerts.swift
│   │   │   └── NotificationContent.swift
│   │   └── Package.swift
│   │
│   ├── FeedFeature/                # Hyperlocal recipe feed (cards)
│   │   ├── Sources/
│   │   │   ├── FeedFeature.swift   # TCA Reducer
│   │   │   ├── FeedView.swift      # SwiftUI card stack
│   │   │   ├── RecipeCard.swift    # Individual card component
│   │   │   └── FeedClient.swift    # @Dependency for feed data
│   │   └── Package.swift
│   │
│   ├── RecipeDetailFeature/        # Full recipe view with voice/video
│   ├── PantryFeature/              # Smart pantry management
│   ├── CameraFeature/              # Fridge scan + receipt scan flows
│   ├── ProfileFeature/             # Culinary DNA, preferences, voice setup
│   └── OnboardingFeature/          # First-run, voice sample, dietary prefs
│
└── Kindred.xcodeproj
```

### Dependency Graph

```
FeedFeature ──────→ KNCore, KNDesignSystem, KNNetworking, KNLocationService
RecipeDetailFeature → KNCore, KNDesignSystem, KNAudioEngine, KNVideoEngine
PantryFeature ─────→ KNCore, KNDesignSystem, KNStorage, KNNotificationService
CameraFeature ─────→ KNCore, KNDesignSystem, KNVisionEngine
ProfileFeature ────→ KNCore, KNDesignSystem, KNStorage, KNAudioEngine
OnboardingFeature ─→ KNCore, KNDesignSystem, KNAudioEngine, KNLocationService
```

**Rule**: Feature modules NEVER depend on other feature modules. All cross-feature communication goes through the `AppFeature` root reducer or shared `@Dependency` values.

---

## 3. Key Frameworks & SDKs

### Apple Frameworks

| Framework | Purpose | Min iOS |
|---|---|---|
| **SwiftUI** | All UI — declarative, accessibility-native | 17.0 |
| **SwiftData** | Local persistence (pantry items, cached recipes, user profile) | 17.0 |
| **AVFoundation** | Audio streaming (voice narration), video playback, camera capture | 17.0 |
| **Core Location** | Hyperlocal feed positioning (5-10 mi radius) | 17.0 |
| **UserNotifications** | Push notifications (expiry alerts, recipe suggestions) | 17.0 |
| **PhotosUI** | PHPickerViewController for photo library access | 17.0 |
| **Vision** | On-device text recognition (receipt OCR fallback) | 17.0 |
| **Observation** | `@Observable` macro for simple ViewModels | 17.0 |
| **WidgetKit** | Home screen widgets (expiring items, daily recipe) | 17.0 |

### Third-Party Dependencies

| Package | Version | Purpose | Source |
|---|---|---|---|
| **swift-composable-architecture** | ~> 1.17+ | App architecture (TCA) | Point-Free (SPM) |
| **swift-dependencies** | ~> 1.6+ | DI container for TCA | Point-Free (SPM) |
| **ElevenLabs Swift SDK** | ~> 3.0+ | Voice cloning, conversational AI | ElevenLabs (SPM) |
| **Firebase SDK (firebase-ios-sdk)** | ~> 11.x | AI Logic (Gemini), Auth, Analytics, Crashlytics | Google (SPM) |
| **Kingfisher** | ~> 8.x | Async image loading + caching | onevcat (SPM) |
| **swift-tagged** | ~> 0.10+ | Type-safe ID wrappers | Point-Free (SPM) |
| **swift-snapshot-testing** | ~> 1.17+ | Snapshot tests for UI | Point-Free (SPM) |

### Minimum Deployment Target: **iOS 17.0**

**Rationale:**
- SwiftData requires iOS 17+ (no way around this)
- `@Observable` macro requires iOS 17+
- iOS 17 adoption is ~95%+ as of early 2026
- Target demographic (75+ users) often has relatively recent iPhones purchased by family members or through carrier upgrade programs
- iOS 17 supports iPhone XS and later (2018+) — 8 years of device coverage

---

## 4. Data Layer Design

### 4.1 Local Storage Strategy

```
┌─────────────────────────────────────────┐
│              SwiftData                   │
│  ┌──────────────┐  ┌────────────────┐  │
│  │ PantryItem   │  │ CachedRecipe   │  │
│  │ - name       │  │ - id           │  │
│  │ - quantity   │  │ - title        │  │
│  │ - expiryDate │  │ - ingredients  │  │
│  │ - category   │  │ - steps        │  │
│  │ - addedDate  │  │ - cachedDate   │  │
│  └──────────────┘  └────────────────┘  │
│  ┌──────────────┐  ┌────────────────┐  │
│  │ UserProfile  │  │ InteractionLog │  │
│  │ - name       │  │ - recipeId     │  │
│  │ - dietary    │  │ - action       │  │
│  │ - voiceId    │  │ - timestamp    │  │
│  │ - location   │  │ (skip/book/    │  │
│  │              │  │  listen/watch) │  │
│  └──────────────┘  └────────────────┘  │
├─────────────────────────────────────────┤
│              Keychain                    │
│  - API tokens (ElevenLabs, Firebase)    │
│  - User auth credentials                │
├─────────────────────────────────────────┤
│            UserDefaults                  │
│  - Onboarding completed flag            │
│  - Preferred text size override         │
│  - Last known location (coarse)         │
│  - Feature flags / remote config cache  │
└─────────────────────────────────────────┘
```

### 4.2 Caching Strategy

| Data Type | Cache Duration | Storage | Eviction |
|---|---|---|---|
| Recipe feed cards | 1 hour | SwiftData + memory | LRU, max 200 recipes |
| Recipe images | 7 days | Kingfisher disk cache | Max 500 MB |
| Generated videos | 48 hours | FileManager (Caches/) | FIFO, max 2 GB |
| Voice audio clips | 24 hours | FileManager (Caches/) | LRU, max 500 MB |
| Pantry data | Persistent | SwiftData | Manual delete only |
| User profile | Persistent | SwiftData + Keychain | Manual delete only |
| Interaction logs | 90 days | SwiftData | Auto-prune on launch |

### 4.3 Offline Support

**Offline-capable features:**
- Browse cached recipe feed (last 50 cards)
- View full recipe details for any cached recipe
- Manage pantry (add/edit/delete items)
- View expiry calendar
- Play previously cached voice narration

**Online-required features:**
- Generate new voice narration (ElevenLabs API)
- Generate cooking videos (Veo API)
- Scan fridge/receipt (Gemini API)
- Refresh feed with new recipes
- Sync pantry to cloud backup

**Sync strategy:** Optimistic local-first with background sync. Changes to pantry items are written to SwiftData immediately and queued for server sync via a `SyncQueue` that processes when connectivity resumes.

### 4.4 TCA Dependency Injection

```swift
// Register dependencies for testability
extension PantryClient: DependencyKey {
    static let liveValue = PantryClient(
        fetchItems: { try await SwiftDataStore.shared.fetchPantryItems() },
        addItem: { item in try await SwiftDataStore.shared.insert(item) },
        deleteItem: { id in try await SwiftDataStore.shared.delete(PantryItem.self, id: id) }
    )

    static let previewValue = PantryClient(
        fetchItems: { PantryItem.previews },
        addItem: { _ in },
        deleteItem: { _ in }
    )

    static let testValue = PantryClient.unimplemented()
}
```

---

## 5. API Integration Patterns

### 5.1 Networking Architecture

All API calls use Swift Structured Concurrency (`async/await`) — no Combine, no completion handlers.

```swift
// Type-safe endpoint definition
enum KindredEndpoint: Endpoint {
    case feedRecipes(latitude: Double, longitude: Double, radiusMiles: Double)
    case recipeDetail(id: Recipe.ID)
    case syncPantry(items: [PantryItem])
    case generateVoice(recipeId: Recipe.ID, voiceId: String)
    case generateVideo(prompt: String, style: VideoStyle)
    case analyzeImage(imageData: Data, task: VisionTask)

    var path: String { /* ... */ }
    var method: HTTPMethod { /* ... */ }
    var body: Encodable? { /* ... */ }
}
```

### 5.2 ElevenLabs Voice Integration

**Architecture:** Server-side voice generation with client-side streaming playback.

```
User taps "Listen" → API request to backend →
Backend calls ElevenLabs TTS API with recipe text + user's cloned voice ID →
Returns streaming audio URL → AVPlayer streams audio in real-time
```

**Key considerations:**
- **Voice Cloning**: User records 30-second sample during onboarding → uploaded to ElevenLabs → returns `voice_id` stored in user profile
- **Audio format**: MP3 128kbps for streaming (good quality, low bandwidth)
- **Playback**: `AVPlayer` with `.playback` audio session category for background audio support
- **Caching**: Generated audio cached locally for 24h keyed by `(recipeId, voiceId, textHash)`
- **Fallback**: If ElevenLabs is down, offer text-only recipe steps (no TTS fallback to lower-quality system voices — brand consistency matters)

```swift
// TCA Effect for voice streaming
case .listenButtonTapped:
    return .run { [recipeId = state.recipe.id, voiceId = state.voiceId] send in
        await send(.voiceLoading)
        let audioURL = try await voiceClient.generateNarration(recipeId, voiceId)
        await send(.voiceReady(audioURL))
    } catch: { error, send in
        await send(.voiceFailed(error))
    }
    .cancellable(id: CancelID.voiceGeneration)
```

### 5.3 Gemini 3 Flash Vision Integration

**Via Firebase AI Logic SDK** — this is the recommended 2026 approach (standalone `generative-ai-swift` is deprecated).

```
Camera capture (AVCaptureSession) → UIImage → Data →
Firebase AI Logic SDK → Gemini 3 Flash (multimodal) →
Structured JSON response → Parse to [Ingredient]
```

**Two vision tasks:**

1. **Fridge Scanning**: Photo of fridge contents → Gemini extracts ingredient list with estimated quantities
2. **Receipt OCR**: Photo of supermarket receipt → Gemini extracts purchased items, quantities, prices

**Prompt engineering** is critical:
```
"Analyze this photo of a refrigerator's contents. Return a JSON array of ingredients
with fields: name (string), estimatedQuantity (string), category (enum: produce,
dairy, protein, condiment, beverage, other), freshnessDays (int estimate)."
```

**Rate limiting**: Queue camera analysis requests — max 1 concurrent Gemini call, debounce rapid re-captures.

### 5.4 Google Veo Video Integration

**Architecture:** Asynchronous polling pattern (Veo generates videos server-side, 11s–6min latency).

```
User taps "Watch" → Submit prompt to Veo 3.1 API →
Show loading animation ("Your cooking video is being prepared...") →
Poll every 10 seconds → Video ready → Download to local cache →
Present in AVPlayer (9:16 vertical for mobile, 720p default)
```

**Critical design decision**: Because video generation takes 11s–6min, this MUST NOT block UI. Implementation:
- Submit generation request immediately when user enters recipe detail (pre-fetch)
- Show "Watch" button in loading state until video is ready
- Cache generated videos for 48h (matches Veo's server-side retention)
- Use `9:16` aspect ratio for mobile-native vertical viewing
- Default to `720p` to balance quality/speed/cost ($0.15/sec for Veo 3.1 Fast)

```swift
// Polling effect
case .videoGenerationSubmitted(let operationId):
    return .run { send in
        while true {
            try await Task.sleep(for: .seconds(10))
            let status = try await veoClient.checkStatus(operationId)
            if status.done {
                await send(.videoReady(status.videoURL))
                return
            }
        }
    }
    .cancellable(id: CancelID.videoPolling)
```

### 5.5 Error Handling & Retry Strategy

| API | Retry Policy | Timeout | Fallback |
|---|---|---|---|
| ElevenLabs TTS | 2 retries, exponential backoff | 30s | Text-only recipe |
| Gemini Vision | 1 retry | 15s | Manual ingredient entry |
| Veo Video | 0 retries (long-running) | 6 min polling | "Video unavailable" state |
| Backend API | 3 retries, exponential backoff | 10s | Cached data |

---

## 6. Camera & Media Pipeline

### 6.1 Camera Capture

```swift
// AVCaptureSession configuration
class CameraService: NSObject {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    func configure() {
        session.sessionPreset = .photo  // High-quality stills for vision AI
        // Add back camera input
        // Configure photo output with HEIC format
    }
}
```

**Camera UX flow:**
1. Tap "Scan Fridge" or "Scan Receipt" → Camera view with overlay guide
2. Guide frame shows where to position fridge/receipt
3. Auto-capture on stability detection OR manual shutter button (large, 60pt)
4. Photo sent to Gemini → Results shown as editable ingredient list
5. User confirms/edits → Items added to pantry

### 6.2 Media Pipeline

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Camera      │────→│  Image       │────→│  Gemini 3    │
│   Capture     │     │  Processing  │     │  Flash API   │
│  (AVCapture)  │     │ (downsample, │     │  (via        │
│               │     │  compress)   │     │  Firebase)   │
└──────────────┘     └──────────────┘     └──────────────┘
                                                │
                           ┌────────────────────┘
                           ▼
                     ┌──────────────┐     ┌──────────────┐
                     │  Parse JSON  │────→│  Pantry      │
                     │  Response    │     │  Update      │
                     └──────────────┘     └──────────────┘
```

**Image preprocessing before Gemini:**
- Downscale to max 1024x1024 (Gemini doesn't need full 12MP)
- JPEG compression at 80% quality
- Strip EXIF data (privacy — no location metadata sent to API)
- Target: <500KB per image sent to API

### 6.3 Video Playback

- Use `AVPlayer` for Veo-generated video playback
- Inline player within recipe detail view (not full-screen by default)
- Support picture-in-picture for cooking along
- Cache videos in `Caches/` directory — OS can evict if storage pressure

---

## 7. Location Services

### 7.1 Approach: Significant Location Change + On-Demand Updates

Kindred does NOT need continuous GPS tracking. The hyperlocal feed needs to know the user's approximate area (~5-10 mile radius), which changes infrequently.

**Strategy:**

1. **On first launch / onboarding**: Request `CLLocationManager.requestWhenInUseAuthorization()`
2. **Feed refresh**: Use `CLLocationManager.requestLocation()` for a single high-accuracy fix
3. **Background**: Use Significant Location Change monitoring (cell tower-based, ~500m accuracy, extremely battery-efficient)
4. **Caching**: Store last known location in UserDefaults — use for feed if location unavailable

### 7.2 Configuration

```swift
struct LocationService {
    let manager = CLLocationManager()

    func configure() {
        manager.desiredAccuracy = kCLLocationAccuracyKilometer  // ~1km is fine for 5-10mi radius
        manager.distanceFilter = 1600  // ~1 mile — don't update for small movements
        manager.activityType = .other
        manager.pausesLocationUpdatesAutomatically = true
    }
}
```

### 7.3 Privacy & Permissions

- Request "When In Use" only — never "Always"
- Explain location purpose in Info.plist: "Kindred uses your location to show trending recipes in your area"
- If user denies: Allow manual zip code / city entry as fallback
- Never send precise coordinates to backend — round to 2 decimal places (~1.1 km precision)

**Battery impact**: Negligible. Single-shot location requests + Significant Location Change uses cell radio only, no GPS activation.

---

## 8. Push Notification Strategy

### 8.1 Notification Types

| Type | Trigger | Priority | Category |
|---|---|---|---|
| **Expiry Warning** | Item expires in 2 days | Time-Sensitive | `expiry-alert` |
| **Expiry Today** | Item expires today | Time-Sensitive | `expiry-urgent` |
| **Daily Recipe** | Daily at user's preferred time | Normal | `daily-recipe` |
| **New Trending** | Viral recipe in user's area | Normal | `trending` |
| **Voice Ready** | Async voice generation complete | Normal | `voice-ready` |
| **Video Ready** | Async video generation complete | Normal | `video-ready` |

### 8.2 Implementation

**Expiry notifications**: Generated locally via `UNUserNotificationCenter` — no server needed. Scheduled when pantry items are added/updated.

```swift
func scheduleExpiryNotification(for item: PantryItem) {
    let content = UNMutableNotificationContent()
    content.title = "\(item.name) expires soon"
    content.body = "Use it today or add it to tomorrow's recipe!"
    content.categoryIdentifier = "expiry-alert"
    content.interruptionLevel = .timeSensitive

    // Trigger 2 days before expiry at 9 AM
    let triggerDate = Calendar.current.date(byAdding: .day, value: -2, to: item.expiryDate)!
    var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
    components.hour = 9
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(identifier: "expiry-\(item.id)", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
```

**Remote notifications**: Firebase Cloud Messaging (FCM) for server-triggered notifications (trending recipes, async generation completion).

### 8.3 Notification Actions

- **Expiry alert**: "Find Recipe" action → deep links to feed filtered by expiring ingredient
- **Daily recipe**: "Listen" / "View" actions → deep links to recipe detail
- **Trending**: "Save" / "Skip" actions → inline engagement without opening app

### 8.4 Notification Budget

Respect user attention — **max 3 notifications per day** to avoid notification fatigue (critical for 75+ users who may find excessive notifications confusing or stressful).

---

## 9. Accessibility Implementation Plan

### 9.1 Target: WCAG 2.2 AA Compliance

Kindred's core demographic includes users aged 75+. Accessibility is not an afterthought — it's a primary design constraint.

### 9.2 Design System Accessibility Tokens

```swift
// KNDesignSystem/Sources/Tokens/AccessibilityTokens.swift
enum KNAccessibility {
    /// Minimum touch target: 48x48 pt (exceeds Apple's 44x44 minimum)
    static let minimumTouchTarget: CGFloat = 48

    /// Large touch target for primary actions (Listen, Watch, Skip): 56x56 pt
    static let primaryActionTarget: CGFloat = 56

    /// Minimum contrast ratio for all text
    static let minimumContrastRatio: CGFloat = 4.5  // WCAG AA

    /// Large text contrast ratio
    static let largeTextContrastRatio: CGFloat = 3.0  // WCAG AA
}
```

### 9.3 Dynamic Type Support

- ALL text uses SwiftUI's built-in Dynamic Type (`.font(.title)`, `.font(.body)`, etc.)
- Custom fonts registered with `UIFontMetrics` for proper scaling
- Layout tested at **all 12 Dynamic Type sizes** including AX5 (largest)
- No truncation — text wraps or scrolls, never clips
- Recipe cards expand vertically at larger type sizes

### 9.4 VoiceOver Support

- Every interactive element has a meaningful `.accessibilityLabel`
- Recipe cards announce: "{Recipe name}, {cook time}, by {author}. Actions: Listen, Watch, or Skip"
- Custom rotor actions for card navigation
- Audio player state announced: "Playing recipe narration. Double-tap to pause"
- Camera view provides audio guidance: "Point camera at your fridge. Tap large button at bottom to capture"

### 9.5 Motor Accessibility

- **Swipe gestures** always have button alternatives (Listen/Watch/Skip buttons visible alongside swipe)
- **No precision gestures** — no pinch, rotate, or long-press required for core functionality
- **Switch Control** tested — all features accessible via single switch
- **Dwell Control** compatible — all actions have minimum 0.5s dwell target

### 9.6 Cognitive Accessibility

- **Simple navigation**: Max 3 levels deep from any screen
- **Consistent layout**: Same card pattern everywhere (feed, pantry, saved)
- **Clear feedback**: Haptic + visual + optional audio confirmation for actions
- **Undo support**: All destructive actions (delete pantry item, skip recipe) are undoable for 5 seconds
- **Reduce Motion**: Respect `UIAccessibility.isReduceMotionEnabled` — disable card animations, use cross-fades instead

### 9.7 Voice-First Design

The app's voice narration feature is inherently accessible:
- Tap "Listen" → hands-free recipe following
- Audio continues in background (screen off while cooking)
- Voice instructions replace need to read small text while cooking

### 9.8 Minimum iOS Version Implication

iOS 17.0 supports VoiceOver, Dynamic Type, Switch Control, Voice Control, and all accessibility APIs used in this architecture. No compatibility concerns.

---

## 10. Performance Considerations

### 10.1 Memory Budget

| Component | Expected Memory | Mitigation |
|---|---|---|
| Base app | ~50 MB | Standard for SwiftUI app |
| Feed images (visible) | ~30 MB (10 cards × 3 MB) | Kingfisher auto-releases off-screen |
| Audio streaming buffer | ~5 MB | AVPlayer manages internally |
| Video playback | ~50 MB | Single video at a time, release on navigate away |
| Camera session | ~40 MB | Release session when leaving camera view |
| SwiftData context | ~10 MB | Batch fetch, fault objects |
| **Peak total** | **~185 MB** | Well within iOS limits (even iPhone XS has 4GB RAM) |

### 10.2 Battery Optimization

| Feature | Battery Impact | Mitigation |
|---|---|---|
| Voice streaming | Moderate (network + audio) | Cache generated audio; stop playback on app background if user preference |
| Video playback | Moderate (GPU decode) | 720p default; no auto-play |
| Camera | High (during active use) | Release capture session immediately after photo taken |
| Location | Negligible | Single-shot requests + Significant Location Change only |
| Gemini API calls | Low (network only) | Batch requests; no polling |
| Veo polling | Low (10s interval HTTP) | Cancel polling when leaving screen |
| Background sync | Low | NSURLSession background transfer; iOS manages scheduling |

### 10.3 App Launch Performance

**Target**: Cold launch < 2 seconds, warm launch < 0.5 seconds.

**Optimizations:**
- Minimal work in `AppDelegate` / `@main` — defer all non-critical init
- Feed shows cached data immediately, refreshes in background
- Lazy-load feature modules — Camera, Profile not loaded until navigated to
- Pre-warm ElevenLabs audio session during feed scroll idle time

### 10.4 Network Efficiency

- **Image CDN**: Serve recipe images as WebP format, multiple resolutions (1x, 2x, 3x)
- **API pagination**: Feed loads 10 cards at a time, prefetch next 10 at card 7
- **Request coalescing**: Multiple pantry changes batched into single sync request
- **Offline queue**: Failed requests queued in SwiftData, retried on connectivity change

---

## 11. AI Feature Feasibility Assessment

### 11.1 ElevenLabs Voice Cloning & Narration

| Aspect | Assessment |
|---|---|
| **Feasibility** | **HIGH** — Fully feasible |
| **How it works** | User records 30s voice sample → ElevenLabs creates voice clone → TTS generates recipe narration on demand |
| **iOS integration** | Official Swift SDK (v3.0+) supports streaming audio; AVPlayer handles playback |
| **Latency** | ~2-5s for generation start; streaming playback begins before full generation completes |
| **Cost** | ~$0.18 per 1,000 characters (~$0.01-0.03 per recipe narration) |
| **Risks** | - Voice quality with 30s sample may vary (ElevenLabs recommends 1-3 min for best quality) |
| | - Network required for all narration (no on-device TTS possible with cloned voice) |
| | - API rate limits could throttle during peak usage |
| **Mitigation** | Cache generated audio aggressively; allow longer voice samples for quality; pre-generate popular recipes |

### 11.2 Gemini 3 Flash — Fridge Scanning

| Aspect | Assessment |
|---|---|
| **Feasibility** | **HIGH** — Fully feasible, impressive accuracy |
| **How it works** | Camera captures fridge photo → Compressed image sent to Gemini 3 Flash → Returns structured ingredient list |
| **iOS integration** | Firebase AI Logic Swift SDK (officially supported path for Gemini on iOS) |
| **Latency** | ~2-4s for image analysis |
| **Accuracy** | Gemini 3 Flash handles multimodal well; accuracy ~85-90% for common grocery items |
| **Cost** | Gemini 3 Flash pricing is very low for image analysis (~$0.001 per image) |
| **Risks** | - Poor lighting in fridges reduces accuracy |
| | - Overlapping/hidden items missed |
| | - Non-standard items (farmer's market, ethnic groceries) may not be recognized |
| **Mitigation** | Allow user to edit/correct results; flash/torch activation during capture; multiple angle prompts |

### 11.3 Gemini 3 Flash — Receipt OCR

| Aspect | Assessment |
|---|---|
| **Feasibility** | **HIGH** — Receipt OCR is a well-solved vision problem |
| **How it works** | Camera captures receipt → Gemini extracts line items with quantities and prices |
| **Latency** | ~1-3s |
| **Accuracy** | ~95%+ for standard printed receipts; lower for handwritten or faded |
| **Risks** | - Long receipts may need multiple photos |
| | - International receipt formats vary significantly |
| **Mitigation** | Apple Vision framework as on-device fallback for basic OCR; allow manual correction |

### 11.4 Google Veo — AI Cooking Videos

| Aspect | Assessment |
|---|---|
| **Feasibility** | **MEDIUM** — Feasible but with significant UX constraints |
| **How it works** | Text prompt describing cooking technique → Veo 3.1 generates 8-second 720p video with audio |
| **iOS integration** | No native iOS SDK — REST API via `URLSession`. Asynchronous polling pattern required |
| **Latency** | **11 seconds to 6 minutes** — this is the primary UX challenge |
| **Cost** | $0.15/sec (Veo 3.1 Fast) × 8 sec = **$1.20 per video** — expensive at scale |
| **Quality** | Good for general cooking visuals; may produce unrealistic food preparation details |
| **Risks** | - **HIGH LATENCY**: 6 min worst case is unacceptable for "tap Watch and see video" UX |
| | - **HIGH COST**: At $1.20/video, 100K users × 2 videos/day = **$240K/month** |
| | - Video accuracy: AI may generate incorrect cooking techniques (safety concern with knives, heat) |
| | - No iOS SDK — must build polling infrastructure ourselves |
| | - Veo retention is 48 hours — must download and cache locally |
| **Mitigation** | Pre-generate videos for popular recipes (amortize cost); show as "bonus" not core feature; budget caps per user (3 videos/day); consider pre-recorded stock video library as supplement |

### 11.5 Hyperlocal Feed (Location-Based)

| Aspect | Assessment |
|---|---|
| **Feasibility** | **HIGH** — Standard iOS capability |
| **How it works** | Device location → Backend query for recipes trending within 5-10 mi radius |
| **iOS integration** | Core Location — well-established, battery-efficient |
| **Risks** | - User may deny location permission |
| | - "Trending" requires sufficient user density in area (cold start problem) |
| **Mitigation** | Fallback to zip code entry; supplement with regional/national trends until local density builds |

### 11.6 Smart Pantry with Expiry Tracking

| Aspect | Assessment |
|---|---|
| **Feasibility** | **HIGH** — Straightforward local feature |
| **How it works** | Items added (manually, camera scan, or receipt scan) → Local storage with expiry dates → Local notifications |
| **iOS integration** | SwiftData for persistence; UNUserNotificationCenter for alerts |
| **Risks** | - Expiry date accuracy depends on input method (camera scan won't get exact dates) |
| | - Notification fatigue if many items expiring |
| **Mitigation** | Default expiry estimates by category (produce: 5 days, dairy: 10 days, etc.); smart notification grouping; daily digest instead of per-item alerts |

### 11.7 Culinary DNA (Taste Profile)

| Aspect | Assessment |
|---|---|
| **Feasibility** | **HIGH** — On-device analytics |
| **How it works** | Track user interactions (skip, bookmark, listen, watch) → Build weighted preference model → Influence feed ranking |
| **iOS integration** | SwiftData stores interaction logs; simple on-device weighted scoring algorithm |
| **Cost** | Zero marginal cost — runs entirely on-device |
| **Risks** | - Cold start: No preferences before ~20 interactions |
| **Mitigation** | Onboarding questionnaire (dietary preferences, cuisine interests) seeds initial profile |

---

## Summary of Risk Matrix

| Feature | Feasibility | Risk Level | Cost Concern | v1 Priority |
|---|---|---|---|---|
| Voice Narration (ElevenLabs) | HIGH | LOW | Low | **Must Have** |
| Fridge Scanning (Gemini) | HIGH | LOW | Very Low | **Must Have** |
| Receipt OCR (Gemini) | HIGH | LOW | Very Low | **Must Have** |
| Smart Pantry + Expiry | HIGH | LOW | None | **Must Have** |
| Hyperlocal Feed | HIGH | MEDIUM | None | **Must Have** |
| Culinary DNA | HIGH | LOW | None | **Should Have** |
| AI Cooking Videos (Veo) | MEDIUM | **HIGH** | **HIGH ($1.20/video)** | **Nice to Have** |

---

## Key Recommendations & Concerns

### Top 3 Recommendations

1. **Adopt TCA + SwiftUI + SPM modular architecture** — provides the testability, composability, and side-effect management needed for a feature-rich app with multiple async AI integrations.

2. **De-risk Veo video generation** — the 11s-6min latency and $1.20/video cost make it the highest-risk feature. Recommend: pre-generate for top 500 recipes, cap at 3 user-generated videos/day, and supplement with a curated stock video library for common techniques.

3. **Invest heavily in accessibility from day one** — 48pt minimum touch targets, full VoiceOver support, Dynamic Type at all sizes. This is not optional for the 75+ demographic. Voice-first design (ElevenLabs narration) is itself an accessibility win.

### Top 3 Concerns

1. **Veo cost at scale**: If the product takes off, AI video generation could become the dominant cost center. Need hard per-user limits and a pre-generation caching strategy before launch.

2. **Voice clone quality from 30s sample**: ElevenLabs recommends 1-3 minutes for high-quality clones. A 30-second clip may produce acceptable but not great results. Recommend offering optional "enhance your voice" flow with longer recording.

3. **Offline experience for elderly users**: If connectivity is poor (common in some elderly living situations), the app must degrade gracefully. Cached feed + local pantry + cached voice must provide a useful experience without network access.

---

## Appendix: Build & CI

- **Xcode 16+** (required for Swift 6 concurrency, iOS 17 SDK)
- **Swift 6.x** with strict concurrency checking enabled
- **CI**: GitHub Actions or Xcode Cloud
- **Testing**: TCA `TestStore` for business logic, `swift-snapshot-testing` for UI, XCUITest for critical user flows
- **Distribution**: TestFlight for beta, App Store for release
- **Code signing**: Xcode automatic signing with Apple Developer Program team
