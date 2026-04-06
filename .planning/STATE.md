---
gsd_state_version: 1.0
milestone: v5.0
milestone_name: Lean App Store Launch
status: planning
last_updated: "2026-04-06T17:41:40.953Z"
progress:
  total_phases: 20
  completed_phases: 15
  total_plans: 63
  completed_plans: 59
---

# Project State: Kindred

**Last Updated:** 2026-04-06
**Status:** Ready to plan

---

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-04)

**Core value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.
**Current focus:** Phase 23 - Spoonacular Backend Integration

---

## Current Position

Phase: 27 of 28 (v5.0 Lean App Store Launch)
Plan: 1 of 4 in current phase (executing Phase 27)
Status: Phase 27 in progress — 1/4 plans complete
Last activity: 2026-04-06 — Completed plan 27-01 (privacy manifest update for Spoonacular + Firebase linking)

Progress: [█████████████████████░░░░░░░] 86% (24/28 phases complete, 1/4 plans in phase 27)

---

## Performance Metrics

**Velocity:**
- Total plans completed: 86 (across v1.5-v5.0)
- Average duration: ~38 min per plan
- Total execution time: ~62.2 hours (across 5 milestones)
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

Last session: 2026-04-06 12:54
Stopped at: Completed 26-03-PLAN.md (Phase 26 Feed UI Migration complete: 3/3 plans)
Resume file: None

**Next action:** Plan Phase 27 (App Store Compliance — Privacy Policy, Privacy Labels, AI consent, nutrition disclaimers)

---

## Performance Metrics (Phase 23)

| Plan | Duration | Tasks | Files | Status |
|------|----------|-------|-------|--------|
| 23-01 | 8 min | 2 | 11 | ✅ Complete |
| 23-02 | 8 min | 2 | 9 | ✅ Complete |
| 23-03 | 6 min | 2 | 7 | ✅ Complete |
| 23-04 | 33 min | 2 | 16 | ✅ Complete |

---

*State updated: 2026-04-06 12:54 — Phase 26 complete (3/3 plans), ready for Phase 27*
