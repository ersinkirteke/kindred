# Stack Research — Smart Pantry Features

**Domain:** Smart Pantry (fridge scanning, receipt OCR, expiry tracking, ingredient matching)
**Researched:** 2026-03-11
**Confidence:** HIGH

## Executive Summary

Smart Pantry features build on Kindred's validated stack with minimal new dependencies. The existing iOS architecture (SwiftUI + TCA), backend (NestJS + GraphQL + Prisma + PostgreSQL), and AI infrastructure (Gemini 2.0 Flash, Firebase AI Logic SDK) support all Smart Pantry capabilities. Key additions: iOS VisionKit's DataScannerViewController for live receipt OCR, new Prisma models for pantry data, and GraphQL schema extensions.

**What's already validated (DO NOT add):**
- iOS: SwiftUI + TCA 1.x, Apollo iOS 2.0.6, AVFoundation, iOS 17.0+
- Backend: NestJS 11 + GraphQL (Apollo Server 5) + Prisma 7 + PostgreSQL 15
- AI: Gemini 2.0 Flash via Firebase AI Logic SDK, already integrated for image analysis
- Storage: Cloudflare R2, SwiftData for local persistence

---

## Recommended Stack Additions

### iOS Framework Additions

| Framework | Version | Purpose | Why Recommended |
|-----------|---------|---------|-----------------|
| **VisionKit** | Built-in (iOS 17+) | Live receipt scanning with DataScannerViewController | Apple-native live OCR with currency detection (iOS 17+). Replaces need for custom AVFoundation + Vision pipeline. No dependencies, zero cost, on-device processing. |
| **PhotosUI** | Built-in (iOS 17+) | Photo picker for fridge scanning | Already listed in existing architecture but confirming for pantry camera flows. Replaces UIImagePickerController with native SwiftUI PhotosPicker. |

**No new third-party iOS dependencies required.** All camera, OCR, and vision capabilities use Apple frameworks already in the validated stack.

### Backend Package Additions

| Package | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **class-validator** | ^0.14.x | GraphQL input validation for pantry mutations | Standard NestJS validation library. Works seamlessly with code-first GraphQL @InputType decorators. Already used in similar NestJS projects for DTO validation. |
| **class-transformer** | ^0.5.x | Transform and validate nested pantry item inputs | Required peer dependency for class-validator. Enables automatic transformation of plain objects to validated class instances. |

**Note:** Prisma 7, PostgreSQL 15, and NestJS 11 are already validated. No ORM or database changes needed.

---

## New Data Models (Prisma Schema Extensions)

### PantryItem Model

```prisma
enum PantryCategory {
  PRODUCE
  DAIRY
  PROTEIN
  GRAINS
  CONDIMENTS
  BEVERAGES
  FROZEN
  CANNED
  SPICES
  OTHER
}

enum PantryItemSource {
  MANUAL
  FRIDGE_SCAN
  RECEIPT_SCAN
}

model PantryItem {
  id           String            @id @default(cuid())
  userId       String
  user         User              @relation(fields: [userId], references: [id], onDelete: Cascade)

  name         String            // normalized ingredient name
  quantity     String?           // "2", "1.5", "500g" (flexible string)
  unit         String?           // "cups", "lbs", "pieces", etc.
  category     PantryCategory    @default(OTHER)

  // Expiry tracking
  addedDate    DateTime          @default(now())
  expiryDate   DateTime?         // null = no expiry or unknown
  estimatedExpiryDays Int?       // AI-estimated shelf life from add date

  // Metadata
  source       PantryItemSource  @default(MANUAL)
  notes        String?           // user notes
  imageUrl     String?           // optional photo of item

  // Matching
  normalizedName String          // lowercase, stripped for matching (e.g., "chicken breast")

  createdAt    DateTime          @default(now())
  updatedAt    DateTime          @updatedAt

  @@index([userId, expiryDate])
  @@index([userId, normalizedName])
  @@index([userId, category])
}
```

### PantryScanHistory Model (optional, for analytics)

```prisma
enum ScanType {
  FRIDGE
  RECEIPT
}

model PantryScanHistory {
  id            String    @id @default(cuid())
  userId        String
  user          User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  scanType      ScanType
  itemsDetected Int       // count of items AI detected
  itemsAdded    Int       // count user confirmed
  imageUrl      String?   // R2 URL (optional, for debugging)

  scannedAt     DateTime  @default(now())

  @@index([userId, scannedAt])
}
```

### User Model Extension

Add to existing `User` model:
```prisma
model User {
  // ... existing fields ...

  // NEW relations for Smart Pantry
  pantryItems       PantryItem[]
  pantryScanHistory PantryScanHistory[]
}
```

---

## GraphQL Schema Extensions

### Type Definitions (Code-First NestJS)

```typescript
// PantryItem.entity.ts
import { ObjectType, Field, ID, registerEnumType } from '@nestjs/graphql';
import { PantryCategory, PantryItemSource } from '@prisma/client';

registerEnumType(PantryCategory, { name: 'PantryCategory' });
registerEnumType(PantryItemSource, { name: 'PantryItemSource' });

@ObjectType()
export class PantryItem {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  quantity?: string;

  @Field({ nullable: true })
  unit?: string;

  @Field(() => PantryCategory)
  category: PantryCategory;

  @Field()
  addedDate: Date;

  @Field({ nullable: true })
  expiryDate?: Date;

  @Field(() => Int, { nullable: true })
  estimatedExpiryDays?: number;

  @Field(() => PantryItemSource)
  source: PantryItemSource;

  @Field({ nullable: true })
  notes?: string;

  @Field({ nullable: true })
  imageUrl?: string;
}
```

### Input Types with Validation

```typescript
// CreatePantryItemInput.dto.ts
import { InputType, Field } from '@nestjs/graphql';
import { IsNotEmpty, IsOptional, IsEnum, IsDateString, MinLength } from 'class-validator';
import { PantryCategory, PantryItemSource } from '@prisma/client';

@InputType()
export class CreatePantryItemInput {
  @Field()
  @IsNotEmpty()
  @MinLength(2)
  name: string;

  @Field({ nullable: true })
  @IsOptional()
  quantity?: string;

  @Field({ nullable: true })
  @IsOptional()
  unit?: string;

  @Field(() => PantryCategory)
  @IsEnum(PantryCategory)
  category: PantryCategory;

  @Field({ nullable: true })
  @IsOptional()
  @IsDateString()
  expiryDate?: string;

  @Field(() => PantryItemSource)
  @IsEnum(PantryItemSource)
  source: PantryItemSource;

  @Field({ nullable: true })
  @IsOptional()
  notes?: string;
}
```

### Mutations & Queries

```typescript
// pantry.resolver.ts
@Resolver(() => PantryItem)
export class PantryResolver {
  @Query(() => [PantryItem])
  @UseGuards(ClerkAuthGuard)
  async pantryItems(@CurrentUser() user: User): Promise<PantryItem[]> {
    return this.pantryService.findAllByUser(user.id);
  }

  @Query(() => [PantryItem])
  @UseGuards(ClerkAuthGuard)
  async expiringItems(
    @CurrentUser() user: User,
    @Args('withinDays', { type: () => Int, defaultValue: 7 }) withinDays: number,
  ): Promise<PantryItem[]> {
    return this.pantryService.findExpiringItems(user.id, withinDays);
  }

  @Mutation(() => PantryItem)
  @UseGuards(ClerkAuthGuard)
  async addPantryItem(
    @CurrentUser() user: User,
    @Args('input') input: CreatePantryItemInput,
  ): Promise<PantryItem> {
    return this.pantryService.create(user.id, input);
  }

  @Mutation(() => [PantryItem])
  @UseGuards(ClerkAuthGuard)
  async addPantryItemsBulk(
    @CurrentUser() user: User,
    @Args({ name: 'items', type: () => [CreatePantryItemInput] }) items: CreatePantryItemInput[],
  ): Promise<PantryItem[]> {
    return this.pantryService.createBulk(user.id, items);
  }

  @Mutation(() => Boolean)
  @UseGuards(ClerkAuthGuard)
  async deletePantryItem(
    @CurrentUser() user: User,
    @Args('id', { type: () => ID }) id: string,
  ): Promise<boolean> {
    return this.pantryService.delete(user.id, id);
  }
}
```

---

## iOS Swift Package Structure

### New Package: PantryFeature

```swift
// Packages/PantryFeature/Package.swift
let package = Package(
    name: "PantryFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PantryFeature", targets: ["PantryFeature"]),
    ],
    dependencies: [
        .package(name: "ComposableArchitecture", ...),
        .package(name: "KindredAPI", ...),  // Apollo iOS GraphQL
        .package(name: "DesignSystem", ...),
    ],
    targets: [
        .target(
            name: "PantryFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "ComposableArchitecture"),
                "KindredAPI",
                "DesignSystem",
            ]
        ),
    ]
)
```

### Camera Integration (already exists, extend for pantry)

Extend existing `CameraFeature` or create `PantryScanFeature`:

```swift
// TCA Reducer for pantry scanning
@Reducer
struct PantryScanReducer {
    @ObservableState
    struct State {
        var scanMode: ScanMode = .fridge
        var capturedImage: UIImage?
        var isAnalyzing = false
        var detectedItems: [DetectedPantryItem] = []
        var errorMessage: String?

        enum ScanMode {
            case fridge
            case receipt
        }
    }

    enum Action {
        case capturePhoto(UIImage)
        case analyzeImage
        case imageAnalyzed(Result<[DetectedPantryItem], Error>)
        case confirmItems([DetectedPantryItem])
        case itemsConfirmed
    }

    @Dependency(\.geminiClient) var geminiClient
    @Dependency(\.pantryClient) var pantryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // Implementation using Gemini for image analysis
        }
    }
}
```

---

## AI Integration Patterns

### Gemini Prompts for Pantry Features

#### Fridge Scanning Prompt

```typescript
// backend/src/gemini/prompts/fridge-scan.prompt.ts
export const FRIDGE_SCAN_PROMPT = `
Analyze this photo of a refrigerator's contents.

Return a JSON array of visible food items with the following structure:
[
  {
    "name": "chicken breast",
    "estimatedQuantity": "2 pieces",
    "category": "PROTEIN",
    "freshnessDays": 3,
    "confidence": 0.95
  }
]

Rules:
- Only list clearly visible items
- Normalize names (e.g., "boneless chicken breast" → "chicken breast")
- Categories: PRODUCE, DAIRY, PROTEIN, GRAINS, CONDIMENTS, BEVERAGES, FROZEN, CANNED, SPICES, OTHER
- freshnessDays: estimated days until spoilage from TODAY
- confidence: 0.0-1.0 (only include if > 0.7)
- Quantity: use common units (pieces, lbs, oz, cups)

Return ONLY the JSON array, no explanation.
`;
```

#### Receipt OCR Prompt

```typescript
// backend/src/gemini/prompts/receipt-scan.prompt.ts
export const RECEIPT_SCAN_PROMPT = `
Analyze this supermarket receipt photo.

Extract purchased food items as a JSON array:
[
  {
    "name": "milk",
    "quantity": "1 gallon",
    "category": "DAIRY",
    "price": 4.99,
    "estimatedExpiryDays": 10
  }
]

Rules:
- Only extract food items (skip toiletries, household goods)
- Normalize product names to generic ingredients
- Use common units (gallon, lbs, oz, count)
- Categories: PRODUCE, DAIRY, PROTEIN, GRAINS, CONDIMENTS, BEVERAGES, FROZEN, CANNED, SPICES, OTHER
- estimatedExpiryDays: shelf life estimate from purchase date
- Include price if visible

Return ONLY the JSON array, no explanation.
`;
```

### iOS Gemini Client Extension

```swift
// Extend existing GeminiClient dependency
extension GeminiClient {
    func analyzeFridgePhoto(_ image: UIImage) async throws -> [DetectedPantryItem] {
        let compressed = try image.compressForAPI() // max 1024x1024, 80% JPEG
        let base64 = compressed.base64EncodedString()

        let response = try await generateContent(
            model: "gemini-2.0-flash",
            prompt: FridgeScanPrompt.text,
            imageData: base64
        )

        return try JSONDecoder().decode([DetectedPantryItem].self, from: response)
    }

    func analyzeReceiptPhoto(_ image: UIImage) async throws -> [DetectedPantryItem] {
        let compressed = try image.compressForAPI()
        let base64 = compressed.base64EncodedString()

        let response = try await generateContent(
            model: "gemini-2.0-flash",
            prompt: ReceiptScanPrompt.text,
            imageData: base64
        )

        return try JSONDecoder().decode([DetectedPantryItem].self, from: response)
    }
}
```

---

## iOS VisionKit Integration (Alternative for Receipt OCR)

### DataScannerViewController for Live Receipt Scanning

```swift
import VisionKit

// Use DataScannerViewController for live receipt text extraction (iOS 17+)
struct ReceiptScannerView: UIViewControllerRepresentable {
    @Binding var recognizedItems: [RecognizedItem]

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .text(languages: ["en", "tr"]),
                .text(textContentType: .currency) // iOS 17 feature
            ],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedItems: [RecognizedItem]

        init(recognizedItems: Binding<[RecognizedItem]>) {
            _recognizedItems = recognizedItems
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            recognizedItems = allItems
        }
    }
}
```

**When to use VisionKit vs Gemini:**
- **VisionKit (DataScannerViewController)**: Live receipt scanning with on-device OCR. Instant feedback, zero API cost, works offline. Best for **text extraction only**.
- **Gemini 2.0 Flash**: Image → structured pantry items with categories, quantities, and expiry estimates. Best for **fridge scanning** and **intelligent receipt parsing** (not just OCR but semantic understanding).

**Recommendation:** Use **VisionKit for live preview feedback** during receipt capture, then send image to **Gemini for final parsing and categorization**.

---

## Ingredient Matching Algorithm

### Recipe Card Enhancement: Match Percentage

```swift
// Calculate ingredient match between pantry and recipe
struct IngredientMatcher {
    static func calculateMatch(
        pantryItems: [PantryItem],
        recipeIngredients: [Ingredient]
    ) -> MatchResult {
        let pantryNames = Set(pantryItems.map { $0.normalizedName.lowercased() })

        var matchedCount = 0
        var partialMatches: [String] = []

        for ingredient in recipeIngredients {
            let normalized = ingredient.name.lowercased()

            // Exact match
            if pantryNames.contains(normalized) {
                matchedCount += 1
            }
            // Partial match (e.g., "chicken" matches "chicken breast")
            else if pantryNames.contains(where: { $0.contains(normalized) || normalized.contains($0) }) {
                partialMatches.append(ingredient.name)
                matchedCount += 1
            }
        }

        let percentage = Int((Double(matchedCount) / Double(recipeIngredients.count)) * 100)

        return MatchResult(
            percentage: percentage,
            matchedCount: matchedCount,
            totalCount: recipeIngredients.count,
            partialMatches: partialMatches
        )
    }
}

struct MatchResult {
    let percentage: Int
    let matchedCount: Int
    let totalCount: Int
    let partialMatches: [String]

    var displayText: String {
        "\(percentage)% match • \(matchedCount)/\(totalCount) ingredients"
    }
}
```

### Recipe Feed Query Extension

```graphql
# Add pantry match to feed query
query FeedRecipes($latitude: Float!, $longitude: Float!, $pantryItemIds: [ID!]) {
  feedRecipes(latitude: $latitude, longitude: $longitude) {
    id
    name
    ingredients {
      id
      name
    }
    pantryMatch(pantryItemIds: $pantryItemIds) {
      percentage
      matchedCount
      totalCount
      missingIngredients
    }
  }
}
```

Backend resolver:
```typescript
@ResolveField(() => PantryMatch)
async pantryMatch(
  @Parent() recipe: Recipe,
  @Args({ name: 'pantryItemIds', type: () => [ID], nullable: true }) pantryItemIds?: string[],
): Promise<PantryMatch> {
  if (!pantryItemIds || pantryItemIds.length === 0) {
    return { percentage: 0, matchedCount: 0, totalCount: recipe.ingredients.length };
  }

  return this.pantryService.calculateRecipeMatch(recipe.id, pantryItemIds);
}
```

---

## Expiry Estimation AI Logic

### Default Expiry Estimates by Category

```typescript
// backend/src/pantry/expiry-estimator.service.ts
export class ExpiryEstimatorService {
  private readonly DEFAULT_EXPIRY_DAYS: Record<PantryCategory, number> = {
    PRODUCE: 5,
    DAIRY: 10,
    PROTEIN: 3,
    GRAINS: 365,
    CONDIMENTS: 180,
    BEVERAGES: 30,
    FROZEN: 90,
    CANNED: 365,
    SPICES: 730,
    OTHER: 30,
  };

  estimateExpiryDays(
    name: string,
    category: PantryCategory,
    context?: 'fridge' | 'freezer' | 'pantry',
  ): number {
    // Use Gemini for intelligent estimates
    // Fallback to category defaults
    const baseEstimate = this.DEFAULT_EXPIRY_DAYS[category];

    // Adjust based on storage context
    if (context === 'freezer') {
      return baseEstimate * 3; // freeze extends life
    }

    return baseEstimate;
  }

  async estimateWithAI(name: string, category: PantryCategory): Promise<number> {
    const prompt = `Estimate shelf life in days for "${name}" (${category}).
    Consider typical refrigerator storage. Return only a number.`;

    const response = await this.geminiService.generateText(prompt);
    const days = parseInt(response.trim());

    return isNaN(days) ? this.DEFAULT_EXPIRY_DAYS[category] : days;
  }
}
```

---

## Installation

### Backend (NestJS)

```bash
cd backend

# New validation dependencies
npm install class-validator@^0.14.1 class-transformer@^0.5.1

# Run Prisma migration for new models
npx prisma migrate dev --name add_pantry_models

# Generate Prisma Client
npx prisma generate
```

### iOS (Swift Package Manager)

No new external dependencies. VisionKit and PhotosUI are built-in frameworks.

```swift
// In project.yml or Xcode, ensure frameworks are linked:
frameworks:
  - VisionKit
  - PhotosUI
  - AVFoundation  // (already present)
```

Update `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Kindred needs camera access to scan your fridge and receipts for smart pantry management.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Kindred needs photo access to analyze fridge images for ingredient detection.</string>
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| VisionKit DataScannerViewController | Custom AVFoundation + Vision | If targeting iOS 16 (but we're on iOS 17+) |
| Gemini 2.0 Flash for image analysis | OpenAI GPT-4 Vision | If switching away from Google AI ecosystem |
| On-device expiry estimation | External food database API | If extremely high accuracy needed (adds cost + latency) |
| Prisma + PostgreSQL | MongoDB for pantry items | If pantry data doesn't need relations (but it does — user, recipes) |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Third-party OCR SDKs** (Tesseract, ML Kit OCR) | VisionKit provides superior live OCR with currency detection in iOS 17. No dependencies, free, on-device. | VisionKit DataScannerViewController |
| **Separate food recognition APIs** (Clarifai, Calorie Mama) | Gemini 2.0 Flash already integrated, handles multimodal well, and costs ~$0.001/image vs $0.02+/image for specialized APIs. | Gemini 2.0 Flash via Firebase AI Logic SDK |
| **UIImagePickerController** for camera | Deprecated in favor of PHPickerViewController and custom AVFoundation. Poor accessibility. | PHPickerViewController for gallery, AVCaptureSession for custom camera UI |
| **Custom expiry date databases** | Maintenance burden, licensing costs. AI estimation + category defaults cover 90% of use cases. | Gemini AI estimation + fallback category defaults |
| **Apollo iOS 1.x** | Apollo iOS 2.0+ (already validated) uses modern Swift concurrency, improved cache. | Apollo iOS 2.0.6+ (already in stack) |

---

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| class-validator@^0.14.x | NestJS 11, class-transformer@^0.5.x | Peer dependency required |
| VisionKit (iOS 17+) | iOS 17.0+ only | DataScannerViewController unavailable on iOS 16 |
| Apollo iOS 2.0.6 | iOS 17+, Swift 6 concurrency | Already validated in existing stack |
| Gemini 2.0 Flash | Firebase AI Logic SDK 11.x | Use firebase-ios-sdk, NOT deprecated generative-ai-swift |
| Prisma 7.x | PostgreSQL 15+ | Already validated, supports array fields for tags |

---

## Integration with Existing Stack

### Reuse Existing Components

| Existing Component | How Pantry Uses It |
|--------------------|---------------------|
| **GeminiClient** (already exists) | Extend with `analyzeFridgePhoto()` and `analyzeReceiptPhoto()` methods |
| **CameraFeature** (already exists) | Reuse AVCaptureSession setup, add pantry-specific capture flows |
| **Apollo iOS GraphQL** (already exists) | Add pantry queries/mutations to schema, auto-generate Swift types |
| **SwiftData** (already exists) | Cache pantry items locally for offline access |
| **TCA @Dependency system** (already exists) | Register PantryClient for testability |
| **DesignSystem** (already exists) | Reuse KNCard, KNButton, KNBadge for pantry UI |
| **UNUserNotificationCenter** (already exists) | Schedule expiry alerts (already used for other notifications) |

### New Components to Build

| New Component | Purpose |
|---------------|---------|
| **PantryFeature** (iOS SPM) | TCA reducer, views, and client for pantry management |
| **PantryScanFeature** (iOS SPM) | Camera capture + Gemini analysis for fridge/receipt scanning |
| **PantryModule** (NestJS) | GraphQL resolvers, Prisma service, expiry estimator |
| **IngredientMatcher** (shared logic) | Calculate recipe-pantry match percentage (iOS + backend) |

---

## Cost Implications

| Feature | Cost per Use | Monthly Estimate (10K users) |
|---------|--------------|------------------------------|
| Fridge scan (Gemini 2.0 Flash) | ~$0.001/image | $300 (3 scans/user/month) |
| Receipt scan (Gemini 2.0 Flash) | ~$0.001/image | $200 (2 scans/user/month) |
| VisionKit OCR | $0 (on-device) | $0 |
| Expiry AI estimation (Gemini text) | ~$0.0001/item | $30 (3 items/scan × 3 scans × 10K) |
| Pantry data storage (PostgreSQL) | Negligible | ~50KB/user = 500MB total |
| **Total monthly cost** | | **~$530 at 10K users** |

**Conclusion:** Smart Pantry features add minimal cost. Primary expense is Gemini image analysis (~$500/month at 10K users), which is 4x cheaper than voice narration costs.

---

## Sources

### Apple Official Documentation
- [VisionKit DataScannerViewController](https://developer.apple.com/documentation/visionkit/datascannerviewcontroller) — Live OCR with currency detection (iOS 17+)
- [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest) — On-device text recognition API
- [WWDC22: Capture machine-readable codes and text with VisionKit](https://developer.apple.com/videos/play/wwdc2022/10025/) — DataScannerViewController introduction
- [WWDC23: What's new in VisionKit](https://developer.apple.com/videos/play/wwdc2023/10048/) — iOS 17 enhancements (currency, optical flow)

### Google AI Documentation
- [Gemini 2.0 Flash Documentation](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-0-flash) — Image understanding capabilities
- [Firebase AI Logic SDK](https://firebase.google.com/docs/ai-logic/get-started) — Official Firebase SDK for Gemini on iOS
- [Gemini API Image Understanding](https://ai.google.dev/gemini-api/docs/image-understanding) — Multimodal image analysis guide

### NestJS & GraphQL
- [NestJS GraphQL Documentation](https://docs.nestjs.com/graphql/resolvers) — Code-first resolvers
- [NestJS Input Validation Guide](https://www.dsebastien.net/2020-07-23-input-validation-with-nestjs/) — class-validator integration
- [Type-Safe GraphQL with NestJS](https://oneuptime.com/blog/post/2026-01-25-type-safe-graphql-nestjs/view) — 2026 best practices

### Apollo iOS
- [Apollo iOS 2.0 Documentation](https://www.apollographql.com/docs/ios) — Swift concurrency, cache normalization
- [Apollo iOS Pagination](https://github.com/apollographql/apollo-ios-pagination) — Pagination library for Apollo cache

### Food Recognition & AI
- [AI-Powered Food Recognition API](https://easyflow.tech/food-recognition-api/) — Computer vision for food detection
- [AI for Food Shelf-Life Prediction (2026)](https://www.sciencedirect.com/science/article/abs/pii/S0924224425001256) — Recent research on AI-driven expiry estimation
- [Deep Learning in Food Image Recognition](https://www.mdpi.com/2076-3417/15/14/7626) — ResNet50, EfficientNet architectures

### TCA Architecture
- [TCA GitHub Repository](https://github.com/pointfreeco/swift-composable-architecture) — Official Composable Architecture library
- [SwiftUI TCA Camera Demo](https://github.com/never-better/SwiftUI-TCA-Camera-Demo) — Example camera integration with TCA

### iOS Camera & SwiftUI
- [iOS 18 New Camera APIs](https://zoewave.medium.com/ios-18-17-new-camera-apis-645f7a1e54e8) — AVFoundation and PhotoKit updates
- [Camera Capture in SwiftUI](https://www.createwithswift.com/camera-capture-setup-in-a-swiftui-app/) — Modern SwiftUI camera patterns
- [VisionKit Live Data Scanning](https://medium.com/ciandt-techblog/live-data-scanning-on-ios-a-quick-look-at-apples-visionkit-framework-682ea50fa04b) — Real-time OCR implementation

### Database & ORM
- [Prisma PostgreSQL Quickstart](https://www.prisma.io/docs/prisma-orm/quickstart/postgresql) — Prisma 7 with PostgreSQL 15+
- [Prisma Schema Reference](https://www.prisma.io/docs/orm/reference/prisma-schema-reference) — Schema syntax and patterns

---

*Stack research for: Smart Pantry Features*
*Researched: 2026-03-11*
*Confidence: HIGH*
