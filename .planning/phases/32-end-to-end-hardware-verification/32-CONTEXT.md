# Phase 32: End-to-End Hardware Verification - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Validate all five v5.1 gaps are confirmed closed on real hardware and Simulator; produce a TestFlight build and formal verification report ready for App Store submission. No new features — this is a testing and sign-off phase.

</domain>

<decisions>
## Implementation Decisions

### Test Execution Approach
- Run on iOS 26 real device (iPhone 16 Pro Max) + Simulator for iOS 17.0 and iOS 18.x
- iOS 17.0 Simulator specifically (minimum supported version, not latest 17.x)
- Strict checklist format — step-by-step test matrix with pass/fail per flow per OS
- Claude prepares the full test matrix document; user executes on device and reports results
- Test against production backend (api.kindredcook.app)
- TestFlight distribution — phase produces the build via beta_internal lane
- Fresh install required (delete existing app, install from TestFlight)
- Test both free-tier and Pro-tier user paths (free first, then Pro)
- Simulator flows: run 1 (onboarding), 2 (feed), 3 (recipe detail), 6 (subscription); skip 4 (voice) and 5 (pantry scan) — documented as 'hardware-only'
- Include v5.1-specific test items as separate entries beyond the 6 core flows (source attribution, search debounce, dietary filter, AVSpeech fallback)
- Pass/fail only — no timing metrics

### API & Backend Validation
- Verify Spoonacular API call count via production server logs (SSH + grep/tail NestJS logs)
- Fixed list of 10 predetermined search queries in the test matrix for reproducibility
- Explicit cache test: search same term twice, verify second hit uses cache (not Spoonacular) via logs
- Verify dietary filter pass-through at API level — confirm backend forwards diet params correctly in production logs

### Voice Tier Verification
- Free-tier: listen and confirm system TTS voice (subjective verification — sounds synthetic, not cloned)
- Pro-tier: verify ElevenLabs cloned voice plays correctly (already subscribed in test account)
- Test on fresh install only for AVSpeech enhanced voice availability / compact fallback
- Verify step highlighting — current cooking step visually highlighted in sync with narration
- Explicit mini player persistence test: start narration, navigate to feed/search/profile, confirm mini player visible and audio continues
- Test interruption scenarios: incoming call, notification banner, app goes to background — verify graceful pause/resume

### Pass/Fail Criteria & Blockers
- Zero tolerance: any flow failure blocks App Store submission
- Simulator failures carry equal weight to real-device failures
- Complete all tests first, document all failures, then batch fixes
- After fixes: full regression (re-run entire test matrix, not just failed items)
- Formal sign-off section in report: build number, date, device info, explicit "Ready for submission: Yes/No"
- Phase produces the TestFlight build (run beta_internal lane) — build number recorded in report

### Claude's Discretion
- Exact search query list for the 10-query test
- Test matrix formatting and organization
- Log grep patterns for backend verification
- Simulator device model selection for iOS 17/18

</decisions>

<specifics>
## Specific Ideas

- The 6 core flows from `Kindred/docs/what-to-test.md` are the baseline
- v5.1 gaps (source attribution, search/debounce/cache, dietary filters, AVSpeech/voice tier routing) get separate dedicated test items
- Cache verification: search 'pasta' → wait → search 'pasta' again → confirm cache hit in logs
- Free-tier test should come first (before subscribing), then Pro-tier test after subscription is active
- Voice interruption tests should cover phone calls, notifications, and background/foreground transitions

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Kindred/docs/what-to-test.md`: Existing 6-flow test guide — test matrix builds on this
- `Kindred/fastlane/Fastfile`: `beta_internal` lane for TestFlight build production
- `Kindred/fastlane/.env`: ASC API key configuration for uploads

### Established Patterns
- TestFlight distribution via Fastlane `beta_internal` lane (proven in Phase 28)
- Production backend at `api.kindredcook.app` with NestJS logging
- Voice tier routing: free → AVSpeechSynthesizer, Pro → ElevenLabs (Phase 30)

### Integration Points
- Backend logs accessed via SSH to production server
- TestFlight build distributed to iPhone 16 Pro Max
- Simulator runtimes needed: iOS 17.0 and iOS 18.x (check Xcode availability)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 32-end-to-end-hardware-verification*
*Context gathered: 2026-04-14*
