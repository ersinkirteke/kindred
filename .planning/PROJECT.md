# Kindred

## What This Is

Kindred is a hyperlocal, AI-humanized culinary assistant mobile app. It discovers viral recipes trending in your neighborhood from Instagram and X, presents them with stunning AI-generated food imagery, and reads the instructions aloud in the cloned voice of someone you love — like your mom or grandma. The iOS app is production-ready with swipeable recipe feed, voice narration from backend R2 CDN, personalization, App Store billing with fraud prevention, smart pantry with AI scanning, ATT consent flow, and complete App Store submission package. Android is planned as a fast-follow.

## Core Value

Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable. Everything else supports getting users to that moment.

## Requirements

### Validated

- ✓ Backend API serves both iOS and Android with shared data models — v1.5
- ✓ Recipe scraping pipeline discovers trending recipes from Instagram/X by location — v1.5
- ✓ AI image generation pipeline creates hero images for each scraped recipe — v1.5
- ✓ App functions with degraded experience when scraping sources are unavailable — v1.5
- ✓ Push notification infrastructure for expiry alerts and engagement nudges — v1.5
- ✓ User session persists across app restarts — v1.5
- ✓ User sees viral recipes trending within a 5-10 mile radius of their location — v1.5
- ✓ Each recipe card displays AI hero image, recipe name, prep time, calories, loves count — v1.5
- ✓ Trending recipes display a "VIRAL" badge based on local engagement metrics — v1.5
- ✓ User can filter recipes by category (cuisine type, meal type, dietary tags) — v1.5
- ✓ User's location is shown at the top of the feed (city badge) — v1.5
- ✓ User can manually change their location to explore other areas — v1.5
- ✓ Feed loads cached content when offline with clear offline indicator — v1.5
- ✓ User can upload a 30-60 second voice clip of a loved one — v1.5
- ✓ App clones the uploaded voice using ElevenLabs API and stores the voice profile — v1.5
- ✓ User can listen to any recipe's instructions narrated in their cloned voice — v1.5
- ✓ Voice narration streams in real-time with play/pause/seek controls (64dp play button) — v1.5
- ✓ Voice narration displays the speaker's name prominently during playback — v1.5
- ✓ Free tier users get 1 voice slot; Pro users get unlimited voice slots — v1.5
- ✓ User can re-record or replace their voice clip to improve quality — v1.5
- ✓ Guest browsing without account — v2.0
- ✓ Google OAuth and Apple Sign In (one-tap) — v2.0
- ✓ Guest-to-account conversion on save/bookmark/voice with data persistence — v2.0
- ✓ Swipe left to skip, right to bookmark recipe cards — v2.0
- ✓ Listen/Watch/Skip buttons as swipe alternatives (56dp touch targets) — v2.0
- ✓ Onboarding flow completable in under 90 seconds (3-step carousel) — v2.0
- ✓ Culinary DNA personalization learns from implicit feedback (50+ interactions) — v2.0
- ✓ Dietary preference filtering (vegan, keto, halal, allergies) with session persistence — v2.0
- ✓ WCAG AAA accessibility (56dp touch targets, 18sp+ text, VoiceOver, 7:1 contrast) — v2.0
- ✓ Free tier with AdMob ads, Pro tier ($9.99/mo) via StoreKit 2 — v2.0
- ✓ Voice profiles cached locally for offline narration (500MB LRU) — v2.0
- ✓ Background audio with lock screen controls and Now Playing info — v2.0
- ✓ Bilingual localization (English + Turkish) — v2.0
- ✓ Persistent digital pantry with manual add/remove/edit and offline-first sync — v3.0
- ✓ Fridge photo scanning to identify ingredients via Gemini 2.0 Flash (Pro) — v3.0
- ✓ Supermarket receipt scanning to populate digital pantry (Pro) — v3.0
- ✓ AI-estimated food expiry tracking with push notification alerts — v3.0
- ✓ Ingredient match % badge on recipe cards based on pantry contents — v3.0
- ✓ Backend GraphQL pantry API with ingredient normalization (185 bilingual entries) — v3.0
- ✓ ATT consent prompt with pre-prompt explanation before personalized ads — v4.0
- ✓ Privacy Nutrition Labels declare all data collection in App Store Connect — v4.0
- ✓ PrivacyInfo.xcprivacy manifest with tracking domains and Required Reason API codes — v4.0
- ✓ Voice cloning consent screen before first upload naming ElevenLabs as AI provider — v4.0
- ✓ Voice consent audit trail stores userId, timestamp, IP, and app version — v4.0
- ✓ Voice profile deletion from Settings with confirmation dialog — v4.0
- ✓ Privacy Policy hosted at public URL and linked in App Store Connect — v4.0
- ✓ Voice narration plays from backend R2 CDN URLs (TestAudioGenerator removed) — v4.0
- ✓ All GraphQL voice profile TODO markers resolved with real backend data — v4.0
- ✓ Narration URL returned via GraphQL query with NarrationAudio cache lookup — v4.0
- ✓ Backend validates StoreKit 2 JWS via SignedDataVerifier with x5c chain — v4.0
- ✓ ScanPaywallView subscribe button triggers MonetizationFeature purchase flow — v4.0
- ✓ Production AdMob unit IDs replace test IDs via xcconfig — v4.0
- ✓ Device FCM token registered with backend via GraphQL mutation — v4.0
- ✓ Backend stores FCM tokens per user for push notification delivery — v4.0
- ✓ Recipe suggestion carousel card tap navigates to recipe detail view — v4.0
- ✓ SwiftData named ModelConfiguration for PantryStore/GuestStore separation — v4.0
- ✓ App Store screenshots created for required device sizes — v4.0
- ✓ App Store metadata with third-party AI disclosure — v4.0
- ✓ TestFlight beta testing plan with internal and external testing docs — v4.0

### Active

## Current Milestone: v5.0 Lean App Store Launch

**Goal:** Strip expensive backend dependencies, replace with free alternatives, and ship the iOS app to the App Store with zero monthly SaaS costs.

**Target features:**
- Replace X API scraping with Spoonacular free recipe API (150 req/day)
- Use Spoonacular-provided recipe images instead of Imagen 4 AI generation
- Replace ElevenLabs with Apple AVSpeechSynthesizer for free-tier voice narration
- Keep ElevenLabs voice cloning behind Pro paywall only
- Update feed framing from "viral near you" to "popular recipes"
- Submit iOS app to App Store via fastlane
- All core features run on $0/month SaaS (free tiers only)

### Future

- Android full feature parity with iOS
- App Store Server API integration for refund and subscription lifecycle events
- Staged ATT rollout with A/B testing for opt-in rate optimization
- Localized permission strings for non-English markets
- Localized voice consent copy for Turkish
- Advanced subscription analytics dashboard
- ATT acceptance rate tracking by cohort

### Out of Scope

- AI cooking video generation (Veo) — $4.50-9/user/month cost, 30-120s latency, cooking safety risk
- Social features (sharing, following) — not core to emotional utility
- Instacart/UberEats "Order Ingredients" integration — requires partnership deals
- Real-time chat or community features — high complexity, not core to value proposition
- Web app — mobile-first, native only
- Cross-platform framework (Flutter/React Native) — native iOS + Android for best UX and accessibility
- RevenueCat integration — @apple/app-store-server-library sufficient
- Force ATT Accept — Apple views as "nagging", causes rejection under guideline 5.1.1(iv)

## Context

**Shipped v4.0:** App Store Launch Prep. ~25,632 LOC Swift across 8 SPM packages + ~11,812 LOC TypeScript backend. Added privacy compliance (voice consent, privacy manifest, nutrition labels), production backend hardening (SignedDataVerifier, rate limiting, narration URL resolver), ATT consent with production AdMob IDs, real voice playback from R2 CDN, and complete App Store submission package with fastlane. 5 phases, 19 plans, 4 days.

**Shipped v3.0:** Smart Pantry milestone. ~23,105 LOC Swift + ~8,113 LOC TypeScript. PantryFeature with local-first SwiftData CRUD, AI fridge/receipt scanning, recipe-ingredient matching, and AI expiry tracking. 6 phases, 17 plans, 7 days.

**Shipped v2.0:** iOS App milestone. 13,319 LOC Swift, 7 SPM packages. Complete iOS experience: swipeable feed, voice narration, personalization, auth, monetization, WCAG AAA accessibility, bilingual localization. 8 phases, 35 plans, 9 days.

**Shipped v1.5:** Backend & AI Pipeline. ~6,066 LOC TypeScript. NestJS backend with GraphQL API, recipe scraping, image generation, voice cloning, and narration streaming. 3 phases, 11 plans, 2 days.

**Platform strategy:** iOS production-ready (v4.0). Android fast-follow (4-6 weeks). Backend/API/AI pipeline is 100% shared between platforms.

**Tech stack:**
- Backend: NestJS 11 + GraphQL (Apollo Server 5, code-first) + Prisma 7 + PostgreSQL 15 + PostGIS
- Storage: Cloudflare R2 (zero-egress CDN)
- Auth: Clerk (Google/Apple OAuth with JWT)
- Voice: ElevenLabs API (custom REST client, eleven_flash_v2_5 model ~75ms latency)
- Vision: Gemini 2.0 Flash (recipe parsing ~$0.001/recipe, narration rewriting temp=0.7)
- Images: Imagen 4 Fast via Vertex AI (~$0.01/image)
- Scraping: X API v2 + Gemini parser (Instagram placeholder ready)
- Geocoding: Mapbox with DB cache (~99% cache hit rate)
- Push: Firebase Cloud Messaging (iOS APNs + Android FCM)
- iOS: SwiftUI + TCA 1.x, Apollo iOS 2.0.6, StoreKit 2, AVFoundation, VisionKit, iOS 17.0 min
- Build: Fastlane with 3 lanes (beta_internal, beta_external, release)
- Android: Jetpack Compose + MVVM/Clean Architecture + Hilt, min SDK 26 (planned)

**Known issues:**
- Voice cloning consent copy needs legal counsel review (Tennessee ELVIS Act, California AB 1836)
- In-memory queues for background processing (may need Redis/BullMQ at scale)
- 8 AM UTC batch notifications (needs per-timezone support)

## Constraints

- **Legal**: Voice cloning consent framework implemented but consent copy requires legal counsel review for multi-state compliance (Tennessee ELVIS Act, California AB 1836, New York digital replica laws). Budget $20-50K for AI/media legal counsel.
- **API Costs**: ElevenLabs ~$0.01-0.03/recipe for voice. Must implement hard budget caps per user.
- **Scraping**: Instagram/X ToS prohibit scraping. Build abstraction layer, diversify sources, ensure app works without scraping as fallback.
- **Accessibility**: WCAG AAA achieved on iOS. Same standard required for Android. 56dp min touch targets, 18sp min body text, max 3 navigation levels.
- **Simplicity**: Max 2 taps from feed to cooking with voice. No hamburger menus, no complex gestures without button fallbacks.

## Release Process

This section documents the end-to-end release procedure for Kindred App Store submissions. It is referenced by criterion #6 of Phase 28 and must be kept current as the release flow evolves.

### Pre-submission (executed by Phase 28)

1. **Preflight:** `cd Kindred/fastlane && bundle exec fastlane preflight` must pass (validates Release.xcconfig, .env, .p8, metadata, screenshots)
2. **Metadata audit:** verify en-US and tr metadata contain no competing platform references and reflect current PrivacyInfo.xcprivacy disclosures
3. **Fresh Release build:** `xcodebuild clean build -configuration Release -scheme Kindred` must exit 0; deprecation warnings triaged per Phase 28 Plan 03
4. **TestFlight bake:** `fastlane beta_internal` uploads a fresh build; 48-72hr bake with internal testers; pre-submission-checklist.md must pass (zero crashers + all 6 core flows work)
5. **Privacy Nutrition Labels:** set manually in App Store Connect > App Privacy to match PrivacyInfo.xcprivacy (fastlane does NOT automate this surface)
6. **Release submission:** `cd Kindred/fastlane && /opt/homebrew/opt/ruby/bin/bundle exec fastlane release` uploads binary + metadata + submits for review
7. **Confirm:** App Store Connect shows "Waiting for Review"

### Post-approval (executed manually when Apple approves)

Apple review typically completes in 24-48 hours (can extend to 72). When the app moves from "In Review" to "Pending Developer Release" or "Ready for Sale":

1. **Tag the release in git:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   Use semantic version matching MARKETING_VERSION from `Kindred/project.yml`.

2. **Update .planning/MILESTONES.md:**
   Append an entry under the current milestone (e.g., v5.0 Lean App Store Launch) with:
   - Release date
   - Build number (from `git log --oneline | wc -l` at tag time)
   - App Store status (Approved / Live / Pending)
   - Any review feedback or conditions

3. **Monitor App Store Connect daily** until status transitions through:
   - `Waiting for Review` > `In Review` > `Processing for App Store` > `Ready for Sale`
   - OR `Metadata Rejected` / `Binary Rejected` (fix and resubmit via Phase 28 loopback)

4. **Smoke-test the live app:**
   - Install from App Store on a clean device (not TestFlight)
   - Verify the 6 core flows from `Kindred/docs/what-to-test.md`
   - Confirm Privacy Nutrition Labels render correctly on the listing page

### If Apple rejects the submission

1. Read the rejection reason in Resolution Center
2. Determine which Phase 28 plan is responsible for the fix (metadata > 28-02, privacy > 28-01 preflight or PrivacyInfo > Phase 27.1, build > 28-03)
3. Create a gap-closure plan via `/gsd:plan-phase 28 --gaps` OR fix in place if scope is small
4. Re-run beta bake if binary changes (Plan 28-04), or Reply to Submission if only metadata changes
5. Resubmit via `fastlane release`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native iOS + Android (not cross-platform) | Best UX, accessibility, and platform-specific capabilities | ✓ Good — iOS shipped, validates approach |
| iOS first, Android fast-follow | Higher ARPU, better accessibility APIs, shared backend | ✓ Good — iOS shipped in 9 days |
| Defer Veo AI video to v2 | $4.50-9/user/month cost, 30-120s latency, cooking safety risk | ✓ Good |
| Custom NestJS backend (not Firebase/Supabase) | Full control over GraphQL schema, scraping pipelines, background processing | ✓ Good |
| ElevenLabs custom REST client (not SDK) | Native SDKs immature — custom client gives full control over streaming | ✓ Good |
| Free voice slot in v1 | Don't paywall the viral hook — voice IS the retention and viral mechanic | ✓ Good — implemented in v2.0 |
| Prisma 7 with PostgreSQL adapter | Direct DB connections, no need for Prisma Accelerate proxy | ✓ Good |
| PostGIS for geospatial queries | Native spatial indexing, ST_DWithin for radius queries, GIST indexes | ✓ Good |
| Mapbox for geocoding (with DB cache) | ~99% cache hit rate saves ~$1,825/year vs raw API calls | ✓ Good |
| Cloudflare R2 for storage | Zero egress fees vs S3 $0.09/GB — significant savings at scale | ✓ Good |
| Imagen 4 Fast (not standard) | ~$0.01/image vs $0.04 standard — 4x cost savings, acceptable quality | ✓ Good |
| In-memory queues for MVP | Simple background processing without Redis/BullMQ — upgrade path documented | ⚠️ Revisit at scale |
| Velocity-based viral detection | (engagement/hour) * time decay — adapts to local engagement patterns | ✓ Good |
| Gemini 2.0 Flash for AI tasks | ~$0.001/recipe for parsing and narration rewriting — cost effective | ✓ Good |
| Per-recipe narration caching | NarrationScript table caches Gemini output — expected 80% hit rate | ✓ Good |
| SwiftUI + TCA architecture | Unidirectional data flow, testable reducers, dependency injection | ✓ Good — clean modular architecture |
| Apollo iOS 2.0.6 with SQLite cache | Offline-first UX via returnCacheDataAndFetch policy | ✓ Good — instant cached loads |
| Deferred location permission | GPS requested only when user taps "Use my location" — not at launch | ✓ Good — low friction |
| Guest browsing first, auth later | Users experience product before converting — Phase 5 before Phase 8 | ✓ Good — natural conversion flow |
| AVPlayer for streaming (not AVAudioPlayer) | HTTP progressive download with background audio support | ✓ Good — after lifecycle fixes |
| Clerk iOS SDK for auth | Google/Apple OAuth, JWT session management, async user state | ✓ Good — but poll required for user state |
| StoreKit 2 (not StoreKit 1) | Modern async/await API, JWS transactions, grace period support | ✓ Good — clean implementation |
| SignedDataVerifier for JWS validation | x5c certificate chain validation prevents subscription fraud | ✓ Good — resolved base64url MVP approach (v4.0) |
| 60/40 personalization/discovery | Culinary DNA re-ranking balances preferences with variety | ✓ Good — prevents filter bubbles |
| Bilingual (English + Turkish) | String Catalog with 98 entries, informal Turkish tone | ✓ Good — extensible pattern |
| SwiftData for local-first pantry | Offline-first with sync — GuestSessionClient pattern | ✓ Good — instant local CRUD |
| Last-write-wins conflict resolution | Simple timestamp comparison for sync conflicts | ✓ Good — sufficient for single-user |
| Server-side ingredient normalization | IngredientCatalog (185 bilingual entries) as single source of truth | ✓ Good — consistent matching |
| Base64 → Apollo multipart upload | Switched from base64 to GraphQLFile for camera photos | ✓ Good — avoids 33% overhead |
| Gemini 2.0 Flash for vision analysis | Cost-effective fridge scanning and receipt parsing | ✓ Good — ~$0.001/scan |
| Client-side ingredient matching | Minimizes latency, enables offline matching | ✓ Good — instant results |
| Exclude common staples from match % | Salt, pepper, water, oil etc. excluded to avoid inflated scores | ✓ Good — meaningful percentages |
| Three-tier expiry estimation | IngredientCatalog → Gemini → conservative defaults | ✓ Good — cost-effective |
| 8 AM UTC batch notifications | Single daily digest for MVP (per-timezone deferred) | ⚠️ Revisit — needs timezone support |
| Progressive camera permission | Poll-based pattern (mirrors LocationClient) | ✓ Good — consistent UX |
| Per-upload voice consent (not once-per-user) | GDPR Article 7 compliance + Tennessee ELVIS Act requirements | ✓ Good — legally defensible (v4.0) |
| xcconfig-based ad unit IDs | Separates Debug test IDs from Release production IDs | ✓ Good — prevents shipping test ads (v4.0) |
| UMP SDK before ATT | Provides GDPR/CCPA coverage alongside ATT | ✓ Good — comprehensive consent (v4.0) |
| Cache-first audio loading | GraphQL query with local cache fallback for narration | ✓ Good — instant replay, offline support (v4.0) |
| Bidirectional fuzzy ingredient matching | "chicken" matches "chicken breast" via contains check in both directions | ✓ Good — natural matching (v4.0) |
| Named ModelConfiguration for SwiftData | PantryStore/GuestStore separation prevents data bleed | ✓ Good — clean container isolation (v4.0) |
| Fastlane 3-lane distribution | beta_internal, beta_external, release for granular control | ✓ Good — flexible pipeline (v4.0) |
| Git commit count for build numbers | Reproducible, monotonically increasing, no manual management | ✓ Good — simple versioning (v4.0) |

---
*Last updated: 2026-04-04 after v5.0 Lean App Store Launch milestone started*
