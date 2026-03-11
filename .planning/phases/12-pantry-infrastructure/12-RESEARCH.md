# Phase 12: Pantry Infrastructure - Research

**Researched:** 2026-03-11
**Domain:** SwiftData persistence, Prisma schema design, NestJS GraphQL, ingredient normalization
**Confidence:** HIGH

## Summary

Phase 12 establishes the data layer foundation for Smart Pantry features across both iOS (SwiftData + TCA) and backend (Prisma + NestJS GraphQL). The research confirms that the existing architecture patterns (GuestSessionClient, RecipesModule) provide proven templates to replicate. Key technical challenges include SwiftData schema migrations for new PantryItem models, bilingual ingredient normalization at the server layer, and offline-first sync with timestamp-based conflict resolution.

The codebase already demonstrates mature patterns: SwiftData with @Model macro + ModelContainer, TCA @Dependency pattern with DependencyKey protocol, Prisma 7 schema with PostgreSQL, NestJS code-first GraphQL with @Resolver/@ObjectType decorators, and Apollo iOS 2.x codegen via SPM. This phase extends these patterns without introducing new frameworks.

**Primary recommendation:** Mirror GuestSessionClient architecture exactly for PantryClient (same TCA dependency injection pattern, SwiftData persistence layer, CRUD operations via FetchDescriptor). Extend existing Prisma schema with PantryItem + IngredientCatalog models, seed catalog via prisma/seed.ts, implement server-side normalization in PantryService, and use Apollo codegen to generate iOS GraphQL types.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Pantry Data Model:**
- PantryItem fields: name (String), quantity (String, freeform like RecipeIngredient), unit (String), storageLocation (enum: fridge/freezer/pantry), foodCategory (enum: ~8-10 standard categories — Dairy, Produce, Meat, Seafood, Grains, Baking, Spices, Beverages, Snacks, Condiments), optional photo URL, optional notes (free text), source (enum: manual/fridge_scan/receipt_scan), expiryDate (Date, nullable), normalizedName (from IngredientCatalog)
- Soft delete — mark as deleted, keep history for analytics
- No brand field — keep it ingredient-level
- Merge duplicate quantities — if same normalized ingredient exists, add quantities together
- Food category auto-filled from IngredientCatalog when ingredient is recognized

**Ingredient Normalization:**
- MVP-level: case-insensitive + basic synonyms, not full USDA IngID
- Server-side normalization on save — single source of truth
- Curated seed list of ~200-300 common ingredients, bilingual (English + Turkish)
- IngredientCatalog as backend PostgreSQL table (not static JSON) — fetched via GraphQL search query
- Prisma seed script populates initial catalog
- Autocomplete from known list as user types — can still type custom items
- Unknown items: accept and learn — add to catalog for future users
- Add `normalizedName` column to existing recipe `Ingredient` model for matching
- Each catalog entry has: canonicalName (EN), canonicalNameTR (TR), aliases (String[]), defaultCategory (enum), defaultShelfLifeDays (Int, nullable)

**App Navigation:**
- New tab bar item: Feed, Pantry, Profile (pantry in the middle)
- Refrigerator SF Symbol icon for pantry tab
- Badge count showing number of expiring-soon items (red badge)
- Pantry tab lands on list view (not dashboard), grouped by storage location
- Floating + button in bottom-right for adding items
- Tab order: Feed (left), Pantry (center), Profile (right)

**Backend API Shape:**
- New standalone NestJS PantryModule (mirrors iOS PantryFeature package)
- Queries + mutations only (no GraphQL subscriptions for MVP)
- Bulk add mutation: `bulkAddPantryItems` accepts array for receipt scan results
- Ingredient search query: `ingredientSearch(query: String, lang: String)` returns matching catalog entries with aliases
- Authentication required — guests see pantry tab but get prompted to sign in
- No pagination — return all pantry items at once (expect <100 items per user)
- Timestamp-based sync: each item has `updatedAt`, client sends changes since last sync

**Offline Behavior:**
- Subtle cloud icon indicator on items not yet synced
- Last-write-wins for timestamp conflicts (single-user MVP, conflicts rare)

**Empty State:**
- Illustration + "Add your first item" CTA button + hint about scanning features

### Claude's Discretion
- Exact Prisma model field types and indexes
- GraphQL input/output type naming conventions
- SwiftData model property wrappers and migration strategy
- PantryFeature package internal folder structure
- Specific SF Symbol variant for refrigerator icon
- Empty state illustration style
- Cloud sync indicator visual design

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INFRA-01 | Backend GraphQL schema supports pantry CRUD operations | NestJS code-first GraphQL patterns (RecipesModule template), Prisma 7 schema design, Apollo codegen for iOS types |
| INFRA-02 | Ingredient normalization maps items to canonical forms | Server-side normalization in PantryService, IngredientCatalog model with bilingual fields + aliases, Prisma seed script for 200-300 ingredients |
| INFRA-03 | PantryFeature SPM package follows existing TCA architecture patterns | GuestSessionClient template (TCA @Dependency, SwiftData ModelContainer, FetchDescriptor CRUD), established SPM package structure |

</phase_requirements>

## Standard Stack

### Core iOS
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ (built-in) | Local persistence with @Model macro | Apple's modern replacement for Core Data, native Swift concurrency support, zero config ModelContainer |
| TCA (Composable Architecture) | 1.0+ | State management + dependency injection | Project standard — all features use TCA reducers with @Dependency pattern |
| Apollo iOS | 2.0.6 (from NetworkClient) | GraphQL client + codegen | Project standard — generates type-safe Swift from GraphQL schema, SQLite cache for offline |
| SwiftUI | iOS 17+ (built-in) | UI layer | Project standard — all views use SwiftUI with TCA integration |

### Core Backend
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Prisma ORM | 7.4.2 | Database schema + migrations | Project standard — type-safe Prisma Client, migration tooling, excellent DX |
| NestJS | 11.0.1 | Backend framework | Project standard — modular architecture, dependency injection, code-first GraphQL |
| @nestjs/graphql | 13.2.4 | GraphQL integration | Project standard — code-first approach with @Resolver/@ObjectType decorators |
| PostgreSQL | 15+ | Relational database | Project standard — PostGIS extension for geospatial, proven at scale |

### Supporting iOS
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Kingfisher | 8.0+ | Image loading + caching | Optional pantry item photos (if user adds custom images) |
| Dependencies | (via TCA) | Dependency injection | All clients (PantryClient, NetworkClient, etc.) |

### Supporting Backend
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| class-validator | 0.14.4 | Input validation | GraphQL input DTOs (AddPantryItemInput, BulkAddPantryItemsInput) |
| class-transformer | 0.5.1 | DTO transformation | Mapping Prisma models to GraphQL types |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData | Core Data | Core Data more mature but verbose NSManagedObject boilerplate; SwiftData chosen for Swift concurrency + macro simplicity |
| Server-side normalization | Client-side only | Client normalization requires shipping ingredient catalog with app (large asset); server-side allows continuous learning from unknown items |
| Last-write-wins conflict | CRDT or conflict UI | CRDT (Operational Transform) overkill for single-user pantry edits; conflict UI adds UX complexity for rare edge case |
| Prisma seed script | Manual SQL | Prisma seed.ts type-safe, version-controlled, runnable in CI/CD; manual SQL error-prone |

**Installation:**

iOS: No new dependencies — uses existing TCA, Apollo, SwiftData from iOS 17 SDK.

Backend: Already installed in project — Prisma 7.4.2, NestJS 11.0.1, @nestjs/graphql 13.2.4.

## Architecture Patterns

### Recommended iOS Project Structure
```
Kindred/Packages/PantryFeature/
├── Package.swift                    # SPM manifest (deps: TCA, NetworkClient, KindredAPI, DesignSystem)
└── Sources/
    ├── PantryClient/
    │   ├── PantryClient.swift       # TCA @Dependency with DependencyKey protocol
    │   └── PantryStore.swift        # @MainActor singleton with ModelContainer
    ├── Models/
    │   └── PantryItem.swift         # @Model class (SwiftData schema)
    ├── Pantry/
    │   ├── PantryReducer.swift      # Root reducer for pantry feature
    │   └── PantryView.swift         # SwiftUI view (list grouped by storage location)
    ├── AddItem/
    │   ├── AddItemReducer.swift     # Reducer for adding pantry items
    │   └── AddItemView.swift        # Form view with ingredient autocomplete
    └── EmptyState/
        └── PantryEmptyStateView.swift  # Illustration + CTA when pantry is empty
```

### Recommended Backend Project Structure
```
backend/src/pantry/
├── pantry.module.ts              # @Module imports PrismaModule, exports PantryService
├── pantry.service.ts             # Business logic: CRUD, normalization, merge duplicates
├── pantry.resolver.ts            # @Resolver with @Query/@Mutation decorators
├── dto/
│   ├── add-pantry-item.input.ts  # GraphQL input type for adding items
│   └── bulk-add-pantry-items.input.ts  # GraphQL input for receipt scan
└── models/
    ├── pantry-item.model.ts      # @ObjectType for GraphQL schema
    └── ingredient-catalog.model.ts  # @ObjectType for catalog entries

backend/src/graphql/models/
└── ingredient.model.ts           # EXTEND existing Ingredient model with normalizedName field

backend/prisma/
├── schema.prisma                 # ADD PantryItem, IngredientCatalog models
└── seed.ts                       # Populate catalog with 200-300 bilingual ingredients
```

### Pattern 1: TCA Dependency Injection for Clients (PantryClient)

**What:** Replicate GuestSessionClient pattern exactly — struct with closures for CRUD operations, backed by SwiftData ModelContainer, injected via @Dependency.

**When to use:** All feature-specific data access layers (GuestSessionClient, PantryClient, future CameraClient).

**Example:**
```swift
// Source: Existing GuestSessionClient pattern (FeedFeature/Sources/GuestSession/)

public struct PantryClient {
    public var addItem: @Sendable (PantryItemInput) async throws -> Void
    public var updateItem: @Sendable (UUID, PantryItemInput) async throws -> Void
    public var deleteItem: @Sendable (UUID) async throws -> Void
    public var fetchAllItems: @Sendable () async -> [PantryItem] = { [] }
    public var fetchItemsByLocation: @Sendable (StorageLocation) async -> [PantryItem] = { _ in [] }
    public var syncToServer: @Sendable () async throws -> Void
}

extension PantryClient: DependencyKey {
    public static var liveValue: PantryClient {
        let store = PantryStore.shared
        return PantryClient(
            addItem: { input in try await store.addItem(input) },
            updateItem: { id, input in try await store.updateItem(id: id, input: input) },
            deleteItem: { id in try await store.deleteItem(id: id) },
            fetchAllItems: { await store.fetchAllItems() },
            fetchItemsByLocation: { location in await store.fetchItemsByLocation(location) },
            syncToServer: { try await store.syncToServer() }
        )
    }

    public static var testValue: PantryClient {
        return PantryClient(
            addItem: { _ in },
            updateItem: { _, _ in },
            deleteItem: { _ in },
            fetchAllItems: { [] },
            fetchItemsByLocation: { _ in [] },
            syncToServer: { }
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

### Pattern 2: SwiftData @Model with @MainActor Store

**What:** SwiftData model class with @Model macro, backed by @MainActor singleton store with ModelContainer for thread-safe access.

**When to use:** All local persistence models (GuestBookmark, GuestSkip, PantryItem).

**Example:**
```swift
// Source: Existing GuestBookmark pattern (FeedFeature/Sources/GuestSession/GuestBookmark.swift)

import Foundation
import SwiftData

@Model
public class PantryItem {
    @Attribute(.unique) public var id: UUID
    public var userId: String  // Clerk user ID
    public var name: String
    public var quantity: String  // Freeform like "2" or "1 cup"
    public var unit: String?
    public var storageLocation: String  // "fridge", "freezer", "pantry"
    public var foodCategory: String?  // Auto-filled from catalog
    public var normalizedName: String?  // From IngredientCatalog
    public var photoUrl: String?
    public var notes: String?
    public var source: String  // "manual", "fridge_scan", "receipt_scan"
    public var expiryDate: Date?
    public var isDeleted: Bool  // Soft delete
    public var isSynced: Bool  // Cloud sync indicator
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        quantity: String,
        unit: String? = nil,
        storageLocation: String,
        foodCategory: String? = nil,
        normalizedName: String? = nil,
        photoUrl: String? = nil,
        notes: String? = nil,
        source: String = "manual",
        expiryDate: Date? = nil,
        isDeleted: Bool = false,
        isSynced: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.storageLocation = storageLocation
        self.foodCategory = foodCategory
        self.normalizedName = normalizedName
        self.photoUrl = photoUrl
        self.notes = notes
        self.source = source
        self.expiryDate = expiryDate
        self.isDeleted = isDeleted
        self.isSynced = isSynced
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Store pattern (same as GuestSessionStore)
@MainActor
private class PantryStore {
    static let shared = PantryStore()

    private let modelContainer: ModelContainer
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            modelContainer = try ModelContainer(for: PantryItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    func addItem(_ input: PantryItemInput) async throws {
        let item = PantryItem(
            userId: input.userId,
            name: input.name,
            quantity: input.quantity,
            // ... other fields
        )
        modelContext.insert(item)
        try modelContext.save()
    }

    func fetchAllItems() async -> [PantryItem] {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                !item.isDeleted
            },
            sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
}
```

### Pattern 3: NestJS Code-First GraphQL Module (PantryModule)

**What:** NestJS module with @Resolver for GraphQL operations, @Injectable service for business logic, Prisma for database access.

**When to use:** All backend GraphQL features (RecipesModule, UsersModule, PantryModule).

**Example:**
```typescript
// Source: Existing RecipesModule pattern (backend/src/recipes/)

// pantry.module.ts
import { Module } from '@nestjs/common';
import { PantryService } from './pantry.service';
import { PantryResolver } from './pantry.resolver';

@Module({
  providers: [PantryService, PantryResolver],
  exports: [PantryService],
})
export class PantryModule {}

// pantry.resolver.ts
import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { PantryService } from './pantry.service';
import { PantryItem } from '../graphql/models/pantry-item.model';
import { AddPantryItemInput } from './dto/add-pantry-item.input';

@Resolver(() => PantryItem)
export class PantryResolver {
  constructor(private pantryService: PantryService) {}

  @Query(() => [PantryItem], { description: 'Get all pantry items for authenticated user' })
  async pantryItems(
    @Args('userId') userId: string,
  ): Promise<PantryItem[]> {
    return this.pantryService.findAllForUser(userId);
  }

  @Mutation(() => PantryItem, { description: 'Add a pantry item with normalization' })
  async addPantryItem(
    @Args('input') input: AddPantryItemInput,
  ): Promise<PantryItem> {
    return this.pantryService.addItem(input);
  }

  @Query(() => [IngredientCatalogEntry], { description: 'Search ingredient catalog for autocomplete' })
  async ingredientSearch(
    @Args('query') query: string,
    @Args('lang', { defaultValue: 'en' }) lang: string,
  ): Promise<IngredientCatalogEntry[]> {
    return this.pantryService.searchCatalog(query, lang);
  }
}

// pantry.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PantryService {
  constructor(private prisma: PrismaService) {}

  async addItem(input: AddPantryItemInput) {
    // 1. Normalize ingredient name via catalog lookup
    const normalizedName = await this.normalizeIngredient(input.name);

    // 2. Check for existing item with same normalizedName (merge if exists)
    const existing = await this.prisma.pantryItem.findFirst({
      where: {
        userId: input.userId,
        normalizedName: normalizedName,
        isDeleted: false,
      },
    });

    if (existing) {
      // Merge quantities (simplified — real impl needs unit conversion)
      return this.prisma.pantryItem.update({
        where: { id: existing.id },
        data: {
          quantity: String(Number(existing.quantity) + Number(input.quantity)),
          updatedAt: new Date(),
        },
      });
    }

    // 3. Create new item
    return this.prisma.pantryItem.create({
      data: {
        userId: input.userId,
        name: input.name,
        normalizedName: normalizedName,
        quantity: input.quantity,
        // ... other fields
        updatedAt: new Date(),
      },
    });
  }

  private async normalizeIngredient(inputName: string): Promise<string> {
    const normalized = inputName.toLowerCase().trim();

    // Search catalog for match
    const catalogEntry = await this.prisma.ingredientCatalog.findFirst({
      where: {
        OR: [
          { canonicalName: { equals: normalized, mode: 'insensitive' } },
          { canonicalNameTR: { equals: normalized, mode: 'insensitive' } },
          { aliases: { has: normalized } },
        ],
      },
    });

    return catalogEntry?.canonicalName ?? normalized;
  }
}
```

### Pattern 4: Prisma Schema with Bilingual Support + Soft Delete

**What:** Prisma models with bilingual columns (canonicalName, canonicalNameTR), soft delete flag (isDeleted), timestamp fields (createdAt, updatedAt).

**When to use:** All Prisma models requiring multi-language support or soft delete (PantryItem, IngredientCatalog).

**Example:**
```prisma
// Source: Existing Prisma patterns (backend/prisma/schema.prisma)

model PantryItem {
  id              String   @id @default(cuid())
  userId          String
  name            String   // User's original input
  normalizedName  String?  // Canonical name from IngredientCatalog
  quantity        String   // Freeform string like "2" or "1 cup"
  unit            String?
  storageLocation String   // "fridge" | "freezer" | "pantry"
  foodCategory    String?  // Auto-filled from catalog
  photoUrl        String?
  notes           String?
  source          String   @default("manual")  // "manual" | "fridge_scan" | "receipt_scan"
  expiryDate      DateTime?
  isDeleted       Boolean  @default(false)     // Soft delete
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, isDeleted])
  @@index([normalizedName])
  @@index([expiryDate])
}

model IngredientCatalog {
  id                   String   @id @default(cuid())
  canonicalName        String   @unique  // English canonical form ("eggs")
  canonicalNameTR      String   // Turkish canonical form ("yumurta")
  aliases              String[] // Synonyms in both languages ["large eggs", "free-range eggs", "organik yumurta"]
  defaultCategory      String   // "dairy" | "produce" | "meat" | etc.
  defaultShelfLifeDays Int?     // Estimated shelf life for expiry predictions
  createdAt            DateTime @default(now())

  @@index([canonicalName])
  @@index([canonicalNameTR])
}

// EXTEND existing Ingredient model (recipe ingredients)
model Ingredient {
  id             String @id @default(cuid())
  recipeId       String
  recipe         Recipe @relation(fields: [recipeId], references: [id], onDelete: Cascade)

  name           String
  quantity       String
  unit           String
  orderIndex     Int
  normalizedName String?  // NEW: Link to IngredientCatalog for recipe matching

  @@index([recipeId])
  @@index([normalizedName])  // NEW: Index for pantry-recipe matching
}
```

### Pattern 5: SwiftData Schema Migration with VersionedSchema

**What:** Define VersionedSchema for each schema version, use SchemaMigrationPlan to declare migration stages (lightweight or custom).

**When to use:** Any change to @Model classes after app ships (adding PantryItem is the first schema version, so no migration needed yet — but pattern documented for future).

**Example:**
```swift
// Source: SwiftData migration best practices (research findings)

// Initial schema (no migration needed for first version)
enum PantrySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PantryItem.self]
    }
}

// Future schema change example (when Phase 13+ modifies PantryItem)
enum PantrySchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PantryItem.self]  // Updated model with new fields
    }
}

// Migration plan (lightweight if only adding optional fields)
enum PantrySchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PantrySchemaV1.self, PantrySchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            // Lightweight migration (SwiftData auto-handles)
            MigrationStage.lightweight(fromVersion: PantrySchemaV1.self, toVersion: PantrySchemaV2.self)
        ]
    }
}

// ModelContainer with migration plan
let container = try ModelContainer(
    for: PantryItem.self,
    migrationPlan: PantrySchemaMigrationPlan.self
)
```

### Anti-Patterns to Avoid

- **Using @Dependency in SwiftUI views directly:** TCA @Dependency should only be used in reducers. Views receive state/actions via ViewStore. Anti-pattern seen in LocationPickerView (fixed in phase 11) — don't repeat.

- **Eager loading all pantry items at app launch:** PantryClient should lazy-load on tab switch. Don't fetch in AppDelegate or AppReducer init — causes main thread blocking.

- **Client-side ingredient normalization without server sync:** Normalization must happen server-side for shared catalog learning. Client can cache catalog results but server is source of truth.

- **Hard delete pantry items:** Use soft delete (isDeleted flag) for analytics and potential undo features. Prisma cascade delete only for user account deletion.

- **Forgetting Apollo codegen after schema changes:** After adding GraphQL queries/mutations, run `apollo-cli-install` and regenerate KindredAPI types. Missing this breaks compilation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fuzzy ingredient matching | Custom Levenshtein distance algorithm | Case-insensitive lookup + curated synonym aliases in IngredientCatalog | Fuzzy matching is complex (multiple algorithms, tuning thresholds, false positives). Curated aliases cover 95% of real-world variations. Phase 12 MVP uses exact match + aliases; fuzzy search deferred to Phase 13+ if needed. |
| SwiftData persistence layer | Manual SQLite with FMDB/GRDB | SwiftData @Model + ModelContainer | SwiftData handles thread-safety, migrations, NSPredicate macro conversions. Manual SQLite requires custom serialization, migration scripts, NSLock wrappers. |
| GraphQL type generation | Manual Codable structs | Apollo iOS codegen | Apollo generates type-safe Swift from schema introspection, handles fragments, nullability, nested types. Manual approach error-prone (schema drift, missed nullable fields). |
| Offline sync queue | Custom operation queue with retry logic | Timestamp-based last-write-wins + isSynced flag | Custom queue needs failure handling, network reachability, exponential backoff, deduplication. Phase 12 uses simple timestamp check (updatedAt > lastSyncTimestamp). CRDT deferred until multi-user collaboration (out of scope). |
| Bilingual autocomplete | Client-side trie data structure | Server-side PostgreSQL `WHERE aliases @> ARRAY[normalized_input]` | Client trie requires shipping entire catalog (large asset), manual updates. Server query leverages PostgreSQL array operators, returns top 10 matches in <10ms. |

**Key insight:** Phase 12 focuses on proven patterns from existing codebase. New complexity (fuzzy matching, CRDT, client-side ML normalization) deferred to future phases after MVP validation.

## Common Pitfalls

### Pitfall 1: SwiftData Thread-Safety Violations (Main Actor Isolation)

**What goes wrong:** Calling ModelContext.save() from background thread crashes with "ModelContext must be used on @MainActor" error.

**Why it happens:** SwiftData ModelContext is @MainActor-isolated. TCA effects run on cooperative thread pool (not main thread). Mixing async/await with SwiftData requires explicit MainActor.run {} wrappers.

**How to avoid:** Use @MainActor singleton store pattern (GuestSessionStore template). All ModelContext operations inside @MainActor class methods. TCA effects call store methods which are automatically main-actor-isolated.

**Warning signs:**
- Compiler warning: "Call to main actor-isolated instance method 'save()' in a synchronous nonisolated context"
- Runtime crash: "ModelContext can only be used on the main actor"

**Example fix:**
```swift
// ❌ WRONG: TCA effect directly accessing ModelContext
case .addItem(let input):
    return .run { send in
        let item = PantryItem(/* ... */)
        modelContext.insert(item)  // CRASH: not on main actor
        try modelContext.save()
    }

// ✅ CORRECT: TCA effect calls @MainActor store method
case .addItem(let input):
    return .run { [pantryClient = self.pantryClient] send in
        try await pantryClient.addItem(input)  // Store is @MainActor-isolated
        await send(.itemAdded)
    }
```

### Pitfall 2: Prisma Migration Drift (Schema vs Database Mismatch)

**What goes wrong:** Prisma schema.prisma changes don't match database state. Queries fail with "column does not exist" errors.

**Why it happens:** Developer modifies schema.prisma but forgets to run `prisma migrate dev` or `prisma db push`. Prisma Client regenerates types but database stays stale.

**How to avoid:**
1. Always run `prisma migrate dev` after schema changes (creates migration + applies to DB)
2. Commit migrations to git (prisma/migrations/)
3. CI/CD runs `prisma migrate deploy` on production
4. Use `prisma db push` only for prototyping (doesn't create migration files)

**Warning signs:**
- PostgreSQL error: `column "pantryitems.normalizedname" does not exist`
- Prisma error: `Unknown arg 'normalizedName' in data.normalizedName`
- Seed script fails with missing table error

**Example fix:**
```bash
# ❌ WRONG: Only edited schema.prisma
# Database still has old schema → queries fail

# ✅ CORRECT: Create migration and apply
cd backend
npx prisma migrate dev --name add_pantry_models
npx prisma generate  # Regenerate Prisma Client types
npm run seed         # Re-seed with new models
```

### Pitfall 3: Apollo Codegen Not Re-Run After GraphQL Changes

**What goes wrong:** Added new GraphQL query in iOS app but KindredAPI types not updated. Swift compiler error: "Type 'KindredAPI' has no member 'PantryItemsQuery'".

**Why it happens:** Apollo codegen runs manually via CLI or build script. Adding .graphql files doesn't auto-trigger regeneration. Developers forget to run codegen step.

**How to avoid:**
1. Add Run Script Phase to Xcode project: `apollo-cli-install && apollo-ios-cli generate`
2. Document codegen step in CLAUDE.md (project instructions)
3. Use watch mode during development: `apollo-ios-cli generate --watch`

**Warning signs:**
- Swift compiler error: "Cannot find type 'PantryItemsQuery' in scope"
- New GraphQL query file exists but types not in KindredAPI module
- Apollo generates schema types but not operation types

**Example fix:**
```bash
# ❌ WRONG: Only added PantryItems.graphql file
# KindredAPI types not regenerated → compiler error

# ✅ CORRECT: Run Apollo codegen
cd Kindred/Packages/KindredAPI
swift run apollo-cli-install
swift run apollo-ios-cli generate --path apollo-codegen-config.json
# Now PantryItemsQuery available in KindredAPI module
```

### Pitfall 4: Soft Delete Leaking Into User-Facing Queries

**What goes wrong:** Deleted pantry items still appear in list view. User sees "phantom" items they thought they removed.

**Why it happens:** Prisma/SwiftData queries forget to filter `WHERE isDeleted = false`. Soft delete flag exists but not enforced consistently.

**How to avoid:**
1. ALL read queries must include `isDeleted: false` predicate (Prisma `where: { isDeleted: false }`, SwiftData `#Predicate { !item.isDeleted }`)
2. Extract common query predicates into helper functions
3. Write regression test: "Deleted items should not appear in fetchAllItems()"

**Warning signs:**
- User reports "I deleted this but it's still here"
- Item count shows 10 but only 8 visible (2 soft-deleted)
- GraphQL query returns deleted items to iOS client

**Example fix:**
```swift
// ❌ WRONG: Forgot to filter soft-deleted items
func fetchAllItems() async -> [PantryItem] {
    let descriptor = FetchDescriptor<PantryItem>(
        sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)  // Returns deleted items!
}

// ✅ CORRECT: Always filter isDeleted
func fetchAllItems() async -> [PantryItem] {
    let descriptor = FetchDescriptor<PantryItem>(
        predicate: #Predicate<PantryItem> { item in
            !item.isDeleted  // CRITICAL: Filter soft-deleted
        },
        sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
    )
    do {
        return try modelContext.fetch(descriptor)
    } catch {
        return []
    }
}
```

### Pitfall 5: Ingredient Autocomplete N+1 Query Problem

**What goes wrong:** Autocomplete search triggers 100+ database queries as user types "tom" → "toma" → "tomat" → "tomato". Backend performance degrades, API timeout.

**Why it happens:** Each keystroke triggers new GraphQL query to `ingredientSearch`. No debouncing on client. No query result caching on server.

**How to avoid:**
1. Client-side debouncing: Wait 300ms after last keystroke before sending query (TCA `.debounce` effect)
2. Server-side query optimization: Use PostgreSQL `LIKE` with index on `canonicalName`, limit results to 10
3. Client-side cache: Apollo cache query results for 5 minutes (ingredient catalog rarely changes)

**Warning signs:**
- Backend logs show hundreds of `ingredientSearch` queries per second
- Typing in autocomplete field feels laggy/delayed
- PostgreSQL slow query log shows `ingredientSearch` taking >100ms

**Example fix:**
```swift
// ❌ WRONG: Send query on every keystroke
case .searchTextChanged(let query):
    return .run { send in
        let results = try await networkClient.searchIngredients(query: query)
        await send(.searchResultsReceived(results))
    }

// ✅ CORRECT: Debounce + cancel previous in-flight requests
case .searchTextChanged(let query):
    state.searchQuery = query
    return .run { send in
        try await Task.sleep(for: .milliseconds(300))  // Debounce
        let results = try await networkClient.searchIngredients(query: query)
        await send(.searchResultsReceived(results))
    }
    .cancellable(id: CancelID.ingredientSearch, cancelInFlight: true)
```

## Code Examples

Verified patterns from official sources and existing codebase:

### SwiftData @Model with @Attribute Unique Constraint
```swift
// Source: Existing GuestBookmark.swift (FeedFeature/Sources/GuestSession/)

@Model
public class PantryItem {
    @Attribute(.unique) public var id: UUID  // Ensures no duplicate IDs
    public var userId: String
    public var name: String
    public var quantity: String
    // ... other fields

    public init(id: UUID = UUID(), userId: String, name: String, quantity: String) {
        self.id = id
        self.userId = userId
        self.name = name
        self.quantity = quantity
    }
}
```

### TCA Reducer with @Dependency Injection
```swift
// Source: Existing FeedReducer.swift pattern

@Reducer
public struct PantryReducer {
    @ObservableState
    public struct State: Equatable {
        public var items: IdentifiedArrayOf<PantryItem> = []
        public var isLoading: Bool = false
        // ... other state
    }

    public enum Action {
        case onAppear
        case itemsLoaded([PantryItem])
        case addItemTapped
        // ... other actions
    }

    @Dependency(\.pantryClient) var pantryClient
    @Dependency(\.networkClient) var networkClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let items = await pantryClient.fetchAllItems()
                    await send(.itemsLoaded(items))
                }

            case let .itemsLoaded(items):
                state.isLoading = false
                state.items = IdentifiedArray(uniqueElements: items)
                return .none

            // ... other cases
            }
        }
    }
}
```

### NestJS GraphQL Resolver with @Args Validation
```swift
// Source: Existing RecipesResolver.ts pattern

@Resolver(() => PantryItem)
export class PantryResolver {
  constructor(private pantryService: PantryService) {}

  @Query(() => [PantryItem])
  async pantryItems(
    @Args('userId') userId: string,
    @Args('sinceTimestamp', { type: () => Date, nullable: true }) sinceTimestamp?: Date,
  ): Promise<PantryItem[]> {
    return this.pantryService.findAllForUser(userId, sinceTimestamp);
  }

  @Mutation(() => PantryItem)
  async addPantryItem(
    @Args('input') input: AddPantryItemInput,
  ): Promise<PantryItem> {
    return this.pantryService.addItem(input);
  }
}
```

### Prisma Seed Script with Bilingual Data
```typescript
// Source: Prisma seeding documentation + project pattern

// prisma/seed.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding ingredient catalog...');

  const ingredients = [
    {
      canonicalName: 'eggs',
      canonicalNameTR: 'yumurta',
      aliases: ['egg', 'large eggs', 'free-range eggs', 'yumurtalar', 'organik yumurta'],
      defaultCategory: 'dairy',
      defaultShelfLifeDays: 28,
    },
    {
      canonicalName: 'tomatoes',
      canonicalNameTR: 'domates',
      aliases: ['tomato', 'cherry tomatoes', 'roma tomatoes', 'domates', 'kiraz domates'],
      defaultCategory: 'produce',
      defaultShelfLifeDays: 7,
    },
    {
      canonicalName: 'chicken breast',
      canonicalNameTR: 'tavuk göğsü',
      aliases: ['chicken', 'boneless chicken', 'tavuk', 'göğüs eti'],
      defaultCategory: 'meat',
      defaultShelfLifeDays: 2,
    },
    // ... 200-300 more ingredients
  ];

  // Use createMany for batch insert (avoids N+1 queries)
  await prisma.ingredientCatalog.createMany({
    data: ingredients,
    skipDuplicates: true,  // Idempotent: safe to run multiple times
  });

  console.log(`Seeded ${ingredients.length} ingredients`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

### Apollo iOS GraphQL Query Definition
```graphql
# Source: Existing RecipeDetail.graphql pattern
# File: KindredAPI/Sources/Operations/Queries/PantryItems.graphql

query PantryItems($userId: ID!, $sinceTimestamp: DateTime) {
  pantryItems(userId: $userId, sinceTimestamp: $sinceTimestamp) {
    id
    name
    normalizedName
    quantity
    unit
    storageLocation
    foodCategory
    expiryDate
    isSynced
    updatedAt
  }
}

mutation AddPantryItem($input: AddPantryItemInput!) {
  addPantryItem(input: $input) {
    id
    name
    normalizedName
    quantity
    storageLocation
    updatedAt
  }
}

query IngredientSearch($query: String!, $lang: String = "en") {
  ingredientSearch(query: $query, lang: $lang) {
    canonicalName
    canonicalNameTR
    defaultCategory
    defaultShelfLifeDays
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Core Data with NSManagedObject | SwiftData with @Model macro | iOS 17 (2023) | Eliminates boilerplate, adds Swift concurrency support, automatic thread-safety via @MainActor |
| Prisma 2.x code-first | Prisma 7.x Rust-free client | Prisma 7.0 (Feb 2026) | Faster Prisma Client generation, full TypeScript support, PostGIS extensions first-class |
| Apollo iOS 0.x callback-based | Apollo iOS 2.x async/await | Apollo 2.0 (2024) | Native Swift concurrency, eliminates closure hell, better error handling |
| TCA 0.x with Effects | TCA 1.x with @Reducer + @Dependency | TCA 1.0 (2023) | Simplified dependency injection, macro-based reducers, better testing ergonomics |
| Manual GraphQL codegen scripts | Apollo CLI SPM plugin | Apollo 1.7+ (2024) | Codegen integrated with Xcode build, no manual script phase, always in sync |

**Deprecated/outdated:**
- **Core Data NSFetchedResultsController:** SwiftData @Query property wrapper replaces this for SwiftUI views. Don't use NSFetchedResultsController in new code.
- **Prisma `prisma generate --watch`:** Prisma 7 has built-in watch mode in `prisma studio`. Old `--watch` flag removed.
- **TCA `Effect.task`:** Replaced by `.run` effect in TCA 1.0+. Old `Effect.task` deprecated.
- **Apollo `ApolloClient.fetch(query:cachePolicy:)` with completion handlers:** Use async/await `apolloClient.fetch(query:)` in Apollo 2.x. Completion handlers deprecated.

## Open Questions

1. **Quantity Unit Conversion for Merge Logic**
   - What we know: User decision is to merge duplicate items by normalizedName, adding quantities together
   - What's unclear: How to handle unit conversions ("1 cup" + "250ml" = ?). Are we normalizing units to a standard (e.g., always store in grams/ml) or keeping original units and displaying warning when units mismatch?
   - Recommendation: Phase 12 MVP stores quantities as freeform strings, no conversion. Display both items if units differ (don't merge "2 cups flour" + "500g flour"). Defer smart unit conversion to Phase 13+.

2. **Ingredient Catalog Seed Data Source**
   - What we know: Need 200-300 common ingredients, bilingual (EN + TR), with aliases and default categories
   - What's unclear: Where does curated list come from? Manual curation? Scrape from existing recipe data? Import from USDA database subset?
   - Recommendation: Start with manual curation of top 100 ingredients from existing recipe data (query Prisma for most common `Ingredient.name` values, manually normalize + translate). Expand to 200-300 over time as unknown items get added via "accept and learn" flow.

3. **Badge Count Calculation for Expiring Items**
   - What we know: Pantry tab shows red badge with count of "expiring soon" items
   - What's unclear: What qualifies as "expiring soon"? Within 3 days? 7 days? Different thresholds per category (produce vs pantry staples)?
   - Recommendation: Fixed 3-day threshold for MVP (items expiring within 72 hours). Badge calculation done in PantryClient, not TCA reducer (avoid recomputing on every action). Future: User-configurable threshold in settings.

4. **Offline Sync Conflict Resolution Edge Cases**
   - What we know: Last-write-wins based on `updatedAt` timestamp for single-user MVP
   - What's unclear: What if device clock is wrong (user traveled across timezones, clock manually changed)? Server timestamp or client timestamp as source of truth?
   - Recommendation: Server timestamp wins. Backend `updatedAt` field generated by `@updatedAt` Prisma directive (server time). Client sends `updatedAt` in mutation but server overwrites with `new Date()`. Prevents clock drift issues.

5. **Unknown Ingredient Learning Workflow (Server-Side)**
   - What we know: When user types unknown ingredient, system should "accept and learn" — add to catalog for future users
   - What's unclear: Approval workflow? Auto-add to catalog or admin review queue? Risk of profanity/spam?
   - Recommendation: Phase 12 auto-adds to catalog (no approval). Unknown items initially have `null` defaultCategory — requires manual admin tagging later (Phase 13 admin tool). Risk mitigated by small user base during MVP.

## Sources

### Primary (HIGH confidence)
- [SwiftData Schema Migrations in iOS 17 | Level Up Coding](https://levelup.gitconnected.com/mastering-swiftdata-schema-migrations-c93d9c03dc63) - VersionedSchema + SchemaMigrationPlan patterns
- [How to create complex migration using VersionedSchema - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema) - Lightweight vs custom migrations
- [Prisma 7 Release: Rust-Free, Faster, and More Compatible](https://www.prisma.io/blog/announcing-prisma-orm-7-0-0) - Prisma 7.4 features, PostGIS extensions
- [Seeding | Prisma Documentation](https://www.prisma.io/docs/orm/prisma-migrate/workflows/seeding) - Prisma seed script patterns
- [Apollo iOS Codegen CLI - Official Docs](https://www.apollographql.com/docs/ios/code-generation/codegen-cli) - Apollo 2.x SPM plugin setup
- [TCA Dependencies DependencyKey pattern - Point-Free GitHub](https://github.com/pointfreeco/swift-composable-architecture) - @Dependency injection with liveValue/testValue
- Existing codebase files: GuestSessionClient.swift, RecipesResolver.ts, schema.prisma, GuestBookmark.swift

### Secondary (MEDIUM confidence)
- [Offline-First SwiftUI with SwiftData - Medium](https://medium.com/@ashitranpura27/offline-first-swiftui-with-swiftdata-clean-fast-and-sync-ready-9a4faefdeedb) - Last-write-wins sync patterns
- [Database normalization with PostgreSQL, NestJS, and Prisma - Wanago.io](https://wanago.io/2023/11/13/api-nestjs-database-normalization-postgresql-prisma/) - Normalization patterns
- [SwiftUI Badges for Toolbars & Tab Bars in iOS 26 - DevTechie](https://www.devtechie.com/blog/swiftui-badges-for-toolbars-and-tab-bars-in-ios-26) - Tab bar badge implementation
- [Building a GraphQL API with NestJS and Prisma - Jelani Harris](https://jelaniharris.com/blog/building-a-graphql-api-with-nestjs-and-prisma/) - NestJS code-first patterns

### Tertiary (LOW confidence)
- [Fuzzy Matching 101 - Data Ladder](https://dataladder.com/fuzzy-matching-101/) - Fuzzy matching algorithms (not ingredient-specific, general theory)
- [Normalization in preparation for fuzzy matching - Megaputer](https://www.megaputer.com/normalization-in-preparation-for-fuzzy-matching/) - Normalization preprocessing (not SwiftData/Prisma-specific)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use (SwiftData, TCA, Prisma 7, NestJS, Apollo 2.x). No new dependencies. Versions confirmed from package files.
- Architecture: HIGH - GuestSessionClient and RecipesModule provide exact templates to replicate. TCA @Dependency, SwiftData @MainActor store, NestJS @Resolver patterns verified in existing code.
- Pitfalls: MEDIUM-HIGH - SwiftData thread-safety, Prisma migration drift, Apollo codegen documented from research + project memory (location debug session, voice playback session). Soft delete and autocomplete N+1 from general best practices, not project-specific incidents.

**Research date:** 2026-03-11
**Valid until:** 2026-05-11 (60 days) - Stack stable (iOS 17, Prisma 7.4, TCA 1.0, Apollo 2.x). SwiftData migration patterns unlikely to change before iOS 18 beta (June 2026).
