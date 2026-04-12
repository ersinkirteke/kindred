# Phase 29: Source Attribution Wiring - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire per-recipe `sourceUrl` + `sourceName` from the backend GraphQL into `RecipeDetailView` as a tappable link. Backend already exposes these fields on the Recipe model; this phase adds them to the iOS query and renders them in the detail view. No backend changes needed.

</domain>

<decisions>
## Implementation Decisions

### Link placement & style
- Source link sits **above** the existing Spoonacular compliance footer, as a separate section
- No divider between source link and compliance footer — just vertical spacing
- Inline link style matching existing "Powered by Spoonacular" pattern: caption-sized text, `kindredTextSecondary` color, `arrow.up.right` icon
- Opens in **SFSafariViewController** (in-app browser), not external Safari
- Update existing "Powered by Spoonacular" link to also use SFSafariViewController for consistency
- Link text is localized — verb portion translated ("View original at" / "Orijinal tarifi gor:"), source name stays English (proper noun)

### Null sourceUrl handling
- When `sourceUrl` is null: source link area does not render at all (no fallback text)
- When `sourceName` is null but `sourceUrl` exists: generic "View original recipe" text
- Malformed URL (`URL(string:)` returns nil): treat as if `sourceUrl` is null — show nothing
- Dead links (404): no client-side check — in-app browser handles the error page
- Spacing collapses when source link is absent — Spoonacular footer sits at its normal position
- No logging for null sourceUrl — silently skip
- Spoonacular compliance footer **always** shows regardless of sourceUrl presence

### Source name display
- Format: "View original at {sourceName}" with arrow.up.right icon
- Source name displayed as-is from backend — no client-side title-casing or cleanup
- Long names: single line with truncation (ellipsis) — no wrapping
- VoiceOver: descriptive accessibility label including source name ("Opens original recipe at AllRecipes in browser")

### Claude's Discretion
- Exact spacing values between source link and compliance footer
- SFSafariViewController presentation style (sheet vs full screen)
- String Catalog key naming for the localized link text

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Link` + `arrow.up.right` pattern: Already used in compliance footer (`RecipeDetailView.swift:199-207`) — source link replicates this exact visual pattern
- `kindredCaptionScaled(size:)` font + `kindredTextSecondary` color: Established footer typography
- `KindredSpacing` constants: Used throughout for consistent spacing

### Established Patterns
- GraphQL codegen: Add fields to `.graphql` operation file, run Apollo codegen, generated Swift types appear in `KindredAPI` package
- Model mapping: `RecipeDetail.from(graphQL:)` static method maps GraphQL response to domain model (`RecipeDetailModels.swift:82-99`)
- Localization: String Catalog with `String(localized:bundle:)` pattern throughout views

### Integration Points
- `RecipeDetailQuery.graphql.swift` (line 11): Add `sourceUrl sourceName` to selection set — currently missing
- `RecipeDetail` model (`RecipeDetailModels.swift`): Add `sourceUrl: String?` and `sourceName: String?` properties
- `RecipeDetail.from(graphQL:)`: Map new fields from query result
- `RecipeDetailView.recipeContentView()` (line 117): Insert source link above existing compliance footer VStack (line 193)
- `RecipeDetailReducer`: May need action for opening SFSafariViewController (or handle via `@Environment(\.openURL)` replacement)

</code_context>

<specifics>
## Specific Ideas

- Source link visually matches the existing Spoonacular footer style — same font, color, icon — but as a distinct line above it
- "View original at AllRecipes" is the primary format; falls back to "View original recipe" when no source name
- In-app Safari (SFSafariViewController) keeps users in Kindred — swipe down to return

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 29-source-attribution-wiring*
*Context gathered: 2026-04-12*
