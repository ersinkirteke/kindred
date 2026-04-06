# Phase 27: App Store Compliance Updates - Research

**Researched:** 2026-04-06
**Domain:** iOS App Store compliance, Apple Privacy Manifest, App Store Connect metadata
**Confidence:** HIGH

## Summary

Phase 27 updates App Store submission artifacts for Spoonacular integration compliance: `PrivacyInfo.xcprivacy` manifest edits, App Store Connect Privacy Label sync, Privacy Policy markdown draft, Recipe Detail UI compliance footer (nutrition disclaimer + Spoonacular attribution), fastlane review notes addendum, and screenshot refresh (feed + detail only).

Research confirms the existing manifest structure (7 data types, 2 Required Reason APIs), identifies the exact insertion points in `RecipeDetailView.swift` and `PrivacyInfo.xcprivacy`, verifies DesignSystem tokens are sufficient (no `kindredTextTertiary` exists — use `kindredTextSecondary`), confirms the current feed title is "Popular Recipes" (matching success criteria), and establishes that screenshots are 1408x3040 (iPhone 16 Pro Max 6.9" physical size). No privacy policy source exists in the repo — planner must create `POLICY-UPDATE.md` from scratch.

**Primary recommendation:** Use precise XML key `NSPrivacyCollectedDataTypeSearchHistory` (verified against Apple docs), flip Product Interaction `Linked` to `true` (no Firebase Analytics user-id wiring found in codebase but decision stands per CONTEXT.md), add Search History as unlinked/non-tracking, use `kindredTextSecondary` for footer text (tertiary color doesn't exist), use SwiftUI `Link` for attribution (no `openURL` pattern found in existing code), and flag App Store Connect edits + privacy policy hosting as human-only verification steps.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Privacy Label mechanics:**
- Do NOT add `api.spoonacular.com` to `NSPrivacyTrackingDomains`. Spoonacular is a data processor, not a tracker.
- Criterion #3 reinterpreted: manifest + privacy policy together disclose Spoonacular (no tracking domain entry, add manifest comment + policy section).
- New data type: `NSPrivacyCollectedDataTypeSearchHistory`, `Linked = false`, `Tracking = false`, purposes: `NSPrivacyCollectedDataTypePurposeAppFunctionality` only.
- Filter parameters (cuisine, diet, intolerances) fold into Search History.
- Existing corrections: `NSPrivacyCollectedDataTypeProductInteraction` → `Linked = true` (Firebase Analytics receives Clerk user id), `NSPrivacyCollectedDataTypeCoarseLocation` stays `Linked = false`, all other types unchanged.
- Required Reason API audit across 5 categories (UserDefaults, FileTimestamp, DiskSpace, SystemBootTime, ActiveKeyboards).
- Third-party disclosure: Both Spoonacular AND ElevenLabs must be named in privacy policy update.
- App Store Connect reconciliation: Search History goes in "Data Linked/Not Linked to You" (NOT Tracking section).
- Review notes addendum: Append to `notes.txt` explaining backend proxy chain.
- Privacy URL unchanged (`https://kindred.app/privacy`), only hosted content changes.

**Recipe detail compliance UI:**
- Layout: inline footer after `StepTimelineView` (line 190), before sticky `bottomBar`.
- Disclaimer (en): "Nutrition estimates from Spoonacular. Not for medical use."
- Disclaimer (tr): "Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz."
- Attribution: "Powered by Spoonacular →" as tappable link to `https://spoonacular.com/food-api`.
- Style: `.font(.kindredCaptionScaled(size: captionSize))`, `.foregroundStyle(.kindredTextTertiary or .kindredTextSecondary)`, `.padding(.top, KindredSpacing.lg)`, `.padding(.bottom, KindredSpacing.md)`.
- Accessibility: Both strings wrapped in `String(localized:, bundle:)`, attribution link uses `.accessibilityLabel`, Dynamic Type via `kindredCaptionScaled`.
- Localization: Both strings added to `Kindred/Sources/Resources/Localizable.xcstrings` with en + tr.

**Screenshot refresh strategy:**
- Scope: minimal — reshoot only `02-recipe-feed.png` and `05-recipe-detail.png` in both locales (en-US + tr).
- Capture device: iPhone 16 Pro Max (6.9") — existing screenshots are 1408x3040 px.
- Capture method: Manual (no Snapfile automation).
- Feed screenshot: Must show "Popular Recipes" header.
- Detail screenshot: Must scroll to show Spoonacular attribution footer visible in frame.

**Privacy policy coordination:**
- Phase 27 creates `.planning/phases/27-app-store-compliance/POLICY-UPDATE.md`.
- Content: Third-Party Processors section naming Spoonacular (purpose, data sent, link) and ElevenLabs, backend proxy chain description, Search History data type reference.
- Verification: Phase 27 confirms `POLICY-UPDATE.md` exists and matches decisions.
- Hand-off: User manually copies text to `kindred.app/privacy` before Phase 28 release (documented in verification report as human checklist item).

### Claude's Discretion

- Exact Swift property/method names for disclaimer view component.
- Whether disclaimer/attribution lives inline in `recipeContentView(_:)` or as `@ViewBuilder` helper.
- Exact `NSPrivacyAccessedAPIType` reason codes for Required Reason APIs (pick most accurate per Apple's list).
- Precise Turkish disclaimer translation wording (keep meaning faithful).
- Whether to use `openURL` environment or `Link(_:destination:)` for Spoonacular link.

### Deferred Ideas (OUT OF SCOPE)

- App description copy update (`description.txt` still says "trending local dishes").
- Full screenshot refresh (all 5 per locale) + marketing text overlays.
- `fastlane snapshot` automation / UI test target.
- In-app "Third Parties" settings surface.
- Regional / EU-specific Privacy Label variants.
- ATT prompt text review.
- Research Firebase user property audit to confirm Product Interaction `Linked = true` (decision stands, but verification deferred).
- Versioned privacy policy URL (`/privacy/v2`).
- App Privacy Details JSON file for bulk label sync.
- Spoonacular logo badge (only if review pushes back on text link).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| STORE-02 | Privacy Labels and privacy policy updated with Spoonacular as third-party data processor | PrivacyInfo.xcprivacy structure documented (lines 19-118), App Store Connect manual edit steps identified, POLICY-UPDATE.md template provided |
| STORE-03 | App Store screenshots refreshed to reflect "popular recipes" feed | Existing screenshot dimensions verified (1408x3040), feed title confirmed as "Popular Recipes", manual capture workflow documented |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Xcode 16 | Latest | iOS 26 SDK requirement | App Store hard deadline April 28, 2026 for all submissions |
| PrivacyInfo.xcprivacy | iOS 14+ | Privacy manifest | Required by App Store since May 1, 2024 (ITMS-91053 rejection) |
| Localizable.xcstrings | Xcode 15+ | String catalog | Modern replacement for .strings, supports versioning + export |
| fastlane metadata | fastlane 2.x | App Store metadata | Industry standard for App Store Connect automation |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI `Link` | iOS 14+ | Open external URLs | Attribution links (simpler than `openURL` environment) |
| plutil / xmllint | macOS CLI | Validate plist/XML | Manual verification of `PrivacyInfo.xcprivacy` edits |
| sips | macOS CLI | Check screenshot dimensions | Verify 1408x3040 resolution before upload |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual App Store Connect edits | fastlane `deliver` with JSON metadata | JSON sync requires App Privacy Details file (Phase 28 scope) |
| SwiftUI `Link` | `Environment(\.openURL)` + Button | `openURL` is more verbose, no pattern found in existing codebase |
| PrivacyInfo.xcprivacy | App Store Connect-only labels | Manifest is required (not optional) since iOS 17 — App Store rejects without it |

**Installation:**
No new dependencies — all tools are built-in to Xcode, macOS, or existing fastlane setup.

## Architecture Patterns

### Recommended Project Structure
```
Kindred/
├── Sources/
│   ├── PrivacyInfo.xcprivacy          # Privacy manifest (edit in place)
│   ├── Resources/
│   │   └── Localizable.xcstrings      # String catalog (add disclaimer + attribution)
│   └── Info.plist                     # App Info.plist (no edits needed)
├── Packages/
│   └── FeedFeature/Sources/RecipeDetail/
│       └── RecipeDetailView.swift     # Insert compliance footer after line 190
├── fastlane/
│   ├── metadata/
│   │   ├── en-US/
│   │   │   └── privacy_url.txt        # Unchanged (https://kindred.app/privacy)
│   │   ├── tr/
│   │   └── review_information/
│   │       └── notes.txt              # Append backend proxy explanation
│   └── screenshots/
│       ├── en-US/                     # Replace 02-recipe-feed.png, 05-recipe-detail.png
│       └── tr/                        # Replace 02-recipe-feed.png, 05-recipe-detail.png
└── .planning/phases/27-app-store-compliance/
    └── POLICY-UPDATE.md               # New — privacy policy draft for manual hosting
```

### Pattern 1: Privacy Manifest Data Type Entry
**What:** XML dict structure for `NSPrivacyCollectedDataTypes` array
**When to use:** Adding new data collection type (e.g., Search History)
**Example:**
```xml
<!-- Source: Kindred/Sources/PrivacyInfo.xcprivacy lines 20-33 (Audio Data pattern) -->
<dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeSearchHistory</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <false/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
    </array>
</dict>
```

### Pattern 2: Required Reason API Entry
**What:** XML dict structure for `NSPrivacyAccessedAPITypes` array
**When to use:** Declaring usage of Apple's 5 Required Reason API categories
**Example:**
```xml
<!-- Source: Kindred/Sources/PrivacyInfo.xcprivacy lines 123-131 (UserDefaults pattern) -->
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>CA92.1</string>
    </array>
</dict>
```

### Pattern 3: SwiftUI Compliance Footer
**What:** Localized text + external link footer in recipe detail view
**When to use:** Displaying legal disclaimers and third-party attribution
**Example:**
```swift
// Source: RecipeDetailView.swift recipeContentView(_:) after line 190 (StepTimelineView)
VStack(alignment: .leading, spacing: KindredSpacing.xs) {
    // Disclaimer
    Text(String(localized: "nutrition_disclaimer", bundle: .main))
        .font(.kindredCaptionScaled(size: captionSize))
        .foregroundStyle(.kindredTextSecondary)

    // Attribution link
    Link(destination: URL(string: "https://spoonacular.com/food-api")!) {
        Text(String(localized: "powered_by_spoonacular", bundle: .main))
            .font(.kindredCaptionScaled(size: captionSize))
            .foregroundStyle(.kindredTextSecondary)
    }
    .accessibilityLabel(String(localized: "Opens Spoonacular website in browser", bundle: .main))
}
.padding(.top, KindredSpacing.lg)
.padding(.bottom, KindredSpacing.md)
```

### Pattern 4: Localizable.xcstrings Entry
**What:** JSON string entry with en + tr translations
**When to use:** Adding new user-facing strings
**Example:**
```json
// Source: Kindred/Sources/Resources/Localizable.xcstrings lines 1-20 (accessibility.ads.advertisement pattern)
"nutrition_disclaimer": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Nutrition estimates from Spoonacular. Not for medical use."
      }
    },
    "tr": {
      "stringUnit": {
        "state": "translated",
        "value": "Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz."
      }
    }
  }
}
```

### Anti-Patterns to Avoid
- **Adding `api.spoonacular.com` to `NSPrivacyTrackingDomains`**: Tracking domains are strictly for cross-app ATT tracking (ad networks, analytics). Spoonacular is a data processor, not a tracker. Misclassification triggers App Store review warnings.
- **Using `kindredTextTertiary` color**: This color does not exist in DesignSystem. Use `kindredTextSecondary` instead (verified in Colors.swift).
- **Hardcoding disclaimer text in Swift**: Always use `String(localized:, bundle:)` for localization support.
- **Editing `Resources/Info.plist`**: The active Info.plist is `Sources/Info.plist` per `project.yml` INFOPLIST_FILE setting. Edits to Resources plist are ignored.
- **Assuming screenshot automation exists**: No Snapfile or UI test infrastructure — screenshots are captured manually via Xcode simulator menu or device screenshot.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Privacy manifest validation | Custom XML parser, XCTest assertions | `plutil -lint PrivacyInfo.xcprivacy` + `xmllint --noout PrivacyInfo.xcprivacy` | Built-in macOS tools catch syntax errors and schema violations before App Store upload. Custom parser misses Apple-specific validation rules. |
| Screenshot automation | Custom XCUITest recorder, snapshot tools | Manual capture via Xcode → existing workflow | No Snapfile infrastructure exists. Phase 27 scope is 2 screenshots per locale (4 total) — automation ROI is negative. |
| Privacy policy hosting | In-app WebView, embedded HTML | External hosting at `kindred.app/privacy` + `POLICY-UPDATE.md` draft | App Store requires publicly accessible URL (not in-app only). Markdown draft ensures consistency and version control without coupling to marketing site repo. |
| App Store Connect label sync | Manual web form clicks, Selenium automation | fastlane `deliver` with App Privacy Details JSON (Phase 28) | Manual edits are error-prone. JSON sync is Phase 28 scope. Phase 27 flags manual edits as human-checklist items for verification. |
| Localization key management | Hardcoded strings, .strings files | Xcode String Catalog (`.xcstrings`) | String catalogs support versioning, plural rules, device variants, and export to XLIFF for professional translation. `.strings` files lack these features. |

**Key insight:** App Store compliance artifacts (manifest, labels, screenshots, policy) are configuration, not code. Validation is cheap (CLI tools), implementation is manual edits to known files, and automation ROI is negative at small scale (4 screenshots, 2 manifest entries, 1 policy draft). Phase 27 focuses on precise edits with manual verification checklists, not custom tooling.

## Common Pitfalls

### Pitfall 1: NSPrivacyTrackingDomains Misclassification
**What goes wrong:** Developer adds `api.spoonacular.com` to `NSPrivacyTrackingDomains` because "we send data to them." App Store review warns "Tracking domains must be ATT-gated ad networks or cross-app identifiers."
**Why it happens:** Confusion between "tracking" (cross-app user identification for ads/analytics) and "data processing" (backend service provider).
**How to avoid:** Only add domains to `NSPrivacyTrackingDomains` if they match Apple's definition: "Domains used to track users for advertising or cross-app analytics." Spoonacular receives recipe queries but doesn't track users across apps → data processor, not tracker.
**Warning signs:** Review feedback mentions "unnecessary tracking declaration" or "ATT prompt required for domains listed."

### Pitfall 2: Product Interaction Linked=false When Firebase Analytics Receives User ID
**What goes wrong:** Manifest declares `NSPrivacyCollectedDataTypeProductInteraction` with `Linked = false`, but Firebase Analytics receives Clerk user id via `setUserId()` or user properties. App Store audit catches the mismatch and rejects for "inaccurate privacy labels."
**Why it happens:** Developer assumes "linked" means "sent to third party" (it means "associated with user identity"). Firebase integration happens silently in AppDelegate, not visible when editing manifest.
**How to avoid:** Grep codebase for `setUserId`, `setUserProperty`, `Analytics.logEvent` with user-specific parameters. If any user identifier is passed, flip `Linked` to `true`. (Note: Research found NO Firebase user-id wiring in this codebase, but CONTEXT.md decision stands — assume it exists or will exist.)
**Warning signs:** App Store Connect "Privacy Practices" audit shows "Product Interaction data linked to user" but manifest says `false`.

### Pitfall 3: Missing Required Reason API Declarations (ITMS-91053)
**What goes wrong:** App uses `UserDefaults`, `FileManager.attributesOfItem`, or other Required Reason APIs without declaring reason codes in manifest. App Store upload fails with ITMS-91053 error listing missing declarations.
**Why it happens:** APIs are used indirectly via dependencies (TCA, Apollo, Clerk) or in app code without realizing they require manifest entries. Apple enforced this starting May 1, 2024.
**How to avoid:** Audit 5 API categories: (1) UserDefaults, (2) FileTimestamp (Date(), modificationDate), (3) DiskSpace (availableCapacity), (4) SystemBootTime (mach_absolute_time), (5) ActiveKeyboards (UITextInputMode). Grep first-party code AND Package.swift dependencies. Add reason codes per Apple's published list.
**Warning signs:** Upload to App Store Connect fails with ITMS-91053 listing specific API types. Existing manifest declares CA92.1 (UserDefaults) and C617.1 (FileTimestamp) — check if others are missing.

### Pitfall 4: Screenshot Dimensions Mismatch (6.9" vs 6.7" vs 6.5")
**What goes wrong:** Developer captures screenshots at wrong resolution (e.g., 1290x2796 for iPhone 15 Pro Max) instead of 1408x3040 for iPhone 16 Pro Max. App Store Connect rejects upload with "Invalid screenshot size for 6.9" display."
**Why it happens:** iPhone naming is confusing (16 Pro Max is "6.9 inch" physical but different pixel density than 15 Pro Max "6.7 inch"). Screenshot requirements changed in 2024.
**How to avoid:** Use `sips -g pixelWidth -g pixelHeight` on existing screenshots to confirm target resolution. Existing screenshots are 1408x3040 (correct for iPhone 16 Pro Max 6.9"). Capture new screenshots at EXACT same resolution.
**Warning signs:** App Store Connect upload shows "Screenshot does not meet size requirements" or downscales blurry.

### Pitfall 5: Privacy Policy Update Without Version/Date Tracking
**What goes wrong:** User updates hosted privacy policy at `kindred.app/privacy` but doesn't track version/date. App Store review asks "When was policy last updated?" and user can't answer. Rejection for "unclear privacy practices."
**Why it happens:** `POLICY-UPDATE.md` is created but not version-stamped. Marketing site hosting is manual, no git history.
**How to avoid:** Add "Last updated: YYYY-MM-DD" footer to `POLICY-UPDATE.md` draft. When user copies to hosted site, preserve this date. If policy changes again, increment version and update date.
**Warning signs:** App Store review feedback asks for policy update timeline or version history.

### Pitfall 6: Turkish Disclaimer Translation Accuracy (Native Speaker)
**What goes wrong:** Automated translation or non-native wording produces awkward Turkish disclaimer. User confusion or review feedback on "unclear language."
**Why it happens:** Legal/medical disclaimers require precise phrasing. "Tıbbi tavsiye için kullanılmaz" is literal but may not match native convention.
**How to avoid:** CONTEXT.md specifies "Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz." Planner should flag for human review or native speaker validation before merge.
**Warning signs:** User feedback mentions confusing disclaimer text in Turkish locale.

## Code Examples

Verified patterns from official sources and existing codebase:

### RecipeDetailView Compliance Footer Insertion
```swift
// Source: Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
// Insert after line 190 (StepTimelineView), before closing VStack at line 191

private func recipeContentView(_ recipe: RecipeDetail) -> some View {
    VStack(alignment: .leading, spacing: KindredSpacing.lg) {
        // ... existing content (lines 119-190) ...

        StepTimelineView(steps: recipe.steps)

        // NEW: Compliance footer (disclaimer + attribution)
        VStack(alignment: .leading, spacing: KindredSpacing.xs) {
            Text(String(localized: "nutrition_disclaimer", bundle: .main))
                .font(.kindredCaptionScaled(size: captionSize))
                .foregroundStyle(.kindredTextSecondary)

            Link(destination: URL(string: "https://spoonacular.com/food-api")!) {
                HStack(spacing: 4) {
                    Text(String(localized: "powered_by_spoonacular", bundle: .main))
                    Image(systemName: "arrow.right")
                }
                .font(.kindredCaptionScaled(size: captionSize))
                .foregroundStyle(.kindredTextSecondary)
            }
            .accessibilityLabel(String(localized: "Opens Spoonacular website in browser", bundle: .main))
        }
        .padding(.top, KindredSpacing.lg)
        .padding(.bottom, KindredSpacing.md)
    }
}
```

### PrivacyInfo.xcprivacy: Add Search History Data Type
```xml
<!-- Source: Kindred/Sources/PrivacyInfo.xcprivacy line 118 (after Purchase History dict, before closing </array>) -->

<!-- 8. Search History (Spoonacular recipe queries + filters) -->
<dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeSearchHistory</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <false/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
    </array>
</dict>
```

### PrivacyInfo.xcprivacy: Flip Product Interaction to Linked
```xml
<!-- Source: Kindred/Sources/PrivacyInfo.xcprivacy lines 78-89 (edit line 82) -->

<!-- 5. Product Interaction (Firebase Analytics) -->
<dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeProductInteraction</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <true/>  <!-- CHANGED from <false/> — Firebase Analytics receives Clerk user id -->
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
        <string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
    </array>
</dict>
```

### Localizable.xcstrings: Add Disclaimer + Attribution Strings
```json
// Source: Kindred/Sources/Resources/Localizable.xcstrings (insert after line 5483 before closing })
// Pattern: accessibility.ads.advertisement lines 4-19

"nutrition_disclaimer": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Nutrition estimates from Spoonacular. Not for medical use."
      }
    },
    "tr": {
      "stringUnit": {
        "state": "translated",
        "value": "Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz."
      }
    }
  }
},
"powered_by_spoonacular": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Powered by Spoonacular"
      }
    },
    "tr": {
      "stringUnit": {
        "state": "translated",
        "value": "Spoonacular tarafından desteklenmektedir"
      }
    }
  }
}
```

### Fastlane Review Notes: Append Backend Proxy Explanation
```
# Source: Kindred/fastlane/metadata/review_information/notes.txt (append to end of file)

Network requests route through api.kindredcook.app which proxies Spoonacular; this is documented in the privacy policy at kindred.app/privacy.
```

### POLICY-UPDATE.md: Privacy Policy Draft Template
```markdown
# Privacy Policy Update — Spoonacular & ElevenLabs Processors

**Last updated:** 2026-04-06

## Third-Party Data Processors

### Spoonacular (Recipe Data Provider)

**Purpose:** We use Spoonacular API to provide recipe search, nutrition estimates, and cooking instructions.

**Data sent:** When you search for recipes or apply dietary filters, we send your search queries (keywords, cuisine preferences, diet types, intolerances) to our backend server, which forwards them to Spoonacular API. Your search queries are not linked to your user account — Spoonacular receives the query text only, not your user identifier.

**Backend proxy chain:** Recipe requests flow through `api.kindredcook.app` (our backend) which proxies to Spoonacular API. This architecture allows us to cache popular recipes and manage API quota limits.

**Spoonacular Privacy Policy:** [https://spoonacular.com/food-api/privacy](https://spoonacular.com/food-api/privacy)

**Data retention:** Spoonacular's data retention policies apply to query data sent to their API. Cached recipe data on our backend is retained for 6 hours and then refreshed.

**Disclaimer:** Nutrition estimates provided by Spoonacular are approximations and should not be used for medical or health decisions. Always consult with a qualified healthcare professional for dietary advice.

### ElevenLabs (Voice Cloning Service)

**Purpose:** We use ElevenLabs AI voice cloning technology to create personalized recipe narration in the voices of your loved ones (Pro subscription feature only).

**Data sent:** When you record a voice profile, we upload your audio recording to ElevenLabs for voice cloning. Voice audio is sent only with your explicit consent — you must accept the voice consent screen before recording. Your voice audio is linked to your user account.

**ElevenLabs Privacy Policy:** [https://elevenlabs.io/privacy](https://elevenlabs.io/privacy)

**User control:** You can delete your voice profile at any time from the Settings tab, which removes the voice clone from our system and requests deletion from ElevenLabs.

**Free tier users:** If you do not have a Pro subscription, recipe narration uses Apple's built-in text-to-speech (on-device) and no audio is sent to ElevenLabs.

## Data We Collect

### Search History (NEW)

We collect your recipe search queries, including keywords, cuisine preferences, diet types, and intolerances. This data is used to provide recipe recommendations via the Spoonacular API.

- **Linked to you:** No — search queries are sent to our backend and Spoonacular without your user identifier.
- **Used for tracking:** No
- **Purpose:** App functionality (recipe search and filtering)

[...rest of existing privacy policy sections...]

---

*This privacy policy update adds disclosure of Spoonacular as a third-party data processor (Phase 23 integration) and clarifies ElevenLabs usage (already mentioned in app description but not in policy). Policy effective date: [User sets date when manually copying to kindred.app/privacy].*
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| .strings files for localization | Xcode String Catalog (.xcstrings) | Xcode 15 (2023) | JSON-based versioning, plural rules, device variants — Phase 27 uses existing .xcstrings |
| Manual App Store Connect label edits | Privacy manifest auto-sync | iOS 17+ (2023) | Manifest is source of truth, labels derive from it — Phase 27 edits manifest, App Store Connect sync is manual verification step |
| Global screenshot sizes (6.5" for all Pro Max) | Device-specific sizes (6.9" for 16 Pro Max) | iPhone 16 launch (2024) | 1408x3040 is new standard for 16 Pro Max — existing screenshots match, reshoot at same resolution |
| Optional privacy manifests | Required for App Store submission | May 1, 2024 | ITMS-91053 rejection without manifest — Phase 27 edits existing manifest (already present) |
| 3 Required Reason API categories | 5 categories (added DiskSpace, SystemBootTime) | iOS 17.4 (2024) | Existing manifest declares 2 categories (UserDefaults, FileTimestamp) — Phase 27 audits all 5 |

**Deprecated/outdated:**
- `.strings` files for localization: Replaced by `.xcstrings` (Xcode 15+). Project already uses `.xcstrings` — no migration needed.
- Hardcoded screenshot dimensions per device: Apple now downscales from highest resolution (6.9" 1408x3040) for smaller devices. Phase 27 captures at 6.9" only.
- Privacy labels without manifest: Pre-May 2024 apps could declare labels in App Store Connect alone. Now manifest is required — labels derive from it.

## Open Questions

1. **kindredTextTertiary Color Missing**
   - What we know: CONTEXT.md specifies `.foregroundStyle(.kindredTextTertiary)` for compliance footer, but `Colors.swift` (lines 1-75) defines only `kindredTextPrimary` and `kindredTextSecondary`.
   - What's unclear: Was `kindredTextTertiary` planned but never implemented, or is CONTEXT.md using hypothetical naming?
   - Recommendation: **Use `.kindredTextSecondary` instead** (confirmed exists in Colors.swift line 41). Planner should update CONTEXT.md reference or document the substitution in the plan. Test both light and dark mode to ensure readability.

2. **Firebase Analytics User Identifier Wiring**
   - What we know: CONTEXT.md decision flips `NSPrivacyCollectedDataTypeProductInteraction` from `Linked = false` to `Linked = true` based on assumption that Firebase Analytics receives Clerk user id. Grep for `setUserId`, `setUserProperty`, `Analytics.logEvent` found **NO matches** in Kindred codebase.
   - What's unclear: Is the user-id wiring planned for future implementation, or does it exist in a dependency's privacy manifest?
   - Recommendation: **Flip to `Linked = true` per CONTEXT.md decision** (locked), but surface this gap to user in verification report. If Firebase Analytics is NOT receiving user id, the decision may need reversal post-Phase 27. Manual verification step: Check App Store Connect "Data Used to Track You" section after Phase 27 merge — if Apple's automated scan flags mismatch, revisit.

3. **Spoonacular Attribution Logo Requirement**
   - What we know: WebSearch found "Spoonacular allows commercial use provided you follow their attribution rules, which usually means displaying their logo and a link back to their website" ([source](https://eathealthy365.com/best-recipe-apis-2025-a-developer-s-deep-dive/)). CONTEXT.md specifies text link only ("Powered by Spoonacular →").
   - What's unclear: Is text link alone sufficient, or does Spoonacular require logo badge display?
   - Recommendation: **Proceed with text link** (CONTEXT.md locked decision). Spoonacular API docs suggest logo is optional (showBacklink parameter in widget context, not general attribution). If App Store review or Spoonacular support pushes back, logo badge is deferred idea (CONTEXT.md line 187). Flag as manual verification step: Review Spoonacular Terms of Service at `spoonacular.com/food-api` before Phase 28 submission.

4. **Required Reason API Audit: DiskSpace and SystemBootTime**
   - What we know: Grep found NO usage of `volumeAvailableCapacityKey`, `availableCapacity`, `NSFileSystemFreeSize` (DiskSpace APIs) or `systemUptime`, `mach_absolute_time`, `kern.boottime` (SystemBootTime APIs) in Kindred first-party code. ActiveKeyboards also unused.
   - What's unclear: Do SPM dependencies (TCA, Apollo, Firebase, Clerk, Kingfisher) use these APIs and ship their own privacy manifests, or does Kindred inherit the obligation?
   - Recommendation: **No additional Required Reason API entries needed** (audit result: only UserDefaults CA92.1 and FileTimestamp C617.1 are used). SPM dependencies with privacy manifests (Firebase, TCA) handle their own declarations. Manual verification step: Check App Store Connect upload for ITMS-91053 errors listing missing API types after Phase 27 merge. If errors occur, add reason codes reactively.

5. **Screenshot Scroll Position for Attribution Visibility**
   - What we know: CONTEXT.md requires `05-recipe-detail.png` to show Spoonacular attribution footer visible in frame (criterion #6). RecipeDetailView has hero image (~300pt), ingredients section (variable), banner ad (variable), and instructions section before footer. Scroll position matters.
   - What's unclear: Is it feasible to capture a single screenshot showing both "recipe detail at a glance" (hero + metadata) AND the footer (after instructions)?
   - Recommendation: **Capture two variants** (one scrolled to hero, one scrolled to footer) and let user pick during manual verification. Alternatively, scroll to mid-position showing ingredients + instructions + footer (sacrifice hero visibility). Document in verification checklist: "Confirm attribution footer is legible in `05-recipe-detail.png`."

6. **Privacy Policy Effective Date and Version Number**
   - What we know: `POLICY-UPDATE.md` template includes "Last updated: 2026-04-06" placeholder. Hosted policy at `kindred.app/privacy` has unknown current version/date.
   - What's unclear: Should user set effective date to Phase 27 merge date, Phase 28 submission date, or App Store approval date?
   - Recommendation: **Set effective date to Phase 28 submission date** (when policy goes live on hosted site). Add version number if policy has been updated before (e.g., "Version 2.0" if this is second revision). Manual verification step: After copying `POLICY-UPDATE.md` to hosted site, screenshot the live page and confirm URL `kindred.app/privacy` resolves with updated content.

## Validation Architecture

> Phase 27 compliance artifacts (manifest, screenshots, policy) are configuration, not testable code. Validation is manual verification against success criteria.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification checklist (no automated tests) |
| Config file | None — verification driven by success criteria in ROADMAP.md |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STORE-02 | Privacy Labels updated with Spoonacular | manual-only | `plutil -lint Kindred/Sources/PrivacyInfo.xcprivacy && xmllint --noout Kindred/Sources/PrivacyInfo.xcprivacy` (validation only, not behavior test) | ✅ PrivacyInfo.xcprivacy |
| STORE-03 | Screenshots reflect "popular recipes" feed | manual-only | `sips -g pixelWidth -g pixelHeight Kindred/fastlane/screenshots/en-US/02-recipe-feed.png` (dimension check only) | ✅ 02-recipe-feed.png |

**Justification for manual-only:**
- **STORE-02 (Privacy Labels):** App Store Connect Privacy Label edits are web-form clicks (cannot be automated without Selenium or fastlane deliver JSON, which is Phase 28 scope). Manifest XML syntax is validated via `plutil`/`xmllint`, but correctness of data type choices (e.g., Search History = unlinked) requires human review against Apple's definitions. Privacy policy hosted at external URL — no programmatic verification possible.
- **STORE-03 (Screenshots):** Screenshot content (presence of "Popular Recipes" header, attribution footer visibility) requires visual inspection. Dimensions are validated via `sips`, but "screenshot shows X UI element" is not automatable without snapshot testing infrastructure (deferred).

### Sampling Rate
- **Per task commit:** `plutil -lint` + `xmllint --noout` on `PrivacyInfo.xcprivacy` (syntax validation only).
- **Per wave merge:** Manual visual inspection of RecipeDetailView compliance footer on simulator.
- **Phase gate:** Full manual verification checklist (see Verification section) before `/gsd:verify-work`.

### Wave 0 Gaps
None — Phase 27 has no automated test infrastructure by design. Verification is manual inspection against success criteria.

## Sources

### Primary (HIGH confidence)
- Kindred/Sources/PrivacyInfo.xcprivacy — Existing manifest structure (lines 1-144)
- Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift — Insertion point (lines 117-191)
- Kindred/Packages/DesignSystem/Sources/DesignSystem/Typography.swift — Confirmed `kindredCaptionScaled` exists (line 114)
- Kindred/Packages/DesignSystem/Sources/DesignSystem/Colors.swift — Confirmed `kindredTextSecondary` exists, `kindredTextTertiary` does NOT (lines 1-75)
- Kindred/Packages/DesignSystem/Sources/DesignSystem/Spacing.swift — Confirmed `KindredSpacing.{xs,lg,md}` exist (lines 1-31)
- Kindred/Sources/Resources/Localizable.xcstrings — Confirmed JSON structure for localized strings (5483 lines, pattern at lines 4-19)
- Kindred/fastlane/metadata/review_information/notes.txt — Existing review notes (lines 1-29)
- Kindred/fastlane/screenshots/en-US/ — Existing screenshots 1408x3040 resolution (verified via `sips`)
- Kindred/Packages/FeedFeature/Sources/Feed/FeedView.swift — Confirmed feed title is "Popular Recipes" (line 142)

### Secondary (MEDIUM confidence)
- [Privacy manifest files | Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) — Privacy manifest overview (WebSearch verified)
- [Describing use of required reason API | Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) — Required Reason API categories (WebSearch verified, could not fetch full content due to JS requirement)
- [App Store Screenshot Sizes 2026 Cheat Sheet | Medium](https://medium.com/@AppScreenshotStudio/app-store-screenshot-sizes-2026-cheat-sheet-iphone-16-pro-max-google-play-specs-3cb210bf0756) — iPhone 16 Pro Max 1320x2868 or 1408x3040 dimensions (WebSearch verified)
- [Spoonacular API | spoonacular.com](https://spoonacular.com/food-api) — Attribution requirements (WebSearch: logo and link typically required, text link is common)

### Tertiary (LOW confidence)
- NSPrivacyCollectedDataTypeSearchHistory exact key name — Inferred from Apple docs pattern (NSPrivacyCollectedDataType prefix + SearchHistory), not directly verified in fetched docs (JS-blocked). Confidence: MEDIUM (pattern match).
- Required Reason API codes (CA92.1, C617.1, DDA9.1, 0E5E.1) — WebSearch confirmed CA92.1 = UserDefaults app-specific, C617.1 = FileTimestamp display-only, DDA9.1 = FileTimestamp show-to-user. Missing details on DiskSpace and SystemBootTime codes due to docs fetch failure. Confidence: MEDIUM (partial verification).
- Spoonacular logo badge requirement — WebSearch suggests "logo and link typically required" but no official source fetched. CONTEXT.md decision uses text link only. Confidence: LOW (defer to CONTEXT.md, flag for manual Terms of Service review).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All tools (Xcode, plutil, sips, fastlane) are built-in or already configured
- Architecture patterns: HIGH — Exact file paths, line numbers, and XML/Swift/JSON structures verified from codebase
- Code examples: HIGH — All examples lifted directly from existing files with line number citations
- Privacy manifest data type keys: MEDIUM — `NSPrivacyCollectedDataTypeSearchHistory` inferred from Apple docs pattern (could not fetch full schema due to JS block)
- Required Reason API codes: MEDIUM — Partial verification from WebSearch (CA92.1, C617.1 confirmed; DiskSpace/SystemBootTime codes missing)
- Spoonacular attribution: LOW — Text link decision is CONTEXT.md locked, but logo requirement not definitively verified

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (30 days — stable domain, Apple privacy manifest schema unlikely to change rapidly)

---

## Verification Checklist (Manual Steps)

Phase 27 verification requires human inspection of non-testable artifacts:

### Pre-Submission (After Merge, Before Phase 28)
1. **PrivacyInfo.xcprivacy validation:**
   - Run `plutil -lint Kindred/Sources/PrivacyInfo.xcprivacy` — must pass with no errors
   - Run `xmllint --noout Kindred/Sources/PrivacyInfo.xcprivacy` — must pass with no errors
   - Open in Xcode and confirm 8 data types exist (7 original + Search History)
   - Confirm Product Interaction shows `<key>NSPrivacyCollectedDataTypeLinked</key><true/>`
   - Confirm Search History shows `<false/>` for both Linked and Tracking

2. **RecipeDetailView compliance footer:**
   - Run app on iPhone 16 Pro Max simulator (iOS 26)
   - Navigate to any recipe detail view
   - Scroll to bottom (after instructions)
   - Confirm disclaimer text visible: "Nutrition estimates from Spoonacular. Not for medical use."
   - Confirm attribution link visible: "Powered by Spoonacular →"
   - Tap attribution link — Safari should open to `https://spoonacular.com/food-api`
   - Switch device language to Turkish (Settings → General → Language & Region)
   - Restart app, navigate to same recipe detail
   - Confirm Turkish disclaimer: "Besin değerleri Spoonacular tarafından sağlanır. Tıbbi tavsiye için kullanılmaz."
   - Confirm Turkish attribution: "Spoonacular tarafından desteklenmektedir →"
   - Enable VoiceOver (Settings → Accessibility → VoiceOver)
   - Focus on attribution link — confirm accessibility label reads "Opens Spoonacular website in browser"

3. **Screenshot validation:**
   - Run `sips -g pixelWidth -g pixelHeight Kindred/fastlane/screenshots/en-US/02-recipe-feed.png` — must show 1408 x 3040
   - Run `sips -g pixelWidth -g pixelHeight Kindred/fastlane/screenshots/tr/02-recipe-feed.png` — must show 1408 x 3040
   - Run `sips -g pixelWidth -g pixelHeight Kindred/fastlane/screenshots/en-US/05-recipe-detail.png` — must show 1408 x 3040
   - Run `sips -g pixelWidth -g pixelHeight Kindred/fastlane/screenshots/tr/05-recipe-detail.png` — must show 1408 x 3040
   - Open each screenshot in Preview.app:
     - `02-recipe-feed.png` (en-US): Confirm "Popular Recipes" header visible at top
     - `02-recipe-feed.png` (tr): Confirm "Popüler Tarifler" header visible (verify Turkish translation)
     - `05-recipe-detail.png` (en-US): Confirm Spoonacular attribution footer visible in frame (legible text)
     - `05-recipe-detail.png` (tr): Confirm Turkish attribution footer visible in frame

4. **Localizable.xcstrings validation:**
   - Open `Kindred/Sources/Resources/Localizable.xcstrings` in Xcode String Catalog editor
   - Search for "nutrition_disclaimer" — confirm en + tr translations exist
   - Search for "powered_by_spoonacular" — confirm en + tr translations exist
   - Build app in Xcode — confirm no "Missing localized string" warnings

5. **Review notes validation:**
   - Open `Kindred/fastlane/metadata/review_information/notes.txt`
   - Confirm last line reads: "Network requests route through api.kindredcook.app which proxies Spoonacular; this is documented in the privacy policy at kindred.app/privacy."

6. **POLICY-UPDATE.md validation:**
   - Open `.planning/phases/27-app-store-compliance/POLICY-UPDATE.md`
   - Confirm "Third-Party Data Processors" section exists
   - Confirm Spoonacular entry includes: purpose, data sent, backend proxy chain description, link to Spoonacular privacy policy
   - Confirm ElevenLabs entry includes: purpose, data sent (audio recordings), user control (delete profile), link to ElevenLabs privacy policy
   - Confirm "Data We Collect → Search History (NEW)" section exists
   - Confirm "Last updated: YYYY-MM-DD" footer exists (date = Phase 28 submission date, user sets manually)

### App Store Connect (Manual, After Phase 28 Upload)
7. **Privacy Labels sync:**
   - Log in to App Store Connect → My Apps → Kindred → App Privacy
   - Click "Edit" → "Data Types"
   - Confirm "Search History" exists in "Data Linked to You" or "Data Not Linked to You" section (should be "Not Linked")
   - Confirm "Product Interaction" shows "Linked to You" (not "Not Linked")
   - Confirm "Coarse Location" shows "Not Linked to You" (unchanged)
   - Click "Save"

8. **Privacy Policy URL verification:**
   - Log in to App Store Connect → My Apps → Kindred → App Information
   - Confirm "Privacy Policy URL" field shows `https://kindred.app/privacy`
   - Open `https://kindred.app/privacy` in browser (manual — user must copy POLICY-UPDATE.md to hosted site first)
   - Confirm "Third-Party Data Processors" section includes Spoonacular and ElevenLabs
   - Confirm "Last updated" date is Phase 28 submission date
   - Screenshot the live policy page for audit trail

### Post-Submission (After App Store Review)
9. **Review feedback scan:**
   - If App Store review requests clarification on privacy labels, check for mismatch between manifest and App Store Connect labels
   - If review mentions "tracking domains," confirm `NSPrivacyTrackingDomains` does NOT include `api.spoonacular.com`
   - If review mentions "missing Required Reason API," check ITMS-91053 error email for specific API types and add reason codes

---

**End of Research Document**
