# Kindred

## What This Is

Kindred is a hyperlocal, AI-humanized culinary assistant mobile app. It discovers viral recipes trending in your neighborhood from Instagram and X, presents them with stunning AI-generated food imagery, and reads the instructions aloud in the cloned voice of someone you love — like your mom or grandma. The iOS app is live with swipeable recipe feed, voice narration, personalization, App Store billing, and a smart pantry that scans your fridge, tracks expiry dates, and shows which recipes you can cook with what you have. Android is planned as a fast-follow.

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

### Active

(Defined in REQUIREMENTS.md for v4.0 App Store Launch Prep)

### Future

- Android full feature parity with iOS
- JWS SignedDataVerifier for production App Store receipt validation
- Backend GraphQL wiring for voice profiles and narration URLs (replace mock data)

### Out of Scope

- AI cooking video generation (Veo) — $4.50-9/user/month cost, 30-120s latency, cooking safety risk
- Social features (sharing, following) — not core to emotional utility
- Instacart/UberEats "Order Ingredients" integration — requires partnership deals
- Real-time chat or community features — high complexity, not core to value proposition
- Web app — mobile-first, native only
- Cross-platform framework (Flutter/React Native) — native iOS + Android for best UX and accessibility

## Current Milestone: v4.0 App Store Launch Prep

**Goal:** Fix all known gaps, wire real voice playback, production-ready ads/billing, and prepare complete App Store submission package.

**Target features:**
- Wire real backend narration URLs (replace TestAudioGenerator)
- Resolve 5 GraphQL voice profile TODO markers with real backend data
- Production AdMob unit IDs + ATT consent flow
- ScanPaywallView → MonetizationFeature purchase flow wiring
- Recipe suggestion card tap → detail view navigation
- JWS SignedDataVerifier for production receipt validation
- Device token registration → backend for push notification delivery
- App Store Connect privacy labels and review metadata
- Voice cloning consent framework (legal compliance)
- SwiftData persistence fix commit (named ModelConfiguration)

## Context

**Shipped v3.0:** Smart Pantry milestone complete. ~23,105 LOC Swift across 8 SPM packages + ~8,113 LOC TypeScript backend. Added PantryFeature package with local-first SwiftData CRUD, AI fridge/receipt scanning (Gemini 2.0 Flash), recipe-ingredient matching with shopping list generation, and AI expiry tracking with push notifications. 6 phases, 17 plans, 7 days.

**Shipped v2.0:** iOS App milestone. 13,319 LOC Swift, 7 SPM packages. Complete iOS experience: swipeable feed, voice narration, personalization, auth, monetization, WCAG AAA accessibility, bilingual localization.

**Shipped v1.5:** Backend & AI Pipeline. ~6,066 LOC TypeScript. NestJS backend with GraphQL API, recipe scraping, image generation, voice cloning, and narration streaming.

**Platform strategy:** iOS shipped (v2.0). Android fast-follow (4-6 weeks). Backend/API/AI pipeline is 100% shared between platforms.

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
- Android: Jetpack Compose + MVVM/Clean Architecture + Hilt, min SDK 26 (planned)

**Known issues:**
- Voice playback uses TestAudioGenerator until backend R2 narration URLs are wired
- 5 GraphQL TODO markers for mock voice profile data
- JWS verification on backend uses base64url decoding (needs SignedDataVerifier for production)
- Test ad unit IDs in AdClient (must replace before App Store submission)
- EXPIRY-02 partial: device token registered locally but not sent to backend for push delivery
- ScanPaywallView subscribe button placeholder — not wired to MonetizationFeature purchase flow
- Recipe suggestion carousel card tap does not navigate to recipe detail view

## Constraints

- **Legal**: Voice cloning consent framework required before launch — Tennessee ELVIS Act, California AB 1836, New York digital replica laws. Budget $20-50K for AI/media legal counsel.
- **API Costs**: ElevenLabs ~$0.01-0.03/recipe for voice. Must implement hard budget caps per user.
- **Scraping**: Instagram/X ToS prohibit scraping. Build abstraction layer, diversify sources, ensure app works without scraping as fallback.
- **Accessibility**: WCAG AAA achieved on iOS. Same standard required for Android. 56dp min touch targets, 18sp min body text, max 3 navigation levels.
- **Simplicity**: Max 2 taps from feed to cooking with voice. No hamburger menus, no complex gestures without button fallbacks.
- **App Store**: Privacy labels, ATT consent for AdMob, production ad unit IDs, and review metadata needed before submission.

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
| In-memory queues for MVP | Simple background processing without Redis/BullMQ — upgrade path documented | ⚠️ Revisit |
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
| Base64url JWS for MVP | Skip x5c chain verification — StoreKit does client-side verification | ⚠️ Revisit — production needs SignedDataVerifier |
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

---
*Last updated: 2026-03-30 after v4.0 App Store Launch Prep milestone started*
