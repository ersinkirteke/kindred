# Phase 22: TestFlight Beta & Submission Prep - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Get the app tested, validated, and ready for App Store submission. This includes creating App Store screenshots and metadata, completing TestFlight internal and external beta testing, and resolving all critical bugs. The app ships as version 1.0.0.

</domain>

<decisions>
## Implementation Decisions

### Screenshot Content & Composition
- 5 screenshots, feature highlights approach (one screenshot per killer feature)
- Order: Voice narration -> Recipe feed -> Pantry scan -> Dietary filters -> Recipe detail
- Voice narration screenshot: Recipe detail view with mini player at bottom (shows integration in cooking flow)
- Pantry screenshot: Camera scan in action (shows AI capability)
- Marketing overlays with text headlines above each screenshot + gradient background matching brand colors
- 6.9" iPhone only (1320x2868px) — no iPad screenshots (app is iPhone-only)
- English + Turkish localization (two sets of screenshots)
- Curated demo content (hand-picked recipes with appetizing photos, demo voice profile)
- Manual creation (Simulator + Figma/Photoshop), no fastlane snapshot automation
- Static screenshots only, no App Preview video for v1

### App Store Listing Copy
- Warm & personal tone — family-focused, emotional (matches voice cloning USP)
- Subtitle: "Recipes in Loved Ones' Voices" (30 chars)
- Category: Food & Drink (primary)
- AI disclosure: Full transparency — name ElevenLabs explicitly in description and AI disclosure fields
- English + Turkish full localization (description, keywords, what's new)
- Pricing: Free with in-app purchases — mention subscription tiers in description
- "What's New" text: Feature list approach ("Introducing Kindred! Voice narration, pantry scanning, trending recipes, and more.")
- Promotional text: Launch promo in warm/personal tone
- App icon: Needs creation — warm & cooking-themed style with warm colors (oranges, reds), suggesting home cooking and family
- Support URL: Needs to be created (email or support page)
- Privacy policy URL: Already hosted (from Phase 18)
- Keywords: Claude researches optimal keywords during planning

### Beta Testing Strategy
- Internal testers: 5-10 people already available (friends/family/team)
- External testers: 50-100 via public TestFlight link shared on social media, Reddit (r/cooking, r/iosapps), Product Hunt
- Internal testing: 1 week minimum before opening external beta
- External testing: 1-2 weeks after internal phase
- Test focus: Core flows end-to-end (onboarding, browse feed, open recipe, play voice narration, scan pantry, subscribe)
- Feedback collection: TestFlight built-in feedback only (shake to report)
- Written "What to Test" guide in TestFlight with specific flows to try
- Pre-loaded demo voice profile so testers can hear narration immediately
- Full production mirror — no feature gating, real subscriptions in sandbox mode
- Standard 90-day TestFlight build expiration
- First-time submitting for external TestFlight review — need extra prep for beta review process
- Go/no-go threshold: Zero crashers + no critical flow-blocking bugs. Minor UI issues are acceptable.

### Pre-Submission Checklist
- Age rating: 4+ (no sensitive content — cooking/recipes only)
- Export compliance: HTTPS only — standard encryption exemption applies
- Critical blocker definition: Any crash + broken onboarding/feed/voice/pantry/purchase flows. Ship with: UI glitches, minor layout issues, edge cases.
- Version: 1.0.0 (build 1)
- Submission: Fastlane automation (automated builds and submission)
- Release: Automatic (goes live immediately after Apple approval)
- Rollout: Immediate full release (no phased rollout)
- Availability: All countries worldwide
- App Store Connect: Developer account set up (Team ID: CV9G42QVG4), app record exists
- IAP products: Need to create subscription products in App Store Connect (local StoreKit config exists)
- AI disclosure concern: Ensure Apple's AI content generation guidelines are met for ElevenLabs voice cloning

### Claude's Discretion
- Exact screenshot overlay text headlines and gradient colors
- App Store keyword research and selection
- Promotional text copy
- "What to Test" guide content for beta testers
- Support page design/approach
- App icon design brief details
- Fastlane configuration specifics

</decisions>

<specifics>
## Specific Ideas

- Lead with the emotional hook — voice narration screenshot first because "hearing a loved one's voice guide you through a recipe" is the unique selling point
- Full transparency about ElevenLabs AI — builds trust with users and Apple review team
- Public TestFlight link for external beta — cast a wide net on cooking communities
- Demo voice profile pre-loaded so beta testers get the "wow moment" immediately without friction of voice cloning setup

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Kindred.storekit`: Local StoreKit configuration exists with subscription products defined — use as reference for creating real products in App Store Connect
- `Sources/Info.plist`: All required privacy keys configured (location, camera, tracking, background audio)
- `Sources/Kindred.entitlements`: Sign in with Apple entitlement configured
- `project.yml`: XcodeGen configuration with all build settings, bundle ID `com.ersinkirteke.kindred`

### Established Patterns
- Bundle ID: `com.ersinkirteke.kindred`
- Team ID: `CV9G42QVG4`
- iOS 17.0 deployment target
- Portrait-only orientation
- Background modes: audio, fetch
- Dependencies: TCA, Firebase Analytics, Google AdMob, Clerk Auth, Apollo GraphQL, Kingfisher

### Integration Points
- MARKETING_VERSION and CURRENT_PROJECT_VERSION in `project.yml` settings — fastlane will need to manage these
- `Config/Debug.xcconfig` and `Config/Release.xcconfig` — may contain environment-specific values (AdMob IDs, Clerk keys)
- Privacy policy already hosted (PRIV-07 complete)
- AdMob configured with production IDs (BILL-03 complete)
- Privacy manifest (PRIV-03 complete)

</code_context>

<deferred>
## Deferred Ideas

- iPad native support — could be its own phase post-launch
- App Preview video — defer to post-launch update
- A/B testing for screenshots — defer until enough download volume
- Localization beyond English + Turkish — future milestone
- Phased release strategy — consider for major updates, not v1

</deferred>

---

*Phase: 22-testflight-beta-submission-prep*
*Context gathered: 2026-04-03*
