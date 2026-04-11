---
gsd_state_version: 1.0
milestone: v5.0
milestone_name: Lean App Store Launch
status: planning
last_updated: "2026-04-08T06:32:38.262Z"
progress:
  total_phases: 21
  completed_phases: 17
  total_plans: 69
  completed_plans: 66
---

# Project State: Kindred

**Last Updated:** 2026-04-08
**Status:** Ready to plan

---

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-04)

**Core value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.
**Current focus:** Phase 23 - Spoonacular Backend Integration

---

## Current Position

Phase: 28 of 28 (v5.0 Lean App Store Launch)
Plan: 4 of 5 in current phase
Status: Phase 28 in progress — 4/5 plans complete
Last activity: 2026-04-11 — Completed plan 28-04 (Beta bake + GO decision for App Store submission)

Progress: [█████████████████████████░░░] 98% (28/28 phases started, Phase 28: 4/5 plans complete)

---

## Performance Metrics

**Velocity:**
- Total plans completed: 87 (across v1.5-v5.0)
- Average duration: ~37 min per plan
- Total execution time: ~62.3 hours (across 5 milestones)
- Phase 23 plan 01: 8 minutes
- Phase 23 plan 02: 8 minutes
- Phase 23 plan 03: 6 minutes
- Phase 23 plan 04: 33 minutes

**By Milestone:**

| Milestone | Phases | Plans | Timeline |
|-----------|--------|-------|----------|
| v1.5 Backend & AI Pipeline | 3 | 11 | 2 days |
| v2.0 iOS App | 8 | 35 | 9 days |
| v3.0 Smart Pantry | 6 | 17 | 7 days |
| v4.0 App Store Launch Prep | 5 | 19 | 4 days |
| v5.0 Lean App Store Launch | 6 | 4 | In progress |

**Recent Trend:**
- Last milestone (v4.0): 4 days, 19 plans — improved efficiency with focused compliance work
- Trend: Stable velocity with well-defined requirements

---
| Phase 23 P01 | 8 | 2 tasks | 11 files |
| Phase 23 P02 | 8 | 2 tasks | 9 files |
| Phase 23 P03 | 6 | 2 tasks | 7 files |
| Phase 23 P04 | 33 | 2 tasks | 16 files |
| Phase 26 P01 | 8 | 2 tasks | 6 files |
| Phase 26 P02 | 9 | 2 tasks | 7 files |
| Phase 26 P03 | 4 | 2 tasks | 6 modified, 4 deleted |
| Phase 27 P01 | 69 | 2 tasks | 1 files |
| Phase 27 P03 | 1 | 2 tasks | 2 files |
| Phase 27 P02 | 6 | 2 tasks | 2 files |
| Phase 27 P04 | 15 | 3 tasks | 6 files |
| Phase 27.1 P01 | 5 min (293 sec) | 3 tasks | 5 files |
| Phase 28 P01 | 7 min | 2 tasks | 1 file |
| Phase 28 P01 | 7 | 2 tasks | 1 files |
| Phase 28 P03 | 16 | 2 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (199 decisions tracked).
Recent decisions affecting v5.0 work:

- **Replace X API with Spoonacular free tier**: 150 req/day quota requires aggressive caching (6-hour TTL + batch pre-warm) to avoid exhaustion
- **Replace ElevenLabs for free users with AVSpeechSynthesizer**: Zero-cost on-device TTS for free tier, ElevenLabs moves behind Pro paywall
- **Replace Imagen 4 with Spoonacular CDN images**: Zero AI generation cost, CDN images included with recipe data
- **Update feed framing from "viral near you" to "popular recipes"**: No geolocation in Spoonacular free tier, popularity scores replace viral detection
- **Fastlane release lane for App Store submission**: Automate binary upload + metadata sync to reduce manual error risk
- [Phase 23-01]: Use atomic increment for quota tracking (better for concurrent requests)
- [Phase 23-01]: Store Spoonacular CDN images as COMPLETED status (no generation needed)
- [Phase 23-02]: 6-hour cache TTL balances quota conservation with freshness
- [Phase 23-02]: Stale-while-revalidate serves stale cache immediately with background refresh
- [Phase 23-02]: Quota exhaustion falls back to popular pre-warmed recipes
- [Phase 23-02]: Cursor pagination uses base64-encoded offsets (Relay-compatible)
- [Phase 23-04]: Preserved R2StorageService in reduced ImagesModule (needed by VoiceModule for voice uploads)
- [Phase 23-04]: Removed @google-cloud/aiplatform dependency (only used by deleted Imagen 4 service)
- [Phase 26-01]: Use popularityScore (0-100 integer) instead of isViral boolean for cleaner semantics
- [Phase 26]: Use endCursor/hasNextPage instead of offset-based pagination for cursor-based GraphQL queries
- [Phase 26]: Show PopularityBadge when popularityScore >= 50 (consistent with MatchBadge threshold)
- [Phase 26-03]: Remove deprecated `Recipes` (offset-based) query alongside `ViralRecipes` — both confirmed dead via grep, full cleanup achieved
- [Phase 26-03]: Delete duplicate generated Apollo files in `NetworkClient/Sources/Schema/Sources/Operations/Queries/` (stale from prior codegen run, not produced by active `apollo-codegen-config.json`)
- [Phase 26-03]: Verify-then-cleanup checkpoint pattern (human-verify gate before destructive deprecation removals)
- [Phase 27]: Flip Product Interaction to Linked=true per Phase 27 CONTEXT.md (Firebase receives Clerk user id)
- [Phase 27]: Add Search History data type for Spoonacular queries (Linked=false, not a tracker)
- [Phase 27]: Do NOT add api.spoonacular.com to tracking domains (data processor, not tracker)
- [Phase 27]: Version 2.0 privacy policy includes Spoonacular, ElevenLabs, and Search History disclosures
- [Phase 27]: Backend proxy chain documented to prevent reviewer confusion with iOS 17+ Privacy Report
- [Phase 27]: Use SwiftUI Link instead of openURL for Spoonacular attribution (simpler, localization-friendly)
- [Phase 27]: Use full English sentence as localization key (Kindred's existing convention)
- [Phase 27-04]: Localize "Popular Recipes" feed heading (user-approved deviation for Turkish screenshot quality)
- [Phase 27-04]: Use iPhone 17 Pro Max for 6.9" screenshots (iPhone 16 Pro Max deprecated in Xcode 26)
- [Phase 27.1-01]: Add 4 AdMob data type entries to PrivacyInfo.xcprivacy (Device ID, Advertising Data, second Coarse Location, Other Diagnostic Data)
- [Phase 27.1-01]: Use NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising constant (not the older Advertising constant)
- [Phase 27.1-01]: Keep NSPrivacyTrackingDomains at 5 Google domains (conservative audit, no additions)
- [Phase 27.1-01]: Preserve Phase 27 verification report unchanged (corrections live in 27.1-VERIFICATION.md only)
- [Phase 28-01]: Precheck lane validates Release.xcconfig, .env, .p8, metadata, and screenshots before any build
- [Phase 28-01]: Wired into beta_internal and release lanes as first statement (fail-fast gate)
- [Phase 28-01]: Lane name 'precheck' conflicts with fastlane built-in tool but still functional
- [Phase 28]: en-US metadata requires no changes (already compliant with all audit criteria)
- [Phase 28]: tr metadata requires only URL file creation (description already has adequate ad disclosure)
- [Phase 28-03]: Defer Apollo generated code warnings (backend schema deprecations, not iOS SDK issues)
- [Phase 28-03]: Use maxPhotoDimensions with max resolution selection instead of isHighResolutionCaptureEnabled
- [Phase 28-03]: Remove WithPerceptionTracking wrappers (not needed on iOS 17+ deployment target)
- [Phase 28-04]: Distribute build 509 manually via ASC web UI (fastlane pilot bug #28630 — internal distribution triggers beta-review submission)
- [Phase 28-04]: Populate Beta App Description in ASC TestFlight Test Information app-wide (one-time fix for pilot bug)
- [Phase 28-04]: Rename precheck lane to preflight (collision with fastlane built-in precheck tool)
- [Phase 28-04]: GO decision after 72h bake — zero crashes, all 6 core flows pass, all checklist items PASS

### Roadmap Evolution

- Phase 27.1 inserted after Phase 27: Reconcile Phase 27 docs with AdMob tracker reality (URGENT) — COMPLETED 2026-04-07

### Pending Todos

None yet.

### Blockers/Concerns

**Spoonacular quota management (Phase 23):**
- 150 req/day quota can exhaust quickly without proper caching
- Mitigation: Implement PostgreSQL caching layer as table stakes (not optimization)
- Monitor usage at 80% threshold with alerts

**AVSpeechSynthesizer iOS 17/18 bugs (Phase 24):**
- Documented crashes ("Could not find audio unit") on iOS 17.0-17.2
- Memory leaks after 5-10 narrations, stops mid-utterance on long recipes
- Mitigation: Test on iPhone 14 Pro (iOS 17.6) + iPhone 16 (iOS 18.2) real devices, implement 500-word segment limit

**App Store compliance (Phase 27):**
- Third-party AI consent (Guideline 5.1.2(i)) enforced since November 2025
- Nutrition disclaimers required for Spoonacular health data (Guideline 1.4.1)
- Mitigation: Update Privacy Policy, Privacy Labels, add disclaimers before submission

**Xcode 16 + iOS 26 SDK requirement (Phase 28):**
- Hard deadline April 28, 2026 for all App Store submissions
- Mitigation: Verify Xcode 16 + macOS Sequoia before starting Phase 28

---

## Session Continuity

Last session: 2026-04-11
Stopped at: Phase 28 plan 04 complete. GO decision recorded. Ready for plan 28-05 (App Store submission).
Resume file: None

**Next action:** Execute plan 28-05 (App Store submission via `fastlane release`)

---

## Performance Metrics (Phase 23)

| Plan | Duration | Tasks | Files | Status |
|------|----------|-------|-------|--------|
| 23-01 | 8 min | 2 | 11 | ✅ Complete |
| 23-02 | 8 min | 2 | 9 | ✅ Complete |
| 23-03 | 6 min | 2 | 7 | ✅ Complete |
| 23-04 | 33 min | 2 | 16 | ✅ Complete |

---

*State updated: 2026-04-07 20:33 — Phase 27.1 complete (1/1 plans), AdMob compliance gap closed, ready for Phase 28*
