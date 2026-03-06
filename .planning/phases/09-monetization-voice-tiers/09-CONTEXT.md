# Phase 9: Monetization & Voice Tiers - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Free and Pro tiers operational with App Store billing and voice slot enforcement. Free tier displays AdMob ads in non-intrusive placements (between recipe cards, not during voice playback). Pro tier ($9.99/mo) removes all ads and unlocks unlimited voice slots. Subscription managed via StoreKit 2 with JWS verification syncing to backend.

</domain>

<decisions>
## Implementation Decisions

### Ad Placements
- Native AdMob ads inserted between swipe cards in the feed, every 5 recipe cards
- Ad card styled to match recipe card look (same rounded corners, similar layout) with "Sponsored" label
- Ad card is swipeable like recipe cards — user swipes left to dismiss
- Each ad card includes a subtle "Remove ads with Pro" upsell link at the bottom
- Additional banner ad in recipe detail view, positioned below ingredients and above step timeline
- Recipe detail banner hides when voice narration is active (not during playback)
- No ads on the very first app launch ever (tracked via UserDefaults/Keychain, resets only on reinstall)
- Guest users (not signed in) see ads (after first session rule)
- Ads appear in feed + recipe detail only — profile, settings, voice picker stay ad-free

### Paywall & Upgrade Flow
- Paywall triggered only at voice slot limit (when free user tries to create 2nd voice profile)
- Paywall presented as bottom sheet overlay sliding up over the voice picker
- Paywall highlights two main perks: ad-free experience + unlimited voice profiles
- Subtle "Restore Purchases" text link below the subscribe button (Apple requirement)
- No soft upsells or banners elsewhere — paywall only appears at the moment of need
- Ad card upsell link ("Remove ads with Pro") is the only other touchpoint besides the voice limit gate

### Voice Slot Enforcement
- Free tier: 1 voice slot total (any voice type — own clone or family member)
- When free user has 1 voice, "Create Voice Profile" button in VoicePickerView replaced with "Upgrade to Pro for more voices" CTA
- Downgrade handling: users who cancel Pro keep ALL existing voice profiles usable, just can't create new ones
- Enforcement on both client-side (UI blocks creation) AND server-side (API rejects if limit exceeded)

### Subscription Status UI
- New subscription section in ProfileView (alongside existing CulinaryDNA and DietaryPreferences sections)
- Styled card showing: plan name (Free/Pro), price, renewal date, and "Manage Subscription" link
- "Manage Subscription" opens iOS Settings > Subscriptions deep link (Apple-standard)
- Small "PRO" pill badge next to user's name in profile for subscribed users
- Free users see an upgrade CTA card with benefits summary and subscribe button in the profile section
- Silent StoreKit 2 entitlement check on app launch — no visible loading, seamless background verification
- Pro features maintained during Apple's billing retry grace period (up to 60 days)

### Claude's Discretion
- Exact native ad card layout and styling details
- AdMob SDK integration approach and ad unit configuration
- StoreKit 2 transaction listener implementation details
- JWS verification flow between app and backend
- Subscription state persistence mechanism (Keychain vs UserDefaults vs backend)
- Banner ad sizing in recipe detail view
- Animation/transition for paywall bottom sheet
- Error handling for failed purchases or network issues during subscription

</decisions>

<specifics>
## Specific Ideas

- Ad cards should feel like natural content in the swipe stack — same gesture to dismiss, similar visual weight
- The paywall should be contextual: appears right where the user hits the limit (voice picker), not a random popup
- "Remove ads with Pro" link on ad cards creates a gentle awareness without being pushy
- First session ad-free creates a good first impression before monetization kicks in

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VoicePickerView`: Shows voice profiles with "Create Voice Profile" button — needs conditional replacement with upgrade CTA for free users at limit
- `VoiceCardView`: Card component for individual voice profiles — pattern reusable for subscription card styling
- `RecipeCardView`: Swipe card in feed — ad card should match this visual pattern
- `SwipeCardStack`: Manages card stack — needs to support interleaving ad cards every 5 recipes
- `DesignSystem`: `.kindredAccent`, `.kindredCardSurface`, `.kindredHeading2()`, etc. — all UI must use these tokens
- `ProfileView` + `ProfileReducer`: Existing profile with sections — new subscription section plugs in here

### Established Patterns
- TCA (ComposableArchitecture) for all state management — subscription state will be a new reducer/client
- `@Dependency` pattern for external services — StoreKit 2 and AdMob should be TCA dependencies
- Kingfisher for image loading — used in voice cards and recipe cards
- Card-based UI with rounded corners, shadows — established visual language

### Integration Points
- `FeedReducer` / `SwipeCardStack`: Ad card injection into the feed card stack
- `RecipeDetailView`: Banner ad insertion between `IngredientChecklistView` and `StepTimelineView`
- `VoicePlaybackReducer`: Needs to signal when narration is active (for hiding ads)
- `VoicePickerView`: Voice slot limit check and CTA replacement
- `ProfileReducer` / `ProfileView`: New subscription section
- `AppDelegate`: App launch subscription status check

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-monetization-voice-tiers*
*Context gathered: 2026-03-06*
