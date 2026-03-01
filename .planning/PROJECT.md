# Kindred

## What This Is

Kindred is a hyperlocal, AI-humanized culinary assistant mobile app (native iOS + Android). It discovers viral recipes trending in your neighborhood from Instagram and X, presents them with stunning AI-generated food imagery, and reads the instructions aloud in the cloned voice of someone you love — like your mom or grandma. It's not a recipe database; it's an emotional utility that turns cooking into a connection with loved ones while solving daily "what should I cook?" decision fatigue.

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

### Active

- [ ] Guest browsing without account (iOS + Android)
- [ ] Google OAuth and Apple Sign In (one-tap)
- [ ] Guest-to-account conversion on save/bookmark/voice
- [ ] Swipe left to skip, swipe right to bookmark recipe cards
- [ ] Listen/Watch/Skip buttons as swipe alternatives
- [ ] Onboarding flow completable in under 90 seconds
- [ ] Fridge photo scanning to identify ingredients (Gemini 3 Flash)
- [ ] Supermarket receipt scanning to populate digital pantry
- [ ] Food expiry tracking with push notification alerts
- [ ] Culinary DNA personalization (learns from skips/bookmarks)
- [ ] Dietary preference filtering (vegan, keto, halal, allergies)
- [ ] WCAG AAA accessibility (56dp touch targets, 18sp+ text, VoiceOver/TalkBack)
- [ ] Free tier with ads, Pro tier ($9.99/mo) via App Store/Play billing
- [ ] Voice profiles cached locally for offline narration
- [ ] Android full feature parity with iOS

### Out of Scope

- AI cooking video generation (Veo) — deferred to v2 due to $4.50-9.00/user/month cost, 30-120s latency, and cooking safety concerns
- Social features (sharing, following) — deferred, not core to emotional utility
- Instacart/UberEats "Order Ingredients" integration — deferred to v2, requires partnership deals
- Real-time chat or community features — high complexity, not core to value proposition
- Web app — mobile-first, native only for v1
- Cross-platform framework (Flutter/React Native) — native iOS + Android for best UX and accessibility

## Context

**Shipped v1.5:** Backend & AI Pipeline milestone complete. ~6,066 LOC TypeScript across NestJS backend with GraphQL API, Prisma ORM, PostgreSQL with PostGIS. Complete AI pipeline: recipe scraping (X API + Gemini parser), image generation (Imagen 4 Fast + R2), voice cloning (ElevenLabs), and narration (Gemini rewriting + streaming TTS).

**Platform strategy:** iOS first launch, Android fast-follow (4-6 weeks). Backend/API/AI pipeline is 100% shared between platforms.

**Tech stack (validated in v1.5):**
- Backend: NestJS 11 + GraphQL (Apollo Server 5, code-first) + Prisma 7 + PostgreSQL 15 + PostGIS
- Storage: Cloudflare R2 (zero-egress CDN)
- Auth: Clerk (Google/Apple OAuth with JWT)
- Voice: ElevenLabs API (custom REST client, eleven_flash_v2_5 model ~75ms latency)
- Vision: Gemini 2.0 Flash (recipe parsing ~$0.001/recipe, narration rewriting temp=0.7)
- Images: Imagen 4 Fast via Vertex AI (~$0.01/image)
- Scraping: X API v2 + Gemini parser (Instagram placeholder ready)
- Geocoding: Mapbox with DB cache (~99% cache hit rate)
- Push: Firebase Cloud Messaging (iOS APNs + Android FCM)
- iOS: SwiftUI + TCA (The Composable Architecture), iOS 17.0 min
- Android: Jetpack Compose + MVVM/Clean Architecture + Hilt, min SDK 26

**Design direction:** Warm cream/terracotta palette (#FFF9F0 backgrounds, #E07849 accents), card-based swipeable feed, 4-tab bottom navigation (Feed, Scan, Pantry, Me). "Build for Grandpa George" — if a 75-year-old can use it, everyone can.

**Cost profile (validated):** ~$0.01-0.03/recipe for voice narration, ~$0.01/image for hero images, ~$0.001/recipe for AI parsing. Scraping costs TBD based on volume.

## Constraints

- **Legal**: Voice cloning consent framework required before launch — Tennessee ELVIS Act, California AB 1836 (covers deceased persons' voices), New York digital replica laws. Budget $20-50K for AI/media legal counsel.
- **API Costs**: ElevenLabs ~$0.01-0.03/recipe for voice. Must implement hard budget caps per user.
- **Scraping**: Instagram/X ToS prohibit scraping. Build abstraction layer, diversify sources, ensure app works without scraping as fallback.
- **Accessibility**: WCAG AAA target. 56dp min touch targets, 18sp min body text, max 3 navigation levels, VoiceOver/TalkBack full support.
- **Simplicity**: Max 2 taps from feed to cooking with voice. No hamburger menus, no complex gestures without button fallbacks.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native iOS + Android (not cross-platform) | Best UX, accessibility, and platform-specific capabilities for elderly users | — Pending |
| iOS first, Android fast-follow | Higher ARPU, better accessibility APIs, shared backend | — Pending |
| Defer Veo AI video to v2 | $4.50-9/user/month cost, 30-120s latency, cooking safety risk | ✓ Good |
| Custom NestJS backend (not Firebase/Supabase) | Full control over GraphQL schema, scraping pipelines, background processing | ✓ Good |
| ElevenLabs custom REST client (not SDK) | Native SDKs immature — custom client gives full control over streaming | ✓ Good |
| Free voice slot in v1 | Don't paywall the viral hook — voice IS the retention and viral mechanic | — Pending |
| Prisma 7 with PostgreSQL adapter | Direct DB connections, no need for Prisma Accelerate proxy | ✓ Good |
| PostGIS for geospatial queries | Native spatial indexing, ST_DWithin for radius queries, GIST indexes | ✓ Good |
| Mapbox for geocoding (with DB cache) | ~99% cache hit rate saves ~$1,825/year vs raw API calls | ✓ Good |
| Cloudflare R2 for storage | Zero egress fees vs S3 $0.09/GB — significant savings at scale | ✓ Good |
| Imagen 4 Fast (not standard) | ~$0.01/image vs $0.04 standard — 4x cost savings, acceptable quality | ✓ Good |
| In-memory queues for MVP | Simple background processing without Redis/BullMQ — upgrade path documented | ⚠️ Revisit |
| Velocity-based viral detection | (engagement/hour) * time decay — adapts to local engagement patterns | ✓ Good |
| Gemini 2.0 Flash for AI tasks | ~$0.001/recipe for parsing and narration rewriting — cost effective | ✓ Good |
| Per-recipe narration caching | NarrationScript table caches Gemini output — expected 80% hit rate | ✓ Good |

---
*Last updated: 2026-03-01 after v1.5 milestone*
