# Kindred v5.1 End-to-End Hardware Test Matrix

**Build Number:** 568
**Test Date:** 2026-04-14
**Device:** iPhone 16 Pro Max (iOS 26.3.1)
**Simulator:** iOS 26.x (iOS 17.0 and 18.x runtimes not installed — download via `xcodebuild -downloadPlatform iOS --version 17.0` / `--version 18.2` if needed)
**Backend:** api.kindredcook.app (production)
**Test Account:** ___

---

## Section A: Core Flows (Real Device — iPhone 16 Pro Max)

> All flows below are designed for real device testing. Delete the app and install fresh from TestFlight before starting Flow 1.

---

### Flow 1: Onboarding (fresh install)

> Pre-requisite: Delete app from device. Install build 568 from TestFlight.

- [ ] 1. Open app for the first time — verify onboarding screen appears (not feed)
- [ ] 2. Dietary preferences screen appears — select 2–3 preferences (e.g. Vegan, Gluten-Free)
- [ ] 3. Verify selected chips are visually highlighted/checked
- [ ] 4. Tap Continue — verify location selection screen appears
- [ ] 5. Tap "Use My Location" — verify iOS permission prompt appears
- [ ] 6. Allow location access — verify app detects a city (not "Unknown" or spinning forever)
- [ ] 7. Verify detected city is correct (or tap manual city picker to override)
- [ ] 8. Voice feature teaser appears — verify it is skippable or dismissable
- [ ] 9. Tap through/skip to end — verify feed screen loads with recipes

**FLOW 1 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### Flow 2: Browse Recipe Feed

- [ ] 1. Feed tab is active — verify recipe cards are visible
- [ ] 2. Scroll down — verify cards load smoothly without stutter
- [ ] 3. Verify at least one recipe card shows cook time and servings
- [ ] 4. Verify recipe cards show a hero image (not a broken placeholder)
- [ ] 5. Verify popularity badge or metadata is visible on recipe cards
- [ ] 6. Pull down to refresh — verify feed reloads new/updated content
- [ ] 7. Navigate away to another tab, then back to Feed — verify state is preserved

**FLOW 2 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### Flow 3: Recipe Detail + Source Attribution (ATTR-01)

- [ ] 1. Tap any recipe card — verify recipe detail screen opens
- [ ] 2. Verify hero image loads
- [ ] 3. Scroll through ingredients — verify list is readable and complete
- [ ] 4. Scroll through cooking steps — verify steps are numbered and readable
- [ ] 5. Scroll to bottom — verify "View original recipe" link is visible with source name (e.g. "View original on AllRecipes")
- [ ] 6. Tap the "View original recipe" link — verify it opens in Safari or in-app browser (not a crash)
- [ ] 7. Dismiss the browser — verify you are back on the recipe detail screen
- [ ] 8. Find a recipe where source URL is null (try a few cards) — verify "Powered by Spoonacular" fallback text renders instead of the link
- [ ] 9. Verify no raw URLs or nil values are visible anywhere in recipe detail

**FLOW 3 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### Flow 4: Voice Narration — Free Tier (VOICE-01, VOICE-02, VOICE-03, VOICE-04)

> Hardware only — AVSpeech requires real device. Ensure you are NOT subscribed (free tier).

- [ ] 1. Open any recipe detail screen
- [ ] 2. Tap the Play button — verify a synthetic (system TTS) voice begins narrating recipe steps
- [ ] 3. Verify the current cooking step is visually highlighted in sync with narration (VOICE-02)
- [ ] 4. While narrating, tap a different step — verify narration jumps to that step
- [ ] 5. Tap Pause — verify narration stops immediately
- [ ] 6. Tap Play again — verify narration resumes from where it stopped
- [ ] 7. Navigate to Feed tab while audio is playing — verify mini player is visible at bottom of screen
- [ ] 8. Verify audio continues playing while on Feed tab
- [ ] 9. Navigate to Search tab — verify mini player persists
- [ ] 10. Navigate to Profile tab — verify mini player persists across all tabs
- [ ] 11. Tap mini player — verify expanded player view opens
- [ ] 12. Trigger interruption: receive a phone call or notification sound — verify audio pauses gracefully (no crash)
- [ ] 13. Return to app — verify audio can be resumed (manually or automatically)
- [ ] 14. Put app in background for 10 seconds — return and verify playback state is intact (still shows current step, can resume)

**FLOW 4 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### Flow 5: Pantry Scan

> Hardware only — requires camera access.

- [ ] 1. Go to Pantry tab at the bottom
- [ ] 2. Tap camera icon to open pantry scanner
- [ ] 3. iOS camera permission prompt appears (or camera opens if already granted)
- [ ] 4. Point camera at ingredients, receipt, or food packaging
- [ ] 5. Verify items are detected and added to pantry list
- [ ] 6. Return to Feed tab — verify recipe cards show ingredient match percentage badges

**FLOW 5 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### Flow 6: Subscription (Free → Pro transition)

> Note: Reset sandbox subscription before starting if needed — Settings > App Store > Sandbox Account > Manage

- [ ] 1. Go to Profile tab — verify "Free tier" or equivalent status is shown
- [ ] 2. Tap "Upgrade to Pro" or subscription CTA — verify paywall screen appears
- [ ] 3. Verify paywall displays product name, price, and benefits list
- [ ] 4. Tap Subscribe — verify sandbox purchase sheet appears
- [ ] 5. Complete sandbox purchase — verify paywall dismisses automatically
- [ ] 6. Verify Profile tab now shows Pro subscription status
- [ ] 7. Return to Feed tab — verify ads are no longer shown
- [ ] 8. Verify no regression in feed or recipe browsing after subscription

**FLOW 6 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### Flow 4b: Voice Narration — Pro Tier (VOICE-04, VOICE-05)

> Pre-requisite: Complete Flow 6 first (user is subscribed to Pro tier).

- [ ] 1. Open any recipe detail screen
- [ ] 2. Tap Play — verify ElevenLabs cloned voice plays (distinct from system TTS, sounds human-like)
- [ ] 3. Verify playback controls work: play, pause, skip step forward, skip step back
- [ ] 4. Navigate across tabs while audio is playing — verify mini player persists (VOICE-04)
- [ ] 5. Stop ElevenLabs playback (tap Pause or dismiss player)
- [ ] 6. Open a different recipe and play it — verify clean audio session handoff (no stuttering, no dual audio, no crash) (VOICE-05)
- [ ] 7. Verify AVPlayer (ElevenLabs) and AVSpeech (system TTS) do not overlap or interfere

**FLOW 4b RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

## Section B: v5.1-Specific Tests (Real Device)

---

### B1: Search — Keyword Search (SEARCH-01, SEARCH-02)

- [ ] 1. Tap the Search tab or search bar in the feed
- [ ] 2. Type "pasta" — verify search results appear below the search bar
- [ ] 3. Verify search result cards use the SAME card layout as the popular feed (image, title, cook time, servings) (SEARCH-02)
- [ ] 4. Tap a search result card — verify recipe detail opens correctly
- [ ] 5. Tap Back — verify you return to search results (not reset)
- [ ] 6. Clear the search bar — verify results clear and feed/browse mode restores

**B1 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### B2: Search — Debounce Verification (SEARCH-03)

- [ ] 1. Type "chi" quickly — verify NO network request fires (less than 3 characters, no results shown)
- [ ] 2. Type "chic" — verify results appear only AFTER a short pause (300ms debounce delay)
- [ ] 3. Type quickly through a long query "chicken soup" — verify results appear AFTER you stop typing, not on every keystroke

Run all 10 queries sequentially (type each, wait for results, note result count):

| # | Query | Results Count | Pass/Fail |
|---|-------|---------------|-----------|
| 1 | `pasta` | ___ | [ ] |
| 2 | `chicken soup` | ___ | [ ] |
| 3 | `vegan chocolate cake` | ___ | [ ] |
| 4 | `salmon` | ___ | [ ] |
| 5 | `tacos` | ___ | [ ] |
| 6 | `quinoa salad` | ___ | [ ] |
| 7 | `bread` | ___ | [ ] |
| 8 | `stir fry` | ___ | [ ] |
| 9 | `mushroom risotto` | ___ | [ ] |
| 10 | `breakfast burrito` | ___ | [ ] |

**B2 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### B3: Search — Cache Verification

After completing the 10-query test above:

- [ ] 1. Search `pasta` again — note response time (should feel instant or very fast = cache hit)
- [ ] 2. Wait 5 seconds — search `pasta` once more
- [ ] 3. Results appear again — note if response was immediate

**Backend log verification** (SSH to production server):

```bash
# Using PM2:
pm2 logs kindred --lines 500 --nostream | grep -E "Searching recipes|stale cache|search failed"

# OR using journalctl (systemd):
journalctl -u kindred-backend --since "15 minutes ago" | grep -E "Searching recipes|stale cache|search failed"
```

Expected behavior:
- First `pasta` search: 1 Spoonacular API call visible in logs
- Second and third `pasta` searches: 0 Spoonacular calls (cache hits)
- Total Spoonacular calls across all 10 queries + 2 repeats: should be single-digit (most queries cached after first run)

SSH command used: ___
Log management (PM2 / journalctl): ___

- [ ] Cache working: second pasta search produced 0 Spoonacular API calls in logs
- [ ] Total Spoonacular calls across 12 queries: ___ (expected: single-digit)

**B3 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### B4: Dietary Filter Pass-Through (FILTER-01, FILTER-02)

- [ ] 1. Select "Vegan" dietary chip — search "cake"
- [ ] 2. Verify returned recipes are genuinely vegan (check recipe titles/descriptions)
- [ ] 3. Select "Gluten-Free" chip (deselect Vegan first) — search "bread"
- [ ] 4. Verify returned recipes are gluten-free
- [ ] 5. Verify "Gluten-Free" maps to `intolerances` param, not `diet` param — evidence: results should include non-vegan gluten-free recipes (e.g. bread with eggs is fine for GF, not for vegan) (FILTER-02)
- [ ] 6. Select both "Vegan" and "Gluten-Free" chips — search "cookies"
- [ ] 7. Verify results satisfy BOTH filters simultaneously
- [ ] 8. Clear all chips (tap each to deselect) — search "cookies" again
- [ ] 9. Verify results are now unfiltered (more results, includes non-vegan options)

**B4 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### B5: AVSpeech Compact Fallback (VOICE-03)

> Test on fresh TestFlight install without enhanced voices downloaded.
> Enhanced voices are in Settings > Accessibility > Spoken Content > Voices.

- [ ] 1. Play any recipe without downloading enhanced voices
- [ ] 2. Verify narration plays using the default/compact quality voice (no error, no silence)
- [ ] 3. Verify compact fallback voice is clear enough to follow recipe steps
- [ ] 4. Note: Enhanced voice quality is NOT expected on fresh install — compact fallback IS the success criterion

**B5 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

### B6: Return to Browse Mode

- [ ] 1. Enter search mode by typing a query (e.g. "pasta")
- [ ] 2. Tap Cancel button or clear the search bar completely
- [ ] 3. Verify popular feed restores (showing popular/location-based recipes, not search results)
- [ ] 4. Verify dietary chip selections are preserved after returning from search
- [ ] 5. Verify scroll position in feed is preserved (not reset to top)
- [ ] 6. If you had swiped past some cards before searching, verify those cards are not re-shown

**B6 RESULT: [ ] PASS  [ ] FAIL**
Notes: ___

---

## Section C: Simulator Flows (iOS 26.x)

> Skip Flow 4 (voice narration — hardware only) and Flow 5 (pantry scan — camera required) on Simulator.
> If iOS 17.0 or 18.x runtimes are available, run on those too.

### Simulator: iOS 26.x

| Flow | Name | Result |
|------|------|--------|
| Flow 1 | Onboarding | [ ] PASS  [ ] FAIL |
| Flow 2 | Browse Feed | [ ] PASS  [ ] FAIL |
| Flow 3 | Recipe Detail + Source Attribution | [ ] PASS  [ ] FAIL |
| Flow 6 | Subscription | [ ] PASS  [ ] FAIL |
| B1 | Search keyword | [ ] PASS  [ ] FAIL |
| B4 | Dietary filter | [ ] PASS  [ ] FAIL |

Notes: ___

---

### Simulator: iOS 17.0 (if runtime downloaded)

| Flow | Name | Result |
|------|------|--------|
| Flow 1 | Onboarding | [ ] PASS  [ ] FAIL  [ ] SKIP |
| Flow 2 | Browse Feed | [ ] PASS  [ ] FAIL  [ ] SKIP |
| Flow 3 | Recipe Detail + Source Attribution | [ ] PASS  [ ] FAIL  [ ] SKIP |
| Flow 6 | Subscription | [ ] PASS  [ ] FAIL  [ ] SKIP |
| B1 | Search keyword | [ ] PASS  [ ] FAIL  [ ] SKIP |
| B4 | Dietary filter | [ ] PASS  [ ] FAIL  [ ] SKIP |

Notes: ___

---

### Simulator: iOS 18.x (if runtime downloaded)

| Flow | Name | Result |
|------|------|--------|
| Flow 1 | Onboarding | [ ] PASS  [ ] FAIL  [ ] SKIP |
| Flow 2 | Browse Feed | [ ] PASS  [ ] FAIL  [ ] SKIP |
| Flow 3 | Recipe Detail + Source Attribution | [ ] PASS  [ ] FAIL  [ ] SKIP |
| Flow 6 | Subscription | [ ] PASS  [ ] FAIL  [ ] SKIP |
| B1 | Search keyword | [ ] PASS  [ ] FAIL  [ ] SKIP |
| B4 | Dietary filter | [ ] PASS  [ ] FAIL  [ ] SKIP |

Notes: ___

---

## Section D: Sign-Off

```
Build Number:    568
Test Date:       ___
Tester:          ___
Device:          iPhone 16 Pro Max (iOS 26.3.1)
Simulator OS(es): ___

Section A Results:
  Flow 1 (Onboarding):            PASS / FAIL
  Flow 2 (Browse Feed):           PASS / FAIL
  Flow 3 (Recipe Detail + ATTR):  PASS / FAIL
  Flow 4 (Voice - Free Tier):     PASS / FAIL
  Flow 5 (Pantry Scan):           PASS / FAIL
  Flow 6 (Subscription):          PASS / FAIL
  Flow 4b (Voice - Pro Tier):     PASS / FAIL

Section B Results:
  B1 (Search keyword):            PASS / FAIL
  B2 (Debounce):                  PASS / FAIL
  B3 (Cache verification):        PASS / FAIL
  B4 (Dietary filter):            PASS / FAIL
  B5 (AVSpeech compact fallback): PASS / FAIL
  B6 (Return to browse mode):     PASS / FAIL

Failures: (list any)
  -
  -

Notes: (any observations)
  -

Ready for App Store Submission: YES / NO
Signature: ___
```

---

## Appendix: Requirements Coverage

| Requirement | Test Section | Description |
|-------------|--------------|-------------|
| VOICE-01 | Flow 4 step 2 | Free tier uses system TTS (AVSpeech) |
| VOICE-02 | Flow 4 step 3 | Current step visually highlighted during narration |
| VOICE-03 | B5 | Compact voice fallback works without enhanced download |
| VOICE-04 | Flow 4 steps 7-11 | Mini player persists across tab navigation |
| VOICE-05 | Flow 4b step 6 | Clean handoff between ElevenLabs and AVSpeech sessions |
| SEARCH-01 | B1 | Keyword search returns relevant results |
| SEARCH-02 | B1 step 3 | Search results use same card layout as feed |
| SEARCH-03 | B2 | Debounce: no request on < 3 chars, 300ms delay |
| FILTER-01 | B4 steps 1-5 | Dietary chip selection filters search results |
| FILTER-02 | B4 step 5 | Gluten-Free maps to intolerances param (not diet) |
| ATTR-01 | Flow 3 steps 5-8 | Source attribution link + Spoonacular fallback |
