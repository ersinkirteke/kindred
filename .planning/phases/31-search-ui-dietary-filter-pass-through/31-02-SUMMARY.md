---
phase: 31-search-ui-dietary-filter-pass-through
plan: 02
subsystem: ui
tags: [swiftui, search, feed, ux, kingfisher]

requires:
  - phase: 31-search-ui-dietary-filter-pass-through
    plan: 01
    provides: FeedReducer search state, actions, and debounce logic

provides:
  - SearchResultCardView with hero image, metadata, dietary tags, zoom transition
  - SearchResultsView with VStack scroll list and pagination trigger
  - FeedView search bar with debounced auto-search (no duplicate on keyboard submit)
  - Browse/search mode switching with animation
  - DietaryChipBar resultCountOverride for server-side result count
  - Search error, empty, quota, offline states in searchModeContentView
  - 13 localization keys (en + tr) for search UI strings

affects:
  - FeedView.swift (search bar, mode switching, layout restructure)
  - SearchResultsView.swift (new)
  - SearchResultCardView.swift (new)
  - DietaryChipBar.swift (resultCountOverride param, spacing)
  - Localizable.xcstrings (13 new keys)

key-files:
  created:
    - Kindred/Packages/FeedFeature/Sources/Feed/SearchResultCardView.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/SearchResultsView.swift
  modified:
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedView.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/DietaryChipBar.swift
    - Kindred/Sources/Resources/Localizable.xcstrings
---

## What was built

Complete search UI for recipe discovery in the Kindred feed.

### Search Bar
- Sticky search bar above dietary chip bar with magnifying glass icon, text field, and clear (X) button
- Auto-search triggers after 3+ characters with 300ms debounce
- Keyboard submit button shows "Done" and just dismisses keyboard (no duplicate search)
- Duplicate query detection: if same query already has results, skip re-search

### Search Result Cards
- Full-width cards with 200pt hero image, recipe name, description (2 lines), metadata row (time, calories, loves), and dietary tag pill badges
- Kingfisher image loading with failure tracking — cards with broken images auto-hide
- Recipes without imageUrl filtered out at the reducer level
- matchedTransitionSource for zoom navigation transition on iOS 18+

### Search Results List
- VStack inside ScrollView with `.scrollBounceBehavior(.basedOnSize)` — prevents bounce when content is shorter than screen
- Pagination trigger when 3rd-from-last card appears
- Bottom spinner during pagination load
- "You've seen all results" footer when no more pages

### Mode Switching
- `FeedMode.browse` shows popular recipes card stack (unchanged)
- `FeedMode.search` shows search results list
- Smooth `.easeInOut(0.2)` animation on transition
- Card count indicator moved inline with heading in browse mode
- Clear search restores browse mode with original cards

### Error States
- Separate `searchError` state (not shared `error`) — search failures stay scoped to search UI, don't replace the entire feed
- Search error shows actual error message with "Browse Instead" button
- Offline state: "Search Unavailable" with wifi.slash icon
- Quota exhausted: warning with "Browse Instead" button
- Empty results: "No Recipes Found" with optional "Clear Filters" button when chips active

### Localization
- 13 new keys added for both en and tr locales
- Result count text: "X recipes found" / "X tarif bulundu"

## Post-implementation fixes

Several issues found during device verification and fixed iteratively:

1. **Search error hijacking feed** — `searchResultsLoaded(.failure)` was setting shared `state.error`, replacing entire feed with network error screen. Fixed: separate `searchError` field.
2. **Browse mode not restoring** — `clearSearch` didn't reset error state. Fixed: clears `searchError`.
3. **Pagination append/replace bug** — used response cursor to detect pagination; last page (null cursor) would replace all results. Fixed: check `state.searchEndCursor` instead.
4. **Double search on keyboard submit** — binding re-fired same query. Fixed: skip when query unchanged and results exist.
5. **Broken image cards** — recipes with URLs but failed CDN images showed stuck spinners. Fixed: `@State imageLoadFailed` hides card on Kingfisher failure.
6. **White gap / bounce** — `LazyVStack` estimated content size confused `.scrollBounceBehavior`. Fixed: switched to `VStack`.
7. **Backend null arrays** — GraphQL sends `null` not `undefined` for optional arrays; `cuisines.length` threw. Fixed: `?? []` fallback deployed to production.

## Self-Check: PASSED
- [x] Search bar visible above chips
- [x] 3+ chars triggers search with spinner
- [x] Results display as scrollable list
- [x] X button clears and restores browse
- [x] Tapping result opens detail view
- [x] Empty state with Clear Filters
- [x] Result count below chips
- [x] No duplicate search on keyboard submit
- [x] Cards without images hidden
