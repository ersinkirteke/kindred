# Pitfalls Research

**Domain:** iOS Recipe App - Lean App Store Launch (Spoonacular API, AVSpeechSynthesizer, First Submission)
**Researched:** 2026-04-04
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Spoonacular Free Tier Quota Exhaustion Within Days

**What goes wrong:**
150 requests/day free tier gets exhausted within 2-3 days of launch. Each API call costs "points" - usually 1 point per request plus 0.01 points per result. With minimal user traffic (10 active users viewing 15 recipes/day), you exceed quota before implementing proper caching. App becomes non-functional until next day's quota reset.

**Why it happens:**
Developers test against Spoonacular without caching layer, assuming 150 requests/day is sufficient. They forget that each recipe detail fetch, nutrition lookup, and image URL retrieval counts separately. Nested loops making repetitive calls or unbatched requests exhaust quota exponentially faster than expected.

**How to avoid:**
1. Implement 1-hour cache maximum (Spoonacular ToS requirement) using Redis or in-memory cache
2. Store recipe details, nutrition data, and image URLs in PostgreSQL after first fetch
3. Use cache-aside pattern: check cache → check database → fetch from API only if both miss
4. Pre-populate database with 50-100 popular recipes during development to reduce day-1 API calls
5. Add quota monitoring dashboard tracking daily usage with alerts at 80% threshold
6. Implement request batching where Spoonacular API supports it

**Warning signs:**
- API calls fail with 402 Payment Required or quota exceeded errors
- Usage statistics show >100 points consumed in first 24 hours
- Multiple users report "No recipes available" messages
- Cache hit rate <70% in first week of production

**Phase to address:**
Phase 1: Spoonacular Integration (implement caching layer as core requirement, not optimization)

---

### Pitfall 2: AVSpeechSynthesizer iOS 17/18 Production Bugs Cause Silent Failures

**What goes wrong:**
AVSpeechSynthesizer crashes on iOS 17.0-17.2 with "Could not find audio unit" errors (TTSErrorDomain Code -4010). Speech playback stops mid-utterance after 300 words on 1200-word recipes. Memory leaks cause app crashes after 5-10 recipe narrations. Some iOS voices produce no sound without error messages. Background audio stops when app backgrounds despite audio session configuration.

**Why it happens:**
AVSpeechSynthesizer has unresolved bugs across iOS 16-18. Apple's audio unit loading fails intermittently on real devices (works fine in Simulator). The API has undefined behavior on iOS 17 where it abruptly stops at random points. Audio session management is broken - synthesizer activates audio session but never deactivates it, leaving other audio "ducked" permanently.

**How to avoid:**
1. Implement comprehensive error handling with user-visible fallback ("Voice unavailable, showing text instead")
2. Add utterance boundary detection - if `didFinish` fires before expected duration, log error and show warning
3. Manually deactivate audio session after synthesis completes: `try? AVAudioSession.sharedInstance().setActive(false)`
4. Test on iOS 17.0-17.6 and iOS 18.0+ real devices (not Simulator) across iPhone 14/15/16 models
5. Implement audio session state monitoring to detect ducking issues
6. Add telemetry tracking synthesis failures by iOS version/device model
7. Limit utterance length to 500 words max, split longer recipes into segments
8. Keep AVPlayer + ElevenLabs as fallback path for critical failures

**Warning signs:**
- User reports: "Voice stops halfway through recipe"
- Analytics show <60% narration completion rate
- Crash reports with `AVAudioUnit` in stack trace
- Background music apps remain quiet after narration ends
- TestFlight beta testers on iOS 17.x report higher failure rates than iOS 18.x users

**Phase to address:**
Phase 2: AVSpeechSynthesizer Integration (include iOS 17/18 real-device testing as acceptance criteria)

---

### Pitfall 3: App Store Rejection for Missing Third-Party AI Consent (Guideline 5.1.2i)

**What goes wrong:**
App rejected during review because ElevenLabs integration lacks explicit user consent modal. Reviewer flags that voice cloning uploads personal data (voice recordings) to third-party AI (ElevenLabs) without dedicated consent screen. Existing voice consent screen bundled with recording flow doesn't meet guideline 5.1.2(i) requirements added November 2025.

**Why it happens:**
Apple updated guidelines in November 2025 requiring apps to "clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so." Consent must appear BEFORE first data transmission, must be unbundled from other permissions, and must specify the AI provider name. Many apps built pre-November 2025 violate this unknowingly.

**How to avoid:**
1. Show dedicated consent modal BEFORE voice upload screen with exact text:
   - "Kindred Pro uses ElevenLabs AI to clone voices. Your voice recording will be sent to ElevenLabs (third-party AI provider) for processing."
   - Two buttons: "Allow" / "Don't Allow" (not "Continue" / "Cancel")
2. Store consent timestamp, IP, userId, app version in `voice_consent_audit` table
3. Block voice upload if user taps "Don't Allow"
4. Update Privacy Policy to list ElevenLabs as third-party data processor
5. Update App Privacy labels in App Store Connect: Data Types → Audio → Linked to User → Shared with ElevenLabs
6. Add PrivacyInfo.xcprivacy disclosure for ElevenLabs API domain
7. Test: Reviewer must see consent modal on first Pro upgrade attempt

**Warning signs:**
- App Store rejection with "Guideline 5.1.2(i) - Privacy - Data Use and Sharing" citation
- Reviewer notes: "App does not obtain permission before sharing data with third-party AI"
- Privacy labels don't list ElevenLabs in "Third-Party Partners" section
- Consent modal appears AFTER voice recording instead of BEFORE

**Phase to address:**
Phase 3: App Store Compliance (implement before TestFlight external beta submission)

---

### Pitfall 4: Spoonacular Data Model Mismatch Breaks Existing Recipe Flow

**What goes wrong:**
Existing app expects `Recipe` schema with fields like `viralScore`, `sourceUrl` (Instagram/X link), `scrapedAt`, `locationId`. Spoonacular returns completely different schema: `spoonacularScore`, `sourceUrl` (recipe blog), `analyzedInstructions`, `extendedIngredients`. Migration breaks feed rendering, bookmarks, pantry matching, and voice narration script generation. Database migration requires rewriting 8+ queries across 4 GraphQL resolvers.

**Why it happens:**
Custom scraping pipeline creates domain-specific schema optimized for viral social content. Spoonacular is recipe-first (not social-first), with different data structures. Developers assume "recipe API" means compatible schema, attempt drop-in replacement without adapter layer. Nutrition data format differs (Spoonacular uses `nutrition.nutrients[]` array, custom API uses flat `calories`/`protein` fields).

**How to avoid:**
1. Create `SpoonacularAdapter` service translating Spoonacular schema to internal `Recipe` model
2. Map fields explicitly:
   - `spoonacularScore` → `viralScore` (with normalization algorithm)
   - `sourceUrl` → store as-is but add `source: 'spoonacular'` tag
   - `analyzedInstructions[0].steps` → flatten to `instructions: string`
   - `extendedIngredients` → `ingredients: {name, amount, unit}[]`
   - `nutrition.nutrients` → extract calories, protein, carbs, fat to flat fields
3. Update GraphQL schema to support both sources during migration:
   ```graphql
   type Recipe {
     viralScore: Float # computed differently per source
     source: RecipeSource! # 'scraping' | 'spoonacular'
     sourceUrl: String
   }
   ```
4. Run dual-write migration: write to both schemas for 2 weeks, compare outputs
5. Update pantry ingredient matching to handle Spoonacular's ingredient format
6. Test voice narration script generation with Spoonacular `analyzedInstructions` structure

**Warning signs:**
- TypeScript compilation errors after integrating Spoonacular types
- Feed shows `undefined` for recipe metadata fields
- Ingredient matching accuracy drops below 60%
- Voice narration scripts are malformed or missing steps
- GraphQL queries return null for previously working fields

**Phase to address:**
Phase 1: Spoonacular Integration (build adapter layer first, direct integration second)

---

### Pitfall 5: Mixed TTS Quality (AVSpeechSynthesizer Free vs ElevenLabs Pro) Creates Negative User Perception

**What goes wrong:**
Free-tier users experience robotic, monotone AVSpeechSynthesizer narration. They see paywalled "Pro" tier promising "natural voice cloning." Users downgrade perception of entire app because free tier feels cheap/broken compared to Pro marketing. 1-star reviews: "App is unusable without paying." Conversion rate to Pro is <2% because free experience creates negative anchor instead of desire to upgrade.

**Why it happens:**
When TTS is "close to human" (ElevenLabs), users raise standards - small unnatural moments break the illusion. When TTS is "clearly synthetic" (AVSpeechSynthesizer), users forgive it BUT if you show them the better version exists behind paywall, free version feels punitive instead of functional. Premium TTS creates expectation that free tier can't meet. User perceives value destruction, not value add.

**How to avoid:**
1. NEVER show ElevenLabs demos/previews to free-tier users - don't create unfavorable comparison
2. Frame AVSpeechSynthesizer as "built-in narration" not "free tier voice"
3. Add voice customization for AVSpeechSynthesizer (pitch, rate, volume) to increase perceived value
4. Use iOS 16+ "enhanced" or "premium" voices (100MB+ downloads) instead of default quality voices
5. Prompt users to download enhanced voices in Settings: "Improve voice quality - download enhanced English voice (120MB)"
6. Position Pro as "personalized cloning" not "better quality" - differentiate on emotion, not fidelity
7. A/B test: Group A sees "Basic Voice" (free) vs "Cloned Voice" (Pro). Group B sees just AVSpeech with no Pro upsell.
8. Monitor conversion rate and 1-star reviews mentioning "robotic" or "unusable without paying"

**Warning signs:**
- App Store reviews mention "free tier is unusable"
- Conversion to Pro <3% despite high feature engagement
- Users immediately hit paywall, bounce without trying narration
- Support tickets: "Why does free version sound so bad?"
- Retention drops >40% after first narration playback

**Phase to address:**
Phase 2: AVSpeechSynthesizer Integration (include enhanced voice quality and messaging strategy)

---

### Pitfall 6: Spoonacular Recipe Images Violate Attribution Requirements, Risk Removal

**What goes wrong:**
App displays Spoonacular-provided recipe images without required attribution. Spoonacular ToS mandates displaying their logo and link back to spoonacular.com. App Store reviewer or Spoonacular notices violation during traffic spike, sends cease & desist. App removed from store for ToS violation until attribution added. Legal fees $5-15K to resolve.

**Why it happens:**
Developers assume API-provided images are freely usable in commercial apps. Spoonacular documentation mentions attribution but doesn't enforce it technically (images load without attribution). Most recipe APIs require attribution "somewhere in your app" - usually interpreted as small footer link. Commercial use requires following their attribution rules.

**How to avoid:**
1. Read Spoonacular ToS attribution requirements at spoonacular.com/food-api/docs
2. Add "Powered by Spoonacular" badge on recipe detail view (near image or footer)
3. Make badge tappable, opens spoonacular.com in Safari
4. Update App Store description: "Recipe data provided by Spoonacular"
5. Email Spoonacular compliance team with app details BEFORE launch for pre-approval
6. Monitor for attribution requirement changes in API docs (set calendar reminder quarterly)
7. Consider: Display attribution less prominently for Pro users? (Check ToS)

**Warning signs:**
- Spoonacular sends email about missing attribution
- App Store reviewer questions image licensing
- Competitor recipe app has visible "Powered by" badge, yours doesn't
- Legal/compliance section of Spoonacular docs unclear about mobile app requirements

**Phase to address:**
Phase 1: Spoonacular Integration (implement attribution UI component alongside image loading)

---

### Pitfall 7: App Store Rejection for Unverified Nutrition Data / Health Claims

**What goes wrong:**
App displays Spoonacular nutrition data (calories, macros, allergen info) as definitive facts. Reviewer flags guideline 1.4.1: "Apps that claim to take x-rays, measure blood pressure... or provide other diagnoses must show proof of proper regulatory approval." Nutrition apps must "clearly disclose data and methodology to support accuracy claims." Spoonacular ToS states users are "responsible for ensuring FDA compliance independently."

**Why it happens:**
Spoonacular sources data from USDA FoodData Central + public recipe sites + user submissions. Core ingredient nutrition is reliable, but recipe nutrition varies. FDA menu labeling requires specific rounding rules, disclaimer text. Apps presenting nutrition as medical-grade data without disclaimers violate App Store guideline 1.4.1. Reviewer interprets "accurate calorie tracking" marketing copy as medical device claim.

**How to avoid:**
1. Add disclaimer on recipe detail nutrition section: "Nutrition estimates provided by Spoonacular. Not for medical use. Consult healthcare provider for dietary advice."
2. Avoid marketing copy: "accurate," "medical-grade," "clinically validated," "FDA-approved"
3. Use softer language: "estimated nutrition," "approximate calories," "based on USDA data"
4. Update App Store metadata: Remove "health" claims from app description
5. App Store Connect > App Information > App Category: DO NOT select "Medical" - use "Food & Drink"
6. Add HealthKit disclaimer if integrating nutrition export: "This app is not a medical device."
7. Cross-check 10 sample recipes against USDA FoodData Central - document methodology in reviewer notes

**Warning signs:**
- App Store rejection citing guideline 1.4.1 or 5.1.1(ix) (health apps)
- Reviewer asks: "How do you validate nutrition accuracy?"
- Marketing materials use "accurate," "clinically proven," "FDA-compliant"
- App category selected as "Health & Fitness" instead of "Food & Drink"
- Nutrition data displayed without "estimate" qualifier

**Phase to address:**
Phase 3: App Store Compliance (add disclaimers before TestFlight submission)

---

### Pitfall 8: First App Store Submission Binary Rejected for iOS 26 SDK Requirement

**What goes wrong:**
Binary upload succeeds but App Store Connect shows error: "This bundle is invalid. The bundle was built with an SDK older than the minimum required version." Starting April 28, 2026, all apps must use iOS 26 SDK (Xcode 16+). Project still builds with Xcode 15 / iOS 25 SDK. Must rebuild with Xcode 16, which introduces breaking changes in StoreKit 2 and AVFoundation APIs.

**Why it happens:**
Apple's April 2026 deadline catches developers mid-development. Xcode 16 requires macOS Sequoia 15.0+. Upgrading macOS + Xcode introduces Swift 6 strict concurrency warnings, deprecated API warnings. Developers delay upgrade until forced by App Store, then scramble to fix build errors 1-2 days before deadline.

**How to avoid:**
1. Upgrade to Xcode 16.0+ and macOS Sequoia 15.0+ IMMEDIATELY (before starting Phase 1)
2. Build with iOS 26 SDK: Set Deployment Target iOS 17.0, Base SDK iOS 26.0
3. Run full test suite after upgrade - check for runtime behavior changes
4. Fix Swift 6 concurrency warnings preemptively (enable SWIFT_STRICT_CONCURRENCY = complete)
5. Update deprecated APIs flagged by Xcode 16:
   - AVPlayer deprecated methods
   - StoreKit 2 transaction verification changes
   - GraphQL client Apollo 2.x compatibility
6. Test on iOS 17.0, 17.6, 18.0, 18.2 real devices after rebuild
7. Archive and upload test build to TestFlight before starting Phase 3 (App Store prep)

**Warning signs:**
- App Store Connect error: "Invalid Bundle - SDK version too old"
- Xcode 15 still installed on development machine
- macOS version <15.0 (Sequoia)
- Build settings show "iOS 25 SDK" or earlier
- No recent test upload to TestFlight (last upload >30 days ago)

**Phase to address:**
Phase 0: Environment Setup (prerequisite before all other phases)

---

### Pitfall 9: App Store Review Stuck in "Waiting for Review" for 7-30 Days (March 2026 Delays)

**What goes wrong:**
App submitted for review enters "Waiting for Review" status. Apple's website promises 24-48 hours. After 7 days, still waiting. After 14 days, support says "we're experiencing higher than normal volume." Launch delayed by 3-4 weeks. Marketing campaign scheduled for April 15 misses window, wastes $5K ad spend.

**Why it happens:**
March 2026 widespread review delays affecting 80%+ of submissions. Apple quotes 24-48 hours but actual timelines are 7-30 days for new apps, updates, and TestFlight external builds. Root cause unknown (speculation: AI guideline enforcement requires manual review, iOS 26 SDK migration causes backlog).

**How to avoid:**
1. Submit for review 30 days BEFORE target launch date (not 7 days)
2. Use TestFlight Internal Testing first (no review delay, 100 internal testers max)
3. Request Expedited Review ONLY for critical bugs, not launch deadlines (abusing expedite gets account flagged)
4. Check live review times at runway.team/appreviewtimes before submitting
5. Schedule marketing campaign AFTER "Ready for Sale" status, not after submission
6. Build in 4-week buffer for v1.0 submission (App Store review + post-rejection fixes)
7. Use Phased Release (7-day rollout) to catch post-approval issues before 100% traffic

**Warning signs:**
- Submission >7 days in "Waiting for Review" with no update
- runway.team/appreviewtimes shows >5 day average for your region
- Marketing materials already printed/scheduled before "Ready for Sale" confirmation
- No TestFlight Internal Testing completed before external submission
- Timeline assumes 48-hour review (not 30-day worst case)

**Phase to address:**
Phase 4: TestFlight Internal Beta (submit early, identify delays before hard launch deadline)

---

### Pitfall 10: AVSpeechSynthesizer Background Audio Stops When App Backgrounds

**What goes wrong:**
User plays recipe narration via AVSpeechSynthesizer. Locks phone or switches to Messages app. Audio immediately stops despite `UIBackgroundModes` audio entitlement and active audio session. User reports: "Voice narration doesn't work with screen locked."

**Why it happens:**
AVSpeechSynthesizer background audio is unreliable on iOS 16-18. Even with proper audio session configuration (category: `.playback`, mode: `.spokenAudio`, options: `.mixWithOthers`), speech sometimes plays immediately when triggered from background, sometimes doesn't play until app brought to foreground. OS queues audio inconsistently. This is documented AVSpeechSynthesizer bug, not configuration issue.

**How to avoid:**
1. Set audio session BEFORE creating AVSpeechSynthesizer:
   ```swift
   try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
   try AVAudioSession.sharedInstance().setActive(true)
   ```
2. Test background audio on iOS 17.0-17.6 AND iOS 18.0+ real devices (behavior differs)
3. Implement fallback: If app backgrounds during AVSpeech narration, show notification:
   "Return to Kindred to continue narration"
4. Consider: For Pro users, use AVPlayer + ElevenLabs audio files (reliable background playback)
5. Add telemetry: Track `UIApplication.didEnterBackgroundNotification` during narration, log if audio stops
6. Document limitation in app description: "Free narration requires app open. Pro narration supports background playback."
7. Alternative: Keep screen awake during AVSpeech narration using `UIApplication.shared.isIdleTimerDisabled = true`

**Warning signs:**
- User reviews: "Audio stops when I lock my phone"
- AVAudioSession configured but background audio still fails
- Works in iOS Simulator but fails on real devices
- Pro users (ElevenLabs/AVPlayer) don't report issue, only free users (AVSpeech)
- Background audio works for music apps but not for your TTS

**Phase to address:**
Phase 2: AVSpeechSynthesizer Integration (test background playback as acceptance criteria)

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip Spoonacular caching layer | Faster integration (2 hours saved) | Quota exhaustion within days, emergency Redis migration under downtime | Never - caching is table stakes |
| Bundle AI consent with voice upload screen | Simpler UX flow | App Store rejection per guideline 5.1.2(i), 2-week resubmission delay | Never - Apple enforces strictly |
| Use Spoonacular schema directly without adapter | No mapping code (4 hours saved) | Breaking changes when Spoonacular updates API, tightly coupled to external schema | Never - adapter pattern is critical |
| Ship AVSpeechSynthesizer without iOS 17 real-device testing | Skip device lab setup | Production bugs discovered by users, 1-star reviews, emergency hotfix | Never - Simulator hides critical bugs |
| Delay Xcode 16 upgrade until App Store forces it | Avoid breaking changes now | Scramble to fix build errors at deadline, miss launch window | Never - upgrade immediately |
| Use default AVSpeechSynthesizer voices instead of enhanced | Smaller app size, no user prompt | Robotic quality reinforces "cheap free tier" perception, lower conversion | MVP only - prompt for enhanced download in v1.1 |
| Skip Spoonacular attribution | Cleaner UI | ToS violation, app removal, legal fees $5-15K | Never - attribution required by contract |
| Hard-code 150 req/day quota assumption | Simple rate limiting | Breaks when Spoonacular changes free tier limits, requires code change | MVP only - read quota from API response header |
| Display nutrition data without "estimate" disclaimer | Looks more authoritative | App Store rejection 1.4.1, potential FDA/FTC scrutiny | Never - legal liability |
| Schedule launch date before TestFlight submission | Marketing pressure | 30-day review delays force rushed fixes or missed campaign | Never - submit early, market late |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Spoonacular API | Assume `GET /recipes/random` doesn't count against quota | Every endpoint costs points (1 + 0.01/result). Use `GET /recipes/{id}` + cache instead of random endpoint. |
| Spoonacular API | Store image URLs permanently, serve directly | Image URLs may expire or change. Re-fetch URLs daily or host copy (check ToS). |
| Spoonacular API | Parse `analyzedInstructions` as flat string | It's nested array: `analyzedInstructions[0].steps[].step`. Flatten with `.map(s => s.step).join('\n')` |
| AVSpeechSynthesizer | Assume `.speak()` returns when audio finishes | It returns immediately. Use `AVSpeechSynthesizerDelegate.didFinish` for completion. |
| AVSpeechSynthesizer | Create new synthesizer instance per utterance | Causes audio channel conflicts. Reuse single instance, stop previous before starting new. |
| AVSpeechSynthesizer | Forget to check iOS voice availability | Enhanced voices require 100MB download. Check `AVSpeechSynthesisVoice.speechVoices()` contains desired voice. |
| ElevenLabs API | Skip 5.1.2(i) consent modal | Guideline added Nov 2025. Must show BEFORE upload with provider name "ElevenLabs AI". |
| App Store Connect | Upload binary without testing on real iOS 17/18 devices | Simulator hides critical bugs. Test on iPhone 14 Pro (iOS 17.6) and iPhone 16 (iOS 18.2) minimum. |
| App Store Connect | Assume 24-48 hour review time in March 2026 | Actual delays: 7-30 days. Build 30-day buffer into launch timeline. |
| GraphQL Schema | Directly expose Spoonacular types in GraphQL schema | Frontend breaks when Spoonacular changes API. Use internal types + adapter mapping. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No Spoonacular caching | 402 quota errors, empty recipe feed | Implement Redis 1-hour cache + PostgreSQL long-term storage | 10 users × 15 recipes/day = 150 req/day quota exhausted |
| In-memory recipe cache (no Redis) | Cache invalidated on server restart, quota spikes | Use Redis with TTL 1 hour, PostgreSQL for permanent storage | First server restart after launch |
| Fetching Spoonacular images on-demand without CDN | Slow load times, bandwidth costs | Proxy through Cloudflare R2 CDN or use Spoonacular URLs directly | >100 concurrent users |
| Generating AVSpeech narration on main thread | UI freezes during synthesis | Dispatch to background queue: `DispatchQueue.global(qos: .userInitiated).async` | Recipes >500 words |
| No telemetry for AVSpeech failures | Silent failures, no visibility into iOS 17 bugs | Log synthesis errors to analytics with iOS version + device model | Launch day - user complaints with no diagnostic data |
| Single GraphQL resolver fetching recipe + Spoonacular data synchronously | Timeout errors, slow feed load | Use DataLoader pattern batching Spoonacular requests, cache aggressively | >50 requests/minute to feed endpoint |
| No Spoonacular request queuing during quota exhaustion | Cascade failures, user sees errors | Queue requests, retry after quota reset (midnight UTC), serve from cache | First quota exhaustion event |
| AVSpeechSynthesizer creating utterances >2000 words | Crashes on iOS 17, incomplete playback | Split into 500-word segments with progress tracking | Long-form recipes (>2000 words) |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Expose Spoonacular API key in client-side code | Quota theft, $99/mo unexpected charges | Proxy all Spoonacular requests through backend GraphQL, never send key to client |
| Store ElevenLabs voice recordings without encryption at rest | GDPR/CCPA violation, voice data breach | Encrypt R2 bucket with AES-256, enable versioning for audit trail |
| No rate limiting on voice upload endpoint | Free users abuse unlimited uploads to exhaust ElevenLabs quota | Enforce 1 voice/account for free tier in GraphQL mutation, validate server-side |
| Display user-submitted Spoonacular recipe content without sanitization | XSS if recipe instructions contain `<script>` tags | Sanitize `analyzedInstructions` and `summary` with DOMPurify before GraphQL response |
| Skip StoreKit 2 transaction verification for Pro unlock | Subscription fraud, revenue loss | Validate JWS with SignedDataVerifier x5c chain (already implemented v4.0) |
| Log user voice consent without IP address or timestamp | Can't prove consent in legal dispute | Store userId, timestamp, IP, app version in `voice_consent_audit` table (already implemented v4.0) |
| Spoonacular API responses cached >1 hour | ToS violation, potential API key revocation | Enforce TTL 1 hour max, document in code comments referencing Spoonacular ToS section |
| Nutrition data displayed to users under 13 without parental consent | COPPA violation, FTC fines | Set minimum age 17+ in App Store Connect, implement age gate if targeting <17 |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Show paywall immediately after first AVSpeech narration | "App is unusable without paying" perception, 1-star reviews | Let users experience 5-10 narrations before showing Pro upsell |
| Display "Powered by Spoonacular" badge prominently on every recipe card | Feels cheap, user questions app value | Small footer badge on recipe detail view only, not feed cards |
| Free-tier narration quality is drastically worse than Pro demo | Creates negative anchor, lowers conversion | NEVER show ElevenLabs demos to free users, position as "different" not "better" |
| Recipe feed shows "Loading..." for 3+ seconds on first launch (no cache) | User bounces before content loads | Pre-populate DB with 50 popular recipes, show immediately while fetching fresh data |
| Nutrition disclaimer in tiny 8pt footer text | User misses it, regulatory risk | 12pt text directly under nutrition panel: "Estimates from Spoonacular. Not for medical use." |
| AVSpeech narration stops mid-recipe without explanation | User thinks app is broken | Detect early stop (didFinish before expected duration), show: "Voice error. Tap to restart or switch to text." |
| Pro paywall blocks free users from trying enhanced AVSpeech voices | Users never experience quality improvement | Offer one-time free trial: "Download enhanced voice to improve narration quality" |
| Recipe detail doesn't indicate data source (Spoonacular vs. scraped) | User confused why some recipes have different metadata | Badge: "Community recipe" vs. "Spoonacular recipe" with tooltip |
| Error message: "API quota exceeded" | Exposes technical implementation, user confused | "Recipe library updating. Try again in a few hours." |
| Background audio limitation not communicated | User locks phone, audio stops, thinks app is broken | Show tip after first narration: "Keep Kindred open during narration, or upgrade to Pro for background playback." |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Spoonacular Integration:** Working in dev, but missing production caching layer → verify 1-hour Redis TTL + PostgreSQL fallback implemented
- [ ] **AVSpeechSynthesizer:** Works in Simulator, but crashes on iOS 17 real devices → verify tested on iPhone 14 Pro (iOS 17.6) and iPhone 16 (iOS 18.2)
- [ ] **Voice Consent:** Existing consent screen implemented, but doesn't meet 5.1.2(i) requirements → verify modal shows BEFORE upload with "ElevenLabs AI" provider name
- [ ] **Nutrition Disclaimers:** Data displays correctly, but missing "estimate" qualifier and FDA disclaimer → verify 12pt text under nutrition panel
- [ ] **Spoonacular Attribution:** Attribution link in Settings, but ToS requires visible badge on recipe view → verify badge on recipe detail screen
- [ ] **App Store Binary:** Builds successfully, but uses iOS 25 SDK → verify Xcode 16 + iOS 26 SDK before upload
- [ ] **GraphQL Schema:** Returns Spoonacular data, but exposes external API types directly → verify adapter layer maps to internal Recipe schema
- [ ] **Background Audio:** AVAudioSession configured, but AVSpeech still stops when backgrounded → verify tested on real devices, document limitation or implement fallback
- [ ] **TestFlight Submission:** Binary uploaded, but no test on real devices → verify internal testing with 10+ testers before external beta
- [ ] **Privacy Labels:** App Privacy section filled out, but missing ElevenLabs in "Third-Party Partners" → verify Data Types → Audio → Shared with ElevenLabs

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Spoonacular quota exhausted on launch day | MEDIUM | 1. Enable cache-first mode: serve stale cached recipes. 2. Upgrade to $49/mo tier (1500 req/day) temporarily. 3. Implement request queuing for next day's quota reset. |
| App rejected for missing AI consent (5.1.2i) | HIGH | 1. Implement consent modal in emergency patch. 2. Request expedited review (critical fix). 3. 3-5 day delay minimum. |
| AVSpeech fails on iOS 17 devices post-launch | HIGH | 1. Hotfix: Detect iOS 17.0-17.2, disable AVSpeech, show text-only fallback. 2. Add telemetry to measure impact. 3. Consider making ElevenLabs free temporarily. |
| Review delayed 30 days, misses marketing campaign | VERY HIGH | 1. Reschedule campaign (sunk cost if ads pre-purchased). 2. Pivot to TestFlight-only soft launch. 3. No technical fix - timeline issue. |
| Spoonacular data model breaks existing queries | MEDIUM | 1. Rollback to custom scraping API temporarily. 2. Implement adapter layer properly. 3. Dual-write migration: support both schemas for 2 weeks. |
| Users complain AVSpeech quality too poor vs. Pro | MEDIUM | 1. Immediate: Prompt all free users to download enhanced iOS voices. 2. A/B test: Remove Pro voice demos from free tier UI. 3. Long-term: Add voice customization (pitch/rate). |
| Nutrition data flagged in review (guideline 1.4.1) | MEDIUM | 1. Add disclaimers to all nutrition displays. 2. Update marketing copy (remove "accurate"). 3. Resubmit with reviewer notes explaining data source. |
| Attribution missing, Spoonacular sends cease & desist | HIGH | 1. Immediate: Add "Powered by Spoonacular" badge via app update. 2. Email Spoonacular compliance with timeline. 3. Request grace period (usually 30 days). |
| Binary rejected for iOS 25 SDK (need iOS 26) | MEDIUM | 1. Upgrade Xcode 16 immediately. 2. Fix breaking changes. 3. Rebuild and resubmit (1-2 day delay). |
| Background AVSpeech audio fails post-launch | LOW | 1. Document limitation in FAQ. 2. Suggest: "Keep app open or upgrade to Pro." 3. Consider screen-awake fallback (UIApplication.isIdleTimerDisabled). |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Spoonacular quota exhaustion | Phase 1: Spoonacular Integration | Cache hit rate >70% in dev, quota usage <100 points/day with 20 test users |
| AVSpeech iOS 17 bugs | Phase 2: AVSpeech Integration | Test plan includes iPhone 14 Pro (iOS 17.6) + iPhone 16 (iOS 18.2) real devices, log synthesis errors |
| Missing AI consent (5.1.2i) | Phase 3: App Store Compliance | Screenshot shows consent modal BEFORE voice upload with "ElevenLabs AI" text |
| Spoonacular data mismatch | Phase 1: Spoonacular Integration | GraphQL schema uses internal Recipe type, adapter maps Spoonacular → internal schema |
| Mixed TTS quality perception | Phase 2: AVSpeech Integration | A/B test shows <5% 1-star reviews mentioning "robotic" or "unusable without paying" |
| Attribution missing | Phase 1: Spoonacular Integration | "Powered by Spoonacular" badge visible on recipe detail screenshot |
| Nutrition data rejection | Phase 3: App Store Compliance | Disclaimer text: "Estimates from Spoonacular. Not for medical use." visible in screenshot |
| iOS 26 SDK requirement | Phase 0: Environment Setup | Build settings show iOS 26.0 Base SDK, Xcode 16.0+ in About dialog |
| 30-day review delay | Phase 4: TestFlight Internal Beta | Submission date is 30 days BEFORE target launch date in timeline |
| Background audio stops | Phase 2: AVSpeech Integration | Real-device test: Lock phone during narration, audio continues OR fallback message shown |

## Sources

### Spoonacular API
- [Spoonacular API Documentation | API Specifications & Integration Guide](https://www.allthingsdev.co/apimarketplace/documentation/Spoonacular%20API/66750a5670009c3ab417c4ed)
- [Guide to Spoonacular API: Recipe, Nutrition & Food Data Integration 2025](https://www.devzery.com/post/spoonacular-api-complete-guide-recipe-nutrition-food-integration)
- [spoonacular recipe and food API](https://spoonacular.com/food-api/docs)
- [Best APIs for Menu Nutrition Data - Bytes AI](https://trybytes.ai/blogs/best-apis-for-menu-nutrition-data)
- [Spoonacular API - APILayer](https://apilayer.com/marketplace/spoonacular-api)

### AVSpeechSynthesizer
- [AVSpeechSynthesizer in background | Apple Developer Forums](https://developer.apple.com/forums/thread/27097)
- [AVSpeechSynthesizer Broken on iOS 17](https://developer.apple.com/forums/thread/737685)
- [AVSpeechSynthesizer is broken on iOS 17 in Xcode 15](https://developer.apple.com/forums/thread/738048)
- [AVSpeechSynthesizer | Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [AVSpeechSynthesisVoice | Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice)
- [On-Device Text To Speech on Apple Devices with AI SDK](https://www.callstack.com/blog/on-device-text-to-speech-on-apple-devices-with-ai-sdk)

### App Store Guidelines
- [iOS App Store Review Guidelines 2026: Requirements, Rejections & Submission Guide](https://theapplaunchpad.com/blog/app-store-review-guidelines)
- [Apple Updates App Store Review Guidelines: Third-Party AI Calls Must Be Disclosed and Approved by the User](https://news.aibase.com/news/22810)
- [App Store Review Guidelines 2025: Essential AI App Rules](https://openforge.io/app-store-review-guidelines-2025-essential-ai-app-rules/)
- [Apple's new App Review Guidelines clamp down on apps sharing personal data with 'third-party AI' | TechCrunch](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)
- [Apple Silently Regulated Third-Party AI—Here's What Every Developer Must Do Now](https://dev.to/arshtechpro/apples-guideline-512i-the-ai-data-sharing-rule-that-will-impact-every-ios-developer-1b0p)

### App Store Submission
- [Live App Store and TestFlight review times | Runway](https://www.runway.team/appreviewtimes)
- [iOS & iPhone App Distribution Guide 2026: Apple Developer Program Fees, TestFlight & Enterprise](https://foresightmobile.com/blog/ios-app-distribution-guide-2026)
- [iOS App Review Delays March 2026: Reasons and What to Do](https://www.lowcode.agency/blog/ios-app-review-delays-march-2026)
- [Everything you need to know about submitting to the App Store (and avoiding rejections) | by Runway](https://www.runway.team/blog/submitting-app-store-avoiding-rejections)
- [Upload builds - App Store Connect - Apple Developer](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)

### Voice Quality & TTS
- [ElevenLabs Review 2026: YouTube-Tested + Best Voices | Nerdynav](https://nerdynav.com/elevenlabs-review/)
- [ElevenLabs Review 2026: We Tested Everything (Voice Cloning, 70+ Languages & Real Performance)](https://hackceleration.com/elevenlabs-review/)
- [Free vs. Premium: Navigating the best text to speech API options - WellSaid Labs](https://www.wellsaid.io/resources/blog/best-text-to-speech-api-offerings)
- [Best TTS APIs in 2026: ElevenLabs, Google, AWS & 9 More Compared](https://www.speechmatics.com/company/articles-and-news/best-tts-apis-in-2025-top-12-text-to-speech-services-for-developers)

### Caching & Performance
- [API caching strategies and best practices | TechTarget](https://www.techtarget.com/searchapparchitecture/tip/API-caching-strategies-and-best-practices)
- [Production best practices | OpenAI API](https://developers.openai.com/api/docs/guides/production-best-practices)
- [Caching Best Practices in REST API Design | Speakeasy](https://www.speakeasy.com/api-design/caching)
- [How Developers Can Use Caching to Improve API Performance | Zuplo](https://zuplo.com/learning-center/how-developers-can-use-caching-to-improve-api-performance)

### ASO & Category Selection
- [App Store Category Selection: ASO Impact & Best Practices](https://passion.io/blog/app-store-category-selection-aso-impact-best-practices)
- [ASO in 2026: Complete App Store Optimization Guide](https://asomobile.net/en/blog/aso-in-2026-the-complete-guide-to-app-optimization/)
- [Categories and Discoverability - App Store - Apple Developer](https://developer.apple.com/app-store/categories/)

---
*Pitfalls research for: v5.0 Lean App Store Launch - Spoonacular API, AVSpeechSynthesizer, First App Store Submission*
*Researched: 2026-04-04*
*Confidence: HIGH (verified with official documentation, developer forums, and 2026-current sources)*
