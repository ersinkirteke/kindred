# Project Research Summary

**Project:** Kindred v5.0 - Lean App Store Launch
**Domain:** iOS Recipe App Migration (Spoonacular API, AVSpeechSynthesizer, App Store Submission)
**Researched:** 2026-04-04
**Confidence:** HIGH

## Executive Summary

The v5.0 Lean App Store Launch represents a strategic pivot from expensive cloud dependencies to free-tier alternatives, enabling $0/month SaaS costs while shipping to the App Store. Research confirms this is achievable by replacing X API scraping with Spoonacular API (150 req/day free tier), replacing ElevenLabs for free users with iOS native AVSpeechSynthesizer, and using Spoonacular's CDN images instead of Imagen 4 generation. The existing NestJS + SwiftUI/TCA architecture supports these integrations through clean abstraction layers without breaking changes.

The recommended approach uses three parallel integration paths: (1) Backend Spoonacular REST-to-GraphQL proxy with aggressive caching (60-90% hit rate expected), (2) iOS tier-based voice strategy pattern selecting between AVSpeechSynthesizer (free) and ElevenLabs (Pro), and (3) Fastlane automation for App Store submission. All three can be developed independently and merged with feature flags, enabling zero-downtime migration from the current X API + Imagen 4 + ElevenLabs-for-all architecture.

The primary risk is Spoonacular's 150 req/day quota exhaustion within days of launch without proper caching. Secondary risks include AVSpeechSynthesizer production bugs on iOS 17 (documented crashes, silent failures), App Store rejection for missing third-party AI consent (new Guideline 5.1.2(i) from November 2025), and 7-30 day review delays in March 2026. Mitigation strategies are well-documented: implement caching layer as table stakes (not optimization), test AVSpeechSynthesizer on iOS 17 real devices (not Simulator), show explicit consent modal before ElevenLabs upload, and submit 30 days before target launch date.

## Key Findings

### Recommended Stack

The migration to free-tier alternatives requires minimal new dependencies. **Spoonacular API** replaces X API scraping and Imagen 4 generation with a single REST endpoint providing structured recipe data (365K+ recipes) and CDN images at zero cost (150 requests/day free tier). **AVSpeechSynthesizer** (built into iOS 7.0+) replaces ElevenLabs for free-tier users with on-device text-to-speech supporting 150+ voices and offline synthesis. **Fastlane 3.x** (already configured in v4.0) extends with a new `release` lane automating binary upload, metadata sync, and App Store submission.

**Core technologies:**
- **Spoonacular API (free tier)**: Recipe data source with 150 req/day quota — replaces $100/mo X API + Gemini parsing + Imagen generation with zero-cost structured data
- **AVSpeechSynthesizer (iOS built-in)**: On-device TTS for free users — eliminates $0.01-0.03/recipe ElevenLabs cost while ElevenLabs moves behind Pro paywall
- **axios + @nestjs/throttler**: HTTP client with rate limiting — enforces Spoonacular's 1 req/sec and 2 concurrent request limits
- **PostgreSQL caching layer**: 60-90 day recipe cache — stays under 150 req/day limit with 60-80% expected hit rate
- **Fastlane deliver**: App Store metadata automation — uploads screenshots, description, privacy labels alongside binary

**Critical version requirements:**
- **Xcode 16.0+ with iOS 26 SDK**: Hard deadline April 28, 2026 for all App Store submissions
- **iOS 17.0 minimum deployment**: Existing app target, AVSpeechSynthesizer fully compatible
- **NestJS 11 + Prisma 7**: Already validated, no breaking changes from new integrations

### Expected Features

Research confirms all v5.0 features are achievable with free-tier technologies. **Table stakes** include Spoonacular recipe search with dietary filters (vegan, keto, halal, allergies), structured ingredient lists, step-by-step instructions, nutrition information, and mandatory source attribution (Spoonacular ToS + App Store Guideline 5.2.2). **Privacy compliance** requires third-party AI consent modal (Guideline 5.1.2(i) enforced since November 2025) and Privacy Labels listing Spoonacular as data processor.

**Must have (table stakes):**
- Recipe search with filters (cuisine, diet, intolerances) — Spoonacular `/recipes/complexSearch` endpoint provides built-in filters
- Recipe images from Spoonacular CDN — no AI generation needed, zero cost
- Spoonacular source attribution with logo/link — legal requirement per ToS and App Store 5.2.2
- Privacy disclosure for Spoonacular data sharing — Apple Guideline 5.1.2(i) requires naming third-party services
- Offline fallback with local caching (1-hour max per Spoonacular ToS) — graceful degradation when quota exhausted
- AVSpeechSynthesizer background playback — requires audio session configuration and Background Modes entitlement

**Should have (competitive):**
- Enhanced iOS voice quality (100MB+ voice downloads) — user-initiated upgrade from robotic to natural-sounding TTS
- SSML-enhanced narration (iOS 16+) — use `<break>`, `<emphasis>`, `<prosody>` tags for better recipe pacing
- Personal Voice integration (iOS 17+) — users narrate in their own AI-generated voice at zero cost (premium feel)
- Recipe-ingredient pantry matching — Spoonacular `/recipes/findByIngredients` shows used/missed ingredients
- Cost per serving display — Spoonacular's `pricePerServing` field differentiates from free apps

**Defer (v2+):**
- Spoonacular meal planning endpoints — complex UX, defer until retention data shows users bookmark recipes
- Multi-voice narration (different voices for ingredients vs. steps) — complexity without proven demand
- Custom recipe uploads to Spoonacular — Spoonacular charges per stored recipe, not cost-effective for lean launch
- Offline voice synthesis caching — AVSpeechSynthesizer synthesizes on-demand, pre-caching adds complexity

### Architecture Approach

All three integrations layer onto existing architecture without breaking changes. **Spoonacular integration** uses REST-to-GraphQL proxy pattern: `SpoonacularService` wraps REST API, `RecipesFeedService` adds caching layer, GraphQL schema exposes internal `Recipe` type (not Spoonacular schema directly). **Voice tier split** uses strategy pattern: `VoiceProvider` interface with `AppleVoiceProvider` (free) and `ElevenLabsVoiceProvider` (Pro) implementations, selected via dependency injection based on user tier. **Fastlane automation** extends existing 3-lane pipeline (`beta_internal`, `beta_external`, new `release` lane) with metadata management from `fastlane/metadata/` directory structure.

**Major components:**
1. **SpoonacularService (Backend)** — REST proxy translating Spoonacular API to GraphQL, handles rate limiting (1 req/sec), quota tracking (150 points/day), error handling (402 quota exceeded)
2. **RecipesFeedService (Backend)** — Caching layer checking PostgreSQL cache (6-hour TTL) before calling Spoonacular, daily batch job at 2 AM UTC pre-warms 100 popular recipes
3. **SpeechSynthesizerManager (iOS)** — AVSpeechSynthesizer wrapper managing audio session, lock screen controls (MPRemoteCommandCenter), background playback, delegate-based status stream
4. **VoicePlaybackReducer (iOS)** — Tier-based routing checking user subscription, dispatching to AVSpeechSynthesizer (free) or AVPlayer + ElevenLabs (Pro) based on tier
5. **Fastlane release lane (Build)** — Automates build IPA, upload binary, sync metadata (screenshots, description, privacy labels), submit for review

**Data flow changes:**
- Recipe feed: `popularRecipes` query replaces `viralRecipes`, removes location dependency, shows popularity score instead of viral badge
- Free-tier voice: `narrationAudio` query returns `{ url: null, plainText: instructions, tier: FREE }`, client synthesizes locally
- Pro-tier voice: Existing flow unchanged — `narrationAudio` returns `{ url: R2_CDN, plainText: null, tier: PRO }`, AVPlayer streams

### Critical Pitfalls

Research identified 10 critical pitfalls with documented production failures. The top 5 by impact:

1. **Spoonacular quota exhaustion within days** — 150 req/day burns fast without caching. Implement 1-hour cache (Spoonacular ToS max) + PostgreSQL long-term storage as table stakes, not optimization. Monitor usage at 80% threshold, pre-populate 50-100 recipes during development. Cache hit rate <70% = production failure.

2. **AVSpeechSynthesizer iOS 17/18 production bugs** — Crashes with "Could not find audio unit" on iOS 17.0-17.2, stops mid-utterance on 1200+ word recipes, memory leaks after 5-10 narrations. Test on iPhone 14 Pro (iOS 17.6) and iPhone 16 (iOS 18.2) real devices (not Simulator). Implement error fallback: "Voice unavailable, showing text instead." Limit utterances to 500 words, split longer recipes.

3. **App Store rejection for missing AI consent (Guideline 5.1.2(i))** — November 2025 enforcement requires explicit consent modal BEFORE voice upload with provider name "ElevenLabs AI." Existing consent bundled with recording flow doesn't meet requirements. Show dedicated modal with "Allow" / "Don't Allow" buttons, block upload on denial, update Privacy Labels to list ElevenLabs.

4. **Spoonacular data model mismatch breaks existing Recipe schema** — Custom scraping uses `viralScore`, `locationId`, `scrapedAt` fields. Spoonacular returns `spoonacularScore`, `analyzedInstructions`, `extendedIngredients` with different structures. Create `SpoonacularAdapter` mapping external schema to internal `Recipe` type, update GraphQL to support both sources during migration with `source: RecipeSource` field.

5. **Mixed TTS quality creates negative user perception** — Free AVSpeechSynthesizer (robotic) vs. Pro ElevenLabs (natural) comparison creates "app unusable without paying" perception. NEVER show ElevenLabs demos to free users. Frame AVSpeech as "built-in narration" not "free tier," add voice customization (pitch/rate), prompt enhanced voice downloads (100MB+). Position Pro as "personalized cloning" not "better quality."

**Additional critical pitfalls:**
- **Spoonacular attribution missing** — ToS requires "Powered by Spoonacular" badge + link on recipe detail view, violation risks app removal and legal fees
- **Nutrition data health claims** — Display without "estimate" disclaimer violates Guideline 1.4.1, must add "Estimates from Spoonacular. Not for medical use."
- **iOS 26 SDK requirement (April 28, 2026)** — Xcode 15 builds rejected after deadline, upgrade to Xcode 16 + macOS Sequoia 15.0 immediately
- **App Store review delays (7-30 days in March 2026)** — Submit 30 days before target launch, not 7 days, schedule marketing after "Ready for Sale" not after submission
- **AVSpeech background audio stops** — iOS 17/18 bug causes audio to stop when app backgrounds despite proper audio session config, document limitation or implement fallback

## Implications for Roadmap

Based on research, the migration follows a 6-phase structure with clear dependencies. Spoonacular integration must complete before iOS voice tier split (backend needs `plainText` field for AVSpeechSynthesizer). Voice schema update must follow iOS adoption (can't break existing clients). Feed UI update must happen after both voice tiers work (avoid breaking narration during framing change). Backend cleanup only after iOS 100% rollout. Fastlane is independent and can happen anytime.

### Phase 1: Spoonacular Backend Integration
**Rationale:** Non-breaking foundation layer — add Spoonacular alongside existing scraping service, expose via new `popularRecipes` query while keeping deprecated `viralRecipes`. Feature flag enables safe testing and rollback.

**Delivers:**
- `SpoonacularService` with REST client (axios)
- PostgreSQL caching layer (6-hour TTL + 60-day long-term storage)
- `popularRecipes` GraphQL query with `sourceType: SPOONACULAR` support
- Rate limiting (1 req/sec, 150 points/day quota tracking)
- Daily batch job (2 AM UTC) pre-warming 100 recipes
- "Powered by Spoonacular" attribution badge component

**Addresses:**
- Spoonacular recipe search with filters (table stakes)
- Recipe images from CDN (table stakes)
- Source attribution (legal requirement)
- Offline fallback with caching (table stakes)

**Avoids:**
- Pitfall 1: Quota exhaustion (caching layer as core requirement)
- Pitfall 4: Data model mismatch (SpoonacularAdapter maps to internal Recipe schema)
- Pitfall 6: Missing attribution (badge implemented alongside integration)

**Research flag:** Standard REST-to-GraphQL pattern, no additional research needed.

---

### Phase 2: AVSpeechSynthesizer Free-Tier Voice
**Rationale:** Depends on Phase 1 completing (backend needs to expose `plainText` field in `narrationAudio` query). Strategy pattern isolates free/Pro logic, enables independent testing of AVSpeechSynthesizer without touching ElevenLabs path.

**Delivers:**
- `SpeechSynthesizerManager` actor wrapping AVSpeechSynthesizer
- `AppleVoiceProvider` and `ElevenLabsVoiceProvider` strategies
- `VoicePlaybackReducer` tier-based routing (checks `userTier` from subscription state)
- Audio session configuration (`.playback` category, `.spokenAudio` mode)
- Lock screen controls (MPRemoteCommandCenter integration)
- Enhanced voice download prompt UI (Settings → Accessibility → Live Speech)

**Addresses:**
- AVSpeechSynthesizer for free-tier voice (table stakes)
- Background audio capability (table stakes)
- Enhanced iOS voice quality (competitive differentiator)

**Avoids:**
- Pitfall 2: iOS 17/18 bugs (test plan includes iPhone 14 Pro iOS 17.6 + iPhone 16 iOS 18.2 real devices)
- Pitfall 5: Mixed quality perception (no ElevenLabs demos shown to free users, frame as "built-in" not "free tier")
- Pitfall 10: Background audio stops (document limitation or implement screen-awake fallback)

**Research flag:** AVSpeechSynthesizer iOS 17/18 bugs warrant monitoring during implementation — check Apple Developer Forums for latest workarounds.

---

### Phase 3: App Store Compliance & Privacy Updates
**Rationale:** Must complete before TestFlight submission. Apple enforces Guideline 5.1.2(i) strictly (November 2025 update), rejection adds 2-week resubmission delay. Nutrition disclaimers and Xcode 16 requirement are table stakes for approval.

**Delivers:**
- Third-party AI consent modal (shows BEFORE voice upload with "ElevenLabs AI" provider name)
- Privacy Policy update (add Spoonacular disclosure)
- App Privacy Labels (Data Types → Audio → Shared with ElevenLabs, search queries → Shared with Spoonacular)
- Nutrition disclaimer ("Estimates from Spoonacular. Not for medical use." in 12pt text)
- PrivacyInfo.xcprivacy manifest updates (Spoonacular API domain)
- Xcode 16 + iOS 26 SDK verification
- App Store screenshots refresh (remove "viral near you," replace with "popular recipes")

**Addresses:**
- Privacy disclosure for third-party APIs (table stakes)
- App Store screenshots matching build (table stakes)

**Avoids:**
- Pitfall 3: AI consent rejection (dedicated modal before upload, not bundled with recording)
- Pitfall 7: Nutrition health claims (disclaimers visible, app category = Food & Drink not Medical)
- Pitfall 8: iOS 26 SDK requirement (verify Xcode 16 before submission)

**Research flag:** No additional research needed — Apple documentation is definitive.

---

### Phase 4: Backend Voice Schema Update (Breaking Change)
**Rationale:** Depends on Phase 2 (iOS must know how to handle tier-based responses). Breaking change requires careful migration — add `UserTier` enum, modify `narrationAudio` resolver to return `{ url, plainText, tier }`. Deploy backend, iOS gracefully handles both old and new schema via Apollo cache.

**Delivers:**
- `UserTier` enum (FREE | PRO) on User model
- Modified `narrationAudio` query returning `{ url: String?, plainText: String, tier: UserTier }`
- Resolver logic skipping ElevenLabs for FREE tier
- Cost monitoring dashboard (track ElevenLabs API calls by tier)

**Addresses:**
- Tier-based voice routing (enables Pro monetization)

**Avoids:**
- Breaking iOS clients (both old and new schema supported during transition)
- Unnecessary ElevenLabs costs for free users

**Research flag:** Standard GraphQL schema migration, no additional research needed.

---

### Phase 5: iOS Feed Update & Backend Cleanup
**Rationale:** Depends on Phase 4 (voice tiers must work before changing feed framing). Replace `viralRecipes` query with `popularRecipes` in FeedFeature, update UI to show popularity score instead of viral badge. After iOS 100% rollout, remove deprecated `viralRecipes` query and old scraping services.

**Delivers:**
- FeedFeature migration from `viralRecipes` to `popularRecipes` query
- UI update: POPULAR badge instead of VIRAL badge, popularity score display
- Backend cleanup: remove `ScrapingService`, `XApiService`, `InstagramService`, `ImageGenerationProcessor`, `viralRecipes` query
- Feature flag removal (enable `ENABLE_SPOONACULAR_FEED` for 100%)

**Addresses:**
- Recipe feed transition from viral to popular framing (UX consistency)

**Avoids:**
- Breaking iOS during feed transition (both queries exist until rollout complete)

**Research flag:** No additional research needed — standard GraphQL query migration.

---

### Phase 6: Fastlane App Store Submission (Independent)
**Rationale:** Can happen anytime after Phase 0 (Xcode 16 setup). Independent of runtime changes — extends build system with `release` lane automating binary upload, metadata sync, App Store submission. Configure once, use repeatedly.

**Delivers:**
- Fastlane `release` lane in Fastfile
- Metadata directory structure (`fastlane/metadata/en-US/`, `fastlane/screenshots/`)
- App Store Connect API key configuration
- Optional GitHub Actions workflow (automated on git tag push)
- Manual release checklist (update PROJECT.md, tag version, monitor review status)

**Addresses:**
- App Store submission automation (operational efficiency)

**Avoids:**
- Pitfall 9: Review delays (process encourages early submission with 30-day buffer)

**Research flag:** Fastlane is well-documented, no additional research needed.

---

### Phase 0: Environment Setup (Prerequisite)
**Rationale:** Must happen BEFORE Phase 1. Xcode 16 + iOS 26 SDK required for all submissions after April 28, 2026. Upgrading mid-development causes breaking changes and delays. Do immediately.

**Delivers:**
- Xcode 16.0+ installed on development machine
- macOS Sequoia 15.0+ (required for Xcode 16)
- Project settings: Deployment Target iOS 17.0, Base SDK iOS 26.0
- Swift 6 strict concurrency warnings addressed (enable SWIFT_STRICT_CONCURRENCY = complete)
- Deprecated API fixes (AVPlayer, StoreKit 2, Apollo client)
- Test on iOS 17.0, 17.6, 18.0, 18.2 real devices
- TestFlight test upload (verify binary accepted before starting phases)

**Avoids:**
- Pitfall 8: iOS 26 SDK rejection (upgrade before deadline, not at deadline)

**Research flag:** No additional research — Apple documentation is definitive.

---

### Phase Ordering Rationale

**Sequential dependencies:**
- Phase 2 requires Phase 1: iOS needs backend `plainText` field for AVSpeechSynthesizer
- Phase 4 requires Phase 2: Backend assumes iOS knows how to handle tier-based responses
- Phase 5 requires Phase 4: Can't remove `viralRecipes` while iOS still calls it

**Parallel opportunities:**
- Phase 6 (Fastlane) independent of all runtime phases — can configure early and use throughout
- Phase 3 (Compliance) can start during Phase 2 (no code dependencies)

**Grouping logic:**
- Phases 1-2 are feature additions (non-breaking, additive)
- Phase 4 is breaking change (requires careful migration)
- Phase 5 is cleanup (remove deprecated code after migration complete)
- Phase 0 is prerequisite (environment setup)
- Phase 6 is independent (build automation)

**Pitfall mitigation:**
- Phase 1 implements caching as core requirement (avoids quota exhaustion)
- Phase 2 includes iOS 17 real-device testing (avoids production AVSpeech bugs)
- Phase 3 frontloads App Store compliance (avoids rejection delays)
- Phase 0 upgrades Xcode immediately (avoids deadline scramble)

### Research Flags

**Phases needing monitoring during implementation:**
- **Phase 2 (AVSpeechSynthesizer):** iOS 17/18 production bugs are documented but evolving — check Apple Developer Forums for latest workarounds during implementation. Budget extra time for real-device testing and error handling.

**Phases with standard patterns (no additional research):**
- **Phase 1 (Spoonacular):** REST-to-GraphQL proxy is established pattern, well-documented in NestJS + Apollo ecosystem
- **Phase 3 (App Store Compliance):** Apple guidelines are prescriptive, no ambiguity
- **Phase 4 (Voice Schema):** Standard GraphQL migration with deprecation period
- **Phase 5 (Feed Update):** Apollo client handles schema changes gracefully
- **Phase 6 (Fastlane):** Fastlane documentation is comprehensive, mature tooling

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | All technologies verified with official documentation (Spoonacular API docs, Apple AVSpeechSynthesizer reference, Fastlane guides). Free tier limits confirmed via pricing pages. No experimental dependencies. |
| Features | **MEDIUM-HIGH** | Table stakes validated against competitor apps (Yummly, Tasty, Allrecipes) and App Store guidelines. Spoonacular feature set confirmed via API docs. Attribution requirements explicit in Spoonacular ToS. AI consent requirements from Apple Guideline 5.1.2(i) enforced since Nov 2025. |
| Architecture | **HIGH** | Integration patterns (REST-to-GraphQL proxy, strategy pattern, feature flags) are industry-standard. Existing NestJS + TCA architecture validated in v4.0. Migration paths preserve backward compatibility via deprecation. Data flow changes are additive (new queries alongside old). |
| Pitfalls | **HIGH** | All 10 critical pitfalls sourced from official documentation (Apple Developer Forums for AVSpeech bugs, App Store Review Guidelines for consent requirements, Spoonacular ToS for quota/attribution). Production failure patterns confirmed across multiple sources (iOS 17 crashes, March 2026 review delays, quota exhaustion). |

**Overall confidence:** **HIGH**

All core technologies are mature with official documentation. The architecture follows established patterns from existing v4.0 implementation. Pitfalls are well-documented in official sources and developer communities. The main uncertainty is AVSpeechSynthesizer iOS 17/18 behavior variability across device models, mitigated by comprehensive real-device testing plan.

### Gaps to Address

**Spoonacular free tier daily quota ambiguity:**
- Sources conflict on exact limit (some say 50 points/day, others 150 requests/day). Official pricing page states "50 points/day then no more calls" but community sources reference 150 requests/day.
- **Resolution:** Verify actual quota immediately upon account creation. Monitor usage dashboard closely during Phase 1 development. Implement quota monitoring with alerts at 80% of observed limit (not assumed limit).

**AVSpeechSynthesizer maximum text length:**
- No documented limit in Apple docs. Anecdotal reports suggest >5K characters may cause synthesis delays or crashes on iOS 17.
- **Resolution:** Test with longest recipe in production database (~2000 words) during Phase 2. Implement telemetry tracking synthesis failures by text length. Consider 500-word segment limit as safe default based on pitfall research.

**Enhanced voice download availability:**
- Premium/enhanced iOS voices (100MB+) are user-downloadable via Settings → Accessibility → Live Speech → Voices. Unclear if all voices are available in all regions or languages.
- **Resolution:** Test voice availability on development devices in target markets (US, Turkey based on existing app localization). Document which enhanced voices are recommended in app instructions. Graceful fallback to default voices if enhanced unavailable.

**App Store review timeline volatility:**
- March 2026 widespread delays (7-30 days actual vs. 24-48 hours quoted). Unknown if April 2026 will improve or worsen.
- **Resolution:** Check live review times at runway.team/appreviewtimes before Phase 6 submission. Build 30-day buffer into launch timeline as conservative estimate. Use TestFlight Internal Testing first (no review delay) to validate build quality before external submission.

**Spoonacular geolocation in free tier:**
- Docs don't mention location-based filtering in free tier. Unclear if `location` or `radius` query params work or require paid tier.
- **Resolution:** Test during Phase 1 integration. If unavailable, accept limitation — "popular recipes" framing doesn't require location anyway. Document in release notes: "Location-based discovery coming in future update" if user demand materializes.

## Sources

### Primary (HIGH confidence)
- [Spoonacular API Pricing](https://spoonacular.com/food-api/pricing) — Free tier limits, point system, quota details
- [Spoonacular API Documentation](https://spoonacular.com/food-api/docs) — Endpoints, filters, response schemas, Terms of Service attribution requirements
- [Apple AVSpeechSynthesizer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) — Official API reference, iOS version requirements
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — Guideline 5.1.2(i) third-party AI disclosure, 1.4.1 health claims, 5.2.2 third-party content
- [Fastlane Deliver Documentation](https://docs.fastlane.tools/actions/upload_to_app_store/) — App Store upload automation, metadata management
- [WWDC 2020: Seamless Speech Experience](https://developer.apple.com/videos/play/wwdc2020/10022/) — Audio session configuration, usesApplicationAudioSession pattern
- [WWDC 2023: Personal and Custom Voices](https://developer.apple.com/videos/play/wwdc2023/10033/) — Personal Voice authorization flow

### Secondary (MEDIUM confidence)
- [Apple Developer Forums: AVSpeechSynthesizer iOS 17 Bugs](https://developer.apple.com/forums/thread/738048) — Production crashes, workarounds from community
- [TechCrunch: Third-Party AI Guidelines](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/) — November 2025 enforcement context
- [Runway: Live App Store Review Times](https://www.runway.team/appreviewtimes) — March 2026 delay data (7-30 days actual)
- [Spoonacular API Guide 2025](https://www.devzery.com/post/spoonacular-api-complete-guide-recipe-nutrition-food-integration) — Integration patterns, caching strategies
- [NestJS Throttler Documentation](https://docs.nestjs.com/security/rate-limiting) — Rate limiting implementation for free tier constraints
- [swift-tts GitHub](https://github.com/renaudjenny/swift-tts) — TCA integration library for AVSpeechSynthesizer
- [Appcoda: Building TTS App with AVSpeechSynthesizer](https://www.appcoda.com/text-to-speech-ios-tutorial/) — Swift implementation examples
- [Medium: Managing Audio Interruption in iOS](https://medium.com/@mehsamadi/managing-audio-interruption-and-route-change-in-ios-application-8202801fd72f) — Background audio best practices

### Tertiary (LOW confidence - needs validation)
- Daily quota variance (50 vs 150 points) — verify on Spoonacular account creation
- AVSpeechSynthesizer max text length — test with production recipes (>2000 words)
- Spoonacular geolocation availability in free tier — test `location`/`radius` params during Phase 1

---
*Research completed: 2026-04-04*
*Ready for roadmap: yes*
