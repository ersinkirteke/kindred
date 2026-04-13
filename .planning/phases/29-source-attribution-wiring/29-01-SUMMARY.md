---
phase: 29-source-attribution-wiring
plan: 01
subsystem: ui
tags: [spoonacular, graphql, apollo, safariview, localization, swiftui, tca]

# Dependency graph
requires:
  - phase: 23-spoonacular-backend-integration
    provides: sourceUrl and sourceName fields in backend GraphQL schema
provides:
  - sourceUrl/sourceName fields in RecipeDetailQuery GraphQL operation
  - Apollo-generated RecipeDetailQuery.graphql.swift with sourceUrl/sourceName accessors
  - RecipeDetail domain model with sourceUrl/sourceName properties
  - SafariView UIViewControllerRepresentable in FeedFeature
  - Source attribution link in RecipeDetailView above compliance footer
  - Spoonacular footer link migrated from SwiftUI Link to SFSafariViewController
  - EN + TR localization keys for attribution text and accessibility labels
affects: [30-free-tier-tts, 31-search-filter, 32-polish-release]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - SFSafariViewController presentation via @State + .sheet(isPresented:) pattern used for in-app browser links
    - Apollo codegen via pre-built binary extracted from .build/checkouts/apollo-ios/CLI/apollo-ios-cli.tar.gz

key-files:
  created:
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/SafariView.swift
  modified:
    - Kindred/Packages/NetworkClient/Sources/GraphQL/RecipeQueries.graphql
    - Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
    - Kindred/Sources/Resources/Localizable.xcstrings

key-decisions:
  - "Used pre-built apollo-ios-cli binary from .build/checkouts/apollo-ios/CLI/apollo-ios-cli.tar.gz (not PATH-installed) to run codegen"
  - "SafariView is internal (no public modifier) — scoped to FeedFeature only, not exported"
  - "Source link renders only when sourceUrl is a valid non-empty URL — malformed/null collapses cleanly with no gap"
  - "Spoonacular Link migrated to Button+SafariView to keep all external links in-app (consistent UX)"

patterns-established:
  - "In-app browser pattern: @State resolvedSourceURL + @State showSafari -> .sheet(isPresented:) -> SafariView(url:)"

requirements-completed: [ATTR-01]

# Metrics
duration: 35min
completed: 2026-04-13
---

# Phase 29 Plan 01: Source Attribution Wiring Summary

**sourceUrl/sourceName wired from Spoonacular GraphQL through Apollo codegen into RecipeDetailView as SFSafariViewController-backed in-app link, satisfying Spoonacular ToS attribution requirement**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-13T06:00:00Z
- **Completed:** 2026-04-13T06:36:10Z
- **Tasks:** 2
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments
- Added sourceUrl/sourceName to RecipeDetail GraphQL query and ran Apollo codegen to regenerate type-safe Swift accessors
- Added sourceUrl/sourceName properties to RecipeDetail domain model with from(graphQL:) mapping
- Created SafariView (UIViewControllerRepresentable) in FeedFeature/RecipeDetail
- Rendered tappable "View original at {sourceName}" link in RecipeDetailView above compliance footer, with null/empty/malformed URL guard
- Migrated "Powered by Spoonacular" SwiftUI Link to Button opening SFSafariViewController (consistent in-app browser UX)
- Added EN + TR localization keys for source attribution text and all accessibility labels
- Full build verified: BUILD SUCCEEDED on iOS Simulator

## Task Commits

Each task was committed atomically:

1. **Task 1: Add sourceUrl/sourceName to GraphQL query and domain model** - `ca761ad` (feat)
2. **Task 2: Render source attribution link with in-app Safari and localization** - `3c301f9` (feat)

## Files Created/Modified
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/SafariView.swift` - UIViewControllerRepresentable wrapping SFSafariViewController
- `Kindred/Packages/NetworkClient/Sources/GraphQL/RecipeQueries.graphql` - Added sourceUrl, sourceName to RecipeDetail selection set
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift` - Apollo-regenerated with sourceUrl/sourceName accessors
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift` - RecipeDetail struct + init + from(graphQL:) mapping for sourceUrl/sourceName
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift` - Source attribution link, Spoonacular link migration, sheet + state
- `Kindred/Sources/Resources/Localizable.xcstrings` - 5 new EN+TR localization keys for attribution text and accessibility labels

## Decisions Made
- Used the pre-built apollo-ios-cli binary from the extracted tar.gz in `.build/checkouts/apollo-ios/CLI/` since the binary isn't installed in PATH. This avoids a full `swift package --allow-writing-to-package-directory apollo-cli-install` build (~3min).
- SafariView is `internal` (no `public`), scoped to FeedFeature — not a shared package component.
- Spoonacular footer Link migrated to Button+SafariView to keep all external links in-app for consistent UX.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `apollo-ios-cli` not found in PATH. Resolved by extracting the pre-built binary bundled in `.build/checkouts/apollo-ios/CLI/apollo-ios-cli.tar.gz` and running it from `/tmp/`.
- iPhone 16 Pro simulator not available in this environment. Used available iPhone 17 Pro simulator (id: C0EF3780) for build verification — same result.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ATTR-01 requirement satisfied: source attribution wired end-to-end
- RecipeDetail domain model now carries sourceUrl/sourceName; any future feature can access them
- Phase 30 (Free-Tier TTS) can proceed independently — no dependency on this plan's outputs
- Phase 31 (Search + Filter) can proceed independently

---
*Phase: 29-source-attribution-wiring*
*Completed: 2026-04-13*
