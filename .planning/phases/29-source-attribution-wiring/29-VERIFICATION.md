---
phase: 29-source-attribution-wiring
verified: 2026-04-12T00:00:00Z
status: passed
score: 6/6 must-haves verified
re_verification: false
---

# Phase 29: Source Attribution Wiring Verification Report

**Phase Goal:** Recipe detail view shows a tappable link to the original recipe source, satisfying Spoonacular ToS attribution requirement
**Verified:** 2026-04-12
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                             | Status     | Evidence                                                                                                 |
|----|---------------------------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------|
| 1  | Recipe detail view shows a tappable "View original at {sourceName}" link when sourceUrl is present | VERIFIED  | RecipeDetailView.swift lines 201–226: conditional Button using `recipe_detail.source_attribution.view_original_at` key with sourceName interpolation |
| 2  | Tapping the source link opens SFSafariViewController in-app (not external Safari)                 | VERIFIED  | `.sheet(isPresented: $showSourceSafari)` at line 83 presents `SafariView(url:)` backed by SFSafariViewController |
| 3  | When sourceUrl is null or malformed, no source link renders — spacing collapses cleanly            | VERIFIED  | Triple guard at lines 201–203: `if let urlString = recipe.sourceUrl, !urlString.isEmpty, let url = URL(string: urlString)` — all three must pass or the block is skipped entirely |
| 4  | When sourceName is null but sourceUrl exists, generic "View original recipe" text appears          | VERIFIED  | Inner conditional at lines 209–213: `if let sourceName = recipe.sourceName, !sourceName.isEmpty` — else branch uses `recipe_detail.source_attribution.view_original_generic` |
| 5  | Existing "Powered by Spoonacular" link also opens in SFSafariViewController (migrated from SwiftUI Link) | VERIFIED | No `Link(` remaining in RecipeDetailView.swift; Spoonacular footer is now a `Button` setting `resolvedSourceURL = URL(string: "https://spoonacular.com/food-api")` then `showSourceSafari = true` (lines 235–247) |
| 6  | Source link text is localized (EN + TR)                                                           | VERIFIED  | Localizable.xcstrings lines 5550–5582: both `recipe_detail.source_attribution.view_original_at` and `recipe_detail.source_attribution.view_original_generic` have EN + TR `stringUnit` entries with `"state": "translated"` |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact                                                                                    | Expected                                                     | Status   | Details                                                                                  |
|---------------------------------------------------------------------------------------------|--------------------------------------------------------------|----------|------------------------------------------------------------------------------------------|
| `Kindred/Packages/NetworkClient/Sources/GraphQL/RecipeQueries.graphql`                      | `sourceUrl` and `sourceName` in RecipeDetailQuery selection  | VERIFIED | Lines 22–23: `sourceUrl` and `sourceName` added after `difficulty`, before `ingredients` |
| `Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift`    | Apollo-generated Swift accessors for sourceUrl/sourceName    | VERIFIED | Lines 66–67 (selections) + lines 94–95 (accessors): both present as `String?.self`       |
| `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift`                | `sourceUrl` and `sourceName` on RecipeDetail + from(graphQL:) mapping | VERIFIED | Properties at lines 28–29, init params at lines 46–47, mapped in `from(graphQL:)` at lines 103–104 |
| `Kindred/Packages/FeedFeature/Sources/RecipeDetail/SafariView.swift`                        | UIViewControllerRepresentable wrapping SFSafariViewController | VERIFIED | File created, 10 lines, contains `SFSafariViewController`, `makeUIViewController`, `updateUIViewController` |
| `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift`                  | Source attribution link above compliance footer, sheet wiring | VERIFIED | `showSourceSafari` state at line 22, sheet at lines 83–87, attribution button at lines 201–226 |
| `Kindred/Sources/Resources/Localizable.xcstrings`                                          | EN + TR keys for source attribution and accessibility labels  | VERIFIED | 5 keys added: `view_original_at`, `view_original_generic`, `Opens original recipe at %@ in browser`, `Opens original recipe in browser`, `Opens Spoonacular website in browser` |

### Key Link Verification

| From                           | To                                | Via                               | Status   | Details                                                                                     |
|--------------------------------|-----------------------------------|-----------------------------------|----------|---------------------------------------------------------------------------------------------|
| `RecipeQueries.graphql`        | `RecipeDetailQuery.graphql.swift` | Apollo codegen                    | VERIFIED | `sourceUrl` + `sourceName` appear in operation document string (line 11) and as typed accessors (lines 94–95) |
| `RecipeDetailModels.swift`     | `RecipeDetailQuery.graphql.swift` | `RecipeDetail.from(graphQL:)` mapping | VERIFIED | `sourceUrl: recipe.sourceUrl` and `sourceName: recipe.sourceName` at lines 103–104          |
| `RecipeDetailView.swift`       | `RecipeDetailModels.swift`        | `recipe.sourceUrl` property access | VERIFIED | `recipe.sourceUrl` accessed at line 201, `recipe.sourceName` at line 209                   |
| `RecipeDetailView.swift`       | `SafariView.swift`                | `sheet(isPresented:)` presentation | VERIFIED | `SafariView(url: url)` at line 85 inside `.sheet(isPresented: $showSourceSafari)`           |

### Requirements Coverage

| Requirement | Source Plan  | Description                                                        | Status    | Evidence                                                                                     |
|-------------|-------------|---------------------------------------------------------------------|-----------|----------------------------------------------------------------------------------------------|
| ATTR-01     | 29-01-PLAN  | Recipe detail view displays clickable source URL linking to original recipe | SATISFIED | End-to-end: sourceUrl flows GraphQL → Apollo → domain model → RecipeDetailView as tappable Button opening SFSafariViewController |

No orphaned requirements: REQUIREMENTS.md maps only ATTR-01 to Phase 29, and 29-01-PLAN.md claims exactly ATTR-01.

### Anti-Patterns Found

None. Scanned all 5 modified/created files for TODO/FIXME/PLACEHOLDER/stub patterns — clean.

### Human Verification Required

#### 1. Source link visible with real data

**Test:** Open a Spoonacular-sourced recipe in the app that has a sourceUrl. Scroll to the bottom of the recipe content.
**Expected:** A "View original at {sourceName}" button appears above the Spoonacular compliance footer, with an `arrow.up.right` icon.
**Why human:** Requires a live backend response with `sourceUrl` populated; cannot verify rendering from static code alone.

#### 2. In-app Safari sheet opens correctly

**Test:** Tap the source attribution link.
**Expected:** SFSafariViewController sheet appears in-app (not switching to the Safari app). The URL bar shows the original recipe URL.
**Why human:** Sheet presentation behavior and Safari controller lifecycle require device/simulator execution.

#### 3. Null sourceUrl collapses with no gap

**Test:** Open a recipe where `sourceUrl` is null or absent in the backend response.
**Expected:** No source attribution button appears; the compliance footer sits directly below the steps list with no blank space.
**Why human:** Dynamic data condition requires a real API response with null sourceUrl.

#### 4. Spoonacular footer opens in-app

**Test:** Tap "Powered by Spoonacular" in any recipe detail.
**Expected:** SFSafariViewController opens `https://spoonacular.com/food-api` in-app.
**Why human:** Requires runtime execution to confirm the button tap wires correctly.

### Gaps Summary

No gaps found. All six observable truths are verified against the actual codebase, all four key links are confirmed wired, ATTR-01 is satisfied end-to-end, and no anti-patterns were detected. Both task commits (`ca761ad`, `3c301f9`) exist in git history with the expected file changes.

---

_Verified: 2026-04-12_
_Verifier: Claude (gsd-verifier)_
