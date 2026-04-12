# Phase 29: Source Attribution Wiring - Research

**Researched:** 2026-04-13
**Domain:** iOS SwiftUI + Apollo GraphQL + SFSafariViewController
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Link placement & style**
- Source link sits **above** the existing Spoonacular compliance footer, as a separate section
- No divider between source link and compliance footer — just vertical spacing
- Inline link style matching existing "Powered by Spoonacular" pattern: caption-sized text, `kindredTextSecondary` color, `arrow.up.right` icon
- Opens in **SFSafariViewController** (in-app browser), not external Safari
- Update existing "Powered by Spoonacular" link to also use SFSafariViewController for consistency
- Link text is localized — verb portion translated ("View original at" / "Orijinal tarifi gor:"), source name stays English (proper noun)

**Null sourceUrl handling**
- When `sourceUrl` is null: source link area does not render at all (no fallback text)
- When `sourceName` is null but `sourceUrl` exists: generic "View original recipe" text
- Malformed URL (`URL(string:)` returns nil): treat as if `sourceUrl` is null — show nothing
- Dead links (404): no client-side check — in-app browser handles the error page
- Spacing collapses when source link is absent — Spoonacular footer sits at its normal position
- No logging for null sourceUrl — silently skip
- Spoonacular compliance footer **always** shows regardless of sourceUrl presence

**Source name display**
- Format: "View original at {sourceName}" with arrow.up.right icon
- Source name displayed as-is from backend — no client-side title-casing or cleanup
- Long names: single line with truncation (ellipsis) — no wrapping
- VoiceOver: descriptive accessibility label including source name ("Opens original recipe at AllRecipes in browser")

### Claude's Discretion
- Exact spacing values between source link and compliance footer
- SFSafariViewController presentation style (sheet vs full screen)
- String Catalog key naming for the localized link text

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ATTR-01 | Recipe detail view displays clickable source URL linking to original recipe | Backend already exposes `sourceUrl`/`sourceName` in GraphQL schema (nullable String). Adding to query selection set + domain model + view renders them. SFSafariViewController is the established in-app browser pattern (ProfileFeature already has SafariView wrapper). |

</phase_requirements>

---

## Summary

Phase 29 is a surgical iOS-only wiring task: add two fields (`sourceUrl`, `sourceName`) to the existing `RecipeDetailQuery` GraphQL selection set, propagate them through the domain model, and render a tappable link in `RecipeDetailView`. All three layers are already structurally in place — the backend schema exposes the fields with `@Field(() => String, { nullable: true })` decorators, the Apollo codegen pipeline is configured, and the project already has a `SafariView` UIViewControllerRepresentable wrapper in `ProfileFeature` that can serve as a direct template.

The work is bounded to four files plus a codegen run: `RecipeQueries.graphql` (add fields to selection set), `RecipeDetailModels.swift` (add properties + map call), `RecipeDetailView.swift` (render source link + migrate Spoonacular link to SafariView), and `Localizable.xcstrings` (add two localization keys for EN + TR). No new dependencies, no new packages, no backend changes.

The only non-trivial design decision is how to present `SFSafariViewController` from a SwiftUI view inside a TCA architecture. ProfileFeature's existing pattern — a `SafariView: UIViewControllerRepresentable` struct presented via `.sheet(isPresented:)` with a local `@State var showSafari = false` — is the established approach. Since `RecipeDetailView` is a TCA-driven view, the cleanest approach is to replicate the same local-state sheet pattern used in ProfileView rather than routing the URL through TCA state (which would add unnecessary complexity for a pure-presentation concern).

**Primary recommendation:** Copy the `SafariView` struct into FeedFeature (or move it to DesignSystem for reuse), use a `Button` with local `@State var safariURL: URL?` + `.sheet(item:)` to present it, replicate this for both the source link and the existing Spoonacular link migration.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Apollo iOS | 2.0.6 (exact) | GraphQL codegen + networking | Already in use throughout project |
| SafariServices (system) | iOS 14+ | SFSafariViewController for in-app browser | System framework, no import overhead |
| SwiftUI | iOS 16+ | View rendering | Project baseline |
| ComposableArchitecture (TCA) | latest | State/action routing | Project-wide architecture |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SafariView (local struct) | — | UIViewControllerRepresentable wrapper for SFSafariViewController | Already exists in ProfileFeature — template to copy |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local `@State` for safari URL | TCA action + state property | TCA adds boilerplate without benefit — purely presentational; local state is correct here |
| Copy SafariView to FeedFeature | Move SafariView to DesignSystem | DesignSystem move is cleaner long-term but out-of-scope for this phase; copy is fine |
| SwiftUI `Link` view (current Spoonacular) | SafariView via `.sheet` | `Link` opens external Safari; SafariView keeps user in-app — decision locked |

**Installation:** No new packages required.

---

## Architecture Patterns

### Recommended Project Structure

Only modified files:
```
Kindred/
├── Packages/
│   ├── NetworkClient/Sources/GraphQL/
│   │   └── RecipeQueries.graphql          # Add sourceUrl + sourceName fields
│   ├── KindredAPI/Sources/Operations/Queries/
│   │   └── RecipeDetailQuery.graphql.swift # Re-generated by apollo-ios-cli
│   └── FeedFeature/Sources/RecipeDetail/
│       ├── RecipeDetailModels.swift        # Add sourceUrl/sourceName properties + mapping
│       ├── RecipeDetailView.swift          # Add source link section + migrate Spoonacular link
│       └── SafariView.swift               # New file: copy from ProfileFeature
└── Sources/Resources/
    └── Localizable.xcstrings              # Add 2 new localization keys
```

### Pattern 1: Adding Fields to Apollo Selection Set

**What:** Edit `.graphql` file, run codegen, generated Swift types update automatically.
**When to use:** Any time new backend fields need to be consumed on iOS.
**Example:**
```graphql
# RecipeQueries.graphql — add after difficulty
query RecipeDetail($id: ID!) {
  recipe(id: $id) {
    ...
    difficulty
    sourceUrl       # add this
    sourceName      # add this
    ingredients {
      ...
    }
  }
}
```

Codegen command (from `/Users/ersinkirteke/Workspaces/Kindred/Kindred/` directory):
```bash
apollo-ios-cli generate --path apollo-codegen-config.json
```

Config file: `Kindred/apollo-codegen-config.json`
- Input operations: `Packages/NetworkClient/Sources/GraphQL/**/*.graphql`
- Input schema: `../backend/schema.gql`
- Output: `Packages/KindredAPI/`

After codegen, `RecipeDetailQuery.Data.Recipe` will gain:
```swift
public var sourceUrl: String? { __data["sourceUrl"] }
public var sourceName: String? { __data["sourceName"] }
```

### Pattern 2: Domain Model Mapping

**What:** Add optional String properties to `RecipeDetail` and map from GraphQL result.
**When to use:** Adding new fields to the domain model layer.

```swift
// RecipeDetailModels.swift — RecipeDetail struct
public let sourceUrl: String?
public let sourceName: String?

// In init:
public init(
    ...
    sourceUrl: String? = nil,
    sourceName: String? = nil
) {
    ...
    self.sourceUrl = sourceUrl
    self.sourceName = sourceName
}

// In from(graphQL:):
public static func from(graphQL recipe: KindredAPI.RecipeDetailQuery.Data.Recipe) -> RecipeDetail {
    return RecipeDetail(
        ...
        sourceUrl: recipe.sourceUrl,
        sourceName: recipe.sourceName
    )
}
```

### Pattern 3: SFSafariViewController via Sheet (ProfileFeature Pattern)

**What:** UIViewControllerRepresentable wrapping SFSafariViewController, presented as a sheet.
**When to use:** In-app browser presentation in SwiftUI.

```swift
// SafariView.swift (copy from ProfileFeature)
import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
```

Presentation in RecipeDetailView (local state approach, matching ProfileView pattern):
```swift
// In RecipeDetailView — add @State
@State private var safariURL: URL?

// In body or recipeContentView:
.sheet(item: $safariURL) { url in
    SafariView(url: url)
}

// Source link button:
Button {
    if let urlString = recipe.sourceUrl, let url = URL(string: urlString) {
        safariURL = url
    }
} label: {
    HStack(spacing: 4) {
        Text(sourceText(for: recipe.sourceName))
        Image(systemName: "arrow.up.right")
    }
    .font(.kindredCaptionScaled(size: captionSize))
    .foregroundStyle(.kindredTextSecondary)
    .lineLimit(1)
    .truncationMode(.tail)
}
.accessibilityLabel(sourceAccessibilityLabel(for: recipe.sourceName))
.accessibilityAddTraits(.isLink)
```

Note: `sheet(item:)` requires `URL` to conform to `Identifiable`. URL does NOT conform to Identifiable by default. Use `@State private var safariURL: URL?` with `sheet(item:)` requires a wrapper, OR use `@State private var showSourceSafari = false` + `@State private var resolvedSourceURL: URL?` with `sheet(isPresented:)`. The `ProfileView` pattern uses `isPresented:` — follow that.

### Pattern 4: Localization (String Catalog)

**What:** Add string keys to `Localizable.xcstrings` for EN and TR.
**When to use:** Any user-visible text.

Existing Spoonacular keys in `Sources/Resources/Localizable.xcstrings` (lines 5482-5545) show the pattern:
```json
"recipe_detail.source_attribution.view_original_at": {
    "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "View original at" } },
        "tr": { "stringUnit": { "state": "translated", "value": "Orijinal tarifi görüntüle:" } }
    }
},
"recipe_detail.source_attribution.view_original_generic": {
    "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "View original recipe" } },
        "tr": { "stringUnit": { "state": "translated", "value": "Orijinal tarifi görüntüle" } }
    }
}
```

Usage in view:
```swift
// With source name:
"\(String(localized: "recipe_detail.source_attribution.view_original_at", bundle: .main)) \(sourceName)"
// Without source name:
String(localized: "recipe_detail.source_attribution.view_original_generic", bundle: .main)
```

### Anti-Patterns to Avoid

- **Routing safari URL through TCA state:** Adds a `safariURL: URL?` property to `RecipeDetailReducer.State` + an action — this bloats state for a purely presentational concern. Local `@State` is correct here.
- **URL construction without nil check:** `URL(string:)` returns nil for invalid strings. Always guard: `if let url = URL(string: urlString)`. The decision says treat malformed URL as null — silently skip rendering.
- **Using SwiftUI `Link` for source URL:** `Link` opens external Safari (leaves app). `SFSafariViewController` keeps user in-app — decision is locked.
- **Adding `sourceUrl`/`sourceName` to `RecipeCard` model:** These fields only appear in detail view. Don't add to the feed card model.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-app browser | Custom WKWebView implementation | SFSafariViewController via existing SafariView wrapper | System framework handles auth, cookies, Reader Mode, share sheet |
| URL validation | Custom regex or URL parser | `URL(string:)` returning nil | Standard Foundation behavior; correct and sufficient |
| Codegen | Manual Swift type editing | `apollo-ios-cli generate` | Generated file is `@generated` — manual edits are overwritten |

---

## Common Pitfalls

### Pitfall 1: Editing `RecipeDetailQuery.graphql.swift` Directly
**What goes wrong:** Manual edits to the generated file get overwritten on next codegen run.
**Why it happens:** File header says `// @generated — This file was automatically generated and should not be edited.`
**How to avoid:** ONLY edit `RecipeQueries.graphql`, then run codegen. The generated `.swift` file updates automatically.
**Warning signs:** Seeing manual properties in a `@generated` file.

### Pitfall 2: `URL` Not `Identifiable` for `sheet(item:)`
**What goes wrong:** `@State private var safariURL: URL?` + `sheet(item: $safariURL)` fails to compile because `URL` does not conform to `Identifiable`.
**Why it happens:** SwiftUI's `sheet(item:)` requires `Identifiable`.
**How to avoid:** Use `sheet(isPresented: $showSafari)` with a separate `@State var resolvedURL: URL?` (the ProfileView pattern), or create an `IdentifiableURL` wrapper.
**Warning signs:** Compiler error about `URL` not conforming to `Identifiable`.

### Pitfall 3: `URL(string:)` Accepts Empty String
**What goes wrong:** `URL(string: "")` returns a non-nil URL pointing to an empty path — not nil.
**Why it happens:** Empty string is technically a valid relative URL.
**How to avoid:** Guard both nil AND empty: `if let urlString = recipe.sourceUrl, !urlString.isEmpty, let url = URL(string: urlString)`. This handles the null case the decision describes.
**Warning signs:** Button appears but safari shows blank/error page.

### Pitfall 4: `bundle: .main` in Package Modules
**What goes wrong:** `String(localized:bundle:)` with `.main` in a Swift Package module loads strings from the app bundle, not the package bundle.
**Why it happens:** Swift Package modules have their own bundle; `.main` is the host app.
**How to avoid:** Observe existing code — `RecipeDetailView.swift` consistently uses `bundle: .main`. The project's `Localizable.xcstrings` lives in `Sources/Resources/` (the main app bundle). Continue this pattern — add new keys to `Sources/Resources/Localizable.xcstrings`, use `bundle: .main`.
**Warning signs:** String appears as the key literal in UI.

### Pitfall 5: Apollo Codegen Changes Both Output Files
**What goes wrong:** Running codegen updates `Packages/KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift` but also regenerates other files if schema changed.
**Why it happens:** Full codegen regenerates all operations.
**How to avoid:** Only edit the `.graphql` operation file, not the schema. Run codegen and review the diff — only `RecipeDetailQuery.graphql.swift` should change (adding `sourceUrl` and `sourceName` accessors + updating the `operationDocument` string).
**Warning signs:** Unexpected changes to other generated files.

---

## Code Examples

### Source Link Rendering in recipeContentView

```swift
// In RecipeDetailView.recipeContentView(_ recipe:)
// Insert this VStack ABOVE the existing compliance footer VStack (currently at line 194)

// Source attribution link (shown only when sourceUrl is valid)
if let urlString = recipe.sourceUrl,
   !urlString.isEmpty,
   let url = URL(string: urlString) {
    Button {
        resolvedSourceURL = url
        showSourceSafari = true
    } label: {
        HStack(spacing: 4) {
            if let sourceName = recipe.sourceName, !sourceName.isEmpty {
                Text(String(localized: "recipe_detail.source_attribution.view_original_at", bundle: .main) + " \(sourceName)")
            } else {
                Text(String(localized: "recipe_detail.source_attribution.view_original_generic", bundle: .main))
            }
            Image(systemName: "arrow.up.right")
        }
        .font(.kindredCaptionScaled(size: captionSize))
        .foregroundStyle(.kindredTextSecondary)
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .accessibilityLabel({
        if let sourceName = recipe.sourceName, !sourceName.isEmpty {
            return String(localized: "Opens original recipe at \(sourceName) in browser", bundle: .main)
        } else {
            return String(localized: "Opens original recipe in browser", bundle: .main)
        }
    }())
    .accessibilityAddTraits(.isLink)
}

// Compliance footer (unchanged, always shown)
VStack(alignment: .leading, spacing: KindredSpacing.xs) {
    Text(String(localized: "Nutrition estimates from Spoonacular. Not for medical use.", bundle: .main))
        ...
    // Migrate Spoonacular link from Link{} to Button{} presenting SafariView
    Button {
        resolvedSourceURL = URL(string: "https://spoonacular.com/food-api")!
        showSourceSafari = true
    } label: {
        HStack(spacing: 4) {
            Text(String(localized: "Powered by Spoonacular", bundle: .main))
            Image(systemName: "arrow.up.right")
        }
        .font(.kindredCaptionScaled(size: captionSize))
        .foregroundStyle(.kindredTextSecondary)
    }
    .accessibilityLabel(String(localized: "Opens Spoonacular website in browser", bundle: .main))
    .accessibilityAddTraits(.isLink)
}
```

### @State Properties to Add in RecipeDetailView

```swift
@State private var showSourceSafari = false
@State private var resolvedSourceURL: URL? = nil
```

### Sheet Modifier to Add on body or ScrollView

```swift
.sheet(isPresented: $showSourceSafari) {
    if let url = resolvedSourceURL {
        SafariView(url: url)
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SwiftUI `Link` (existing Spoonacular link) | SFSafariViewController via SafariView | Phase 29 decision | User stays in-app; consistent with source link |

**Deprecated/outdated:**
- Using `Link` for in-app browsing in Kindred: The decision is to use SFSafariViewController for all external links in detail view. The existing `Link(destination:)` for Spoonacular should be migrated.

---

## Open Questions

1. **Apollo codegen CLI availability**
   - What we know: `apollo-codegen-config.json` exists at `Kindred/apollo-codegen-config.json`. The project uses `apollo-ios` 2.0.6. The codegen command is `apollo-ios-cli generate`.
   - What's unclear: Whether `apollo-ios-cli` is installed globally or only via a build tool plugin. No Makefile or script was found referencing it explicitly.
   - Recommendation: The plan should include a verification step — `which apollo-ios-cli` or check `~/.mint/bin/`. If not globally available, use `swift package --allow-writing-to-package-directory generate-code-from-schema` (ApolloCodegenLib build tool plugin). The codegen output files exist, so codegen has been run before — the developer knows how to do it.

2. **`SafariView` placement: copy vs. DesignSystem move**
   - What we know: `SafariView` currently lives in `ProfileFeature/Sources/SafariView.swift` as a `struct` (no `public` access modifier — package-internal only).
   - What's unclear: Whether FeedFeature has a dependency on ProfileFeature (likely not — they're sibling packages).
   - Recommendation: Copy `SafariView.swift` into `FeedFeature/Sources/RecipeDetail/SafariView.swift` (internal to FeedFeature). Moving to DesignSystem is a clean-up task for a future phase.

---

## Validation Architecture

> `workflow.nyquist_validation` is not present in `.planning/config.json` — this section is skipped as the field is absent (treated as false).

---

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `backend/src/graphql/models/recipe.model.ts` lines 154-158 — `sourceUrl` and `sourceName` fields confirmed with `@Field(() => String, { nullable: true })` decorator
- Direct file inspection: `backend/schema.gql` lines 348-349 — `sourceName: String` and `sourceUrl: String` confirmed in generated schema
- Direct file inspection: `Kindred/apollo-codegen-config.json` — codegen config with input/output paths
- Direct file inspection: `Packages/NetworkClient/Sources/GraphQL/RecipeQueries.graphql` — current selection set (missing sourceUrl/sourceName)
- Direct file inspection: `Packages/KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift` — generated file structure confirmed (no sourceUrl/sourceName yet)
- Direct file inspection: `Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift` — domain model + `from(graphQL:)` mapping pattern
- Direct file inspection: `Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift` lines 192-213 — existing compliance footer + `Link` pattern
- Direct file inspection: `Packages/ProfileFeature/Sources/SafariView.swift` — existing SafariView wrapper (UIViewControllerRepresentable)
- Direct file inspection: `Packages/ProfileFeature/Sources/ProfileView.swift` lines 101-106 — sheet(isPresented:) + SafariView presentation pattern
- Direct file inspection: `Sources/Resources/Localizable.xcstrings` lines 5482-5545 — EN + TR localization structure for Spoonacular keys

### Secondary (MEDIUM confidence)
- SwiftUI `URL` + `Identifiable` constraint: training knowledge, high confidence based on Swift stdlib — `URL` does NOT conform to `Identifiable`, requiring `isPresented:` sheet pattern.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all files verified directly
- Architecture: HIGH — established patterns found in live codebase (ProfileView + SafariView)
- Pitfalls: HIGH — URL/Identifiable and empty-string URL issues are well-known; bundle pattern confirmed by reading existing view code

**Research date:** 2026-04-13
**Valid until:** 2026-06-13 (stable domain; Apollo codegen config rarely changes)
