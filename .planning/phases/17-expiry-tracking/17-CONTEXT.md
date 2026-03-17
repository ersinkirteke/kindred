# Phase 17: Expiry Tracking - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

AI-estimated expiry dates on pantry items with push notification alerts and visual indicators. Users see freshness status at a glance in the pantry list, receive batched morning notifications before items expire, and can mark expired items as consumed or discarded with swipe gestures.

</domain>

<decisions>
## Implementation Decisions

### Expiry Visual Indicators
- Color-coded left edge strip on each pantry item row (green/yellow/red)
- Thresholds: green > 3 days, yellow 1-3 days, red = expired
- Static colors only — no animation or pulsing (clean, respects reduceMotion by default)
- Expired items: red edge + dimmed row (reduced opacity) to visually separate from fresh
- Items expiring soonest sort to top within each storage location group
- Items with no expiry date: no indicator at all — clean row, only items WITH expiry get visual treatment

### Notification Timing & Tone
- Single daily digest notification, max one per day
- Delivery at 9 AM local time
- Warm & helpful tone matching Kindred's personality (e.g., "Your milk expires tomorrow — time for a smoothie?")
- Notification permission requested progressively after user's first pantry item add
- Backend cron job runs once daily at 8 AM UTC to batch and send

### Consume/Discard Flow
- Swipe actions on expired/expiring item rows: left = discard, right = consumed
- After marking: soft delete immediately (item disappears from list, recoverable via existing isDeleted pattern)
- No undo toast or history section — keep it simple with existing soft delete

### AI Expiry Estimation
- Display as date with disclaimer: "Expires ~Mar 22" with small subtitle "AI estimate — check packaging"
- Manual override: tap the expiry date directly to open a date picker (quick inline edit)
- Auto-estimate on item add when user doesn't set a date (uses IngredientCatalog.defaultShelfLifeDays + Gemini for unknowns)
- Scan results (fridge/receipt) also auto-estimate expiry during the same Gemini analysis call — no extra API request

### Claude's Discretion
- Exact Gemini prompt for expiry estimation
- Date picker component style (inline vs sheet)
- Swipe gesture animation details
- Notification copy variations for different item types
- How to handle items with no IngredientCatalog match for expiry estimation

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- PantryItem (SwiftData @Model): Already has `expiryDate: Date?` field — no schema change needed on iOS
- PantryItem (Prisma): Already has `expiryDate DateTime?` field — no migration needed
- IngredientCatalog: Has `defaultShelfLifeDays Int?` — pre-seeded for 185 ingredients
- PushService: Firebase FCM with multi-device support, batch sending (up to 500), auto token cleanup
- DeviceToken model: Already tracks userId + platform for push delivery
- PantryView: Groups items by storage location — expiry sort slots into existing grouping
- AddEditItemFormView: Existing edit form for manual expiry date override fallback
- Soft delete pattern: `isDeleted` flag on PantryItem with PantrySyncWorker

### Established Patterns
- TCA reducers with @Dependency injection (PantryReducer, FeedReducer)
- Progressive permission requests: location (Phase 8), camera (Phase 14) — same pattern for notifications
- @Scheduled cron jobs via NestJS ScheduleModule (already imported in AppModule)
- Gemini 2.0 Flash for AI tasks (ScanAnalyzerService pattern for structured JSON output)

### Integration Points
- PantryReducer: Add expiry sort logic and swipe consume/discard actions
- PantryView: Add color-coded left edge to item rows
- ScanAnalyzerService: Extend Gemini prompt to include expiry estimation in scan results
- PushService: New method for batched expiry digest notifications
- Backend: New @Cron job in PantryModule or dedicated ExpiryModule

</code_context>

<specifics>
## Specific Ideas

- Notification feels personal like a friend reminding you, not a utility alert
- Color edge should be thin (2-3pt) and only on left side — not a full border
- Dimmed expired items should still be tappable for consume/discard actions

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 17-expiry-tracking*
*Context gathered: 2026-03-17*
