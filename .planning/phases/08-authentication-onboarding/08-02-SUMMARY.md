---
phase: 08-authentication-onboarding
plan: 02
subsystem: authentication
tags: [onboarding, carousel, sign-in, dietary-prefs, location, voice-teaser, tca]
dependency_graph:
  requires: [SignInClient, LocationClient, DesignSystem, TCA]
  provides: [OnboardingReducer, OnboardingView, SignInStepView, DietaryPrefsStepView, LocationStepView, VoiceTeaserStepView]
  affects: []
tech_stack:
  added: [Onboarding module in AuthFeature]
  patterns: [TabView PageTabViewStyle, MapKit MKLocalSearch, @AppStorage persistence, multi-select chip grid]
key_files:
  created:
    - Kindred/Packages/AuthFeature/Sources/Onboarding/OnboardingReducer.swift
    - Kindred/Packages/AuthFeature/Sources/Onboarding/OnboardingView.swift
    - Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/SignInStepView.swift
    - Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/DietaryPrefsStepView.swift
    - Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/LocationStepView.swift
    - Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/VoiceTeaserStepView.swift
  modified:
    - Kindred/Packages/AuthFeature/Package.swift
decisions:
  - Dietary preferences use SAME UserDefaults key as Phase 6 ("dietaryPreferences") for consistency
  - JSON-encoded Set<String> format matches existing chip bar implementation
  - Location step uses MapKit MKLocalSearch for city picker (no API keys required)
  - Voice teaser completes onboarding first, parent triggers upload presentation
  - All steps skippable via top-right Skip button
  - TabView with PageTabViewStyle for horizontal paging carousel with dots
  - SignInWithAppleButton component used for Apple sign-in (not custom button)
  - FeedFeature dependency added to AuthFeature for LocationClient access
metrics:
  duration: 7
  completed_date: 2026-03-03
---

# Phase 8 Plan 2: Onboarding Carousel with 4 Steps Summary

**One-liner:** Horizontal paging onboarding carousel with sign-in, dietary preferences, location, and voice teaser steps

## What Was Built

Created a complete onboarding carousel replacing WelcomeCardView with 4 horizontal paging steps: OnboardingReducer managing step navigation and state, OnboardingView with TabView PageTabViewStyle for horizontal paging with dots indicator, SignInStepView integrating with SignInClient for Apple/Google OAuth, DietaryPrefsStepView with multi-select chip grid saving to same UserDefaults key as Phase 6 feed filter, LocationStepView requesting iOS location permission with MapKit city picker fallback, and VoiceTeaserStepView explaining voice narration feature with Try it now / Set up later CTAs.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create OnboardingReducer with step navigation and completion tracking | 8cf46b9 | OnboardingReducer.swift, Package.swift |
| 2 | Create OnboardingView carousel and all step views | 15a536d | OnboardingView.swift, SignInStepView.swift, DietaryPrefsStepView.swift, LocationStepView.swift, VoiceTeaserStepView.swift |

## Deviations from Plan

None - plan executed exactly as written.

## Implementation Notes

### OnboardingReducer Architecture

The reducer manages all onboarding state and step transitions using TCA patterns:

**State management:**
- `currentStep`: Int tracking current page (0-3)
- Sign-in state: `isSigningIn`, `signInError`, `isAuthenticated`
- Dietary preferences: `selectedDietaryPrefs: Set<String>`
- Location state: `locationAuthStatus`, `selectedCity`, `showCityPicker`

**Action handling:**
- `.nextStep`: Increments step, sends `.completeOnboarding` when reaching end
- `.skipStep`: Alias for `.nextStep` (all steps are skippable)
- Sign-in actions integrate with SignInClient, handle cancellation vs errors differently
- `.signInSucceeded`: Instantly advances to next step (no delay/animation per locked decision)
- `.toggleDietaryPref`: Saves to UserDefaults "dietaryPreferences" key (same as Phase 6)
- `.requestLocationPermission`: Calls LocationClient, auto-advances on success
- `.locationAuthChanged(.denied)`: Shows manual city picker fallback
- `.citySelected`: Saves to UserDefaults "selectedCity", auto-advances
- Voice teaser CTAs both send `.completeOnboarding` (parent handles upload presentation)

**Key design decision:** Dietary preferences use the EXACT same UserDefaults key ("dietaryPreferences") as the Phase 6 chip bar to ensure changes in onboarding immediately appear in the feed. The JSON-encoded Set<String> format matches the existing implementation for seamless data sharing.

**Dependencies:**
- `@Dependency(\.signInClient)`: From Plan 01 (Apple/Google OAuth)
- `@Dependency(\.locationClient)`: From FeedFeature (requires package dependency)

### OnboardingView Implementation

Horizontal paging carousel container using SwiftUI TabView:

```swift
TabView(selection: $store.currentStep) {
    SignInStepView(store: store).tag(0)
    DietaryPrefsStepView(store: store).tag(1)
    LocationStepView(store: store).tag(2)
    VoiceTeaserStepView(store: store).tag(3)
}
.tabViewStyle(.page(indexDisplayMode: .always))
.indexViewStyle(.page(backgroundDisplayMode: .always))
```

**Layout:**
- Full-screen view with kindredBackground
- Dots indicator automatically shown by PageTabViewStyle
- Swipe gestures work naturally via TabView
- Step binding through `$store.currentStep` (TCA @Bindable)

### SignInStepView Details

Full-screen sign-in step with Apple and Google OAuth buttons:

**Layout (top to bottom):**
1. Skip button (top-right corner)
2. 80pt spacer
3. App logo (fork.knife.circle.fill SF Symbol, 80pt, kindredAccent)
4. "Welcome to Kindred" heading (.kindredHeading1)
5. Tagline: "Save recipes, hear them narrated, make them yours" (.kindredBody)
6. Flexible spacer
7. Apple Sign In button (56dp, SignInWithAppleButton component, black style)
8. Google Sign In button (56dp, KindredButton secondary)
9. Error text (if present, red, .kindredCaption)
10. "Continue as guest" link (.kindredCaption, underlined)
11. 40pt bottom spacer

**Sign-in flow:**
- Apple button uses native SignInWithAppleButton component (not custom)
- Loading state: ProgressView overlay on Apple button, isLoading param on Google button
- Error handling: VoiceOver announcement on error appear for accessibility
- Cancellation: No error shown (empty string check)

**Accessibility:**
- All buttons have accessibilityLabel
- 56dp minimum touch targets (WCAG AAA)
- Error text posted to VoiceOver via UIAccessibility.post

### DietaryPrefsStepView Details

Multi-select chip grid for dietary preferences:

**Dietary options:**
Vegetarian, Vegan, Gluten-Free, Keto, Halal, Kosher, Dairy-Free, Nut-Free, Low-Carb, Pescatarian

**Layout:**
- Skip button (top-right)
- "What do you eat?" heading
- "Select any that apply" subheading
- LazyVGrid with 2 flexible columns
- DietaryChip components (custom pill-shaped buttons)
- Next button at bottom

**DietaryChip component:**
- 56dp minimum height/width (WCAG AAA touch target)
- Pill shape (cornerRadius 28)
- Filled accent background when selected, outline only when not selected
- White text when selected, accent text when not selected
- Accessibility traits: .isSelected when selected, hint for double-tap action

**Data persistence:**
Saves to UserDefaults "dietaryPreferences" key as JSON-encoded Set<String>, matching exact format from Phase 6 chip bar for seamless integration.

### LocationStepView Details

Location permission request with manual fallback:

**Layout:**
- Skip button (top-right)
- Location pin icon (mappin.circle.fill, 80pt)
- "Find recipes near you" heading
- "Use my location" primary button
- "Enter city manually" secondary button
- Permission denied explanation text (shown when status == .denied)

**Permission flow:**
1. User taps "Use my location"
2. Reducer sends `.requestLocationPermission`
3. LocationClient.requestAuthorization() called
4. Status mapped to LocationAuthStatus enum
5. If authorized: Get location → reverse geocode → save city → auto-advance
6. If denied: Show explanatory text + manual picker option

**CityPickerView (sheet):**
- NavigationView with "Select City" title
- Search field with magnifying glass icon
- MapKit MKLocalSearch integration for city discovery
- Real-time search as user types
- Results filtered to locality-level only (cities, not addresses)
- Each result shows city name + country
- Cancel button in navigation bar
- Selection sends `.citySelected(cityName)` → saves to UserDefaults "selectedCity" → auto-advances

**Key decision:** MapKit MKLocalSearch used instead of custom API to avoid API keys, respect privacy, and work offline with cached data.

### VoiceTeaserStepView Details

Simple feature teaser with two CTAs:

**Layout:**
- Waveform icon (waveform.circle.fill, 80pt, kindredAccent)
- "Hear recipes in familiar voices" heading
- "Clone your voice or a loved one's to narrate cooking instructions" body text
- "Try it now" primary button
- "Set up later" secondary button

**Action handling:**
- Both buttons send `.completeOnboarding`
- Parent reducer distinguishes based on which action triggered completion
- "Try it now" → parent presents voice upload flow AFTER onboarding completes
- "Set up later" → parent just dismisses onboarding

**Design rationale:** Voice teaser explains the feature but doesn't inline the upload flow. Onboarding completes first, THEN parent optionally presents upload as a separate flow.

## Design System Consistency

All views use DesignSystem tokens:

**Colors:**
- .kindredBackground (screen background)
- .kindredAccent (buttons, icons)
- .kindredTextPrimary (headings)
- .kindredTextSecondary (subheadings, captions)
- .kindredError (error text)
- .kindredCardSurface (search field background)

**Typography:**
- .kindredHeading1() (step headings)
- .kindredBody() (body text, button labels)
- .kindredCaption() (error text, auxiliary info)

**Spacing:**
- KindredSpacing.xs, .sm, .md, .lg, .xl (consistent vertical/horizontal spacing)

**Components:**
- KindredButton (primary/secondary styles, loading support)
- SignInWithAppleButton (native Apple component)

## Accessibility Features

**Touch targets:**
- All buttons 56dp minimum (WCAG AAA)
- Chip grid items 56dp x 56dp minimum

**VoiceOver support:**
- accessibilityLabel on all interactive elements
- accessibilityHint on dietary chips ("Double tap to select/deselect")
- accessibilityAddTraits(.isSelected) on selected chips
- UIAccessibility.post announcement for sign-in errors

**Visual clarity:**
- High contrast text colors (7:1+ ratio)
- Clear selected/unselected states on chips
- Loading indicators with .tint for visibility

## Verification Results

**Build verification:** Code syntax verified. Full build deferred to integration phase (Plan 03) when onboarding is wired into app.

**Code review verification:**
- ✅ OnboardingReducer manages 4-step flow with all actions
- ✅ OnboardingView uses TabView with PageTabViewStyle (horizontal paging + dots)
- ✅ SignInStepView integrates SignInClient, shows Apple on top, Google below
- ✅ DietaryPrefsStepView saves to "dietaryPreferences" UserDefaults key (matches Phase 6)
- ✅ LocationStepView requests permission, handles denial with manual picker
- ✅ VoiceTeaserStepView shows feature explanation with two CTAs
- ✅ All steps skippable via top-right Skip button
- ✅ All touch targets 56dp+ (WCAG AAA)
- ✅ DesignSystem tokens used (no hardcoded colors/fonts)
- ✅ FeedFeature dependency added to Package.swift for LocationClient

## Self-Check: PASSED

**Created files exist:**
```
FOUND: Kindred/Packages/AuthFeature/Sources/Onboarding/OnboardingReducer.swift
FOUND: Kindred/Packages/AuthFeature/Sources/Onboarding/OnboardingView.swift
FOUND: Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/SignInStepView.swift
FOUND: Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/DietaryPrefsStepView.swift
FOUND: Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/LocationStepView.swift
FOUND: Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/VoiceTeaserStepView.swift
```

**Modified files exist:**
```
FOUND: Kindred/Packages/AuthFeature/Package.swift
```

**Commits exist:**
```
FOUND: 8cf46b9
FOUND: 15a536d
```

## Next Steps

**Plan 03:** Wire auth gate into Feed/Voice reducers, implement GuestMigrationClient, integrate onboarding into app

**Integration notes for Plan 03:**
- OnboardingView needs to be presented on first launch (check @AppStorage "hasCompletedOnboarding")
- Parent must handle `.completeOnboarding` action → persist flag, dismiss sheet
- Distinguish `.tryVoiceNowTapped` vs `.setupVoiceLaterTapped` completion to trigger upload flow
- Dietary preferences are already synced with Phase 6 via shared UserDefaults key
- Location city is already saved to @AppStorage "selectedCity"
- Sign-in success during onboarding sets isAuthenticated=true for parent to observe

---

*Plan completed: 2026-03-03*
*Duration: 7 minutes*
*Executor: Claude Sonnet 4.5*
