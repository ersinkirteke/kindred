# Phase 12: Pantry Infrastructure - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Build backend GraphQL schema, ingredient normalization system, and PantryFeature SPM package foundation. This phase delivers the data layer and package structure — no user-facing UI beyond the tab bar placeholder. Manual CRUD, scanning, matching, and expiry tracking are separate phases (13-17).

</domain>

<decisions>
## Implementation Decisions

### Pantry Data Model
- PantryItem fields: name (String), quantity (String, freeform like RecipeIngredient), unit (String), storageLocation (enum: fridge/freezer/pantry), foodCategory (enum: ~8-10 standard categories — Dairy, Produce, Meat, Seafood, Grains, Baking, Spices, Beverages, Snacks, Condiments), optional photo URL, optional notes (free text), source (enum: manual/fridge_scan/receipt_scan), expiryDate (Date, nullable), normalizedName (from IngredientCatalog)
- Soft delete — mark as deleted, keep history for analytics
- No brand field — keep it ingredient-level
- Merge duplicate quantities — if same normalized ingredient exists, add quantities together
- Food category auto-filled from IngredientCatalog when ingredient is recognized

### Ingredient Normalization
- MVP-level: case-insensitive + basic synonyms, not full USDA IngID
- Server-side normalization on save — single source of truth
- Curated seed list of ~200-300 common ingredients, bilingual (English + Turkish)
- IngredientCatalog as backend PostgreSQL table (not static JSON) — fetched via GraphQL search query
- Prisma seed script populates initial catalog
- Autocomplete from known list as user types — can still type custom items
- Unknown items: accept and learn — add to catalog for future users
- Add `normalizedName` column to existing recipe `Ingredient` model for matching
- Each catalog entry has: canonicalName (EN), canonicalNameTR (TR), aliases (String[]), defaultCategory (enum), defaultShelfLifeDays (Int, nullable)

### App Navigation
- New tab bar item: Feed, Pantry, Profile (pantry in the middle)
- Refrigerator SF Symbol icon for pantry tab
- Badge count showing number of expiring-soon items (red badge)
- Pantry tab lands on list view (not dashboard), grouped by storage location
- Floating + button in bottom-right for adding items
- Tab order: Feed (left), Pantry (center), Profile (right)

### Backend API Shape
- New standalone NestJS PantryModule (mirrors iOS PantryFeature package)
- Queries + mutations only (no GraphQL subscriptions for MVP)
- Bulk add mutation: `bulkAddPantryItems` accepts array for receipt scan results
- Ingredient search query: `ingredientSearch(query: String, lang: String)` returns matching catalog entries with aliases
- Authentication required — guests see pantry tab but get prompted to sign in
- No pagination — return all pantry items at once (expect <100 items per user)
- Timestamp-based sync: each item has `updatedAt`, client sends changes since last sync

### Offline Behavior
- Subtle cloud icon indicator on items not yet synced
- Last-write-wins for timestamp conflicts (single-user MVP, conflicts rare)

### Empty State
- Illustration + "Add your first item" CTA button + hint about scanning features

### Claude's Discretion
- Exact Prisma model field types and indexes
- GraphQL input/output type naming conventions
- SwiftData model property wrappers and migration strategy
- PantryFeature package internal folder structure
- Specific SF Symbol variant for refrigerator icon
- Empty state illustration style
- Cloud sync indicator visual design

</decisions>

<specifics>
## Specific Ideas

- PantryClient lives inside PantryFeature package (self-contained). FeedFeature imports PantryFeature to access PantryClient for recipe matching (one-way dependency).
- Follow GuestSessionClient pattern exactly: TCA `@Dependency` with `DependencyKey`, `liveValue`/`testValue`, backed by SwiftData `ModelContainer`
- IngredientCatalog should support bilingual search — "domates" and "tomato" find the same canonical item
- RecipeIngredient already has name/quantity/unit — PantryItem mirrors this structure with additional fields
- Merge behavior: "You already have 2 eggs" + adding 12 from receipt = 14 eggs (same normalizedName)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GuestSessionClient` (FeedFeature/Sources/GuestSession/): Direct template for PantryClient pattern — TCA @Dependency, SwiftData ModelContainer, liveValue/testValue, CRUD operations with FetchDescriptor + #Predicate
- `GuestSessionStore`: @MainActor singleton with ModelContainer — same pattern for PantryStore
- `RecipeIngredient` model (FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift): name/quantity/unit structure — pantry items mirror this
- `KindredAPI/Schema/Objects/Ingredient.graphql.swift`: GraphQL Ingredient type exists — extend for pantry
- `NetworkClient` package: Apollo iOS 2.0.6 with SQLite cache, Dependencies integration — extend with pantry operations

### Established Patterns
- SwiftData: `ModelContainer`, `ModelContext`, `@Model`, `FetchDescriptor`, `#Predicate` macros (GuestBookmark, GuestSkip models)
- TCA Dependencies: `DependencyKey` protocol with `liveValue`/`testValue` statics
- GraphQL code-first on backend (Prisma schema → NestJS resolvers → Apollo codegen → KindredAPI types)
- SPM packages: each feature is self-contained with Package.swift, Sources/, dependencies on shared packages

### Integration Points
- `AppReducer` (Sources/App/AppReducer.swift): Composes all feature reducers — add PantryReducer here
- `schema.prisma` (backend/prisma/): Add PantryItem + IngredientCatalog models, add normalizedName to Ingredient
- `KindredAPI` package: Apollo codegen output — new pantry queries/mutations generate types here
- Tab bar in main app view: Add pantry tab between feed and profile

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 12-pantry-infrastructure*
*Context gathered: 2026-03-11*
