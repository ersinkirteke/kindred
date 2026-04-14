# Phase 32: End-to-End Hardware Verification — Research

**Researched:** 2026-04-14
**Domain:** iOS hardware testing, TestFlight distribution, backend log verification
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Test Execution Approach**
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

**API & Backend Validation**
- Verify Spoonacular API call count via production server logs (SSH + grep/tail NestJS logs)
- Fixed list of 10 predetermined search queries in the test matrix for reproducibility
- Explicit cache test: search same term twice, verify second hit uses cache (not Spoonacular) via logs
- Verify dietary filter pass-through at API level — confirm backend forwards diet params correctly in production logs

**Voice Tier Verification**
- Free-tier: listen and confirm system TTS voice (subjective verification — sounds synthetic, not cloned)
- Pro-tier: verify ElevenLabs cloned voice plays correctly (already subscribed in test account)
- Test on fresh install only for AVSpeech enhanced voice availability / compact fallback
- Verify step highlighting — current cooking step visually highlighted in sync with narration
- Explicit mini player persistence test: start narration, navigate to feed/search/profile, confirm mini player visible and audio continues
- Test interruption scenarios: incoming call, notification banner, app goes to background — verify graceful pause/resume

**Pass/Fail Criteria & Blockers**
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

## Summary

Phase 32 is a test-and-sign-off phase with no new code. Its deliverables are: (1) a TestFlight build produced by the `beta_internal` Fastlane lane, (2) a structured test matrix document the user executes on real hardware, and (3) a formal verification report with explicit "Ready for submission: Yes/No".

The phase covers the five v5.1 requirements (ATTR-01, VOICE-01–05, SEARCH-01–03, FILTER-01–02) that were implemented across Phases 29–31. All five were verified at the code level by the GSD verifier; Phase 32 is the on-device confirmation that the plumbing works under real conditions — live network, real audio hardware, actual TestFlight distribution.

**Critical finding:** iOS 17.0 and iOS 18.x Simulator runtimes are NOT installed on this machine. Only iOS 26.x Simulators are available (`xcrun simctl list runtimes` confirms iOS 26.2, 26.3, 26.4 only). The real device is also on iOS 26.3.1, not iOS 17.0. The CONTEXT.md decision to test on iOS 17.0 and iOS 18.x Simulators cannot be fulfilled without downloading those runtimes via Xcode → Platforms → iOS. The plan must either include a pre-step to download the iOS 17.0 and 18.x runtimes, OR document that Simulator testing will be performed on iOS 26 only, with real iOS 17 hardware deferred.

**Primary recommendation:** Structure the phase as two plans: Plan 01 = build + TestFlight + prepare test matrix document; Plan 02 = user executes tests and reports results + planner writes verification report. The Simulator runtime download issue must be addressed before Plan 02.

---

## Standard Stack

### Core (no new libraries — all already in project)

| Component | Version / Location | Purpose | Notes |
|-----------|-------------------|---------|-------|
| Fastlane `beta_internal` lane | `Kindred/fastlane/Fastfile` | Produce TestFlight build | Uses `agvtool` for build number, `build_app` + `upload_to_testflight` |
| Xcode Simulator | iOS 26.x available now; iOS 17/18 must be downloaded | Run Simulator test flows | Only iOS 26.x present — see Critical Finding above |
| SSH + NestJS Logger | `Logger` from `@nestjs/common` in `SpoonacularService` + `RecipesService` | Backend log grep | Both services use `this.logger.log(...)` on every Spoonacular search call |
| AVSpeechSynthesizer | iOS 17.0+ | On-device TTS for free-tier | Enhanced voice quality preferred, compact fallback automatic |
| ElevenLabs / AVPlayer | Production backend | Pro-tier cloned voice playback | Already subscribed test account available |

---

## Architecture Patterns

### How the TestFlight Build Works

The `beta_internal` lane in `Kindred/fastlane/Fastfile`:
1. Loads ASC API key from `.env`
2. Runs `preflight` lane (checks xcconfig, .env, .p8, metadata, screenshots)
3. Sets build number to `number_of_commits`
4. Calls `build_app` with `Release` configuration + manual signing (Apple Distribution cert + "com.ersinkirteke.kindred AppStore" profile)
5. Calls `upload_to_testflight(skip_waiting_for_build_processing: false, distribute_external: false, groups: ["Internal Testers"])`

Run from: `cd Kindred/fastlane && /opt/homebrew/opt/ruby/bin/bundle exec fastlane beta_internal`

### How Backend Log Verification Works

NestJS `SpoonacularService` logs every actual Spoonacular API call at `Logger.log` level:
- Line 76: `Searching recipes: query="${query}", number=${number}, offset=${offset}` — fires only when cache MISS or stale (background refresh)
- `RecipesService` line 45: `Serving stale cache for ${normalizedKey}, triggering background refresh` — cache HIT but stale
- `RecipesService` line 96: `Spoonacular search failed: ${error.message}` — error case

Cache HIT (fresh): no Spoonacular log line appears. Only DB queries run.

**Log grep pattern to verify debounce + cache:**
```bash
# SSH to production server, then:
journalctl -u kindred-backend -f --since "5 minutes ago" | grep -E "Searching recipes|Serving stale|Spoonacular search failed"
# OR if using PM2:
pm2 logs kindred --lines 200 | grep -E "Searching recipes|Serving stale|cache"
```

**Diet param pass-through verification:** The resolver accepts `SearchRecipesInput` with `diets` and `intolerances` arrays. In `SpoonacularService.search()`, diets map to `params.diet = filters.diets[0]` and intolerances map to `params.intolerances = filters.intolerances.join(',')`. Logs do not print params at the service level — the backend log will show the query string but not diet params. To verify diet param delivery, check the Spoonacular dashboard for request params, OR add a temporary log. An easier approach: verify the response correctness (returned recipes are actually vegan/gluten-free) as the functional evidence.

### How Voice Tier Routing Works (for test design)

From `VoicePlaybackReducer.swift`:
- `startPlayback`: free/unknown/guest users → immediately sends `.selectVoice("kindred-default")` → `isAVSpeechActive = true` → `avSpeechClient.speak(preprocessedSteps)`
- Pro users → fetches subscription status → if `.pro` → shows voice picker or uses existing ElevenLabs voice
- `preferredVoice()` in `AVSpeechManager`: selects `.enhanced` quality first, `.default` fallback, `AVSpeechSynthesisVoice(language:)` last resort

**AVSpeech enhanced voice test:** On a fresh TestFlight install without additional voice downloads in Settings, the device will use the default (compact) quality voice. The enhanced voice is downloaded separately via Settings > Accessibility > Spoken Content > Voices. The test should verify that compact fallback renders without error — not that enhanced voice is present (that depends on device configuration).

### How the 6 Core Flows Map to Phase Requirements

| Flow | Requirement Coverage | Simulator OK? | Notes |
|------|---------------------|---------------|-------|
| Flow 1: Onboarding | None (pre-v5.1) | Yes | Tests location detection, preferences |
| Flow 2: Browse Feed | None (pre-v5.1) | Yes | Tests FILTER-01/02 via chip visibility |
| Flow 3: Recipe Detail | ATTR-01 (source link) | Yes | Source attribution link must be tappable |
| Flow 4: Voice Narration | VOICE-01–05 | Real device only | AVSpeech audio requires hardware |
| Flow 5: Pantry Scan | None (pre-v5.1) | Real device only | Camera required |
| Flow 6: Subscription | None (pre-v5.1) | Yes (sandbox) | Confirms free→Pro transition |
| v5.1 Search | SEARCH-01–03 | Yes | Debounce, pagination, result cards |
| v5.1 Dietary Filters | FILTER-01–02 | Yes | Diet vs intolerance routing |

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Build number tracking | Custom script | `number_of_commits` in `beta_internal` lane | Already wired and proven (build 509+) |
| Backend log access | Custom log API | SSH + `journalctl`/`pm2 logs` | NestJS Logger writes to stdout; process manager captures it |
| Simulator device selection | Manual trial | `xcrun simctl list devices` to get available device names | Avoids hardcoding UDIDs that change between Xcode versions |

---

## Common Pitfalls

### Pitfall 1: iOS 17/18 Simulator Runtimes Not Installed
**What goes wrong:** The CONTEXT.md specifies iOS 17.0 and iOS 18.x Simulator targets, but `xcrun simctl list runtimes` shows only iOS 26.x on this machine. Running the plan without addressing this means the Simulator test steps silently can't execute.
**Why it happens:** Xcode 26 ships with iOS 26 Simulator runtime by default. Older runtimes must be downloaded separately via Xcode → Settings → Platforms.
**How to avoid:** Plan 01 must include a step to download iOS 17.0 and iOS 18.x Simulator runtimes before the test matrix document references them. Or the plan adjusts the Simulator targets to iOS 26.x (which IS available) and documents that iOS 17/18 is covered only by real device.
**Warning signs:** `xcodebuild -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'` fails with "No such runtime" error.

### Pitfall 2: beta_internal Lane Requires Clean Git Status
**What goes wrong:** `before_all` in Fastfile calls `ensure_git_status_clean` (unless `SKIP_GIT_STATUS_CHECK` env var set). If there are uncommitted changes, the lane aborts before building.
**Why it happens:** Git status check is a safety guard against shipping unreleased changes.
**How to avoid:** Commit all pending changes (PaywallView, SubscriptionReducer, ProfileReducer, RootView, Info.plist, project.pbxproj — all listed in git status as modified) before running the lane.
**Warning signs:** `ensure_git_status_clean` error at lane start.

### Pitfall 3: Modified Files in Git Status May Indicate Unfinished Phase 31 Work
**What goes wrong:** Current git status shows `M Kindred/Packages/MonetizationFeature/Sources/Subscription/PaywallView.swift`, `M ...SubscriptionReducer.swift`, `M ...ProfileReducer.swift`, `M .../RootView.swift`, `M .../Info.plist` as modified. These are Phase 31 plan 02 changes that may not be committed yet.
**Why it happens:** Phase 31 plan 02 (Search UI wire-up) was stated as done in STATE.md but the git status shows modified files.
**How to avoid:** Before building TestFlight, verify all Phase 31 changes are committed. Run `git status` and `git log --oneline -5` to confirm.
**Warning signs:** Modified source files present when running `beta_internal` lane.

### Pitfall 4: Test Account Subscription State
**What goes wrong:** Testing free-tier first, then Pro-tier — if the test account has an active StoreKit sandbox subscription from a previous session, it will show as Pro from the start, skipping free-tier tests.
**Why it happens:** StoreKit sandbox subscriptions persist until explicitly reset or expired.
**How to avoid:** In Xcode Organizer or Settings, delete/expire the sandbox subscription before starting tests. Or use two different Apple IDs — one without subscription for free-tier, one with for Pro-tier.
**Warning signs:** App shows Pro UI immediately on fresh install.

### Pitfall 5: Production Backend Log Access Pattern Unknown
**What goes wrong:** Plan includes "SSH to production server and grep logs" but the exact SSH command, PM2 config, and log format are not documented in the codebase. The `.planning/` docs only say "SSH + grep/tail NestJS logs".
**Why it happens:** Server setup details live outside the repo (Hetzner VPS, mentioned in MEMORY.md reference_landing_page.md). The log access pattern needs to be confirmed before the test matrix document can give exact commands.
**How to avoid:** Plan 01 should include a checkpoint where the user confirms the SSH access pattern and PM2/journalctl command before Plan 02 references it. Provide both `pm2` and `journalctl` variants.
**Warning signs:** `pm2 not found` or `journalctl` permission denied.

### Pitfall 6: SEARCH-02 Still Marked Pending in REQUIREMENTS.md
**What goes wrong:** `REQUIREMENTS.md` has `SEARCH-02` (search results same card layout as popular feed) marked as `[ ]` Pending, but Phase 31 VERIFICATION.md item 7 notes it's actually implemented and recommends updating the checkbox.
**Why it happens:** The verifier flagged it as human-confirm-needed. No one updated REQUIREMENTS.md yet.
**How to avoid:** Plan 01 (or as a pre-task) should update REQUIREMENTS.md to mark SEARCH-02 complete after visual confirmation during Phase 32 device testing.

### Pitfall 7: AVSpeech Enhanced Voice Test Expectation
**What goes wrong:** Success criterion 4 states "AVSpeech enhanced voice is present on fresh TestFlight install; if absent, compact fallback renders without error." The enhanced voice IS absent on most fresh installs — it requires the user to go to Settings > Accessibility > Spoken Content and download it. The compact (default quality) voice is what ships with the OS.
**Why it happens:** Apple's enhanced voices are large downloads (~200MB) not bundled by default.
**How to avoid:** Test matrix should verify that narration plays without error using the default/compact voice, not that enhanced voice is available. The "if absent, compact fallback renders without error" clause is the actual success criterion. Document this clearly so the user doesn't expect to hear an enhanced voice by default.

---

## Code Examples

### Backend Log Grep — Spoonacular Call Verification
```bash
# Via PM2 (most common NestJS production setup)
pm2 logs kindred --lines 500 --nostream | grep -E "SpoonacularService|Searching recipes|stale cache|search failed"

# Via journalctl (if using systemd)
journalctl -u kindred-backend --since "10 minutes ago" | grep -E "Searching recipes|stale cache|search failed"

# To watch in real-time during test
pm2 logs kindred --lines 0 | grep --line-buffered -E "SpoonacularService|cache"
```

### Check Simulator Runtimes Available
```bash
xcrun simctl list runtimes | grep iOS
# Expected output shows iOS 17 and 18 if installed:
# iOS 17.0 (17.0 - 21A5248v) - com.apple.CoreSimulator.SimRuntime.iOS-17-0
# iOS 18.2 (18.2 - 22C150) - com.apple.CoreSimulator.SimRuntime.iOS-18-2
```

### Download Missing Simulator Runtimes (Xcode 16+)
```bash
# Download iOS 17.0 runtime via xcodebuild
xcodebuild -downloadPlatform iOS --version 17.0
# OR via Xcode GUI: Xcode > Settings > Platforms > iOS > Add (+)
```

### Run beta_internal Lane
```bash
cd /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane
/opt/homebrew/opt/ruby/bin/bundle exec fastlane beta_internal
# Expected output at success: "Internal beta build uploaded successfully!"
# Build number = number_of_commits (verify with: git rev-list --count HEAD)
```

### 10-Query Search Test List (Claude's Discretion)
Predetermined queries that test diverse food categories and ensure reproducible Spoonacular call counts:

1. `pasta` — broad Italian, high cache hit likelihood on repeat
2. `chicken soup` — two-word query, popular
3. `vegan chocolate cake` — long query, dessert + dietary
4. `salmon` — protein-focused
5. `tacos` — Mexican cuisine
6. `quinoa salad` — health-focused
7. `bread` — baking category
8. `stir fry` — Asian technique term
9. `mushroom risotto` — Italian, specific
10. `breakfast burrito` — compound noun

Cache test protocol: run query #1 (`pasta`), wait 5 seconds, run `pasta` again. Backend logs should show 1 Spoonacular call (first) and 0 Spoonacular calls (second — cache hit).

---

## Open Questions

1. **iOS 17/18 Simulator Runtime Availability**
   - What we know: Only iOS 26.x Simulator runtimes are installed. CONTEXT.md requires iOS 17.0 and iOS 18.x Simulator.
   - What's unclear: Whether the plan should (a) add a pre-step to download runtimes, (b) substitute iOS 26.x Simulator for 17/18, or (c) document Simulator as iOS 26 only and rely on real device for version coverage.
   - Recommendation: Plan 01 includes `xcodebuild -downloadPlatform iOS --version 17.0` and `--version 18.2` as pre-tasks, with the acknowledgment these downloads take 5-15 minutes each. If the user cannot or does not download them, Simulator testing proceeds on iOS 26.x with a clear note in the report.

2. **Production SSH Access Pattern**
   - What we know: Backend is on Hetzner VPS at `api.kindredcook.app`. NestJS uses `Logger` which outputs to stdout. Reference to `pm2 logs` or `journalctl` both possible.
   - What's unclear: Exact SSH host/user, whether PM2 or systemd manages the process, and whether NestJS log level is configured to show `log()` vs only `warn()`/`error()`.
   - Recommendation: Plan 01 should include a user checkpoint to confirm SSH command and verify log access before the test matrix document references specific commands.

3. **Phase 31 Plan 02 Commit Status**
   - What we know: Git status shows modified files in PaywallView, SubscriptionReducer, ProfileReducer, RootView, Info.plist. STATE.md progress shows "Phase 31 Plan 01 complete."
   - What's unclear: Whether Phase 31 Plan 02 changes are committed or still pending.
   - Recommendation: Plan 01 first task should be "verify Phase 31 complete: check `git log --oneline -10` and ensure Phase 31 plan 02 changes are committed."

---

## Sources

### Primary (HIGH confidence)
- Live codebase — `Kindred/fastlane/Fastfile` (beta_internal lane, export options, preflight checks)
- Live codebase — `backend/src/spoonacular/spoonacular.service.ts` (Logger.log call sites, cache check pattern)
- Live codebase — `backend/src/recipes/recipes.service.ts` (cache-first logic, stale-while-revalidate log messages)
- Live codebase — `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechManager.swift` (preferredVoice enhanced/compact selection)
- Live codebase — `Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift` (tier routing, isAVSpeechActive flag)
- Live codebase — `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` (debounce 300ms, SearchDebounceID, mapChipsToSearchParams)
- Live codebase — Phase 30 and 31 VERIFICATION.md files (human verification items deferred to Phase 32)
- `xcrun simctl list runtimes` command output (iOS 26.x only available, no iOS 17/18)
- `xcrun xctrace list devices` (real device: iPhone 16 Pro Max, iOS 26.3.1)

### Secondary (MEDIUM confidence)
- MEMORY.md — Fastlane lessons (Homebrew Ruby required, build number via git commits, beta review pitfall)
- `.planning/REQUIREMENTS.md` — v5.1 requirement status and SEARCH-02 pending flag

---

## Metadata

**Confidence breakdown:**
- Test matrix content: HIGH — derived directly from live code, Phase 30/31 verification items, and CONTEXT.md decisions
- Backend log patterns: MEDIUM — log messages verified in source code, but exact SSH/PM2 access pattern not confirmed (see Open Question 2)
- Simulator availability: HIGH — confirmed via `xcrun simctl list runtimes`; iOS 17/18 absence is a verified fact

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (stable — no fast-moving dependencies)
