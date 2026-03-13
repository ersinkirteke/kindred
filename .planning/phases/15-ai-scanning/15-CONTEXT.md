# Phase 15: AI Scanning - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Pro users can scan fridge photos or supermarket receipts to auto-populate their pantry inventory using AI. Fridge photos analyzed by Gemini Vision for ingredient identification. Receipts scanned via VisionKit on-device OCR with Gemini post-processing for abbreviation resolution. Both flows produce an editable ingredient checklist that bulk-adds to the pantry. Includes recipe suggestions based on scanned items and a one-free-scan trial for free users.

</domain>

<decisions>
## Implementation Decisions

### Scan Results Experience
- Editable checklist UI for both fridge and receipt scan results (shared component)
- Color-coded confidence badges: green (>90%), yellow (70-90%), red (<70%). High confidence items pre-checked, low confidence unchecked by default
- Inline edit on any field (name, quantity, category) right in the results list
- Photo shown as header above the ingredient list (helps verify AI accuracy)
- Items appear all at once after full analysis (no streaming)
- Results presented as a bottom sheet sliding up over the dimmed photo
- "Add X items to pantry" bulk button at bottom adds all checked items in one tap
- "+ Add item AI missed" button at bottom of results list opens quick-add field inline
- Show all items including low confidence ones, flag low confidence with yellow badge and unchecked by default

### Fridge Scan AI
- Gemini estimates quantities where possible ("~6 eggs", "~500g chicken"). Pre-fills quantity field, user can edit
- AI suggests storage location per item (fridge/freezer/pantry) based on item type
- AI auto-categorizes each item to FoodCategory enum (dairy, produce, protein, etc.)
- AI estimates expiry dates per item (conservative estimates, shown in checklist as "~7 days")
- Only identify clearly visible items — don't guess at items behind others

### Receipt Scanning
- VisionKit DataScannerViewController with live text recognition overlay (highlighted text in real-time)
- No fallback needed — iOS 17.0 minimum guarantees VisionKit + A12+ chip availability
- Single capture mode (not multi-page). Long receipts may need folding or two passes
- On-device OCR extracts text, sends just the TEXT (not image) to backend for Gemini parsing
- Straight to processing after capture — no intermediate raw text preview
- Same editable checklist UI as fridge scan results
- Receipt items get names + quantities only (no prices). Expiry dates estimated by Gemini based on item type

### Gemini Prompt Design
- Strict JSON schema response (responseMimeType: 'application/json') — matches existing RecipeParserService pattern
- Always English output regardless of input language. Turkish product names normalized to English
- Gemini self-reports confidence score (0-100) per item in JSON response
- FoodCategory enum values passed in prompt context for accurate categorization
- Two separate prompts: fridge prompt optimized for visual recognition, receipt prompt for text parsing/abbreviation expansion
- Low temperature (0.1-0.2) for precise, deterministic extraction

### Recipe Suggestions After Scan
- Immediately after adding items, show "You can make these!" with 3-5 matching recipe cards in horizontal scroll carousel
- Recipes matched based on newly scanned items only (not full pantry)
- Full VoiceOver support on recipe cards: name, prep time, ingredients available

### AI Failure Handling
- Total failure: "We couldn't identify items. Retry or add items manually?" with Retry button + link to manual add form
- Low confidence items shown in checklist with yellow badge, unchecked by default — user decides whether to include
- Receipt OCR failure: same pattern as fridge failure (consistent error handling)
- No learning/correction tracking for now — each scan independent
- Unlimited scans for Pro users (no daily/weekly limit)
- Graceful degradation when Gemini is down: "AI scanning temporarily unavailable. Add items manually?" Fridge photo still uploads to R2 for later processing

### Backend Processing Flow
- Single request/response pattern: new GraphQL mutation analyzeScan(jobId) called after upload, waits for response with results. Gemini Flash typically responds in 3-10s
- Persist scan results in database (Prisma ScanJob table with results JSON) — enables history, re-processing, analytics
- New GraphQL mutation analyzeReceiptText(text, userId) for receipt scanning — sends just OCR text, not image
- Normalize scanned item names against existing IngredientCatalog server-side before returning results
- Accept-and-learn pattern for unknown items: auto-create catalog entries for items Gemini identifies that don't exist
- 30 second timeout for Gemini analysis
- Require Clerk JWT authentication for all scan mutations (no anonymous access)

### Pantry Auto-Population
- Local first, sync later — items saved to SwiftData instantly, PantrySyncWorker pushes to backend. Matches Phase 13 offline-first pattern
- Scan-added items show small "Scanned" camera icon badge in pantry list (uses existing ItemSource model)
- Duplicate check with quantity merge: if "eggs" already in pantry, add scanned quantity to existing ("Updated: eggs 6 → 12")
- Success screen: brief "✓ 8 items added" animation, then immediately show 3-5 matching recipe carousel

### Pro Paywall
- Visual teaser before paywall: short demo/mockup of scan results ("Scan your fridge and we'll tell you what you can cook")
- Scan-specific paywall highlighting scanning benefits (not generic Pro paywall)
- Animated mockup on paywall: looping animation showing fridge photo → AI analyzing → ingredient list
- One free scan for all users (first scan free, paywall after). Server-side tracking of free scan usage per userId
- After free scan results, show "Loved it? Upgrade to Pro for unlimited scans" banner

### Accessibility
- VoiceOver full announcement on scan result items: "Eggs, quantity 6, high confidence, checked. Double tap to uncheck or edit."
- Success haptic (UINotificationFeedbackGenerator.success()) when scan results arrive
- Light haptic pulse when VisionKit first detects text in receipt scanner
- Reduce Motion: static text + standard ProgressView spinner instead of scanning animation
- Full Dynamic Type support on scan results checklist (no capped scaling)
- Bulk add button announces live count updates as items checked/unchecked
- Double-tap to enter edit mode on scan result items
- Full VoiceOver support on recipe suggestion carousel

### Claude's Discretion
- Exact scanning animation design during processing
- Gemini prompt wording and JSON schema structure
- ScanJob Prisma model schema design
- Exact layout/spacing of scan results checklist
- Recipe matching algorithm for "You can make these" suggestions
- Error message copy and retry UX details

</decisions>

<specifics>
## Specific Ideas

- Results should feel instant and satisfying — the "analyzing" wait followed by ingredients appearing should be a magical moment
- The free trial scan is a conversion hook — make the first scan experience as polished as possible
- Receipt scanning should feel like a natural extension of the camera flow — same quality, different input
- Confidence badges should feel informative, not alarming — green/yellow is fine, red should be rare

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- ScanUploadReducer: Already handles camera → upload → "processing" state. Phase 15 extends from "processing" → "results"
- ScanJob / ScanType models: Ready with fridge/receipt types and uploading/processing/completed/failed statuses
- RecipeParserService: Existing Gemini integration pattern (GoogleGenerativeAI, JSON schema, 0.1 temp)
- PantryClient + AddEditItemReducer: Handle adding items to SwiftData pantry
- PantrySyncWorker: Offline-first sync to backend already implemented
- ItemSource model: Exists for tracking how items were added (manual vs scan)
- IngredientCatalog: Server-side normalization with accept-and-learn pattern
- R2StorageService: Already uploads scan photos, returns URLs

### Established Patterns
- TCA reducer + @Presents child for modal flows (PantryReducer → ScanUploadReducer pattern)
- Apollo GraphQL mutations with KindredAPI codegen types
- Poll-based permission pattern (camera, location) — extends to VisionKit if needed
- Offline-first: SwiftData local → PantrySyncWorker pushes to backend
- WCAG AAA: 56dp touch targets, 18sp+ text, VoiceOver labels, 7:1 contrast, Dynamic Type

### Integration Points
- ScanUploadReducer.uploadCompleted → triggers analyzeScan mutation (new)
- Backend ScanService.uploadScanPhoto → extend with Gemini analysis step
- PantryReducer → present scan results as @Presents child
- PantryClient.addItem → bulk add from scan results
- FeedReducer → recipe matching query for "You can make these" carousel

</code_context>

<deferred>
## Deferred Ideas

- Scan accuracy learning/personalization — track user corrections for future improvement
- Multi-page receipt scanning — scan long receipts in sections
- Price extraction from receipts — budget tracking potential
- Camera capture fallback for VisionKit failures — not needed with iOS 17.0 minimum

</deferred>

---

*Phase: 15-ai-scanning*
*Context gathered: 2026-03-13*
