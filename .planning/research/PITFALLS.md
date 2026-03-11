# Pitfalls Research

**Domain:** Smart Pantry Features (Fridge Scanning, Receipt OCR, Expiry Tracking)
**Researched:** 2026-03-11
**Confidence:** MEDIUM

## Critical Pitfalls

### Pitfall 1: AI Hallucination in Expiry Date Prediction

**What goes wrong:**
ML models hallucinate expiry dates or ingredient identifications, leading to food safety risks. Users trust the app's predictions and consume spoiled food or discard safe food. Models predict "plausible" dates rather than accurate ones, optimized for fluency not accuracy.

**Why it happens:**
Generative AI predicts statistically probable outputs based on training data patterns, not verified truth. Research proves eliminating hallucination in LLMs is fundamentally impossible given their architecture. Models trained in one geography (temperate) experience 15-30% accuracy drops in different climates (tropical). Food spoilage signatures vary by climate zone, supply chain practices, and packaging types.

**How to avoid:**
- Never present AI-estimated expiry dates as authoritative truth
- Require manual confirmation for all expiry dates before relying on them for notifications
- Add clear disclaimers: "Estimated expiry — verify packaging"
- Use conservative estimates (err on side of caution)
- Track confidence scores and surface low-confidence predictions differently
- Build user feedback loop to improve model accuracy over time
- Implement safety guardrails: flag predictions >30 days for review, warn on high-risk foods (dairy, meat)

**Warning signs:**
- Users reporting "app said it was fine but it was spoiled"
- Predictions varying wildly for identical products
- Confidence scores consistently low for common items
- Model performing worse in production than testing

**Phase to address:**
Phase 1 (Foundation) — Establish ML prediction strategy with safety-first approach, manual override patterns, disclaimer UI components. Phase 3 (Expiry Tracking) — Implement conservative default logic, user feedback collection.

---

### Pitfall 2: OCR Misreads Leading to Broken Ingredient Matching

**What goes wrong:**
Receipt OCR mangles ingredient names (e.g., "EGGS" → "LG EGO 12 CT", "EDGS", "STO LRG BRUNN"). Simple regex/exact matching against recipe database fails. Users scan receipts, nothing matches their recipes, feature feels broken. Extreme example: OCR-detected tax of $833.00 on a $26.64 receipt (actual: $1.69).

**Why it happens:**
Receipts vary in layout, print quality, language, and are often crumpled or faded. Retailers use cryptic abbreviations (Fred Meyer: "STO LRG BRUNN", Whole Foods: "EDGS"). OCR text extraction errors (0→O, I→1) break rule-based extraction ("TOTAL" vs "T0TAL"). Training OCR on clean receipt images doesn't transfer to real-world conditions.

**How to avoid:**
- Use two-stage pipeline: PaddleOCR-VL (text extraction) → Gemini/Claude (structured extraction with fuzzy matching)
- Implement fuzzy matching with Levenshtein distance (FuzzyWuzzy library)
- Build ingredient normalization database with common abbreviations and misspellings
- Allow manual correction with suggested matches
- Use hybrid approach: vector-based semantic search + exact match
- Train on real crumpled/faded receipts, not just clean samples
- Build retailer-specific abbreviation mappings (crowdsource from users)

**Warning signs:**
- Match rate <60% on real receipts during testing
- Users repeatedly manually correcting the same items
- High variance in OCR accuracy between test receipts
- Support tickets about "scanning doesn't work"

**Phase to address:**
Phase 2 (Receipt Scanning) — Build robust two-stage OCR pipeline, fuzzy matching, normalization database. Phase 4 (Recipe Matching) — Integrate semantic search for ingredient matching.

---

### Pitfall 3: Memory Explosion from Batch Photo Processing

**What goes wrong:**
User selects 10 fridge photos, app loads all at full resolution (iPhone 16 Pro Max: 48MP each), app crashes with out-of-memory error. iOS kills app without warning. Users lose all scanned data.

**Why it happens:**
PHPicker returns high-resolution images (easily 10-20MB each). Loading multiple `UIImage` objects simultaneously consumes hundreds of MB. Drawing full images into graphics contexts amplifies memory usage. Developers test with 1-2 photos, works fine, production users select 10+ photos.

**How to avoid:**
- Never load full `UIImage` objects for batch processing
- Use `loadFileRepresentation` API with file paths, not `UIImage` loading
- Process photos sequentially or in small batches (2-3 at a time) with autoreleasepool
- Resize images immediately after loading, before processing
- Stream to disk, pass file paths to ML processing
- Set `maxFileSize` limits on picker configuration
- Implement progress UI showing "Processing photo 3 of 10" to set expectations
- Test with 20+ high-resolution photos on device (not simulator)

**Warning signs:**
- Memory usage >300MB during testing with 3 photos
- App occasionally crashes when processing multiple photos
- Instruments showing memory spikes during image processing
- Users reporting crashes "when scanning whole fridge"

**Phase to address:**
Phase 1 (Foundation) — Establish image processing patterns, memory-safe batch processing utilities. Phase 2 (Fridge Scanning) — Implement streaming file-based approach.

---

### Pitfall 4: Offline-First State Sync Conflicts

**What goes wrong:**
User adds "2 eggs" offline, backend processes receipt scan adding "12 eggs" while user offline, sync resumes, conflict resolution chooses wrong version. Pantry shows incorrect quantities. Users manually add items that auto-scan already added. Duplicate entries accumulate.

**Why it happens:**
TCA reducers expect unidirectional data flow, but offline-first creates bidirectional sync. GraphQL mutations succeed locally then fail on server. Simple "last write wins" loses user-entered data. "Latest version wins" without timestamps creates race conditions. No version tracking means conflicts detected too late.

**How to avoid:**
- Implement operation-based CRDT for quantity changes (add +2, not set to 2)
- Add `version` field to all pantry items, use optimistic locking
- Queue mutations with WorkManager-style persistence
- Sync layer detects conflicts before reducer sees them
- Show conflict resolution UI for ambiguous cases
- Use event sourcing: store all mutations, replay on conflict
- Merge strategies: for quantities, sum additions from both sources
- Tag mutations with source: "user_manual" vs "receipt_scan" (user wins)

**Warning signs:**
- Pantry quantities mysteriously change after sync
- Duplicate ingredients appearing in pantry
- Users reporting "I added that already"
- Sync errors in logs showing conflicts
- GraphQL mutations succeeding then failing after retry

**Phase to address:**
Phase 1 (Foundation) — Design offline-first sync architecture with conflict resolution strategy. Phase 2 (Pantry Management) — Implement CRDT-based quantity tracking, conflict UI.

---

### Pitfall 5: Ingredient Normalization Chaos

**What goes wrong:**
Database has "eggs", "large eggs", "lg eggs", "EGGS", "egg", "Eggs (Large)", "free range eggs" as separate items. Recipe matching fails because recipe says "eggs" but pantry has "large eggs". OCR adds "mlk" (milk typo), doesn't match "milk". User has 50 ingredient variations instead of 15 actual ingredients.

**Why it happens:**
Ingredients are informal user-generated text with spelling errors, synonyms, variants. "High fructose corn syrup" can be "glucose-fructose syrup", "high levulose corn syrup", "glucose-fructose syrup (corn)", "HFCS". No canonical ingredient list enforced. Manual entry allows typos. OCR introduces new spellings. Recipe database uses different terminology than receipt OCR.

**How to avoid:**
- Adopt USDA IngID Thesaurus for Preferred Descriptors (PDs)
- All ingredients map to canonical PD on save
- Use character-based encoder-decoder for normalization
- FuzzyWuzzy matching during manual entry with suggestions
- Build ingredient synonym database (use FooDB or Open Food Facts)
- Auto-merge obvious variants: case-insensitive, strip punctuation
- Show "Did you mean?" for near-matches during entry
- Backend GraphQL mutation normalizes before saving
- Implement ingredient autocomplete with canonical list

**Warning signs:**
- Ingredient count growing faster than expected
- Recipe match rate declining over time
- Users searching can't find ingredients they added
- Duplicate detection running constantly
- Database queries scanning hundreds of near-matches

**Phase to address:**
Phase 1 (Foundation) — Establish ingredient normalization strategy, integrate USDA IngID. Phase 2 (Pantry Management) — Implement normalization on all input paths. Phase 4 (Recipe Matching) — Use normalized canonical forms for matching.

---

### Pitfall 6: Unit Conversion Hell in Recipe Matching

**What goes wrong:**
Recipe calls for "200g flour", pantry has "1 cup flour". No match. Recipe matching shows "missing flour" when user has plenty. Different ingredients have different densities: 1 cup flour ≠ 1 cup sugar by weight. Conversion hard-coded for one ingredient breaks for others.

**Why it happens:**
Developers assume simple conversion ratios (1 cup = 240ml), but weight-volume conversions require ingredient-specific density data. Training data uses mix of US customary (cups), UK imperial (ounces), and metric (grams). Recipe sources use inconsistent conventions. No single source of truth for density values. Building density database from scratch is massive undertaking.

**How to avoid:**
- Use ingredient-aware conversion library with density database (don't build from scratch)
- Integrate FAO (Food and Agricultural Organisation) density data
- Store quantities in canonical units (grams for solids, ml for liquids)
- Convert at display time, not storage time
- For ambiguous ingredients, use conservative matching: "flour (any form)"
- Allow "approximate matches" with confidence scores
- Show unit conversions in UI: "200g (~1.5 cups)"
- Use libraries like convert-units with ingredient extensions
- For MVP, support only weight-based or volume-based (not both) for sanity

**Warning signs:**
- Recipe matching showing false negatives ("you're missing flour")
- Conversion calculations failing for certain ingredients
- Users manually entering same ingredient in multiple units
- Support tickets about incorrect conversions
- Database showing mix of units without canonical form

**Phase to address:**
Phase 1 (Foundation) — Research and integrate density-aware conversion library. Phase 2 (Pantry Management) — Implement canonical unit storage. Phase 4 (Recipe Matching) — Build fuzzy matching with unit conversion.

---

### Pitfall 7: Push Notification Permission Fatigue

**What goes wrong:**
App requests notification permission on first launch before user sees value. User taps "Don't Allow", app can never send expiry alerts, core feature broken. Re-prompting users is intrusive and usually fails. 60%+ users deny notification permission when asked too early.

**Why it happens:**
Developers eager to enable features request all permissions upfront. iOS only allows one notification permission prompt (subsequent requests do nothing). Users deny by default when they don't understand why app needs permission. Asking before user has pantry items makes permission feel premature.

**How to avoid:**
- Delay notification permission until user adds first item to pantry
- Show contextual explanation: "Get alerts 2 days before food expires"
- Implement provisional/soft permission first (delivered quietly)
- Build value before asking: let user scan items, then offer expiry alerts
- Add in-app notification center for users who deny permission
- Graceful degradation: show expiry dates in-app without push
- Never block core features behind notification permission
- Add Settings deep-link for users to enable later

**Warning signs:**
- Notification permission acceptance rate <50%
- Users complaining "I never got an alert"
- High percentage of users with pantry items but no permission
- Support tickets asking "how do I enable notifications"
- Analytics showing permission prompt on first screen

**Phase to address:**
Phase 3 (Expiry Tracking) — Implement progressive permission request after user adds first item. Include in-app fallback for denied permission.

---

### Pitfall 8: ML Image Recognition Accuracy Collapse

**What goes wrong:**
Gemini Flash ingredient recognition works great in bright kitchen during testing, fails miserably in real fridges with poor lighting, different angles, overlapping items. App identifies yogurt as "cheese", misses items in shadows, hallucinates ingredients not in photo. User scans fridge 3 times, gets different results each time.

**Why it happens:**
ML Kit requires minimum 100x100 pixels per object (200x200 for contours). Real fridge photos have poor lighting, occlusion, reflections, condensation. Models trained on clean product photos don't generalize to messy fridges. Gemini hallucinates on low-quality, rotated, or low-resolution images. Semantic similarity errors most insidious (identifies "cheddar" instead of "mozzarella" — both cheese).

**How to avoid:**
- Set clear photo quality requirements: well-lit, minimal occlusion
- Show preview with overlay guides: "Position camera 12 inches away"
- Pre-flight image quality check before sending to ML API
- Require minimum resolution per ingredient (not just overall image)
- Use Gemini 2.0 Flash (20% better recognition than older versions)
- Implement confidence thresholds: only show results >70% confidence
- Allow manual correction with suggested items
- Multi-shot mode: "Scan top shelf", "Scan middle shelf" separately
- Test with real fridge lighting conditions, not studio lighting
- Build feedback loop: user corrections train model over time

**Warning signs:**
- Recognition confidence scores <60% on average
- Users reporting "wrong ingredients detected"
- High manual correction rate (>40%)
- Different results from same photo sent twice
- Model performs worse on device photos than test images

**Phase to address:**
Phase 1 (Foundation) — Establish ML quality gates, confidence thresholds. Phase 2 (Fridge Scanning) — Implement photo guidance UI, multi-shot mode, manual correction flow.

---

### Pitfall 9: GraphQL File Upload Memory Leak

**What goes wrong:**
Fridge photo upload mutation receives photo stream, processes synchronously in GraphQL resolver, server memory climbs with each upload, never released. After 50 uploads, server OOM crashes. Production users all uploading 5-10 photos simultaneously overwhelms backend.

**Why it happens:**
GraphQL resolvers block event loop during file processing. Using `graphql-upload` without proper stream handling buffers entire file in memory. Image processing (resizing, format conversion) happens in resolver before response. Sharp/Jimp keeps processed images in memory. No cleanup after processing. Developers test sequentially, production has concurrent uploads.

**How to avoid:**
- Use `graphqlUploadExpress` middleware with `maxFileSize` and `maxFiles` limits
- Stream uploads directly to S3/object storage using `fs-capacitor`
- Process uploads asynchronously: return immediately, process in background job
- Use `Promise.allSettled` for concurrent uploads with proper error handling
- Promisify and await file upload streams properly
- Implement image processing queue (Bull/BullMQ) separate from GraphQL server
- Set up auto-scaling based on memory usage
- Add request timeout (30s max for uploads)
- Monitor memory usage per resolver in production
- Use streaming libraries that release buffers: Sharp with streaming API

**Warning signs:**
- Server memory climbing linearly with uploads
- Memory not released after garbage collection
- Resolver timing out on larger photos
- Server crashes under concurrent load testing
- CloudWatch/metrics showing memory spikes during upload peaks

**Phase to address:**
Phase 1 (Foundation) — Design async file upload architecture with streaming. Phase 2 (Backend Integration) — Implement upload queue, memory-safe processing.

---

### Pitfall 10: Camera Permission Before Value Demonstration

**What goes wrong:**
App requests camera permission on fridge scan screen load, before explaining why. User sees system prompt "Allow Kindred to access camera?" with no context, taps "Don't Allow" reflexively. Camera permission denied permanently, fridge scanning broken. 40% of users deny camera permission when asked cold.

**Why it happens:**
Developers trigger permission request when mounting camera component. No pre-permission explanation screen. iOS doesn't show `NSCameraUsageDescription` text prominently. Users trained to deny permissions by default due to privacy concerns. Single-shot permission means you get one chance.

**How to avoid:**
- Add pre-permission screen: "Scan your fridge to track ingredients"
- Show screenshot of camera view with successful scan
- Use custom permission UI before triggering system prompt
- Implement permission priming: explain, then request
- Update `NSCameraUsageDescription` with clear reason: "Take photos of your fridge and receipts to automatically track ingredients"
- Add Settings deep-link for users to grant permission later
- Test permission acceptance rate (target >70%)
- Never auto-request — wait for user to tap "Scan fridge" button
- Graceful fallback: offer manual ingredient entry if camera denied

**Warning signs:**
- Camera permission acceptance rate <60%
- Users tapping back immediately after system prompt
- High drop-off rate on scan screen
- Support tickets: "Camera not working"
- Analytics showing permission denied on first prompt

**Phase to address:**
Phase 2 (Fridge Scanning) — Implement permission priming screen before camera access. Include fallback flow for denied permission.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoded expiry date rules (milk = 7 days) | Fast MVP, no ML needed | Inaccurate predictions, user distrust | MVP only — must be replaced Phase 3 |
| Simple exact-match ingredient lookup | Easy implementation | Fails for typos, abbreviations, variants | Never — fuzzy matching is table stakes |
| Load all pantry items in-memory | Works for <100 items | Memory explosion, slow queries | Never — paginate from start |
| Skip offline-first, assume always-online | Simpler state management | Poor UX in basements/rural areas | Never in cooking app (kitchen WiFi spotty) |
| Store photos on server without compression | Fast to implement | Storage costs explode, slow uploads | Never — compress client-side with Sharp |
| Skip conflict resolution, last-write-wins | Simple sync logic | Users lose data randomly | Never — implement version tracking from start |
| Manual ingredient normalization | No external dependencies | Unmaintainable, inconsistent | Never — integrate standard database (USDA IngID) |
| Synchronous image processing in resolver | No queue infrastructure needed | Server crashes under load | Never — async processing is required |
| Ask for all permissions upfront | Get permissions early | 60%+ denial rate | Never — progressive permission request only |
| Skip unit conversion, assume all grams | No density database needed | Recipe matching useless for US users | Acceptable if targeting single region with consistent units |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Gemini Flash API | Sending full-resolution photos (10MB+) | Resize to 1024x1024 before API call, costs 1/10th |
| PHPicker | Loading all selected photos into UIImage array | Use `loadFileRepresentation`, process sequentially with file paths |
| GraphQL file upload | Processing synchronously in resolver | Stream to S3, process in background queue (Bull) |
| TCA + camera | Using `@Dependency(\.camera)` in view | Camera effects in reducer only, view sends actions |
| StoreKit 2 | Checking `purchase()` absence of error = success | Check `Transaction.currentEntitlements` for active subscriptions |
| Core ML | Assuming model works on low-resolution images | Pre-check image meets minimum 100x100px per object |
| UserNotifications | Scheduling notifications while app running | Notifications scheduled persist even if app killed |
| AVFoundation session | Modifying session settings without beginConfiguration/commitConfiguration | Always wrap in begin/commit to prevent crashes |
| Prisma + GraphQL | Separate schemas get out of sync | Use Prisma to generate GraphQL schema, single source of truth |
| FuzzyWuzzy matching | Using default threshold (70) for ingredients | Tune threshold per use case: 85+ for critical matches, 60+ for suggestions |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading all pantry items on app launch | Slow app startup, memory warnings | Paginate queries, load recent/expiring items first | >200 pantry items |
| Sending full-resolution photos to ML API | Long processing times, timeout errors | Resize to 1024x1024 client-side before upload | Photos >2MB |
| Synchronous receipt OCR processing | UI freezes during scan | Process on background thread, show progress UI | OCR processing >1s |
| N+1 queries for recipe ingredient matching | Query latency increases linearly with recipes | Use GraphQL DataLoader, batch ingredient lookups | >50 recipes in database |
| Storing ingredient photos in PostgreSQL | Database bloat, slow backups | Store in S3/object storage, save URLs in database | >100 photos uploaded |
| Re-running ML inference for same photo | Wasted API costs, slow response | Cache results with photo hash, 24h TTL | Users retry failed scans |
| Not debouncing ingredient search input | API rate limiting, laggy typing | Debounce 300ms, implement client-side fuzzy search | Live search across >1000 ingredients |
| Loading all expiry notifications at once | Notification permission UI sluggish | Schedule notifications just-in-time (3 days before expiry) | >100 tracked items |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing photos with user-generated filenames | Path traversal attacks | Generate UUID filenames server-side, ignore client filename |
| No rate limiting on photo upload endpoint | DOS via large file spam | Implement rate limiting: 10 photos/minute, 50 photos/hour |
| Trusting client-side expiry date estimates | User could manipulate dates to game system | Server validates all dates, flags suspicious patterns |
| Exposing other users' pantry data via GraphQL | Data leak if queries not scoped by user | All queries filter by authenticated user ID, test with multiple users |
| No validation on uploaded file types | Malicious files disguised as images | Validate MIME type server-side with `file-type` library, not just extension |
| Storing photos without virus scanning | Malware distribution via user uploads | Integrate ClamAV or cloud scanning before storage |
| Allowing unlimited photo storage per user | Storage cost abuse | Enforce limits: 100 photos per user, 5MB per photo |
| Not sanitizing OCR-extracted text before saving | SQL/NoSQL injection via receipt text | Use parameterized queries, sanitize all user input |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Auto-requesting all permissions on first launch | Users reflexively deny, features broken permanently | Progressive disclosure: request each permission when feature first used |
| No manual fallback when camera permission denied | Core feature completely broken for denied users | Show "enable in Settings" guide + manual entry option |
| Showing ML confidence scores to users | Confusing, erodes trust ("Why only 73% sure?") | Hide confidence, only show results above threshold, allow correction |
| Processing scan in foreground without progress | User thinks app froze, force quits | Show progress: "Analyzing photo... Detecting ingredients... Matching database..." |
| Deleting expired items without warning | User discarded item, checks pantry, it's gone — unsettling | Notify 1 day before, require confirmation to delete |
| Asking "Is this correct?" for every scanned ingredient | Fatigue, users skip checking | Only confirm low-confidence items, auto-accept high-confidence |
| No undo after auto-scan adds wrong ingredients | User must manually find and delete incorrect items | Show "Scan added 8 items" banner with Undo button for 10 seconds |
| Recipe match showing "You're missing 1 ingredient" without saying which | User scans entire recipe looking for missing item | Highlight missing ingredients, show "Add milk to pantry" CTA |
| Notification spam: "Eggs expire tomorrow", "Milk expires tomorrow", "Butter expires tomorrow" | Notification fatigue, user disables all notifications | Batch expiry notifications: "3 items expiring soon: eggs, milk, butter" |
| Scanning receipt shows raw OCR text before cleanup | Looks broken: "MLK 2% 1GAL $3.79" vs "Milk" | Show cleaned, normalized ingredients only |

## "Looks Done But Isn't" Checklist

- [ ] **Fridge scanning:** Often missing error handling for ML API rate limits — verify retry logic with exponential backoff, fallback to manual entry
- [ ] **Receipt OCR:** Often missing retailer-specific abbreviation handling — verify works with receipts from Target, Costco, Whole Foods, not just one test receipt
- [ ] **Expiry tracking:** Often missing timezone handling — verify notifications fire at correct local time for users in different timezones
- [ ] **Offline pantry edits:** Often missing conflict resolution UI — verify what users see when offline add conflicts with scanned receipt
- [ ] **Photo batch processing:** Often missing memory testing — verify app doesn't crash when processing 20 high-res photos sequentially
- [ ] **Ingredient normalization:** Often missing synonym database — verify "green onions" matches recipes calling for "scallions"
- [ ] **Unit conversions:** Often missing density-aware logic — verify "1 cup flour" (120g) ≠ "1 cup sugar" (200g) handled correctly
- [ ] **Push notifications:** Often missing notification permission denied path — verify users can still see expiry warnings in-app
- [ ] **Recipe matching:** Often missing partial match logic — verify shows "You have 7/8 ingredients" not just "missing ingredients"
- [ ] **GraphQL mutations:** Often missing optimistic updates rollback — verify UI reverts if server mutation fails after showing success
- [ ] **Camera permissions:** Often missing pre-permission explanation — verify user sees value proposition before iOS permission prompt
- [ ] **File upload streaming:** Often missing cleanup after processing — verify temp files deleted, memory released after upload completes

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| AI hallucinated expiry dates in production | HIGH | 1) Immediate: Add disclaimer to all dates 2) Flag all AI-estimated dates for manual review 3) Reset notifications, re-send with conservative estimates 4) User communication: "We're improving accuracy" |
| OCR ingredient matching broken (<30% match rate) | HIGH | 1) Add manual correction flow immediately 2) Build retailer abbreviation mappings from support tickets 3) Implement two-stage OCR pipeline 4) Offer refunds for Pro users affected |
| Memory crashes from batch photo processing | MEDIUM | 1) Emergency: Limit picker to 3 photos max 2) Implement sequential processing with file streaming 3) Add progress UI 4) Release patch within 48h |
| Offline sync conflicts causing data loss | HIGH | 1) Add conflict detection without auto-resolution 2) Show conflict UI for user to choose 3) Implement CRDT for quantities 4) Restore lost data from server logs where possible |
| Ingredient normalization chaos (duplicates) | MEDIUM | 1) Run deduplication script: merge obvious variants 2) Integrate USDA IngID for canonical mapping 3) Add normalization to all input paths 4) Migrate existing data in background |
| Unit conversion bugs in recipe matching | LOW | 1) Add "approximate match" mode ignoring units 2) Integrate FAO density database 3) Re-index all pantry items with canonical units 4) Show unit conversions in UI |
| Notification permission denied by most users | MEDIUM | 1) Add in-app notification center immediately 2) Implement progressive permission request 3) Analytics: track acceptance rate 4) A/B test permission priming screens |
| ML recognition accuracy collapse in production | HIGH | 1) Increase confidence threshold to 80% 2) Add photo quality pre-check 3) Implement multi-shot mode 4) Build user feedback loop 5) Consider switching to Gemini 2.0 Flash |
| GraphQL file upload memory leak | HIGH | 1) Emergency restart schedule every 6h 2) Add request timeout (30s) 3) Implement async processing queue 4) Monitor memory, auto-scale on threshold 5) Migrate to streaming API |
| Camera permission denied, no fallback | LOW | 1) Add manual ingredient entry screen 2) Show Settings deep-link with instructions 3) Implement permission priming for new users 4) Track permission status in analytics |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AI hallucination in expiry prediction | Phase 1 (Foundation), Phase 3 (Expiry Tracking) | Test with 50 products, compare predictions to actual expiry dates, measure accuracy >85% |
| OCR misreads breaking ingredient matching | Phase 2 (Receipt Scanning) | Scan 20 real receipts from 5 retailers, verify match rate >70% |
| Memory explosion from batch photos | Phase 1 (Foundation), Phase 2 (Fridge Scanning) | Process 20 high-res photos sequentially, memory stays <150MB |
| Offline-first state sync conflicts | Phase 1 (Foundation), Phase 2 (Pantry Management) | Simulate offline add + online receipt scan conflict, verify conflict UI appears |
| Ingredient normalization chaos | Phase 1 (Foundation), Phase 2 (Pantry Management) | Add "eggs" 5 different ways, verify all map to single canonical entry |
| Unit conversion hell | Phase 1 (Foundation), Phase 4 (Recipe Matching) | Match "200g flour" recipe against "1.5 cups flour" pantry item, verify match succeeds |
| Push notification permission fatigue | Phase 3 (Expiry Tracking) | Track permission acceptance rate >70% with progressive request |
| ML recognition accuracy collapse | Phase 1 (Foundation), Phase 2 (Fridge Scanning) | Scan 30 fridge photos in poor lighting, verify recognition confidence >70% |
| GraphQL file upload memory leak | Phase 1 (Foundation), Phase 2 (Backend Integration) | Load test 100 concurrent photo uploads, verify memory stable <2GB |
| Camera permission before value demo | Phase 2 (Fridge Scanning) | Track camera permission acceptance rate >75% with priming screen |

## Sources

- [Yuka - Food Scanner Case Study](https://www.scandit.com/resources/case-studies/yuka/)
- [Best Food Scanner Apps UK 2026](https://nutrasafe.co.uk/blog/best-food-scanner-apps-uk-2026)
- [Best Receipt OCR 2026](https://unstract.com/blog/unstract-receipt-ocr-scanner-api/)
- [OCR for Receipts Data Extraction](https://surveyinsights.org/?p=17190)
- [Push Notification Best Practices 2026](https://reteno.com/blog/push-notification-best-practices-ultimate-guide-for-2026)
- [iOS Push Notifications Guide](https://www.pushwoosh.com/blog/ios-push-notifications/)
- [Food Expiry Tracker UK](https://nutrasafe.co.uk/food-expiry-tracker-uk)
- [Database Design Bad Practices](https://www.toptal.com/database/database-design-bad-practices)
- [Integrating Core ML into iOS](https://tapptitude.com/blog/blog-post)
- [Using PHPickerViewController Efficiently](https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/)
- [Evaluating Gemini LLM in Food Image Recognition](https://arxiv.org/html/2511.08215v1)
- [CalCam: Transforming Food Tracking with Gemini API](https://developers.googleblog.com/calcam-transforming-food-tracking-with-the-gemini-api/)
- [Deep-based Ingredient Recognition for Recipe Retrieval](https://dl.acm.org/doi/10.1145/2964284.2964315)
- [Information Extraction from Recipes (Stanford NLP)](https://nlp.stanford.edu/courses/cs224n/2011/reports/rahul1-kjmiller.pdf)
- [StoreKit 2 iOS Subscription Tutorial](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)
- [The iOS Paywall That Solved StoreKit Nightmares](https://medium.com/@kcrdissanayake/the-ios-paywall-that-finally-solved-my-storekit-nightmares-bfdb07e67524)
- [State Management for Offline-First Apps](https://blog.pixelfreestudio.com/state-management-for-offline-first-web-applications/)
- [Offline-First Mobile App Architecture](https://dev.to/odunayo_dada/offline-first-mobile-app-architecture-syncing-caching-and-conflict-resolution-1j58)
- [Two-step Validation in Ingredient Normalization](https://dl.acm.org/doi/10.1145/3230519.3230589)
- [Recipes, Ingredients, and Normalization](https://etcusic.github.io/recipes_ingredients_and_normalization)
- [USDA IngID Thesaurus](https://www.ars.usda.gov/ARSUSERFILES/80400535/DATA/INGID/USDA_INGID_THESAURUS_FOR_RELEASE_FINAL.PDF)
- [FooDB - Food Constituents Database](https://foodb.ca/)
- [Open Food Facts Database](https://world.openfoodfacts.org/discover)
- [NestJS GraphQL File Upload](https://stephen-knutter.github.io/2020-02-07-nestjs-graphql-file-upload/)
- [NestJS GraphQL Image Upload to S3](https://dev.to/tugascript/nestjs-graphql-image-upload-to-a-s3-bucket-1njg)
- [AI for Food Safety: Predictive Models](https://www.sciencedirect.com/science/article/pii/S0924224425002894)
- [Predictive AI Models for Food Spoilage](https://www.researchgate.net/publication/389104195_Predictive_AI_Models_for_Food_Spoilage_and_Shelf-Life_Estimation)
- [Understanding AI Hallucination Risks](https://natlawreview.com/article/ai-hallucinations-are-creating-real-world-risks-businesses)
- [AI Hallucination Rates & Benchmarks 2026](https://suprmind.ai/hub/ai-hallucination-rates-and-benchmarks/)

---
*Pitfalls research for: Smart Pantry Features (Fridge Scanning, Receipt OCR, Pantry Management, Expiry Tracking)*
*Researched: 2026-03-11*
