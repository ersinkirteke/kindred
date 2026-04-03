# Feature Research

**Domain:** Recipe API integration, iOS text-to-speech, and App Store submission for existing cooking app
**Researched:** 2026-04-04
**Confidence:** MEDIUM-HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or app gets rejected.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Recipe search with filters | Core functionality of any recipe app — users need to find recipes by cuisine, diet, meal type | LOW | Spoonacular provides `/recipes/complexSearch` endpoint with built-in filters for cuisine, diet, intolerances, ingredients |
| Recipe images | Visual food presentation is non-negotiable in recipe apps — users judge appeal by image | LOW | Spoonacular provides recipe images in API response (no need for AI generation) |
| Ingredient lists | Users need to know what to buy/use | LOW | Spoonacular returns structured `extendedIngredients` array with amounts, units, and measurements |
| Step-by-step instructions | Users need clear cooking guidance | LOW | Spoonacular returns `analyzedInstructions` with step objects containing text and equipment |
| Nutrition information | Health-conscious users expect calorie/macro data | LOW | Spoonacular auto-calculates nutrition (may contain errors per their disclaimer) |
| Recipe source attribution | App Store REQUIRES proper attribution for third-party content | LOW | Spoonacular provides `sourceName`, `sourceUrl`, and `creditsText` fields — MUST display with link back to source |
| Privacy disclosure for third-party APIs | Apple enforces Guideline 5.1.2(i) — must disclose data sharing with third-party services | MEDIUM | Privacy Policy must name Spoonacular explicitly, declare what data is sent (search queries, user preferences), and obtain consent before first API call |
| App Store screenshots matching build | Metadata must reflect actual app functionality — mismatches cause rejection | LOW | Cannot show features not in submitted build; must use correct device frames and RGB color space |
| Spoonacular logo/attribution | Spoonacular Terms require displaying their logo and link in app | LOW | Usually in recipe detail view or app settings/about section |
| Offline fallback for failed API calls | App must handle quota exceeded (402), network errors, and rate limits gracefully | MEDIUM | Local caching (max 1 hour per Spoonacular Terms), error states, retry logic with exponential backoff |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AVSpeechSynthesizer for free-tier voice | Zero-cost TTS for guests/free users — removes $0.01-0.03/recipe ElevenLabs cost | MEDIUM | On-device synthesis, works offline, 150+ voices, supports SSML for intonation control |
| Personal Voice integration (iOS 17+) | Users can narrate recipes in their own AI-generated voice alongside system voices | HIGH | Requires `requestPersonalVoiceAuthorization()`, shows user's Personal Voices in AVSpeechSynthesisVoice list — premium feel at zero cost |
| Enhanced/Premium voice downloads | Higher quality voices (100MB+ each) for better narration experience | LOW | Users download via Settings → Accessibility → Live Speech → Voices; app can prompt but can't auto-download |
| Smart voice pausing during interruptions | Handle phone calls, notifications, other audio without breaking narration | MEDIUM | Requires `usesApplicationAudioSession = false` to delegate interruption handling to system; observe audio session notifications |
| SSML-enhanced recipe narration | Use SSML markup for better pacing, emphasis, pauses in cooking instructions | MEDIUM | `AVSpeechUtterance(ssmlRepresentation:)` available in iOS 16+; improves naturalness with `<break>`, `<emphasis>`, `<prosody>` tags |
| Recipe-ingredient pantry matching | Spoonacular's `/recipes/findByIngredients` shows `usedIngredients`, `missedIngredients`, `unusedIngredients` | LOW | Already have pantry feature — can enhance feed ranking with Spoonacular's ingredient matching |
| Dietary/allergen filtering persistence | Spoonacular supports dietary tags (vegan, keto, gluten-free) and intolerances (dairy, egg, peanut, etc.) | LOW | Already have dietary filtering — Spoonacular aligns with existing UX |
| Cost per serving display | Spoonacular returns `pricePerServing` field — helps budget-conscious users | LOW | Nice value-add; differentiate from free apps that don't show cost data |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Unlimited recipe browsing on free tier | Users want access to all 365K+ recipes | Spoonacular free tier is 150 requests/day — burns quota fast with pagination/infinite scroll | Cache popular/trending recipes locally; limit free users to curated daily picks; prompt Pro upgrade for search |
| Real-time voice downloading in-app | Auto-download enhanced voices for better quality | Enhanced/Premium voices are 100MB+ each; iOS doesn't allow programmatic downloads — user must go to Settings | Provide in-app instructions/deep link to Settings → Accessibility → Live Speech → Voices; detect voice quality and suggest upgrade |
| Aggressive retry on quota exceeded | Retry failed API calls to improve reliability | Spoonacular returns 402 when quota exceeded — retrying wastes attempts and delays failure feedback | Detect 402 specifically, show clear "daily limit reached" message, cache aggressively (1 hour max per Terms) |
| AVSpeechSynthesizer background playback without audio session setup | Assume speech "just works" in background | iOS requires Background Modes capability + proper audio session category (`playback` mode with `voicePrompt`) to play in background/locked screen | Enable "Audio, AirPlay, Picture-in-Picture" background mode; configure AVAudioSession category `.playback` with mode `.voicePrompt` |
| Displaying ALL Spoonacular recipe data | Show every field returned by API for "completeness" | Response includes 50+ fields (gaps, lowFodmap, weightWatcherSmartPoints, etc.) — clutters UI and confuses users | Curate display: title, image, servings, time, nutrition (calories/protein/carbs), ingredients, instructions; hide niche fields unless relevant to user |
| Bypassing Spoonacular attribution | Hide source attribution to look like original content | Violates Spoonacular Terms AND App Store Guideline 5.2.2 (third-party content requires authorization proof) — causes rejection and potential account termination | Prominently display `sourceName` with hyperlink to `sourceUrl`; show Spoonacular logo in About/Settings |
| Using recipe data to clone Spoonacular | Build competing recipe database/API using Spoonacular data | Explicitly prohibited in Spoonacular Terms: "cannot create a site meant to provide the same experience as spoonacular" | Use Spoonacular as backend API, focus differentiation on UX (voice narration, pantry matching, personalization) not raw recipe database |

## Feature Dependencies

```
[Recipe Search with Filters]
    └──requires──> [Spoonacular API Integration]
                       └──requires──> [API Key Management]
                       └──requires──> [Rate Limit Handling]
                       └──requires──> [Attribution Display]

[Voice Narration with AVSpeechSynthesizer]
    └──requires──> [Audio Session Configuration]
    └──requires──> [Background Audio Capability]
    └──optional──> [SSML Markup Generation] (for better naturalness)
    └──optional──> [Personal Voice Authorization] (iOS 17+ premium feature)

[Recipe Detail View]
    └──requires──> [Recipe Search with Filters] (data source)
    └──requires──> [Recipe Source Attribution] (legal compliance)
    └──enhances──> [Voice Narration] (what to narrate)

[App Store Submission]
    └──requires──> [Privacy Policy with Spoonacular Disclosure]
    └──requires──> [App Store Screenshots Matching Build]
    └──requires──> [Third-Party AI Consent Flow] (if using Gemini/ElevenLabs for Pro)
    └──requires──> [Privacy Manifest Updated] (if needed)

[Offline Fallback]
    └──requires──> [Local Recipe Caching]
    └──conflicts──> [Real-time Recipe Data] (1-hour cache max per Spoonacular Terms)
```

### Dependency Notes

- **Recipe Search requires Rate Limit Handling:** Spoonacular free tier has 150 requests/day and 1 req/sec limits. Must implement request throttling, queue management, and 402 error detection to avoid burning quota.
- **Voice Narration requires Audio Session Configuration:** AVSpeechSynthesizer activates AVAudioSession but doesn't deactivate it, causing other audio to remain "ducked." Setting `usesApplicationAudioSession = false` delegates session management to system but removes app control over audio options.
- **Personal Voice enhances Voice Narration (iOS 17+):** Users can authorize access to their AI-generated Personal Voice via `requestPersonalVoiceAuthorization()`. Once authorized, Personal Voices appear in `AVSpeechSynthesisVoice.speechVoices()` alongside system voices. Premium feature at zero cost.
- **App Store Submission requires Privacy Disclosure for Spoonacular:** Apple Guideline 5.1.2(i) enforces disclosure when sharing user data with third-party services. Even though Spoonacular receives only search queries (not personal data), Privacy Policy must name Spoonacular and explain data sharing.
- **Local Caching conflicts with Real-time Data:** Spoonacular Terms allow caching for up to 1 hour, then must delete and refresh via API. Cannot cache indefinitely for offline-first experience.
- **Attribution Display required for Recipe Detail:** Spoonacular Terms require crediting original source with hyperlink. App Store Guideline 5.2.2 requires authorization proof for third-party content. Both align — must display `sourceName` + `sourceUrl`.

## MVP Definition

### Launch With (v5.0 — Lean App Store Launch)

Minimum viable product — what's needed to ship to App Store with zero monthly SaaS costs.

- [x] **Spoonacular API integration** — Replace X API scraping with Spoonacular `/recipes/complexSearch` endpoint (150 requests/day free tier)
- [x] **Recipe image display from Spoonacular** — Use Spoonacular-provided images instead of Imagen 4 AI generation (saves ~$0.01/image)
- [x] **Spoonacular source attribution** — Display `sourceName` with hyperlink to `sourceUrl` on recipe detail view (legal requirement)
- [x] **AVSpeechSynthesizer for free-tier voice** — Use on-device TTS for guest/free users instead of ElevenLabs (saves $0.01-0.03/recipe)
- [x] **Audio session background playback** — Configure `.playback` category with `.voicePrompt` mode for lock screen narration
- [x] **Rate limit handling** — Detect 402 quota exceeded errors, implement 1-hour local caching, show "daily limit reached" state
- [x] **Privacy Policy update** — Add Spoonacular disclosure (name, data shared, consent) per Apple Guideline 5.1.2(i)
- [x] **App Store screenshots refresh** — Update screenshots to remove "viral near you" framing, replace with "popular recipes" (no location dependence)
- [x] **Fastlane release lane** — Automate iOS app submission to App Store via `fastlane release`

### Add After Validation (v5.x)

Features to add once core is working and initial users validate the approach.

- [ ] **SSML-enhanced narration** — Use `AVSpeechUtterance(ssmlRepresentation:)` with `<break>`, `<emphasis>`, `<prosody>` tags for better pacing (triggers: user feedback on voice quality)
- [ ] **Personal Voice integration** — Request authorization for iOS 17+ users to narrate in their own voice (triggers: Pro user adoption shows willingness to pay)
- [ ] **Enhanced voice download prompts** — Detect default voice quality, show in-app instructions to download Premium voices (triggers: analytics show users listening to full narrations)
- [ ] **Recipe cost filtering** — Use Spoonacular's `pricePerServing` field to filter budget-friendly recipes (triggers: user requests for budget features)
- [ ] **Spoonacular meal planning** — Leverage `/mealplanner` endpoints for weekly meal plans (triggers: retention data shows users save/bookmark multiple recipes)
- [ ] **Ingredient-based search optimization** — Use `/recipes/findByIngredients` with existing pantry data for "cook with what you have" feature (triggers: pantry feature usage shows engagement)

### Future Consideration (v6+)

Features to defer until product-market fit is established.

- [ ] **Multi-voice narration** — Support multiple AVSpeechSynthesizer voices in single recipe (e.g., different voices for ingredients vs. instructions) — why defer: complexity without proven user demand
- [ ] **Spoonacular nutrition analysis** — Use `/recipes/analyzeRecipe` endpoint for user-submitted recipes — why defer: not core to discovery-first UX, adds complexity
- [ ] **Custom recipe uploads to Spoonacular** — Store user recipes via Spoonacular API — why defer: Spoonacular charges per custom recipe stored, not cost-effective for lean launch
- [ ] **Voice speed/pitch customization** — Expose AVSpeechUtterance `rate` and `pitchMultiplier` properties — why defer: niche power-user feature, complicates UX
- [ ] **Offline voice synthesis caching** — Pre-generate and cache AVSpeechSynthesizer audio files — why defer: AVSpeechSynthesizer synthesizes on-demand (no access to raw audio buffer), would require AVSpeechSynthesizerDelegate streaming to file which adds complexity

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Spoonacular API integration | HIGH (core replacement for scraping) | MEDIUM (new API client, GraphQL schema updates) | P1 |
| AVSpeechSynthesizer for free tier | HIGH (removes $0.01-0.03/recipe cost) | MEDIUM (audio session config, background playback) | P1 |
| Recipe source attribution | HIGH (legal requirement for App Store) | LOW (display `sourceName` + hyperlink) | P1 |
| Rate limit handling (402 errors) | HIGH (prevents broken UX when quota exceeded) | MEDIUM (error detection, caching, retry logic) | P1 |
| Privacy Policy update | HIGH (App Store rejection risk) | LOW (add Spoonacular disclosure to existing policy) | P1 |
| Audio session interruption handling | MEDIUM (prevents broken playback during calls/notifications) | MEDIUM (observe notifications, handle lifecycle) | P1 |
| App Store screenshots refresh | MEDIUM (metadata must match build) | LOW (capture new screens, update ASC) | P1 |
| SSML-enhanced narration | MEDIUM (improves voice quality perception) | MEDIUM (parse instructions, inject SSML tags) | P2 |
| Personal Voice integration (iOS 17+) | MEDIUM (premium differentiation at zero cost) | HIGH (authorization flow, voice listing, testing) | P2 |
| Enhanced voice download prompts | LOW (nice UX improvement) | LOW (detect voice quality, show instructions) | P2 |
| Recipe cost filtering | MEDIUM (budget-conscious users) | LOW (use existing filter UX, add `pricePerServing` param) | P2 |
| Spoonacular meal planning | MEDIUM (retention feature) | HIGH (new feature area, complex UX) | P3 |
| Ingredient-based search optimization | MEDIUM (leverages existing pantry) | MEDIUM (new API endpoint, ranking logic) | P3 |
| Multi-voice narration | LOW (novelty without proven demand) | HIGH (manage multiple synthesizers, timing coordination) | P3 |
| Custom recipe uploads | LOW (not core to discovery UX) | HIGH (new UX, Spoonacular charges per recipe) | P3 |

**Priority key:**
- P1: Must have for v5.0 launch (lean App Store release)
- P2: Should have for v5.x (add when usage validates approach)
- P3: Nice to have for v6+ (defer until product-market fit)

## Competitor Feature Analysis

| Feature | Recipe apps (Yummly, Tasty, Allrecipes) | Our Approach (Kindred v5.0) |
|---------|------------------------------------------|------------------------------|
| Recipe database | Proprietary recipe databases OR licensing deals | Spoonacular API (365K+ recipes, free tier 150 req/day) |
| Recipe images | High-quality photography OR user submissions | Spoonacular-provided images (no AI generation needed) |
| Voice narration | Text-to-speech with robotic voices OR no voice feature | AVSpeechSynthesizer (on-device, offline, 150+ voices) + ElevenLabs behind Pro paywall |
| Personalization | Dietary filters, manual preferences | Existing Culinary DNA (60/40 personalization/discovery) + Spoonacular dietary filters |
| Pantry management | Manual ingredient lists | Smart pantry with fridge/receipt scanning + Spoonacular ingredient matching |
| Monetization | Ads + subscriptions for ad removal | Free tier with AdMob + Pro tier ($9.99/mo) for ElevenLabs voices, advanced features |
| Offline support | Limited or none | AVSpeechSynthesizer works fully offline; recipe data cached 1 hour per Spoonacular Terms |
| Location-based discovery | None (generic recipe browsing) | Remove "viral near you" framing for v5.0 (X API too expensive); reframe as "popular recipes" |
| Source attribution | Often buried or missing | Prominent display per Spoonacular Terms + App Store compliance |

**Our differentiation:**
- **Voice narration quality**: Premium ElevenLabs voices behind paywall + free AVSpeechSynthesizer for all users (competitors have robotic TTS or no voice)
- **Smart pantry integration**: Already built fridge/receipt scanning — can enhance with Spoonacular ingredient matching
- **Zero SaaS costs for core features**: Spoonacular free tier + AVSpeechSynthesizer = $0/month baseline (vs. ElevenLabs $0.01-0.03/recipe + Imagen $0.01/image + X API)

## App Store Submission Specifics

### Required for Approval

| Requirement | Details | Rejection Risk |
|-------------|---------|----------------|
| **Third-party content authorization** | Must provide proof of authorization to use Spoonacular recipes | HIGH — Guideline 5.2.2 |
| **Privacy disclosure for third-party APIs** | Clearly disclose Spoonacular data sharing, name the service, obtain explicit consent before first API call | HIGH — Guideline 5.1.2(i) enforced Nov 2025 |
| **App Privacy Labels** | Declare data shared with Spoonacular (search queries, dietary preferences) in App Store Connect | HIGH — Missing/inaccurate labels cause rejection |
| **Accurate screenshots** | Screenshots must match submitted build functionality; correct device frames, RGB color space, no placeholder content | MEDIUM — 40% of first submissions rejected for metadata issues |
| **Minimum functionality** | App must feel complete, no broken links, crashes, or unfinished features | HIGH — Guideline 2.1 Performance |
| **Not spam/template** | Guideline 4.3 Design/Spam — app must provide unique, high-quality experience beyond generic recipe browsing | MEDIUM — Recipe apps are somewhat saturated |
| **Proper attribution display** | Spoonacular logo and link required per Terms; source attribution per recipe required per App Store + Spoonacular | MEDIUM — Third-party content compliance |

### Common Rejection Reasons (Food/AI Apps)

1. **Missing AI disclosure**: Apps that use AI (Gemini, ElevenLabs for Pro users) must clearly explain how they work, which service is used, what data is shared — rejection if hidden or vague
2. **Privacy violations**: Camera permission (fridge scanning), location permission (city picker) flagged by automated review even when legitimately used — provide clear usage descriptions in Info.plist
3. **Misleading capabilities**: If screenshots show features (e.g., ElevenLabs voice cloning) not accessible in submitted build (e.g., broken paywall), rejection occurs
4. **Incomplete app**: Crashes during review, placeholder content, "coming soon" features trigger immediate rejection
5. **Copyright/attribution**: Recipe sources without proper attribution or missing Spoonacular Terms compliance

### TestFlight Beta Testing (Optional but Recommended)

- **No minimum testers required** — can submit to TestFlight with zero external testers
- **Maximum limits**: 100 internal testers (Account Holder, Admin, App Manager, Developer, Marketing roles), 10,000 external testers
- **First build review**: External TestFlight distribution requires App Review approval (same guidelines as production)
- **Value for Kindred**: Test rate limit handling (150 req/day exhaustion), voice narration quality on real devices, attribution display compliance

## Sources

**Spoonacular API:**
- [Spoonacular API Pricing](https://spoonacular.com/food-api/pricing) — Free tier details, point system
- [Spoonacular API Terms](https://spoonacular.com/food-api/terms) — Attribution requirements, caching limits
- [Guide to Spoonacular API 2025](https://www.devzery.com/post/spoonacular-api-complete-guide-recipe-nutrition-food-integration) — Feature overview
- [Spoonacular API Tutorial](https://blog.api.rakuten.net/api-tutorial-spoonacular-api-for-food-and-recipes/) — Real-world usage examples
- [Building Recipe App with Spoonacular](https://reintech.io/blog/building-recipe-app-android-spoonacular-api) — Implementation patterns

**AVSpeechSynthesizer:**
- [On-Device TTS on Apple Devices](https://www.callstack.com/blog/on-device-text-to-speech-on-apple-devices-with-ai-sdk) — Offline synthesis, quality tiers
- [WWDC23: Personal and Custom Voices](https://developer.apple.com/videos/play/wwdc2023/10033/) — Personal Voice authorization
- [Using Personal Voice in iOS App](https://bendodson.com/weblog/2024/04/03/using-your-personal-voice-in-an-ios-app/) — Implementation guide
- [WWDC20: Seamless Speech Experience](https://developer.apple.com/videos/play/wwdc2020/10022/) — Audio session best practices
- [Managing Audio Interruption in iOS](https://medium.com/@mehsamadi/managing-audio-interruption-and-route-change-in-ios-application-8202801fd72f) — Interruption handling
- [Apple Developer Forums: AVSpeechSynthesizer Issues](https://developer.apple.com/forums/) — Common issues: background playback, pausing bugs, audio session conflicts

**App Store Submission:**
- [iOS App Store Review Guidelines 2026](https://theapplaunchpad.com/blog/app-store-review-guidelines) — AI disclosure requirements
- [App Store Review Guidelines (Official)](https://developer.apple.com/app-store/review/guidelines/) — Authoritative source
- [Navigating AI Rejections in App Store](https://appitventures.com/blog/navigating-ai-rejections-app-store-play-store-submissions) — AI-specific rejections
- [Apple App Review Guidelines: Essential AI Rules](https://openforge.io/app-store-review-guidelines-2025-essential-ai-app-rules/) — Guideline 5.1.2(i) details
- [TechCrunch: Third-Party AI Guidelines](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/) — Nov 2025 enforcement
- [App Store Screenshots Guidelines 2026](https://theapplaunchpad.com/blog/app-store-screenshots-guidelines-in-2026) — Metadata compliance
- [Common App Store Rejections](https://appfollow.io/blog/app-store-review-guidelines) — First submission mistakes
- [TestFlight Overview (Official)](https://developer.apple.com/testflight/) — Beta testing requirements

**Third-Party Content & Copyright:**
- [Apple Guidelines for Third-Party Content](https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html) — Copyright/trademark requirements
- [Recipe Copyright Issues](https://www.legalmatch.com/law-library/article/recipe-copyright-issues.html) — Legal status of recipes
- [Publishing Apps: Legal Considerations](https://legarithm.io/blog/publishing-an-app-on-the-apple-store-legal-considerations/) — Third-party content authorization

---
*Feature research for: Lean App Store Launch (Spoonacular, AVSpeechSynthesizer, App Store submission)*
*Researched: 2026-04-04*
*Confidence: MEDIUM-HIGH (Context7 unavailable for Spoonacular/AVSpeechSynthesizer; official docs + WebSearch verified with multiple sources)*
