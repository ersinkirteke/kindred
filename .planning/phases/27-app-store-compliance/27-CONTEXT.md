# Phase 27: App Store Compliance Updates - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Update App Store submission artifacts — `PrivacyInfo.xcprivacy`, App Store Connect Privacy Labels, the externally-hosted Privacy Policy at `kindred.app/privacy`, the Recipe Detail UI (nutrition disclaimer + Spoonacular attribution), fastlane metadata (review notes), and App Store screenshots — so the app can be submitted in Phase 28 without rejection after the Phase 23 Spoonacular backend integration.

**Not in scope:**
- Fastlane release automation (Phase 28)
- App description copy updates (can be handled during Phase 28 release prep or as deferred polish)
- New in-app transparency surfaces (e.g., "Third Parties" settings screen)
- Regional/per-market label variants
- ATT prompt text changes
- Snapshot test infrastructure for screenshots
- Marketing text overlays on screenshots
- Full screenshot refresh beyond feed + detail

</domain>

<decisions>
## Implementation Decisions

### Privacy Label mechanics

**Criterion #3 interpretation (Spoonacular + manifest):**
- Do NOT add `api.spoonacular.com` to `NSPrivacyTrackingDomains`. Apple's tracking domains key is strictly for cross-app ATT tracking, and Spoonacular is a backend data processor, not a tracker. Misclassifying it risks review warnings.
- Criterion #3 is reinterpreted as: **manifest + privacy policy together disclose Spoonacular as a data processor.** The planner/executor should leave tracking domains untouched but add a manifest-level comment documenting Spoonacular's role, AND name Spoonacular in the updated privacy policy at `kindred.app/privacy`.
- No ROADMAP edit required — reinterpretation is captured here and will be referenced in the verification report.

**New data type to add:**
- `NSPrivacyCollectedDataTypeSearchHistory` (or the App Store Connect equivalent "Search History")
- `Linked = false` — backend proxies the query, user identifier is NOT attached to the Spoonacular request
- `Tracking = false`
- Purposes: `NSPrivacyCollectedDataTypePurposeAppFunctionality` only
- **Filter parameters (cuisine, diet, intolerances) fold into Search History** — Apple's Search History description covers "information entered by the user to perform a search," which includes filter refinements.

**Existing data type corrections:**
- **`NSPrivacyCollectedDataTypeProductInteraction` → switch `Linked` from `false` to `true`**. Rationale: Clerk auth (Phase 11) gave us a user id that Firebase Analytics receives as a user property, which Apple considers "linked." Purposes stay `NSPrivacyCollectedDataTypePurposeAnalytics` (don't broaden).
- **`NSPrivacyCollectedDataTypeCoarseLocation` stays `Linked = false`**. City is derived on-device and sent as a string query parameter; it's not stored against the account.
- **`NSPrivacyCollectedDataTypePurchaseHistory` unchanged** (App Functionality, Linked). Matches actual use.
- All other existing data types unchanged.

**Required Reason API audit:**
- Phase 27 includes a pass over the 5 Required Reason API categories (UserDefaults, FileTimestamp, DiskSpace, SystemBootTime, ActiveKeyboards) across the Kindred main target + SPM dependencies.
- Goal: prevent ITMS-91053 rejection at upload. Existing manifest declares only UserDefaults (CA92.1) and FileTimestamp (C617.1).
- Researcher should grep for API usage and produce a delta list; planner adds any missing entries to `PrivacyInfo.xcprivacy`.

**Third-party disclosure in privacy policy:**
- **Both Spoonacular and ElevenLabs must be named** as processors in the same policy update. ElevenLabs is already mentioned in the App Store description, but the hosted privacy policy does not currently name it — surfacing both now avoids a second revision.
- Each processor section should include: name, purpose, data sent, link to their privacy policy.
- Policy text also describes the backend proxy chain: "We send your search queries to our backend, which forwards them to Spoonacular API (data processor)."

**App Store Connect App Privacy Label reconciliation:**
- Plan includes a step to re-verify the ASC "Data Used to Track You" section against `NSPrivacyTrackingDomains` after adding Search History.
- Search History stays in "Data Linked/Not Linked to You," NOT in the Tracking section, because it's not used for cross-app tracking.
- Single global labels — no EU/regional variants in Phase 27.

**Review notes addendum:**
- Append a sentence to `Kindred/fastlane/metadata/review_information/notes.txt`: "Network requests route through api.kindredcook.app which proxies Spoonacular; this is documented in the privacy policy at kindred.app/privacy."
- Purpose: reduce reviewer friction when they see only the backend domain in iOS 17+ Privacy Report.

**Privacy URL unchanged:**
- `fastlane/metadata/en-US/privacy_url.txt` stays `https://kindred.app/privacy`. Only the hosted content changes.
- No per-locale URL split.

**Deliverfile untouched** — Phase 27 is pure compliance artifacts. Release mechanics stay with Phase 28.

### Recipe detail compliance UI

**Layout: inline footer section**
- Single surface appended **after `StepTimelineView`** (bottom of the scrollable content in `RecipeDetailView.swift`), before the sticky `bottomBar`. Structure: a `VStack(alignment: .leading, spacing: KindredSpacing.xs)` containing the disclaimer on one line and the attribution link on the next.
- **Disclaimer text (en):** `"Nutrition estimates from Spoonacular. Not for medical use."`
  **Disclaimer text (tr):** `"Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz."` (final wording to be validated by planner; keep meaning faithful to the English source.)
- **Attribution:** `"Powered by Spoonacular →"` as a tappable link to `https://spoonacular.com/food-api`, following Spoonacular's brand attribution guidelines (text link is acceptable; logo badge is optional and not required here).
- **Style:** `.font(.kindredCaptionScaled(size: captionSize))`, `.foregroundStyle(.kindredTextTertiary)` (or `.kindredTextSecondary` if tertiary reads too light in dark mode). `.padding(.top, KindredSpacing.lg)`, `.padding(.bottom, KindredSpacing.md)`, leading-aligned.
- **Accessibility:** Both strings wrapped in `Text(String(localized: ..., bundle: .main))`. Attribution link uses `.accessibilityLabel` explaining it opens Spoonacular in the browser. Dynamic Type respected via `kindredCaptionScaled`.
- **Dark mode:** Inherits semantic `kindredText*` colors; no explicit color override.
- **Localization:** Both strings added to `Kindred/Sources/Resources/Localizable.xcstrings` with `en` + `tr` translations.

**Rationale:** Single surface satisfies both criterion #4 (disclaimer) and #6 (attribution visible on detail view), keeps the recipe content uncluttered, matches the "Source:" footer pattern common in recipe apps, and is clearly visible to a reviewer without requiring any interaction.

### Screenshot refresh strategy

**Scope: minimal — reshoot feed + detail only**
- Retake only **`02-recipe-feed.png`** and **`05-recipe-detail.png`** in both locales (`en-US` + `tr`). Screenshots `01-voice-narration`, `03-pantry-scan`, `04-dietary-filters` stay unchanged.
- **Capture device:** iPhone 16 Pro Max (6.9") — covers Apple's current iPhone required screenshot size. No 6.5" variant needed unless App Store Connect explicitly blocks the upload.
- **Capture method:** Manual. Run the app on the physical iPhone 16 Pro Max or iOS 26 simulator, navigate to the target screen, and take a screenshot via Xcode simulator menu or device screenshot. Save to `Kindred/fastlane/screenshots/{en-US,tr}/`.
- **No marketing text overlays.** Pure UI screenshots. Branding/headline overlays can be handled in a future marketing-polish phase or Phase 28.
- **No snapshot-test automation.** `fastlane snapshot` / Snapfile infrastructure is deferred to Phase 28 or later.

**Feed screenshot requirements (`02-recipe-feed.png`):**
- Must show the "Popular Recipes" header (NOT "Viral near you"). Verify the feed UI actually renders that exact title in both locales before capturing.
- Should show multiple recipe cards with Spoonacular-sourced imagery and titles.
- Device status bar: typical (full battery, full signal, reasonable time).

**Detail screenshot requirements (`05-recipe-detail.png`):**
- Must be captured with the scroll position such that the **new Spoonacular attribution footer is visible in frame** (criterion #6). This may require scrolling past the hero image / ingredients so that the footer is near the bottom of the visible area.
- Alternative: if scroll-position framing is hard, capture two variants and pick the one that best shows the attribution while still conveying "recipe detail" at a glance.

**Locale handling:** Both `en-US` and `tr` screenshots must be refreshed in lockstep. App language must be switched before each capture session.

### Privacy policy coordination

**Approach: Phase produces a markdown draft**
- Phase 27 creates **`.planning/phases/27-app-store-compliance/POLICY-UPDATE.md`** containing the full updated privacy policy text (or the specific sections that change).
- Content includes:
  - New "Third-Party Processors" section naming **Spoonacular** (purpose: recipe data, data sent: search queries + filter parameters, link to Spoonacular's privacy policy).
  - New "Third-Party Processors" entry for **ElevenLabs** (purpose: voice cloning, data sent: audio recordings with consent, link to ElevenLabs' privacy policy).
  - Description of the backend proxy chain for Spoonacular.
  - Reference to the new "Search History" data type in the data-we-collect section.
- **Verification:** Phase 27's verification step confirms `POLICY-UPDATE.md` exists, lists both Spoonacular and ElevenLabs, and matches the decisions above.
- **Hand-off:** User manually copies the text from `POLICY-UPDATE.md` to the hosted site at `kindred.app/privacy` before running Phase 28 release. This manual step is explicitly documented in the Phase 27 verification output as a human checklist item.
- Phase 27 does NOT attempt to edit any sibling repo or external hosting.

### Claude's Discretion

- Exact Swift property/method names for the new disclaimer view component.
- Whether the disclaimer/attribution lives inline in `recipeContentView(_:)` or as a small private `@ViewBuilder` helper (e.g., `private var complianceFooter: some View`).
- Exact `NSPrivacyAccessedAPIType` reason codes for any Required Reason APIs discovered during the audit (pick the most accurate reason per Apple's published list).
- The precise final wording of the Turkish disclaimer translation (keep meaning faithful; planner or a quick human review can polish).
- Whether to use `openURL` environment or `Link(_:destination:)` for the "Powered by Spoonacular" link.
- Logging/tracking to add or remove during the compliance audit that isn't covered by the explicit decisions above.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Kindred/Sources/PrivacyInfo.xcprivacy`** — Existing manifest with 7 data types and 5 Google tracking domains. Edit in place to add Search History, toggle Product Interaction to Linked, and audit Required Reason APIs.
- **`DesignSystem` spacing + type tokens** — `KindredSpacing.{xs,sm,md,lg}`, `kindredCaptionScaled(size:)`, `kindredTextTertiary/Secondary`. Reuse for the compliance footer; do NOT introduce new typography tokens.
- **`Kindred/Sources/Resources/Localizable.xcstrings`** — Existing bilingual string catalog (en + tr). New disclaimer and attribution strings go here, following the existing `String(localized: "...", bundle: .main)` pattern seen throughout `RecipeDetailView.swift`.
- **`Kindred/fastlane/metadata/{en-US,tr}/`** — Existing metadata directory structure with 5 screenshot slots per locale. Reuse filename conventions (`02-recipe-feed.png`, `05-recipe-detail.png`).
- **`Kindred/fastlane/metadata/review_information/notes.txt`** — Existing review notes file; append the backend-proxy explanation here.

### Established Patterns
- **Localized strings always use `String(localized: "...", bundle: .main)`** — seen on nearly every `Text(...)` in `RecipeDetailView.swift`. New compliance strings must follow this.
- **Dynamic Type via `@ScaledMetric` + `kindred*Scaled(size:)` fonts** — all text in `RecipeDetailView.swift` scales with Dynamic Type. The new footer must use the same pattern (`captionSize` scaled metric).
- **Accessibility labels and traits on every interactive element** — existing view applies `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityAddTraits(.isHeader)`. The attribution link must follow this standard.
- **Dark mode via semantic color tokens** — no hex colors; always `.kindredTextPrimary/Secondary/Tertiary` etc. Footer inherits automatically.
- **External URLs in the app** — not yet standardized; planner should pick between `Environment(\.openURL)` and SwiftUI `Link`. Check for any existing `openURL` usage before deciding.

### Integration Points
- **`RecipeDetailView.recipeContentView(_:)`** at `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift:117` — append the compliance footer at the end of the `VStack` (after `StepTimelineView` at line 190).
- **`PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypes` array** at `Kindred/Sources/PrivacyInfo.xcprivacy:19` — add the Search History dict and toggle the Product Interaction dict's `NSPrivacyCollectedDataTypeLinked` from `<false/>` to `<true/>`.
- **`PrivacyInfo.xcprivacy` `NSPrivacyAccessedAPITypes` array** at `Kindred/Sources/PrivacyInfo.xcprivacy:121` — append any missing Required Reason API entries discovered by the audit.
- **`Kindred/fastlane/metadata/review_information/notes.txt`** — append the backend proxy sentence.
- **`Kindred/Sources/Resources/Localizable.xcstrings`** — add two new string keys (disclaimer + attribution).
- **App Store Connect (external, manual):** App Privacy form in App Store Connect must be edited to match the manifest changes. Phase 27 verification flags this as a human checklist item; it cannot be automated from inside the phase.
- **`kindred.app/privacy` (external, manual):** hosted policy site — content update performed by the user from `POLICY-UPDATE.md`.

### Constraints
- **No tests for screenshots or manifest** — verification is visual/manual. Plan the verification step accordingly.
- **Spoonacular is NOT referenced anywhere in the iOS codebase yet** (confirmed via grep). The string "Spoonacular" lands for the first time in `Localizable.xcstrings` via Phase 27.
- **Screenshots are captured manually** — no Snapfile, no UI test target for snapshots. Don't plan around automation.
- **`project.yml` → `INFOPLIST_FILE` points at `Sources/Info.plist`** — if any Info.plist edits are required (none expected in Phase 27), edit `Sources/Info.plist` NOT `Resources/Info.plist`.

</code_context>

<specifics>
## Specific Ideas

- "Spoonacular is a data processor, not a tracker" is the anchor phrase for the whole Privacy Label approach — keep it in the planner's framing and in the policy update copy.
- The disclaimer should feel like a "Source:" footer in a news article or a "Powered by" footer in a search widget — unobtrusive, legal, and clearly distinct from recipe content.
- The policy update should be written in plain language, not legalese — match the existing Kindred voice seen in `fastlane/metadata/en-US/description.txt` ("We're transparent about our AI usage…").
- ElevenLabs bonus disclosure is a deliberate one-touch cleanup: better to name both processors in a single policy revision than to ship two revisions a week apart.
- Review notes addendum is cheap insurance — Apple reviewers get confused when the Privacy Report shows only the backend domain and the policy mentions Spoonacular. One sentence in review notes prevents back-and-forth.

</specifics>

<deferred>
## Deferred Ideas

- **App description copy update** — `fastlane/metadata/en-US/description.txt` and `tr/description.txt` still say "trending local dishes" / "şehrinizdeki popüler trendleri" which is stale after Spoonacular. Handle during Phase 28 release prep or as a dedicated copy pass. Not blocking Phase 27's compliance goal.
- **Full screenshot refresh (all 5 per locale) + marketing text overlays** — dedicated marketing-polish phase. Phase 27 does the compliance-driven minimum.
- **`fastlane snapshot` automation / UI test target for screenshots** — Phase 28 or later release-automation work.
- **In-app "Third Parties" settings surface** listing ElevenLabs + Spoonacular — future transparency phase.
- **Regional / EU-specific Privacy Label variants** — future internationalization phase if/when the app ships beyond en-US + tr.
- **ATT prompt text review** — future pre-submission polish pass.
- **Purchase History → add Analytics purpose** — not needed unless StoreKit events are piped to Firebase as purchase conversion events. Track as a follow-up audit item.
- **Research Firebase user property audit to confirm Product Interaction `Linked = true`** — the decision stands, but the researcher should verify the Firebase Analytics `userId`/`userProperty` wiring during Phase 27 research to make the change well-founded.
- **Versioned privacy policy URL (`/privacy/v2`)** — not needed now; revisit only if policy undergoes frequent major revisions.
- **App Privacy Details JSON file for bulk label sync (fastlane `app_privacy_details_url`)** — Phase 28 release-automation concern.
- **Spoonacular logo badge (in addition to the text link)** — only if App Store review pushes back on text-only attribution. Text link follows Spoonacular's brand guidelines and is usually sufficient.

</deferred>

---

*Phase: 27-app-store-compliance*
*Context gathered: 2026-04-06*
