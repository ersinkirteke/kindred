# Project Research Summary

**Project:** Kindred Smart Pantry Milestone
**Domain:** iOS food/cooking app — pantry management with AI-powered scanning
**Researched:** 2026-03-11
**Confidence:** HIGH

## Executive Summary

Smart Pantry features integrate seamlessly with Kindred's validated iOS architecture (SwiftUI + TCA) and backend (NestJS + GraphQL + Prisma + PostgreSQL). The recommended approach leverages existing infrastructure—particularly the Firebase AI Logic SDK / Gemini 2.0 Flash integration already used for voice narration—to power fridge and receipt scanning. Core features require minimal new dependencies: iOS VisionKit for live OCR, two new backend packages for validation (class-validator, class-transformer), and SwiftData for local-first pantry persistence.

The winning strategy is progressive complexity: launch with manual pantry management and basic recipe matching (table stakes), gate advanced AI features (photo/receipt scanning) behind Pro tier for monetization, and defer loyalty card integration to v2+ due to high partnership costs. This approach validates core hypothesis—"do Kindred users want pantry management?"—before investing in complex AI pipelines. The architecture follows established patterns from FeedFeature and VoicePlaybackFeature, creating a new PantryFeature SPM package that depends on shared infrastructure without creating circular dependencies.

Critical risks center on AI reliability: expiry date hallucination, OCR misreads, and ML recognition accuracy collapse in real-world conditions. Mitigation requires safety-first design (conservative estimates, manual confirmation, clear disclaimers), two-stage OCR processing (VisionKit → Gemini), and progressive permission requests to avoid 60%+ denial rates. Memory management, offline-first sync conflicts, and ingredient normalization chaos are secondary risks with well-documented solutions from existing TCA patterns and standard practices (SwiftData local-first, USDA IngID canonical mapping, streaming file uploads).

## Key Findings

### Recommended Stack

Kindred's existing stack supports all Smart Pantry capabilities without framework changes. The iOS architecture (SwiftUI + TCA 1.x, Apollo iOS 2.0.6, AVFoundation, iOS 17.0+), backend (NestJS 11 + GraphQL + Prisma 7 + PostgreSQL 15), and AI infrastructure (Gemini 2.0 Flash via Firebase AI Logic SDK) already exist and are validated. Stack research identified only two new backend dependencies and two iOS frameworks (both built-in).

**Core technologies:**
- **VisionKit (iOS 17+)** — Live receipt OCR with DataScannerViewController, replacing custom AVFoundation pipelines. Built-in framework, zero cost, on-device processing with currency detection.
- **Gemini 2.0 Flash** — Already integrated for voice narration; extend for image analysis (fridge scanning, receipt parsing). Cost-effective at ~$0.001/image vs specialized food APIs at $0.02+/image.
- **SwiftData** — Local-first pantry persistence following existing GuestSessionClient pattern. Offline-first UX, automatic migrations, query performance with @Predicate macros.
- **class-validator/class-transformer (backend)** — Standard NestJS validation libraries for GraphQL input validation on pantry mutations. Works seamlessly with code-first @InputType decorators.
- **Apollo iOS 2.0.6** — Already validated; extend with pantry GraphQL operations. Offline-first cache with optimistic updates, local cache mutations for instant UI feedback.

**Critical stack decision:** Use VisionKit for live OCR preview feedback during receipt capture, then send image to Gemini for final semantic parsing and categorization. Gemini provides intelligent ingredient extraction (not just text, but categories, quantities, expiry estimates) while VisionKit gives instant on-device feedback.

### Expected Features

Feature research reveals a clear MVP boundary: 7 table-stakes features for v1.0, 6 differentiators for v1.x after validation, and 4 future considerations for v2+. Competitor analysis (Cooklist, SuperCook, Portions Master) shows match % badge and voice integration are unique differentiators within Kindred's ecosystem.

**Must have (table stakes):**
- Manual pantry CRUD — Essential fallback when scanning fails; users need control over inventory
- Barcode scanning for packaged goods — 99% accuracy expectation; speeds up bulk purchases
- Expiry tracking with push notifications — Core value proposition (prevent food waste)
- Basic ingredient matching to recipes — Answers "what can I make?" using existing recipe database
- Match % badge on recipe cards — Visual indicator of "cookability" based on pantry contents
- Shopping list from missing ingredients — Completes workflow loop; prevents app switching
- Persistent digital pantry with iCloud sync — Users expect inventory to persist across sessions

**Should have (competitive differentiators):**
- Photo-based fridge scanning (Pro) — Bulk capture multiple items vs one-by-one barcode scanning
- Receipt OCR for batch import (Pro) — Instant pantry population after shopping trip; saves 10+ minutes manual entry
- AI expiry estimation for fresh produce — Estimate shelf life for items without expiry dates
- Food waste analytics dashboard (Pro) — "You saved $47 this month" messaging; aligns with sustainability values
- Voice-based pantry updates via Siri — Natural synergy with existing voice narration feature
- Storage location categorization — Organize by fridge/freezer/pantry; improves findability for power users

**Defer (v2+):**
- Loyalty card integration — Requires partnership agreements with grocery chains; high business development effort
- Pantry-aware meal planning — Requires sophisticated constraint solver; build after understanding user planning patterns
- Household collaboration — Multi-user complexity (conflict resolution, permissions)
- Ingredient substitution engine — Complex cooking chemistry logic; high risk of recipe failure eroding trust

**Anti-features to avoid:**
- Real-time continuous fridge monitoring — Requires expensive smart fridge hardware or drains battery
- Automatic expiry detection from package photos — OCR accuracy <60% due to format variability; fails gracefully
- Every scanning method at once — Overwhelming UI; users pick one preferred method and stick with it

### Architecture Approach

Smart Pantry integrates as a new SPM package (PantryFeature) following established patterns from FeedFeature and VoicePlaybackFeature. Architecture leverages SwiftData for local persistence (same pattern as GuestSessionClient), Apollo GraphQL for backend sync with offline-first cache, UIImagePickerController for camera capture, and TCA Dependencies for testable composable clients. The key architectural decision: PantryFeature is a peer to FeedFeature (both depend on shared infrastructure), not a modification of FeedFeature. FeedFeature imports PantryFeature models (one-way dependency) for recipe matching logic, with AppReducer coordinating cross-feature effects.

**Major components:**

1. **PantryFeature (new SPM package)** — Complete pantry management with scanning, CRUD, expiry tracking. Structured with reducers per screen (PantryReducer, ScanningReducer, ItemDetailReducer), clients for side effects (PantryClient, VisionClient, ExpiryClient), and SwiftData models for domain. Dependencies: ComposableArchitecture, NetworkClient, DesignSystem, AuthClient.

2. **VisionClient (new client)** — Abstract camera capture + AI image analysis. Handles UIImagePickerController camera capture, Gemini 2.0 Flash API calls for fridge/receipt analysis, and error handling (camera permission denied, API failures). Lives inside PantryFeature, not shared (pantry-specific).

3. **FeedReducer modifications** — Add dependency on PantryFeature models for match % calculation using Jaccard similarity (standard recipe matching metric). Calculate match on recipe load, add filter action for "cookable now" (match >= 50%), maintain one-way dependency (FeedFeature reads from PantryClient, never writes).

4. **Backend GraphQL API extensions** — New Prisma models (PantryItem with category, expiry tracking, sync status), GraphQL resolvers (pantryItems query, add/update/delete mutations, bulkAddPantryItems for receipt scan). Cache policy: returnCacheDataAndFetch for lists, optimistic local updates for mutations.

5. **AppReducer coordination** — Compose PantryReducer as peer to FeedReducer, add pantry tab to navigation, coordinate cross-feature effects (pantry item saved → recalculate recipe matches). Acts as orchestrator for bidirectional communication without creating circular dependencies.

**Data flow patterns:**
- **Fridge scanning:** Camera capture → Gemini analysis (3-5s) → editable results → local SwiftData save → background GraphQL sync → recalculate recipe matches
- **Receipt OCR:** VisionKit live preview → Gemini semantic extraction → expiry estimation → bulk pantry add → notification scheduling
- **Recipe matching:** Recipe load → fetch pantry items → Jaccard similarity calculation → update match % → render badge (green >70%, yellow >50%)
- **Offline-first:** Local SwiftData persistence → queue GraphQL mutations → replay on reconnect → CRDT-based conflict resolution for quantities

### Critical Pitfalls

Research identified 10 critical pitfalls with detailed prevention strategies. Top 5 by risk severity:

1. **AI hallucination in expiry prediction** — ML models hallucinate dates, creating food safety risks. Users trust app predictions and consume spoiled food or discard safe food. Prevention: never present AI estimates as authoritative, require manual confirmation, add disclaimers ("Estimated expiry—verify packaging"), use conservative estimates, implement safety guardrails (flag predictions >30 days, warn on dairy/meat).

2. **OCR misreads breaking ingredient matching** — Receipt OCR mangles ingredient names ("EGGS" → "LG EGO 12 CT"), simple exact matching fails, feature feels broken. Retailers use cryptic abbreviations (Fred Meyer: "STO LRG BRUNN"). Prevention: two-stage pipeline (VisionKit text extraction → Gemini structured extraction with fuzzy matching), implement FuzzyWuzzy Levenshtein distance matching, build retailer-specific abbreviation mappings, allow manual correction with suggested matches.

3. **Memory explosion from batch photo processing** — User selects 10 fridge photos at 48MP each, app loads all at full resolution, crashes with OOM error. Prevention: never load full UIImage objects, use loadFileRepresentation API with file paths, process sequentially with autoreleasepool, resize immediately, test with 20+ high-res photos on device.

4. **Offline-first sync conflicts** — User adds "2 eggs" offline, backend processes receipt adding "12 eggs", conflict resolution chooses wrong version. TCA reducers expect unidirectional flow but offline creates bidirectional sync. Prevention: implement operation-based CRDT for quantities (add +2, not set to 2), add version field for optimistic locking, queue mutations with persistence, tag sources ("user_manual" vs "receipt_scan"), show conflict UI for ambiguous cases.

5. **Ingredient normalization chaos** — Database accumulates "eggs", "large eggs", "lg eggs", "EGGS", "egg" as separate items. Recipe matching fails because recipe says "eggs" but pantry has "large eggs". Prevention: adopt USDA IngID Thesaurus for canonical Preferred Descriptors, map all ingredients to canonical form on save, implement FuzzyWuzzy matching during manual entry, build synonym database (FooDB, Open Food Facts), auto-merge obvious variants (case-insensitive, strip punctuation).

**Secondary pitfalls:** Unit conversion hell (1 cup flour ≠ 1 cup sugar by weight; requires FAO density database), push notification permission fatigue (60%+ denial if asked too early; use progressive disclosure), ML recognition accuracy collapse (works in bright kitchen testing, fails in real fridges with poor lighting; add photo quality pre-checks), GraphQL file upload memory leak (stream to S3, don't buffer in resolver), camera permission denied without fallback (show Settings deep-link + manual entry option).

## Implications for Roadmap

Based on combined research, suggested 6-phase structure optimized for dependency resolution and risk mitigation:

### Phase 1: Foundation & Infrastructure (Week 1)
**Rationale:** Bottom-up dependency resolution—infrastructure before features, models before UI. All subsequent phases depend on these shared clients and data models.

**Delivers:**
- VisionClient interface (stub implementation for testing)
- PantryItem SwiftData model with validation
- Backend GraphQL schema (Prisma migrations, pantry queries/mutations deployed to staging)
- Ingredient normalization strategy integrated with USDA IngID
- Memory-safe batch processing utilities
- Offline-first sync architecture with conflict resolution strategy

**Addresses pitfalls:**
- Ingredient normalization chaos (establish canonical mapping upfront)
- Memory explosion (create reusable streaming utilities)
- Offline-first conflicts (design CRDT strategy before implementation)
- AI hallucination (establish safety-first ML prediction patterns)

**Research flags:** Standard practices (TCA dependency injection, SwiftData models, Prisma migrations). No phase-specific research needed.

---

### Phase 2: Pantry CRUD & Manual Entry (Week 2)
**Rationale:** Build core table-stakes feature that validates entire flow without AI complexity. Manual entry is essential fallback for all scanning features.

**Delivers:**
- PantryClient with SwiftData persistence
- PantryReducer state management
- PantryView list with swipe-to-delete
- Manual item add/edit forms
- GraphQL sync with optimistic updates
- Offline queue for mutations

**Addresses features:**
- Manual pantry CRUD (table stakes)
- Persistent digital pantry (table stakes)

**Uses stack:**
- SwiftData for local-first persistence
- Apollo iOS for GraphQL sync
- TCA Dependencies for testable clients

**Avoids pitfalls:**
- Offline-first conflicts (CRDT implementation for quantities)
- Ingredient normalization (canonical mapping on save)

**Research flags:** Standard CRUD patterns. No phase-specific research needed.

---

### Phase 3: Camera Capture (Week 3)
**Rationale:** Camera infrastructure needed before AI analysis. Isolate permission flow and image storage from ML complexity.

**Delivers:**
- UIImagePickerController integration
- Camera permission flow with progressive disclosure
- Photo capture → UIImage
- Upload to Cloudflare R2
- Store image URLs in PantryItem
- Memory-safe sequential processing

**Addresses pitfalls:**
- Camera permission denial (permission priming screen, Settings deep-link)
- Memory explosion (file streaming, not UIImage buffering)

**Uses stack:**
- UIImagePickerController for camera
- Cloudflare R2 for image storage
- Streaming file uploads (not sync resolver processing)

**Research flags:** Standard camera integration. Consider researching iOS camera permission best practices if acceptance rate <70% during testing.

---

### Phase 4: AI Image Analysis (Week 4)
**Rationale:** Build on camera infrastructure, add intelligence. Fridge scanning is premium differentiator, validates AI pipeline before receipt OCR.

**Delivers:**
- Firebase AI Logic SDK integration
- VisionClient implementation (analyzeFridgePhoto, analyzeReceipt)
- Gemini 2.0 Flash prompts for fridge scanning
- ScanResultsView with editable ingredient list
- Confidence thresholds (>70% for auto-accept)
- Manual correction flow

**Addresses features:**
- Photo-based fridge scanning (Pro differentiator)

**Uses stack:**
- Gemini 2.0 Flash (already integrated)
- Firebase AI Logic SDK

**Avoids pitfalls:**
- AI hallucination (show confidence, allow correction, conservative estimates)
- ML accuracy collapse (photo quality pre-checks, multi-shot mode)

**Research flags:** NEEDS PHASE RESEARCH—Gemini prompt engineering for optimal food recognition accuracy, confidence threshold tuning, real-world fridge photo testing strategy.

---

### Phase 5: Recipe Matching & Feed Integration (Week 5)
**Rationale:** Delivers core user value ("what can I make?"). Depends on populated pantry from Phase 2-4.

**Delivers:**
- FeedReducer pantry integration
- Jaccard similarity matching algorithm
- Match % badge on recipe cards (green >70%, yellow >50%)
- "Cookable now" filter (match >= 50%)
- Sort by match % descending
- Shopping list from missing ingredients

**Addresses features:**
- Basic ingredient matching (table stakes)
- Match % badge (unique differentiator)
- Shopping list generation (table stakes)

**Implements architecture:**
- FeedFeature dependency on PantryFeature models
- AppReducer coordination (pantry change → recalculate matches)

**Avoids pitfalls:**
- Unit conversion hell (defer complex conversions to v1.x; match on normalized names only for MVP)
- Ingredient normalization (leverage Phase 1 canonical mapping)

**Research flags:** Standard pattern (TCA reducer composition). May need research on recipe similarity algorithms if Jaccard proves insufficient.

---

### Phase 6: Expiry Tracking & Notifications (Week 6)
**Rationale:** Final table-stakes feature. Depends on pantry items existing (Phase 2) and scanning populating data (Phase 4).

**Delivers:**
- ExpiryClient with heuristic shelf-life calculation
- Local notification scheduling
- Progressive notification permission request (after first pantry add)
- Expiry badge in PantryView ("Expires in 2 days")
- Deep linking (tap notification → filtered pantry view)
- In-app notification center for denied permission
- Batched expiry notifications (avoid spam)

**Addresses features:**
- Expiry tracking with notifications (table stakes)
- AI expiry estimation (differentiator, use conservative defaults for MVP)

**Avoids pitfalls:**
- Push notification permission fatigue (progressive request after user sees value)
- AI hallucination (conservative estimates, manual confirmation)

**Research flags:** Standard iOS notification patterns. No phase-specific research needed unless targeting complex timezone handling.

---

### Phase Ordering Rationale

**Why this order:**
- **Phases 1-2 before 3-6:** Infrastructure and manual CRUD validate entire architecture without AI complexity. If users don't want pantry management at all, stop before investing in scanning.
- **Phase 3 before 4:** Camera capture isolated from ML processing. Permission flow and file handling are orthogonal concerns; decoupling reduces debugging complexity.
- **Phase 4 before 5:** Recipe matching requires populated pantry. Users must have ingredients (from scanning or manual entry) before matching provides value.
- **Phase 6 last:** Notifications are enhancement to existing pantry. Core features (add items, match recipes) work without notifications; can deprioritize if timeline compresses.

**Dependency enforcement:**
- Phase 2 depends on Phase 1 (needs VisionClient interface, PantryItem model, normalization strategy)
- Phase 4 depends on Phase 3 (needs captured images from camera flow)
- Phase 5 depends on Phase 2 (needs populated pantry from manual/scan sources)
- Phase 6 depends on Phase 2 (needs pantry items with expiry dates)

**Parallel work opportunities:**
- Phases 1-2 can overlap (infrastructure + CRUD use different files)
- Phase 3 (camera) + Phase 4 (AI) can overlap with stub (camera returns test image while AI develops)
- Phase 5 (matching) independent of camera/AI, only needs PantryClient interface

**Pitfall avoidance:**
- Early phases establish patterns that prevent late-phase disasters (normalization in Phase 1 prevents chaos in Phase 5)
- Progressive complexity reveals integration issues early (manual CRUD before AI complexity)
- Each phase is independently testable with clear exit criteria

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 4 (AI Image Analysis):** Gemini prompt engineering is experimental domain. Need phase research on optimal prompts for food recognition, confidence threshold tuning based on real fridge photos (not just clean test images), and fallback strategies when recognition fails. Sparse documentation on production food recognition accuracy.
- **Phase 5 (Recipe Matching):** If Jaccard similarity proves insufficient (doesn't handle partial ingredients, synonyms, or unit conversions), may need research on semantic similarity (vector embeddings), ingredient substitution rules, or recipe recommendation systems. Standard Jaccard likely sufficient for MVP.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Foundation):** Well-documented TCA dependency injection, SwiftData models, Prisma migrations, USDA IngID integration.
- **Phase 2 (Pantry CRUD):** Standard CRUD operations with TCA, established Apollo cache patterns from FeedFeature.
- **Phase 3 (Camera Capture):** UIImagePickerController is documented iOS pattern; Cloudflare R2 upload established in existing codebase.
- **Phase 6 (Expiry Tracking):** UNUserNotificationCenter local notifications are standard iOS pattern with extensive documentation.

**When to trigger phase research:**
- During Phase 4 planning, if Gemini recognition accuracy <70% on initial tests → research alternative ML models (CoreML Food101, specialized food APIs)
- During Phase 5 planning, if recipe match rate <50% user satisfaction → research semantic matching, ingredient embeddings

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommended technologies already validated in existing Kindred codebase (Gemini 2.0 Flash, SwiftData, Apollo iOS 2.0.6, TCA). Only additions are built-in iOS frameworks (VisionKit) and standard NestJS packages (class-validator). Source quality: official Apple documentation, Firebase docs, NestJS official guides. |
| Features | MEDIUM | Based on verified competitor analysis (Cooklist, SuperCook, Portions Master), UX case studies, and user expectation research. Confidence is MEDIUM (not HIGH) because CoreML food classification accuracy claims need independent verification beyond GitHub examples, and receipt OCR accuracy standards come from vendor marketing (TabScanner, Yomio) rather than peer-reviewed research. |
| Architecture | HIGH | TCA patterns verified with existing codebase (FeedFeature, VoicePlaybackFeature, GuestSessionClient). Apollo offline-first cache patterns, SwiftData local-first persistence, and UIImagePickerController integration all have official Apple/Apollo documentation. Component boundaries follow established SPM package structure. Build order dependencies validated against existing project. |
| Pitfalls | MEDIUM | Based on production app case studies (Yuka food scanner, KitchenPal, CalCam), technical deep-dives (PHPicker memory usage, GraphQL file upload patterns), and AI reliability research. Confidence is MEDIUM because some pitfalls (AI hallucination rates, OCR misread frequency) cite specific percentages from recent sources (2026 benchmarks) but lack longitudinal validation. Prevention strategies verified with established patterns (CRDT for offline sync, USDA IngID for normalization). |

**Overall confidence:** HIGH

Research quality benefits from existing validated stack (no new framework risks), clear competitor feature landscape (table stakes vs differentiators well-defined), and documented architectural patterns (TCA + SwiftData + Apollo). Confidence reduced slightly by reliance on vendor claims for ML accuracy and lack of direct food recognition benchmarks in production conditions, but mitigation strategies (manual correction flows, confidence thresholds, conservative defaults) address uncertainty.

### Gaps to Address

**Gaps identified during research:**

1. **Gemini 2.0 Flash food recognition accuracy in production conditions** — Research cites general image recognition capabilities but lacks specific benchmarks for fridge photos with poor lighting, occlusion, and varied angles. Vendor blog (CalCam) shows proof-of-concept but not production accuracy metrics.
   - **Mitigation:** Build confidence threshold testing into Phase 4 with 30+ real fridge photos. If accuracy <70%, trigger phase research on alternative models (CoreML Food101, ML Kit) or adjust UX to require more user confirmation.

2. **Receipt OCR retailer-specific abbreviation coverage** — Research identifies problem (Fred Meyer "STO LRG BRUNN", Whole Foods "EDGS") but doesn't provide comprehensive abbreviation database or solution beyond "crowdsource from users."
   - **Mitigation:** Start with two-stage Gemini pipeline (semantic understanding should handle abbreviations better than regex). Track OCR match rate during Phase 4 beta. If <60%, consider building retailer-specific mapping database or integrating specialized receipt OCR service (TabScanner API).

3. **Unit conversion density database integration** — Research recommends FAO density data and ingredient-aware conversion but doesn't specify integration path or library availability.
   - **Mitigation:** For MVP (Phase 5), match on normalized ingredient names only, ignore unit conversions. Display "200g (~1.5 cups)" as informational but don't block matches. Defer intelligent unit conversion to v1.x, research density libraries (convert-units with extensions) during Phase 5 if user feedback demands it.

4. **Offline-first CRDT implementation details** — Research recommends operation-based CRDT for quantities but doesn't specify library or implementation pattern for SwiftData + Apollo.
   - **Mitigation:** Phase 1 architecture research should identify CRDT approach: either Automerge/Yjs Swift bindings or custom operation log with conflict resolution UI. If no clear Swift CRDT library, implement simpler version-based optimistic locking with conflict detection (show UI for user resolution rather than auto-merge).

5. **iOS notification permission acceptance benchmarks** — Research cites 60%+ denial for early requests and 70%+ target with progressive disclosure but doesn't provide iOS-specific benchmarks (vs general mobile).
   - **Mitigation:** Instrument Phase 6 with analytics tracking permission request timing and acceptance rate. A/B test permission priming screen variations. If acceptance <60%, iterate on timing and messaging before declaring phase complete.

**How to handle gaps during execution:**
- Phase 1: Resolve CRDT implementation strategy (research libraries or design custom conflict UI)
- Phase 4: Validate Gemini food recognition accuracy with real-world testing; trigger phase research if <70%
- Phase 4: Track receipt OCR match rate; build retailer abbreviation mappings if <60%
- Phase 5: Defer unit conversion to v1.x unless user feedback demands it
- Phase 6: Instrument permission acceptance rate; iterate on priming screen if needed

## Sources

### Primary (HIGH confidence)

**Stack (official documentation):**
- [VisionKit DataScannerViewController](https://developer.apple.com/documentation/visionkit/datascannerviewcontroller) — Apple official docs for iOS 17+ live OCR
- [WWDC22: Capture machine-readable codes and text with VisionKit](https://developer.apple.com/videos/play/wwdc2022/10025/) — Apple official session introducing DataScannerViewController
- [Gemini 2.0 Flash Documentation](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-0-flash) — Google Cloud official docs for image understanding
- [Firebase AI Logic SDK](https://firebase.google.com/docs/ai-logic/get-started) — Official Firebase SDK for Gemini on iOS
- [Apollo iOS 2.0 Documentation](https://www.apollographql.com/docs/ios) — Official Apollo GraphQL iOS docs for cache transactions
- [NestJS GraphQL Documentation](https://docs.nestjs.com/graphql/resolvers) — Official NestJS code-first GraphQL patterns
- [SwiftData in iOS 17](https://developer.apple.com/documentation/swiftdata) — Apple official SwiftData documentation
- [Prisma PostgreSQL Quickstart](https://www.prisma.io/docs/prisma-orm/quickstart/postgresql) — Official Prisma 7 with PostgreSQL 15+ docs

**Architecture (official frameworks):**
- [TCA GitHub Repository](https://github.com/pointfreeco/swift-composable-architecture) — Official Composable Architecture library and patterns
- [Apollo iOS Cache Transactions](https://www.apollographql.com/docs/ios/caching/cache-transactions) — Official cache mutation patterns
- [UIImagePickerController](https://developer.apple.com/documentation/uikit/uiimagepickercontroller) — Apple official camera capture docs

### Secondary (MEDIUM confidence)

**Features (competitor analysis, case studies):**
- [GE Profile Smart Refrigerator](https://pressroom.geappliances.com/news/ge-profileTM-unveils-game-changing-smart-refrigerator-with-kitchen-assistantTM-revolutionizing-grocery-shopping-and-meal-planning) — Enterprise investment validation ($4,899 fridge with barcode scanner)
- [Cooklist App Store](https://apps.apple.com/us/app/cooklist-pantry-meals-recipes/id1352600944) — Loyalty card integration competitor analysis
- [Portions Master](https://portionsmaster.com/blog/best-pantry-inventory-app-and-fridge-management-tool/) — AI meal recommendations + image recognition competitor
- [Best Meal Planning Apps 2026](https://www.foodieprep.ai/blog/meal-planning-apps-in-2026-which-tools-actually-simplify-your-kitchen) — User expectation research for pantry features
- [ConsumeSmart](https://www.consumesmart.com/) — AI grocery/pantry app with receipt scanning validation
- [NourishMate Complete Guide](https://www.nourishmate.app/blog/complete-guide-smart-pantry-management) — User value research ($2K+ annual savings)

**Architecture (implementation guides):**
- [Getting Started with TCA | Kodeco](https://www.kodeco.com/24550178-getting-started-with-the-composable-architecture) — Multi-step TCA flow patterns
- [SwiftData Local-First Architectures](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2) — Offline-first patterns with SwiftData
- [SwiftUI Camera Integration 2026](https://www.createwithswift.com/camera-capture-setup-in-a-swiftui-app/) — Modern camera capture patterns
- [Recipe Similarity Networks | Nature](https://www.nature.com/articles/s41598-025-17189-6) — Jaccard similarity for recipe matching (peer-reviewed)

**Pitfalls (production case studies, benchmarks):**
- [Yuka Food Scanner Case Study](https://www.scandit.com/resources/case-studies/yuka/) — Real-world barcode scanning accuracy (99% availability, 79% within 5% accuracy)
- [CalCam: Gemini API Food Tracking](https://developers.googleblog.com/calcam-transforming-food-tracking-with-the-gemini-api/) — Gemini production use case for food recognition
- [OCR for Receipts Data Extraction](https://surveyinsights.org/?p=17190) — Receipt OCR accuracy benchmarks (>95% for vendor/date, lower for items)
- [AI Hallucination Rates 2026](https://suprmind.ai/hub/ai-hallucination-rates-and-benchmarks/) — LLM hallucination frequency and prevention
- [Using PHPickerViewController Efficiently](https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/) — Memory management for batch photo processing
- [Push Notification Best Practices 2025](https://www.pushwoosh.com/blog/push-notification-best-practices/) — Permission acceptance rates (73% disable if overwhelmed, 60%+ deny early requests)

### Tertiary (LOW confidence, needs validation)

**Features (vendor claims):**
- [CoreML Food101 GitHub](https://github.com/ph1ps/Food101-CoreML) — Food classification accuracy claims (86.97% Top-1, 97.42% Top-5) from repository readme, not peer-reviewed
- [TabScanner Receipt OCR](https://tabscanner.com/ocr-supermarket-receipts/) — Vendor marketing claims (>95% accuracy for line items) without independent verification

**Pitfalls (specific numeric claims):**
- [Ingredient Matching Research](https://www.researchgate.net/publication/234061858_Ingredient_Matching_to_Determine_the_Nutritional_Properties_of_Internet-Sourced_Recipes) — 47.2% match without rules, 91.1% with rules (single study, 2012)
- [Food Barcode Scanning Quality](https://pmc.ncbi.nlm.nih.gov/articles/PMC10260744/) — 79% products within 5% accuracy (specific to energy values, may not generalize)

**Stack (specialized use cases):**
- [USDA IngID Thesaurus](https://www.ars.usda.gov/ARSUSERFILES/80400535/DATA/INGID/USDA_INGID_THESAURUS_FOR_RELEASE_FINAL.PDF) — Ingredient normalization canonical mappings (official USDA resource)
- [FooDB](https://foodb.ca/) — Food constituent database for synonym mapping (academic resource, unclear maintenance status)

---
*Research completed: 2026-03-11*
*Ready for roadmap: yes*
