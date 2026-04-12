---
phase: 27-app-store-compliance
plan: 03
subsystem: compliance
tags: [privacy-policy, app-store-review, third-party-disclosure, documentation]
dependency_graph:
  requires: [27-RESEARCH, 27-CONTEXT]
  provides: [privacy-policy-draft, review-notes-disclosure]
  affects: [phase-28-submission]
tech_stack:
  added: []
  patterns: [markdown-documentation, external-hosting-prep]
key_files:
  created:
    - .planning/phases/27-app-store-compliance/POLICY-UPDATE.md
  modified:
    - Kindred/fastlane/metadata/review_information/notes.txt
decisions:
  - Plain-language policy voice matching "transparent about our AI usage" tone from app description
  - Version 2.0 policy includes Spoonacular, ElevenLabs, and Search History disclosures
  - Backend proxy chain documented to prevent reviewer confusion with iOS 17+ Privacy Report
  - Contact email and effective date left as placeholders for user to set during manual hosting
metrics:
  duration_minutes: 1
  tasks_completed: 2
  files_created: 1
  files_modified: 1
  commits: 2
  completed_date: "2026-04-06"
---

# Phase 27 Plan 03: External Privacy Documents Summary

**One-liner:** Privacy policy draft with Spoonacular/ElevenLabs disclosures and backend proxy explanation for App Store reviewers

---

## What Was Built

Created two external-facing compliance documents for App Store submission:

1. **POLICY-UPDATE.md** — Full privacy policy draft (v2.0) ready for manual hosting at `kindred.app/privacy`
2. **Review notes addendum** — One-sentence backend proxy disclosure appended to fastlane review notes

---

## Key Changes

### 1. Privacy Policy Draft (POLICY-UPDATE.md)

**Location:** `.planning/phases/27-app-store-compliance/POLICY-UPDATE.md`

**Sections created:**
- Summary of Changes in This Update (5 changes documented)
- Third-Party Data Processors
  - Spoonacular (purpose, data sent, backend proxy chain, retention, privacy policy link, nutrition disclaimer)
  - ElevenLabs (purpose, data sent, user control, privacy policy link, free-tier note)
- Data We Collect
  - Search History (NEW) — query keywords and filters, not linked, not tracked, app functionality only
  - Other Data Types (8 existing types listed)
- Contact (placeholder for user to set email)

**Key content:**
- **Backend proxy chain description:** `Your device → api.kindredcook.app (our backend) → Spoonacular API`
- **Spoonacular privacy policy link:** https://spoonacular.com/food-api/privacy
- **ElevenLabs privacy policy link:** https://elevenlabs.io/privacy
- **Nutrition disclaimer:** Estimates suitable for general meal planning, not intended for medical/therapeutic/diagnostic use
- **Search History disclosure:** Query text sent to backend, proxied to Spoonacular without user identifier

**Placeholders for user:**
- `[USER SETS THIS when copying to hosted site — recommended: Phase 28 submission date]` (Effective date)
- `[USER SETS CONTACT EMAIL]` (Contact section)

**Voice/tone:** Plain language matching Kindred's "transparent about our AI usage" app description tone (not legalese)

### 2. Fastlane Review Notes Update

**File:** `Kindred/fastlane/metadata/review_information/notes.txt`

**Appended section:**
```
BACKEND PROXY DISCLOSURE

Network requests route through api.kindredcook.app which proxies Spoonacular; this is documented in the privacy policy at kindred.app/privacy.
```

**Why this matters:**
- iOS 17+ Privacy Report shows reviewers only `api.kindredcook.app` in network traffic
- App Privacy Label and privacy policy name Spoonacular as third-party processor
- One-sentence disclosure prevents reviewer confusion and potential rejection for "mismatch"

**Existing sections preserved:**
- APP DESCRIPTION
- AI TECHNOLOGY DISCLOSURE
- DEMO ACCOUNT CREDENTIALS
- KEY FEATURES TO TEST
- AGE RATING
- EXPORT COMPLIANCE
- SUBMISSION NOTES

---

## Deviations from Plan

None — plan executed exactly as written.

---

## MANUAL STEP REQUIRED

**CRITICAL:** Before running Phase 28 (`fastlane release`), the user MUST:

1. **Copy POLICY-UPDATE.md content to hosted site:**
   - Navigate to the marketing site admin panel at `kindred.app`
   - Paste the full privacy policy text from POLICY-UPDATE.md into the `/privacy` page editor
   - Set the Effective date placeholder to the Phase 28 submission date (e.g., `April 6, 2026`)
   - Set the contact email placeholder to the Kindred support email (e.g., `privacy@kindredcook.app`)
   - Preserve the Version 2.0 marker for audit history
   - Publish the page

2. **Verify hosted policy is live:**
   - Visit https://kindred.app/privacy in a browser
   - Confirm Spoonacular and ElevenLabs sections are visible
   - Confirm effective date and contact email are set (not placeholders)

**Why this can't be automated:**
- The marketing site at `kindred.app` lives in a separate repo/hosting service (outside Kindred iOS repo)
- Phase 27 produces the versioned draft; Phase 28 submission requires the hosted version to be live
- App Store reviewers will visit the privacy policy link during review — it must match the app's Privacy Label

**Timeline:**
- Hosting must complete BEFORE the `fastlane deliver` command in Phase 28
- Recommended: Host the policy immediately after Phase 27-04 completes (all compliance work done)

---

## Testing & Verification

### Automated Checks (PASSED)

**Task 1 (POLICY-UPDATE.md):**
- [x] File exists at `.planning/phases/27-app-store-compliance/POLICY-UPDATE.md`
- [x] Contains "Spoonacular" processor entry
- [x] Contains "ElevenLabs" processor entry
- [x] Contains "Search History" data collection entry
- [x] Contains "api.kindredcook.app" backend proxy description
- [x] Contains "Effective date" placeholder
- [x] Contains "spoonacular.com/food-api/privacy" link
- [x] Contains "elevenlabs.io/privacy" link

**Task 2 (notes.txt):**
- [x] File exists at `Kindred/fastlane/metadata/review_information/notes.txt`
- [x] Contains "BACKEND PROXY DISCLOSURE" section header
- [x] Contains "api.kindredcook.app which proxies Spoonacular" sentence
- [x] Contains "kindred.app/privacy" reference
- [x] All existing sections preserved (APP DESCRIPTION, DEMO ACCOUNT CREDENTIALS, etc.)

### Manual Review Items (For User)

**Policy voice/tone:**
- [ ] User reviews POLICY-UPDATE.md for tone alignment with Kindred's brand
- [ ] User confirms plain-language wording (not overly legal) before hosting
- [ ] (Optional) Native Turkish speaker reviews if user has concerns about localization

**External link verification (before Phase 28):**
- [ ] Spoonacular privacy policy link resolves: https://spoonacular.com/food-api/privacy
- [ ] ElevenLabs privacy policy link resolves: https://elevenlabs.io/privacy
- [ ] Hosted policy goes live at https://kindred.app/privacy (user action required)

---

## Context for Phase 28

**What Phase 27-03 delivered:**
- Privacy policy draft with all third-party disclosures required by STORE-02
- Review notes explaining backend proxy chain to App Store reviewers

**What Phase 28 expects:**
- Privacy policy hosted at `kindred.app/privacy` (MANUAL STEP)
- Review notes uploaded to App Store Connect via `fastlane deliver`
- Privacy Label manifest already configured (Plan 27-01)
- In-app privacy policy footer already implemented (Plan 27-02)

**Integration points:**
- `notes.txt` → fastlane uploads to App Store Connect during `deliver` action
- Hosted privacy policy → App reviewers visit link from App Store Connect metadata
- Privacy policy footer (Plan 27-02) → links to hosted policy from Settings tab

**Known gap:**
- Phase 27 cannot verify the hosted policy is live (external site)
- Phase 28 checklist should include "Confirm privacy policy hosted" step before `deliver`

---

## Files Modified

**Created:**
- `.planning/phases/27-app-store-compliance/POLICY-UPDATE.md` (90 lines, full privacy policy draft)

**Modified:**
- `Kindred/fastlane/metadata/review_information/notes.txt` (+5 lines, added BACKEND PROXY DISCLOSURE section)

---

## Commits

1. **138087b** — `docs(27-03): create privacy policy update draft`
   - Created POLICY-UPDATE.md with Spoonacular, ElevenLabs, Search History disclosures
   - Documented backend proxy chain and nutrition disclaimer
   - Staged for manual hosting at kindred.app/privacy

2. **4950059** — `docs(27-03): add backend proxy disclosure to review notes`
   - Appended BACKEND PROXY DISCLOSURE section to notes.txt
   - Explained api.kindredcook.app proxies Spoonacular
   - Helps reviewers understand network traffic in iOS 17+ Privacy Report

---

## Relationship to Other Plans

**Plan 27-01 (Privacy Manifest + App Store Checklist):**
- Configures in-app manifest entries for Search History, Audio Data, etc.
- App Store Connect checklist references the privacy policy URL (which this plan drafts)

**Plan 27-02 (In-App Privacy Policy Footer):**
- Adds "Privacy Policy" link to Settings tab footer
- Link points to `kindred.app/privacy` (where user hosts POLICY-UPDATE.md content)

**Plan 27-03 (this plan):**
- Produces the actual privacy policy text and review notes
- External-facing documentation (not in-app)

**Plan 27-04 (expected next):**
- Likely covers final submission prep (screenshots, metadata, build upload)
- Depends on privacy policy being hosted (MANUAL STEP from this plan)

---

## Self-Check: PASSED

**Verified created files:**
```
FOUND: .planning/phases/27-app-store-compliance/POLICY-UPDATE.md
```

**Verified commits:**
```
FOUND: 138087b (privacy policy draft)
FOUND: 4950059 (review notes update)
```

**Verified content integrity:**
- POLICY-UPDATE.md contains all required sections (Third-Party Data Processors, Data We Collect, Contact)
- Spoonacular and ElevenLabs disclosures present with privacy policy links
- Search History data type documented with correct classification (not linked, not tracked, app functionality)
- Backend proxy chain explained in plain language
- Review notes appended without modifying existing sections

All deliverables verified. Plan 27-03 complete.
