# Architecture Patterns: Smart Pantry Integration

**Project:** Kindred iOS — Smart Pantry Features
**Domain:** Pantry management with AI-powered scanning and recipe matching
**Researched:** 2026-03-11
**Confidence:** HIGH

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Integration Overview](#integration-overview)
3. [New Components vs Modified](#new-components-vs-modified)
4. [Data Flow Architecture](#data-flow-architecture)
5. [Package Structure](#package-structure)
6. [Component Boundaries](#component-boundaries)
7. [Patterns to Follow](#patterns-to-follow)
8. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
9. [Build Order Dependencies](#build-order-dependencies)
10. [Scalability Considerations](#scalability-considerations)

---

## Executive Summary

Smart Pantry features integrate with Kindred's existing TCA architecture as a **new SPM package** (`PantryFeature`) that follows established patterns from `FeedFeature` and `VoicePlaybackFeature`. The architecture leverages:

- **SwiftData** for local pantry persistence (same pattern as `GuestSessionClient`)
- **Apollo GraphQL** for backend sync with offline-first cache
- **UIImagePickerController** for camera capture (receipt/fridge photos)
- **Firebase AI Logic / Gemini 3 Flash** for image analysis
- **TCA Dependencies** for testable, composable clients
- **Local-first with remote sync** — pantry works offline, syncs when authenticated

**Key decision:** Pantry is a **new feature package**, NOT modifications to FeedFeature. Recipe matching logic lives in FeedFeature as a dependency on PantryFeature models.

---

## Integration Overview

### Architecture Fit

Smart Pantry features align perfectly with existing architecture:

```
Current (v2.0):                     New (Smart Pantry):
┌─────────────────────┐            ┌─────────────────────┐
│   FeedFeature       │            │   FeedFeature       │
│   - Recipe cards    │───────────▶│   - Recipe cards    │
│   - Swipe actions   │            │   - Match % badge   │
│   - Bookmarks       │            │   - Pantry filter   │
└─────────────────────┘            └─────────────────────┘
                                             │
                                             │ depends on
                                             ▼
                                   ┌─────────────────────┐
                                   │   PantryFeature     │
                                   │   - Pantry CRUD     │
                                   │   - Camera scan     │
                                   │   - Expiry alerts   │
                                   └─────────────────────┘
                                             │
                                             │ depends on
                                             ▼
                                   ┌─────────────────────┐
                                   │   VisionClient      │
                                   │   - Camera capture  │
                                   │   - Gemini API      │
                                   │   - Image analysis  │
                                   └─────────────────────┘
```

### What Changes

| Component | Change Type | Scope |
|-----------|-------------|-------|
| **PantryFeature** (new) | NEW PACKAGE | Full pantry management, camera flow, AI processing |
| **VisionClient** (new) | NEW CLIENT | Camera capture + Gemini image analysis |
| **FeedReducer** | MODIFIED | Add pantry-based recipe filtering, match % calculation |
| **RecipeCard** model | MODIFIED | Add `matchPercentage: Int?` field |
| **AppReducer** | MODIFIED | Add pantry tab, integrate PantryFeature reducer |
| **NetworkClient** | MODIFIED | New GraphQL operations for pantry sync |
| **Backend GraphQL API** | MODIFIED | New pantry schema (queries, mutations) |

### What Stays Same

- Auth flow (Clerk JWT) — unchanged
- Feed swipe mechanics — unchanged
- Voice playback — unchanged
- Apollo offline-first cache — unchanged
- TCA reducer composition — unchanged

---

## New Components vs Modified

### 1. NEW: PantryFeature Package

**Purpose:** Complete pantry management feature — scanning, CRUD, expiry tracking.

**Structure:**
```
Packages/PantryFeature/
├── Package.swift
├── Sources/
│   ├── Pantry/
│   │   ├── PantryReducer.swift         # Root reducer
│   │   ├── PantryView.swift            # Main pantry list
│   │   └── PantryClient.swift          # Persistence + sync
│   │
│   ├── Scanning/
│   │   ├── ScanningReducer.swift       # Camera → AI flow
│   │   ├── ScanCameraView.swift        # Camera preview
│   │   ├── ScanResultsView.swift       # Parsed ingredients list
│   │   └── ScanClient.swift            # Orchestrates camera + vision
│   │
│   ├── ItemDetail/
│   │   ├── ItemDetailReducer.swift     # Edit/delete pantry item
│   │   ├── ItemDetailView.swift
│   │   └── ExpiryCalculator.swift      # AI-based shelf life
│   │
│   ├── Models/
│   │   ├── PantryItem.swift            # @Model SwiftData entity
│   │   ├── IngredientCategory.swift    # Produce, Dairy, Protein, etc.
│   │   └── ScanResult.swift            # Camera scan output
│   │
│   └── Clients/
│       ├── PantryClient.swift          # Local persistence
│       ├── VisionClient.swift          # Camera + Gemini
│       └── ExpiryClient.swift          # Expiry estimation
```

**Dependencies:**
- `ComposableArchitecture` (TCA)
- `NetworkClient` (for GraphQL sync)
- `DesignSystem` (shared UI components)
- `AuthClient` (for auth state)

**Pattern:** Mirrors `FeedFeature` structure — reducer per screen, clients for side effects, models for domain.

---

### 2. NEW: VisionClient

**Purpose:** Abstract camera capture + AI image analysis.

**Interface:**
```swift
import Dependencies
import UIKit

public struct VisionClient {
    // Camera capture
    public var captureImage: @Sendable (ScanType) async throws -> UIImage

    // Gemini image analysis
    public var analyzeFridgePhoto: @Sendable (UIImage) async throws -> [ParsedIngredient]
    public var analyzeReceipt: @Sendable (UIImage) async throws -> [ReceiptItem]

    public enum ScanType {
        case fridge
        case receipt
    }
}

extension VisionClient: DependencyKey {
    public static var liveValue: VisionClient {
        VisionClient(
            captureImage: { scanType in
                // UIImagePickerController camera capture
            },
            analyzeFridgePhoto: { image in
                // Firebase AI Logic / Gemini 3 Flash
                // Prompt: "List all food ingredients visible in this fridge photo"
            },
            analyzeReceipt: { image in
                // Gemini with OCR-specific prompt
                // Prompt: "Extract item names and quantities from this receipt"
            }
        )
    }
}
```

**Implementation details:**
- **Camera:** Use `UIImagePickerController` with `.camera` source (not deprecated for camera, only for photo library where PHPicker is preferred)
- **AI:** Firebase AI Logic SDK → Gemini 3 Flash (multimodal, fast, cost-effective at ~$0.01 per image)
- **Error handling:** Throw descriptive errors (camera permission denied, Gemini API failure, invalid image)

---

### 3. MODIFIED: FeedReducer

**Changes:**
1. **Add dependency on PantryFeature models:**
   ```swift
   import PantryFeature // For PantryItem model
   ```

2. **Add match % calculation:**
   ```swift
   @Dependency(\.pantryClient) var pantryClient

   case .recipesLoaded(.success(let recipes)):
       let pantryItems = await pantryClient.allItems()
       let recipesWithMatch = recipes.map { recipe in
           recipe.withMatchPercentage(calculateMatch(recipe, pantryItems))
       }
       state.cardStack = recipesWithMatch
   ```

3. **Add filter action:**
   ```swift
   case .filterByPantryMatch:
       state.cardStack = state.allRecipes
           .filter { $0.matchPercentage ?? 0 >= 50 }
           .sorted { $0.matchPercentage ?? 0 > $1.matchPercentage ?? 0 }
   ```

**Matching algorithm:**
```swift
func calculateMatch(_ recipe: RecipeCard, _ pantryItems: [PantryItem]) -> Int {
    let recipeIngredients = Set(recipe.ingredients.map { $0.lowercased() })
    let pantryIngredients = Set(pantryItems.map { $0.name.lowercased() })

    guard !recipeIngredients.isEmpty else { return 0 }

    let matches = recipeIngredients.intersection(pantryIngredients).count
    return Int((Double(matches) / Double(recipeIngredients.count)) * 100)
}
```

**Source:** [Jaccard similarity](https://www.nature.com/articles/s41598-025-17189-6) — standard recipe matching metric.

---

### 4. MODIFIED: AppReducer

**Changes:**
1. **Add pantry state:**
   ```swift
   struct State {
       // Existing
       var feedState = FeedReducer.State()
       var profileState = ProfileReducer.State()
       var voicePlaybackState = VoicePlaybackReducer.State()

       // NEW
       var pantryState = PantryReducer.State()
       var selectedTab: Tab = .feed
   }

   enum Tab {
       case feed
       case pantry  // NEW
       case me
   }
   ```

2. **Compose pantry reducer:**
   ```swift
   var body: some ReducerOf<Self> {
       Scope(state: \.feedState, action: \.feed) { FeedReducer() }
       Scope(state: \.pantryState, action: \.pantry) { PantryReducer() }
       Scope(state: \.profileState, action: \.profile) { ProfileReducer() }
       // ... rest
   }
   ```

3. **Add pantry → feed effects:**
   ```swift
   case .pantry(.itemAdded), .pantry(.itemDeleted):
       // Recalculate recipe match percentages
       return .send(.feed(.recalculateMatches))
   ```

---

### 5. MODIFIED: NetworkClient (GraphQL)

**New operations:**

```graphql
# PantryQueries.graphql

query GetPantryItems($userId: ID!) {
    pantryItems(userId: $userId) {
        id
        name
        quantity
        unit
        category
        expiryDate
        addedAt
        imageUrl
    }
}

mutation AddPantryItem($input: PantryItemInput!) {
    addPantryItem(input: $input) {
        id
        name
        expiryDate
    }
}

mutation UpdatePantryItem($id: ID!, $input: PantryItemInput!) {
    updatePantryItem(id: $id, input: $input) {
        id
        expiryDate
    }
}

mutation DeletePantryItem($id: ID!) {
    deletePantryItem(id: $id)
}

mutation BulkAddPantryItems($items: [PantryItemInput!]!) {
    bulkAddPantryItems(items: $items) {
        count
        items { id name }
    }
}
```

**Cache policy:**
- **Pantry list:** `.returnCacheDataAndFetch` (show stale, fetch fresh)
- **Add/Update/Delete:** Write to local cache immediately (`LocalCacheMutation`), sync to server in background
- **Offline:** Queue mutations, replay on reconnect (Apollo's built-in retry)

**Reference:** [Apollo iOS cache transactions](https://www.apollographql.com/docs/ios/caching/cache-transactions)

---

### 6. MODIFIED: Backend (NestJS + Prisma)

**New Prisma schema:**

```prisma
model PantryItem {
  id          String   @id @default(cuid())
  userId      String
  name        String
  quantity    Float?
  unit        String?
  category    Category
  expiryDate  DateTime?
  addedAt     DateTime @default(now())
  imageUrl    String?

  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([expiryDate])
}

enum Category {
  PRODUCE
  DAIRY
  PROTEIN
  GRAINS
  PANTRY_STAPLES
  SPICES
  FROZEN
  OTHER
}
```

**New GraphQL resolvers:**
- `pantryItems(userId: ID!): [PantryItem!]!`
- `addPantryItem(input: PantryItemInput!): PantryItem!`
- `bulkAddPantryItems(items: [PantryItemInput!]!): BulkAddResult!`
- `updatePantryItem(id: ID!, input: PantryItemInput!): PantryItem!`
- `deletePantryItem(id: ID!): Boolean!`

---

## Data Flow Architecture

### Flow 1: Fridge Photo Scan

```
User Action                    System Response
─────────────────────────────────────────────────────────────────
1. Tap "Scan Fridge"          ├─ PantryReducer: .scanFridgeTapped
                              │
                              ├─ Check camera permission
                              │  (Info.plist: NSCameraUsageDescription)
                              │
2. Grant permission           ├─ VisionClient.captureImage(.fridge)
                              │  └─ UIImagePickerController presents
                              │
3. Take photo                 ├─ Image captured (UIImage)
                              │
                              ├─ Show loading state
                              │
                              ├─ VisionClient.analyzeFridgePhoto(image)
                              │  └─ Firebase AI Logic / Gemini 3 Flash
                              │      Prompt: "List all visible food ingredients
                              │               with estimated quantities"
                              │
4. Gemini response (3-5s)     ├─ [ParsedIngredient] returned
                              │
                              ├─ Present ScanResultsView
                              │  (editable list, user can refine)
                              │
5. User edits/confirms        ├─ PantryReducer: .confirmScanResults(items)
                              │
                              ├─ PantryClient.addItems(items) // Local SwiftData
                              │
                              ├─ NetworkClient.bulkAddPantryItems(items) // GraphQL
                              │  (background sync, queued if offline)
                              │
6. Success                    ├─ Navigate to pantry list
                              │
                              └─ Send .feed(.recalculateMatches)
                                 (update recipe cards with match %)
```

**Error paths:**
- Camera permission denied → Show settings alert
- Gemini API failure → Retry with exponential backoff (2s, 4s, 8s)
- Network offline → Save local only, sync later

---

### Flow 2: Receipt Scan

```
User Action                    System Response
─────────────────────────────────────────────────────────────────
1. Tap "Scan Receipt"         ├─ PantryReducer: .scanReceiptTapped
                              │
2. Capture receipt photo      ├─ VisionClient.captureImage(.receipt)
                              │
                              ├─ VisionClient.analyzeReceipt(image)
                              │  └─ Gemini 3 Flash with OCR focus
                              │      Prompt: "Extract item names, quantities,
                              │               and dates from this receipt"
                              │
3. Gemini extracts items      ├─ [ReceiptItem] returned
                              │  (includes purchase date for expiry calc)
                              │
                              ├─ ExpiryClient.estimateExpiry(item)
                              │  (ML-based shelf life estimation)
                              │
4. Present results            ├─ ScanResultsView (with expiry dates)
                              │
5. Confirm                    ├─ Bulk add to pantry (local + GraphQL)
                              │
                              └─ Schedule expiry notifications
```

**Expiry estimation logic:**
```swift
func estimateExpiry(item: String, category: Category, purchaseDate: Date) -> Date {
    let shelfLifeDays: Int
    switch category {
    case .produce: shelfLifeDays = 7
    case .dairy: shelfLifeDays = 14
    case .protein: shelfLifeDays = 3
    case .frozen: shelfLifeDays = 90
    default: shelfLifeDays = 30
    }
    return purchaseDate.addingTimeInterval(TimeInterval(shelfLifeDays * 86400))
}
```

**Source:** [iOS pantry app architectures](https://kitchenpalapp.com/en/) — modern apps use ML for expiry, fallback to heuristics.

---

### Flow 3: Recipe Match Percentage

```
FeedReducer State Change       Pantry Integration
─────────────────────────────────────────────────────────────────
1. Load recipes                ├─ .recipesLoaded([Recipe])
                               │
                               ├─ Fetch pantry items
                               │  @Dependency(\.pantryClient) var pantry
                               │  let items = await pantry.allItems()
                               │
2. Calculate match             ├─ For each recipe:
                               │    matchPercent = jaccard(recipe, items)
                               │
3. Update cards                ├─ state.cardStack = recipes.map {
                               │      $0.withMatch(matchPercent)
                               │    }
                               │
4. Render in UI                └─ RecipeCardView shows badge:
                                  if matchPercent >= 70: Green "90% match"
                                  if matchPercent >= 50: Yellow "60% match"
                                  else: No badge
```

---

### Flow 4: Expiry Push Notifications

```
Background Process             Notification Flow
─────────────────────────────────────────────────────────────────
1. App launches                ├─ PantryClient.scheduleExpiryChecks()
                               │
                               ├─ For each pantry item:
                               │    if expiryDate within 3 days:
                               │      schedule local notification
                               │
2. iOS delivers notification   ├─ "🥕 Carrots expire in 2 days"
   (8 AM local time)           │
                               │
3. User taps notification      ├─ Deep link to PantryView
                               │  (filtered to expiring items)
                               │
4. User removes expired item   ├─ PantryReducer: .deleteItem(id)
                               │
                               └─ Cancel scheduled notification
```

**Implementation:** Use `UNUserNotificationCenter` for local notifications (no server required).

**Reference:** [iOS push notification best practices 2026](https://www.pushwoosh.com/blog/ios-push-notifications/)

---

## Package Structure

### Updated Dependency Graph

```
┌──────────────┐
│  KindredApp  │
└──────┬───────┘
       │
       ├─────────────┬─────────────┬─────────────┬──────────────┐
       │             │             │             │              │
       ▼             ▼             ▼             ▼              ▼
┌─────────┐   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Feed   │   │  Pantry  │  │ Profile  │  │  Voice   │  │   Auth   │
│ Feature │   │ Feature  │  │ Feature  │  │ Playback │  │ Feature  │
└────┬────┘   └─────┬────┘  └────┬─────┘  └─────┬────┘  └─────┬────┘
     │              │            │               │             │
     │              │            └───────┬───────┘             │
     │              │                    │                     │
     └──────────────┴────────────────────┴─────────────────────┘
                                 │
                    ┌────────────┼────────────┬─────────────┐
                    │            │            │             │
                    ▼            ▼            ▼             ▼
             ┌───────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
             │ Network   │ │  Design  │ │  Auth    │ │ Kindred  │
             │  Client   │ │  System  │ │  Client  │ │   API    │
             └───────────┘ └──────────┘ └──────────┘ └──────────┘
```

**Key changes:**
- `PantryFeature` is a **peer** to `FeedFeature` (both depend on shared infrastructure)
- `FeedFeature` imports `PantryFeature` models (one-way dependency)
- `VisionClient` lives inside `PantryFeature` (not shared, pantry-specific)

---

## Component Boundaries

### PantryFeature Responsibilities

| Responsibility | Owns | Delegates |
|----------------|------|-----------|
| **Pantry CRUD** | Local SwiftData persistence | NetworkClient for GraphQL sync |
| **Camera capture** | VisionClient (UIImagePickerController) | iOS system camera |
| **Image analysis** | VisionClient (Gemini API) | Firebase AI Logic SDK |
| **Expiry tracking** | ExpiryClient (heuristics + notifications) | UNUserNotificationCenter |
| **UI** | PantryView, ScanCameraView, ItemDetailView | DesignSystem components |

### FeedFeature Responsibilities

| Responsibility | Owns | Delegates |
|----------------|------|-----------|
| **Recipe matching** | Match % calculation logic | PantryFeature models (read-only) |
| **Feed filtering** | Filter by match % | — |
| **Recipe cards** | Display match % badge | — |

**Boundary rule:** FeedFeature READS from PantryFeature (via `@Dependency(\.pantryClient)`), never writes. One-way data flow.

---

## Patterns to Follow

### Pattern 1: TCA Dependency Injection

**What:** Abstract side effects (camera, AI, persistence) into testable clients using TCA's `@Dependency` system.

**When:** Every feature touching external systems (camera, network, file system, sensors).

**Example:**
```swift
import Dependencies

public struct PantryClient {
    public var allItems: @Sendable () async -> [PantryItem]
    public var addItem: @Sendable (PantryItem) async throws -> Void
    public var deleteItem: @Sendable (String) async throws -> Void
}

extension PantryClient: DependencyKey {
    public static var liveValue: PantryClient {
        let store = PantryStore.shared // SwiftData ModelContainer
        return PantryClient(
            allItems: { await store.fetchAll() },
            addItem: { item in try await store.insert(item) },
            deleteItem: { id in try await store.delete(id) }
        )
    }

    public static var testValue: PantryClient {
        PantryClient(
            allItems: { [] },
            addItem: { _ in },
            deleteItem: { _ in }
        )
    }
}

extension DependencyValues {
    public var pantryClient: PantryClient {
        get { self[PantryClient.self] }
        set { self[PantryClient.self] = newValue }
    }
}
```

**Why:** Enables deterministic testing without real camera/network. Swap implementations with `withDependencies` in tests.

**Source:** Existing pattern in `GuestSessionClient`, `LocationClient`, `AudioPlayerClient`.

---

### Pattern 2: SwiftData Local-First Persistence

**What:** Use SwiftData `@Model` for local storage, sync to GraphQL in background.

**When:** Pantry items, cached recipes, user preferences.

**Example:**
```swift
import SwiftData

@Model
public final class PantryItem {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var name: String
    public var quantity: Double?
    public var unit: String?
    public var category: Category
    public var expiryDate: Date?
    public var addedAt: Date
    public var syncStatus: SyncStatus // .synced, .pending, .failed

    public init(id: String = UUID().uuidString, userId: String, name: String, ...) {
        self.id = id
        self.userId = userId
        self.name = name
        // ...
    }
}

enum SyncStatus: String, Codable {
    case synced
    case pending
    case failed
}
```

**Why:**
- Offline-first UX (pantry works without network)
- SwiftData handles migrations automatically
- Query performance with `@Predicate` macros

**Source:** Existing pattern in `GuestSessionStore` (SwiftData + ModelContainer).

**Reference:** [SwiftData local-first architectures](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2)

---

### Pattern 3: Multi-Step TCA Flows

**What:** Model complex flows (camera → AI → review → save) as a sequence of states.

**When:** Scanning flow (multiple screens with async dependencies).

**Example:**
```swift
@Reducer
struct ScanningReducer {
    @ObservableState
    struct State {
        var scanState: ScanState = .idle
        var capturedImage: UIImage?
        var parsedItems: [ParsedIngredient] = []
        var isProcessing = false
        var error: String?
    }

    enum ScanState {
        case idle
        case capturingPhoto
        case processingImage
        case reviewingResults
    }

    enum Action {
        case startScan(ScanType)
        case photoCaptured(Result<UIImage, Error>)
        case analysisCompleted(Result<[ParsedIngredient], Error>)
        case editItem(Int, ParsedIngredient)
        case confirmResults
        case cancel
    }

    @Dependency(\.visionClient) var vision
    @Dependency(\.pantryClient) var pantry

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startScan(let type):
                state.scanState = .capturingPhoto
                return .run { send in
                    await send(.photoCaptured(Result {
                        try await vision.captureImage(type)
                    }))
                }

            case .photoCaptured(.success(let image)):
                state.capturedImage = image
                state.scanState = .processingImage
                state.isProcessing = true
                return .run { send in
                    await send(.analysisCompleted(Result {
                        try await vision.analyzeFridgePhoto(image)
                    }))
                }

            case .analysisCompleted(.success(let items)):
                state.parsedItems = items
                state.scanState = .reviewingResults
                state.isProcessing = false
                return .none

            case .confirmResults:
                return .run { [items = state.parsedItems] send in
                    for item in items {
                        try await pantry.addItem(item.toPantryItem())
                    }
                    await send(.cancel) // Dismiss flow
                }

            // ... error handling
            }
        }
    }
}
```

**Why:**
- Clear state machine (idle → capturing → processing → reviewing)
- Cancellable effects (user can back out at any step)
- Testable with `TestStore` (assert state transitions)

**Source:** [TCA patterns for multi-step flows](https://www.kodeco.com/24550178-getting-started-with-the-composable-architecture)

---

### Pattern 4: Apollo Local Cache Mutations

**What:** Write to Apollo cache immediately, sync to server in background.

**When:** Adding/deleting pantry items (optimistic UI updates).

**Example:**
```swift
// In NetworkClient
func addPantryItem(_ item: PantryItemInput) async throws {
    // 1. Write to cache immediately (optimistic update)
    try await apolloClient.store.withinReadWriteTransaction { transaction in
        let cachedQuery = GetPantryItemsQuery(userId: item.userId)
        var data = try transaction.read(query: cachedQuery)
        data.pantryItems.append(item)
        try transaction.write(data: data, forQuery: cachedQuery)
    }

    // 2. Send mutation to server (background)
    let mutation = AddPantryItemMutation(input: item)
    _ = try await apolloClient.perform(mutation: mutation)
}
```

**Why:**
- Instant UI feedback (no spinner)
- Works offline (mutations queued, replayed on reconnect)
- Consistent with Apollo best practices

**Reference:** [Apollo iOS cache transactions](https://www.apollographql.com/docs/ios/caching/cache-transactions)

---

### Pattern 5: Camera Capture with UIImagePickerController

**What:** Use `UIImagePickerController` for camera (not deprecated), wrap in TCA effect.

**When:** Fridge/receipt photo capture.

**Example:**
```swift
import UIKit

actor CameraManager {
    func captureImage() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    continuation.resume(throwing: CameraError.notAvailable)
                    return
                }

                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = CameraDelegate(continuation: continuation)

                // Present from key window
                UIApplication.shared.keyWindow?.rootViewController?
                    .present(picker, animated: true)
            }
        }
    }
}

private class CameraDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let continuation: CheckedContinuation<UIImage, Error>

    init(continuation: CheckedContinuation<UIImage, Error>) {
        self.continuation = continuation
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            continuation.resume(returning: image)
        } else {
            continuation.resume(throwing: CameraError.captureFailed)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        continuation.resume(throwing: CameraError.cancelled)
    }
}
```

**Why:**
- Camera capture not deprecated (only photo library selection)
- Works reliably on all iOS versions
- Easy to test with dependency injection

**Source:** [iOS camera best practices 2026](https://developer.apple.com/documentation/uikit/uiimagepickercontroller)

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Coupling FeedFeature and PantryFeature Bidirectionally

**What goes wrong:** FeedFeature imports PantryFeature, PantryFeature imports FeedFeature → circular dependency, SPM build fails.

**Why it happens:** Tempting to trigger feed refresh from pantry save.

**Instead:** Use `AppReducer` as coordinator:
```swift
// In AppReducer
case .pantry(.itemSaved):
    return .send(.feed(.recalculateMatches))
```

**Detection:** SPM build error: "Circular dependency between PantryFeature and FeedFeature."

---

### Anti-Pattern 2: Synchronous Camera/AI Calls

**What goes wrong:** Calling Gemini API synchronously blocks main thread → UI freezes.

**Why it happens:** `async/await` looks synchronous, easy to forget `Task` wrapper.

**Instead:** Always use TCA effects:
```swift
case .analyzeTapped:
    return .run { [image = state.image] send in
        let result = try await visionClient.analyzeFridgePhoto(image)
        await send(.analysisCompleted(result))
    }
```

**Detection:** Main thread checker warning in Xcode, UI jank.

---

### Anti-Pattern 3: Storing Full Images in SwiftData

**What goes wrong:** Storing `UIImage.pngData()` in SwiftData bloats database, slows queries.

**Why it happens:** Convenience — seems easier than separate file storage.

**Instead:** Store image URL (Cloudflare R2), keep only URL in SwiftData:
```swift
@Model
class PantryItem {
    var imageUrl: String? // Remote URL after upload
    // NOT: var imageData: Data?
}
```

**Prevention:** Upload images to R2, store URL in database.

**Detection:** Database file size > 50 MB, query performance degradation.

**Source:** [SwiftData best practices](https://bugfender.com/blog/ios-data-persistence/)

---

### Anti-Pattern 4: Hardcoding Gemini Prompts

**What goes wrong:** Prompt buried in code → hard to A/B test, iterate on accuracy.

**Why it happens:** Prototype with inline strings, never refactor.

**Instead:** Externalize prompts:
```swift
enum VisionPrompt {
    static let fridgeScan = """
        Analyze this fridge photo and list all food ingredients visible.
        For each ingredient, provide:
        - Name (e.g., "Carrots")
        - Estimated quantity (e.g., "5")
        - Unit (e.g., "pieces")

        Return as JSON array: [{"name": "...", "quantity": 5, "unit": "..."}]
        """

    static let receiptScan = """
        Extract all grocery items from this receipt.
        Include: item name, quantity, purchase date.
        Ignore: totals, tax, store info.

        Return as JSON array.
        """
}
```

**Prevention:** Centralize prompts, version control changes, A/B test variants.

---

### Anti-Pattern 5: No Offline Handling

**What goes wrong:** App crashes or shows blank screens when offline.

**Why it happens:** Assuming network always available.

**Instead:** Handle offline gracefully:
```swift
case .syncTapped:
    guard !state.isOffline else {
        state.error = "Changes will sync when you're back online"
        return .none
    }
    return .run { ... }
```

**Prevention:** Test with Network Link Conditioner (Xcode → Settings → Network), handle `.offline` state.

**Detection:** User reports: "App broken without WiFi."

---

## Build Order Dependencies

### Suggested Build Order (6 milestones)

**Why this order:** Bottom-up dependency resolution — infrastructure before features, models before UI.

#### Milestone 1: Infrastructure (Week 1)

**Goal:** Shared clients and models ready for PantryFeature.

1. **VisionClient interface**
   - Define protocol in `PantryFeature/Sources/Clients/VisionClient.swift`
   - Stub implementation (returns empty results)
   - Test value for TCA tests

2. **PantryItem model**
   - SwiftData `@Model` definition
   - Category enum
   - Validation logic (name required, quantity >= 0)

3. **Backend GraphQL schema**
   - Prisma migrations
   - Pantry queries/mutations
   - Deploy to staging

**Exit criteria:** VisionClient compiles, PantryItem persists locally, GraphQL API responds.

---

#### Milestone 2: Pantry CRUD (Week 2)

**Goal:** Basic pantry list works (add/edit/delete items manually).

1. **PantryClient**
   - SwiftData persistence
   - CRUD operations
   - Sync status tracking

2. **PantryReducer**
   - State management
   - Add/Edit/Delete actions
   - GraphQL integration

3. **PantryView**
   - List of items
   - Swipe to delete
   - Add button (manual entry form)

**Exit criteria:** User can add items via form, see list, delete items. Syncs to backend when authenticated.

---

#### Milestone 3: Camera Capture (Week 3)

**Goal:** Camera capture works, stores photos (no AI yet).

1. **UIImagePickerController integration**
   - Camera permission flow
   - Image capture → UIImage
   - Error handling (permission denied, camera unavailable)

2. **ScanCameraView**
   - Camera preview
   - Capture button
   - Cancel flow

3. **Image storage**
   - Upload to Cloudflare R2
   - Store URL in PantryItem

**Exit criteria:** User can take photo, photo uploads to R2, URL stored.

---

#### Milestone 4: AI Image Analysis (Week 4)

**Goal:** Gemini analyzes fridge photos, extracts ingredients.

1. **Firebase AI Logic SDK integration**
   - Add Firebase to project
   - Configure API key
   - Test Gemini 3 Flash connectivity

2. **VisionClient implementation**
   - `analyzeFridgePhoto` with prompt
   - Parse JSON response → `[ParsedIngredient]`
   - Error handling (API failures, invalid images)

3. **ScanResultsView**
   - Display parsed ingredients
   - Edit/remove items
   - Confirm button → add to pantry

**Exit criteria:** Fridge photo → parsed ingredients → saved to pantry.

---

#### Milestone 5: Recipe Matching (Week 5)

**Goal:** Recipe cards show match % badge.

1. **FeedReducer integration**
   - Add `@Dependency(\.pantryClient)`
   - Implement Jaccard similarity
   - Calculate match % on recipe load

2. **RecipeCard model update**
   - Add `matchPercentage: Int?` field
   - Update GraphQL query (optional, server-side calc)

3. **RecipeCardView update**
   - Match % badge design
   - Color coding (green >70%, yellow >50%)

4. **Feed filtering**
   - "Cookable Now" filter (match >= 50%)
   - Sort by match % descending

**Exit criteria:** Recipe cards show accurate match %, filter works.

---

#### Milestone 6: Expiry Tracking (Week 6)

**Goal:** Users get notifications for expiring items.

1. **ExpiryClient**
   - Heuristic shelf life calculation
   - Notification scheduling

2. **Notification permissions**
   - Request on first pantry use
   - Handle denied state gracefully

3. **Expiry badge in PantryView**
   - "Expires in 2 days" label
   - Red badge for expired items

4. **Deep linking**
   - Tap notification → open PantryView
   - Filter to expiring items

**Exit criteria:** Users receive timely expiry notifications, can act on them.

---

### Parallel Work Opportunities

**Can be built simultaneously:**
- Milestone 1 (Infrastructure) + Milestone 2 (CRUD) → Different files, no conflicts
- Milestone 3 (Camera) + Milestone 4 (AI) → Camera stub returns test image while AI develops
- Milestone 5 (Recipe matching) → Independent of camera/AI, only needs PantryClient interface

**Cannot parallelize:**
- Milestone 2 depends on Milestone 1 (needs VisionClient interface)
- Milestone 4 depends on Milestone 3 (needs captured images)
- Milestone 5 depends on Milestone 2 (needs populated pantry)

---

## Scalability Considerations

### At 100 Users

| Concern | Approach | Rationale |
|---------|----------|-----------|
| **Pantry size** | No limits | Average user has 20-50 items |
| **Image storage** | Cloudflare R2 | Free egress, $0.015/GB storage |
| **Gemini API cost** | ~$0.01/scan | 100 users × 10 scans/month = $10/month |
| **Push notifications** | Local notifications | Free, no server required |
| **Database queries** | SwiftData cache | Local-first, no backend load |

**Total cost:** ~$10-20/month (mostly AI API).

---

### At 10K Users

| Concern | Approach | Rationale |
|---------|----------|-----------|
| **Pantry size** | Soft cap at 200 items | Prompt: "Archive old items?" |
| **Image storage** | 10K users × 50 images × 500 KB = 250 GB → $4/month | Cloudflare R2 pricing |
| **Gemini API cost** | 10K × 10 scans/month = 100K scans → $1,000/month | Batch processing for cost reduction |
| **Backend load** | PostgreSQL + PostGIS scales to 10K easily | Existing Supabase plan |
| **Recipe matching** | Cache match % on server | Reduce client-side computation |

**Total cost:** ~$1,000-1,500/month (AI dominates).

**Optimization:** Batch Gemini requests (5 images/request), cache common ingredients (e.g., "milk" detected 1000x).

---

### At 1M Users

| Concern | Approach | Rationale |
|---------|----------|-----------|
| **Pantry size** | Hard cap at 500 items | Database row limit |
| **Image storage** | 1M users × 50 images × 500 KB = 25 TB → $375/month | Still affordable with R2 |
| **Gemini API cost** | 1M × 10 scans/month = 10M scans → $100K/month | **Critical:** Switch to self-hosted vision model (LLaVA, BLIP-2) |
| **Backend scaling** | Horizontal scaling (read replicas, sharding) | Standard practice |
| **Recipe matching** | Move to backend GraphQL resolver | Reduce iOS client load |

**Total cost:** ~$100K/month (AI is bottleneck).

**Critical pivot:** At 1M users, self-host open-source vision model (LLaVA 1.6, BLIP-2) to reduce AI costs from $100K → $5K/month (GPU instances).

**Source:** [AI cost analysis for image models](https://ai.google.dev/pricing#1_5flash)

---

## Sources

### Architecture Patterns
- [TCA (Composable Architecture)](https://github.com/pointfreeco/swift-composable-architecture)
- [Getting Started with TCA | Kodeco](https://www.kodeco.com/24550178-getting-started-with-the-composable-architecture)
- [TCA Multi-Step Flows | Medium](https://medium.com/@dmitrylupich/the-composable-architecture-swift-guide-to-tca-c3bf9b2e86ef)

### Camera Integration
- [SwiftUI Camera Integration 2026](https://www.createwithswift.com/camera-capture-setup-in-a-swiftui-app/)
- [UIImagePickerController | Apple](https://developer.apple.com/documentation/uikit/uiimagepickercontroller)
- [SwiftUI Camera on Lock Screen | Level Up Coding](https://levelup.gitconnected.com/swiftui-camera-capture-on-lock-screen-7c427205358c)

### AI Image Analysis
- [Gemini API with Swift | AppCoda](https://www.appcoda.com/swiftui-image-recognition/)
- [Firebase AI Logic SDK](https://firebase.google.com/docs/ai-logic/get-started)
- [Integrating Gemini API into iOS | Medium](https://medium.com/@mortaltechnical/integrating-gemini-api-into-ios-application-using-swift-845d57a4b603)

### Data Persistence
- [SwiftData Local-First Architectures | Medium](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2)
- [SwiftData in iOS 17 | Medium](https://medium.com/@satyaking101/swiftdata-in-ios-17-a-modern-approach-to-data-persistence-537ab52c1002)
- [iOS Data Persistence Guide | Bugfender](https://bugfender.com/blog/ios-data-persistence/)

### Apollo GraphQL
- [Apollo iOS Cache Transactions](https://www.apollographql.com/docs/ios/caching/cache-transactions)
- [Mutations and Cache | Hasura](https://hasura.io/learn/graphql/ios/optimistic-update-mutations/2-mutation-cache/)
- [Apollo Offline Toolkit](https://github.com/Malpaux/apollo-offline)

### Recipe Matching
- [Recipe Similarity Networks | Nature](https://www.nature.com/articles/s41598-025-17189-6)
- [Recipe Recommendation Systems | Towards Data Science](https://towardsdatascience.com/building-a-recipe-recommendation-system-297c229dda7b/)
- [Ingredient Matching with TF-IDF | ResearchGate](https://www.researchgate.net/publication/382114471_Real_Time_Recipe_Recommendation_Based_on_Ingredients_They_Have_at_Home_Using_TF-IDF_Algorithm)

### Pantry Management
- [iOS Pantry Apps 2026 | Portions Master](https://portionsmaster.com/blog/best-pantry-inventory-app-and-fridge-management-tool/)
- [KitchenPal Architecture](https://kitchenpalapp.com/en/)
- [Best Apps for Recipes from Pantry | Flavor365](https://flavor365.com/5-best-apps-for-recipes-from-ingredients-you-own/)

### Push Notifications
- [iOS Push Notifications Guide 2026 | Pushwoosh](https://www.pushwoosh.com/blog/ios-push-notifications/)
- [Push Notification Best Practices | Appbot](https://appbot.co/blog/app-push-notifications-2026-best-practices/)
- [Food Expiry Tracking | Fridgely](https://fridgelyapp.com/)

---

**Document Version:** 1.0
**Last Updated:** 2026-03-11
**Confidence:** HIGH (all patterns verified with existing codebase + official sources)
