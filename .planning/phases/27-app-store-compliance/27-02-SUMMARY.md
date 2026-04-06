---
phase: 27-app-store-compliance
plan: 02
subsystem: feed-feature
tags: [compliance, localization, attribution, spoonacular]
dependency_graph:
  requires: []
  provides: [nutrition-disclaimer, spoonacular-attribution]
  affects: [recipe-detail-ui]
tech_stack:
  added: []
  patterns: [swiftui-link, localized-strings, accessibility]
key_files:
  created: []
  modified:
    - Kindred/Sources/Resources/Localizable.xcstrings
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
decisions:
  - Use SwiftUI Link instead of openURL environment for simpler implementation
  - Use kindredTextSecondary (kindredTextTertiary does not exist in DesignSystem)
  - Follow Kindred's convention of using full English sentence as localization key
  - Force-unwrap hard-coded URL (acceptable for compile-time constant)
metrics:
  duration: 6
  completed_date: "2026-04-06"
---

# Phase 27 Plan 02: Spoonacular Attribution Summary

**One-liner:** Added nutrition disclaimer and "Powered by Spoonacular" attribution footer to recipe detail view with full localization (en + tr) and accessibility support.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add nutrition disclaimer + powered by Spoonacular strings to Localizable.xcstrings | 4c371d3 | Localizable.xcstrings |
| 2 | Add compliance footer to RecipeDetailView.swift | 93de193 | RecipeDetailView.swift |

---

## Changes Made

### Task 1: Localizable.xcstrings

**Added three new string entries** (en + tr translations):

1. **Nutrition disclaimer:**
   - English: "Nutrition estimates from Spoonacular. Not for medical use."
   - Turkish: "Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz."

2. **Attribution link:**
   - English: "Powered by Spoonacular"
   - Turkish: "Spoonacular tarafından desteklenmektedir"

3. **Accessibility label:**
   - English: "Opens Spoonacular website in browser"
   - Turkish: "Spoonacular web sitesini tarayıcıda açar"

**Verification:**
```bash
$ python3 -c "import json; json.load(open('Kindred/Sources/Resources/Localizable.xcstrings'))"
✓ JSON is valid
✓ Found English disclaimer
✓ Found English attribution
✓ Found Turkish disclaimer
✓ Found Turkish attribution
```

---

### Task 2: RecipeDetailView.swift

**Added compliance footer** after StepTimelineView at line 190.

**Footer structure:**
- VStack with nutrition disclaimer text
- Link to https://spoonacular.com/food-api with "Powered by Spoonacular" text + arrow icon
- Full accessibility support (label + .isLink trait)

**Code diff (lines 191-212 added):**

```swift
            StepTimelineView(steps: recipe.steps)

            // Compliance footer: nutrition disclaimer + Spoonacular attribution (Phase 27 STORE-03)
            // Uses kindredTextSecondary because kindredTextTertiary does not exist in DesignSystem.
            VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                Text(String(localized: "Nutrition estimates from Spoonacular. Not for medical use.", bundle: .main))
                    .font(.kindredCaptionScaled(size: captionSize))
                    .foregroundStyle(.kindredTextSecondary)

                Link(destination: URL(string: "https://spoonacular.com/food-api")!) {
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
            .padding(.top, KindredSpacing.lg)
            .padding(.bottom, KindredSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
```

**Verification:**
```bash
✓ Found disclaimer string in RecipeDetailView.swift
✓ Found Spoonacular URL in RecipeDetailView.swift
✓ Found attribution text in RecipeDetailView.swift
✓ No kindredTextTertiary usage (doesn't exist in DesignSystem)
✓ Uses kindredTextSecondary
✓ Uses kindredCaptionScaled(size: captionSize) reusing existing @ScaledMetric
```

**Design decisions:**
- Used `.kindredTextSecondary` because `.kindredTextTertiary` does not exist in DesignSystem
- Reused existing `captionSize` @ScaledMetric (no new declaration needed)
- Used SwiftUI `Link(destination:)` instead of `openURL` environment (simpler, localization-friendly)
- Force-unwrapped URL (acceptable for compile-time constant)
- Used SF Symbol `arrow.up.right` for external link indication

---

## Deviations from Plan

None - plan executed exactly as written.

---

## STORE-03 Compliance Coverage

**Before this plan:**
- No Spoonacular attribution visible on recipe detail
- No nutrition disclaimer for health data

**After this plan:**
- ✅ Spoonacular attribution footer visible on every recipe detail
- ✅ Nutrition disclaimer stating estimates are not for medical use
- ✅ Tappable link to https://spoonacular.com/food-api
- ✅ Full localization support (English + Turkish)
- ✅ Full accessibility support (VoiceOver reads link destination)

**Note for Plan 27-04:** Detail screenshot must scroll to show this footer in frame for App Store review.

---

## Self-Check: PASSED

**Files created:**
```bash
✓ FOUND: .planning/phases/27-app-store-compliance/27-02-SUMMARY.md
```

**Files modified:**
```bash
✓ FOUND: Kindred/Sources/Resources/Localizable.xcstrings
✓ FOUND: Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
```

**Commits:**
```bash
✓ FOUND: 4c371d3 (Task 1 - Localizable.xcstrings)
✓ FOUND: 93de193 (Task 2 - RecipeDetailView.swift)
```

**Content verification:**
```bash
$ grep "Nutrition estimates from Spoonacular" Kindred/Sources/Resources/Localizable.xcstrings
✓ Found in Localizable.xcstrings

$ grep "Nutrition estimates from Spoonacular" Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
✓ Found in RecipeDetailView.swift

$ git log --oneline -2
93de193 feat(27-02): add Spoonacular compliance footer to recipe detail
4c371d3 feat(27-02): add Spoonacular compliance strings
```

---

## Next Steps

**Plan 27-03:** Update Privacy Policy URL and content for Spoonacular + ElevenLabs disclosure

**Plan 27-04:** Refresh App Store screenshots to show compliance footer on recipe detail

**Visual confirmation (deferred to Plan 27-04):**
- Footer visible at bottom of recipe detail scroll view (after instructions)
- Tapping link opens Safari at https://spoonacular.com/food-api
- VoiceOver reads accessibility label when focusing link
- Turkish locale shows Turkish translations
