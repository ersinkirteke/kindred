---
phase: 09-monetization-voice-tiers
plan: 02
subsystem: MonetizationFeature
tags: [ads, admob, native-ads, banner-ads, tca]
dependency_graph:
  requires: [09-01-subscription-models]
  provides: [ad-client, ad-card-view, banner-ad-view]
  affects: []
tech_stack:
  added:
    - GoogleMobileAds SDK 11.0.0+
    - UIViewRepresentable pattern for AdMob integration
  patterns:
    - TCA @DependencyClient for AdClient
    - Coordinator pattern for GADAdLoaderDelegate
    - Adaptive banner sizing with dynamic height
key_files:
  created:
    - Kindred/Packages/MonetizationFeature/Sources/Ads/AdClient.swift
    - Kindred/Packages/MonetizationFeature/Sources/Models/AdModels.swift
    - Kindred/Packages/MonetizationFeature/Sources/Ads/AdCardView.swift
    - Kindred/Packages/MonetizationFeature/Sources/Ads/BannerAdView.swift
  modified:
    - Kindred/Packages/MonetizationFeature/Package.swift
decisions:
  - title: "Test ad unit IDs for development"
    rationale: "Used Google's test ad unit IDs to avoid policy violations during development. Must be replaced with production IDs before App Store submission."
  - title: "First-launch ad suppression via UserDefaults"
    rationale: "AdClient checks 'kindredFirstLaunchComplete' flag set by AppDelegate. First launch = no ads for good first impression."
  - title: "AdCardView matches recipe card styling"
    rationale: "16:9 media view, CardSurface background, rounded corners, shadow matching RecipeCardView for visual consistency."
  - title: "Coordinator pattern for ad loading"
    rationale: "GADAdLoaderDelegate requires object-based delegate, so Coordinator class handles callbacks and bridges to SwiftUI state."
metrics:
  duration_minutes: 6
  tasks_completed: 2
  files_created: 4
  files_modified: 1
  commits: 2
  completed_date: "2026-03-07"
---

# Phase 09 Plan 02: AdMob Integration Summary

AdMob advertising infrastructure with AdClient, AdCardView, and BannerAdView ready for integration into feed and recipe detail views.

## Overview

Created the foundational AdMob components within MonetizationFeature: AdClient for SDK initialization and first-launch suppression, AdCardView for native ads styled to match recipe cards, and BannerAdView for adaptive banners in recipe detail. All components use TCA patterns and UIViewRepresentable wrappers for Google Mobile Ads SDK.

## Tasks Completed

### Task 1: Create AdClient, AdModels, and update Package.swift

**Files:**
- `Kindred/Packages/MonetizationFeature/Package.swift` (modified)
- `Kindred/Packages/MonetizationFeature/Sources/Models/AdModels.swift` (created)
- `Kindred/Packages/MonetizationFeature/Sources/Ads/AdClient.swift` (created)

**What was done:**
- Added GoogleMobileAds SDK dependency (11.0.0+) to Package.swift
- Created AdModels.swift with test ad unit IDs (feedNative, detailBanner) and AdLoadState enum
- Implemented AdClient as TCA @DependencyClient with three closures:
  - `initializeSDK`: Wraps GADMobileAds.sharedInstance().start() with async/await
  - `shouldShowAds`: Returns false if "kindredFirstLaunchComplete" flag doesn't exist (first launch), true otherwise
  - `isFirstLaunchEver`: Checks if UserDefaults flag exists
- Added liveValue and testValue dependency implementations
- testValue returns false for shouldShowAds to suppress ads in tests

**Commit:** `8225fb7`

**Verification:** Package compiles with GoogleMobileAds dependency. AdClient provides first-launch suppression logic.

### Task 2: Create AdCardView and BannerAdView with UIViewRepresentable wrappers

**Files:**
- `Kindred/Packages/MonetizationFeature/Sources/Ads/AdCardView.swift` (created)
- `Kindred/Packages/MonetizationFeature/Sources/Ads/BannerAdView.swift` (created)

**What was done:**

**AdCardView:**
- SwiftUI view wrapping GADNativeAdView via NativeAdMediaView UIViewRepresentable
- Visual layout matching RecipeCardView:
  - 16:9 media view (280pt height) at top
  - "Sponsored" label in top-right corner with .kindredCaption() styling
  - Headline in .kindredHeading2(), body in .kindredBody()
  - "Remove ads with Pro" upsell link at bottom in .kindredAccent color
- AdLoaderCoordinator class implements GADAdLoaderDelegate + GADNativeAdDelegate
- Loading placeholder with shimmer skeleton matching card dimensions (340x400)
- Checks adClient.shouldShowAds() before loading ad
- Accessibility label: "Sponsored content. Remove ads with Pro subscription."

**BannerAdView:**
- UIViewRepresentable wrapping GADBannerView with adaptive sizing
- Uses GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth for responsive layout
- Coordinator class implements GADBannerViewDelegate
- Updates @State bannerHeight dynamically after ad loads
- Collapses to zero height (EmptyView) when no ad loaded or ads suppressed
- Background: .kindredCardSurface to blend with recipe detail
- Accessibility label: "Advertisement"

**Commit:** `6f9c337`

**Verification:** Both views compile with UIViewRepresentable pattern. AdCardView styled to match recipe cards. BannerAdView collapses when ad fails to load.

## Deviations from Plan

None - plan executed exactly as written.

## Key Integration Points

### For Plan 03 (Feed Integration):
- `AdCardView` ready to be injected into SwipeCardStack every 5 recipe cards
- `onUpgradeTapped` callback triggers paywall presentation
- Uses existing DesignSystem tokens and CardSurface pattern

### For Plan 03 (Recipe Detail Integration):
- `BannerAdView` ready to be placed below ingredients section
- Dynamic height prevents layout jump
- Hides when voice narration is active (Plan 03 handles visibility logic)

### For Plan 04 (App Launch):
- `AdClient.initializeSDK()` should be called in AppDelegate.didFinishLaunchingWithOptions
- AppDelegate must set "kindredFirstLaunchComplete" flag after first launch completes

## Technical Notes

### First-Launch Suppression:
- AdClient checks for UserDefaults key "kindredFirstLaunchComplete"
- Flag is SET by AppDelegate in Plan 04 Task 2 at end of didFinishLaunchingWithOptions
- On first launch: flag doesn't exist → shouldShowAds returns false → no ads shown
- On subsequent launches: flag exists → shouldShowAds returns true → ads appear

### Ad Unit IDs:
- Currently using Google's test ad unit IDs
- **CRITICAL:** Replace with production ad unit IDs from AdMob console before App Store submission
- Test IDs clearly commented in AdModels.swift

### UIViewRepresentable Pattern:
- AdCardView uses NativeAdMediaView wrapper for GADMediaView
- BannerAdView wraps GADBannerView directly
- Both use Coordinator pattern for delegate callbacks
- Associated objects retain coordinators to prevent deallocation

### Styling Consistency:
- AdCardView matches RecipeCardView dimensions (340x400)
- Uses same corner radius (16pt), shadow (12pt radius), and stroke
- DesignSystem tokens ensure visual consistency (.kindredCardSurface, .kindredAccent, etc.)

## Next Steps

**Plan 03 (Feed + Detail Ad Integration):**
1. Inject AdCardView into SwipeCardStack every 5 recipe cards
2. Connect AdCardView.onUpgradeTapped to PaywallReducer
3. Add BannerAdView to RecipeDetailView below ingredients
4. Implement banner hiding logic when voice playback active

**Plan 04 (App Launch + Ad Initialization):**
1. Call AdClient.initializeSDK() in AppDelegate
2. Set "kindredFirstLaunchComplete" flag after first launch
3. Register MonetizationFeature in app target dependencies

## Self-Check: PASSED

**Created files exist:**
```
FOUND: Kindred/Packages/MonetizationFeature/Sources/Ads/AdClient.swift
FOUND: Kindred/Packages/MonetizationFeature/Sources/Models/AdModels.swift
FOUND: Kindred/Packages/MonetizationFeature/Sources/Ads/AdCardView.swift
FOUND: Kindred/Packages/MonetizationFeature/Sources/Ads/BannerAdView.swift
```

**Commits exist:**
```
FOUND: 8225fb7 (Task 1)
FOUND: 6f9c337 (Task 2)
```

**Modified files verified:**
```
FOUND: Kindred/Packages/MonetizationFeature/Package.swift (GoogleMobileAds dependency added)
```
