---
phase: 30-avspeechclient-voice-tier-routing
verified: 2026-04-13T12:45:00Z
status: passed
score: 15/15 must-haves verified
re_verification: false
---

# Phase 30: AVSpeechClient + Voice Tier Routing Verification Report

**Phase Goal:** Build AVSpeechClient TCA dependency, wire tier-based voice routing (free=Kindred Voice, Pro=ElevenLabs), update voice picker UI with sections
**Verified:** 2026-04-13T12:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | AVSpeechClient TCA dependency exists with all 9 required methods | VERIFIED | `AVSpeechClient.swift` has speak, pause, resume, stopSpeaking, jumpToStep, setRate, statusStream, stepIndexStream, cleanup — all `@Sendable` closures |
| 2  | AVSpeechManager wraps AVSpeechSynthesizer with delegate callbacks | VERIFIED | `AVSpeechManager.swift` is `@MainActor NSObject`, conforms to `AVSpeechSynthesizerDelegate`, all 5 delegate methods present |
| 3  | TextPreprocessor expands cooking abbreviations, fractions, strips HTML/markdown | VERIFIED | 6-stage pipeline: HTML strip, markdown strip, fraction expansion (½¼¾⅓⅔+more), abbrev expansion (tbsp/tsp/oz/lb/ml/g/kg/min), amount normalization, step prefix |
| 4  | iOS 17 silent failure detected via 5-second timeout with auto-retry and error state | VERIFIED | `startSilentFailureTimeout()` + `handleSilentFailure()` in `AVSpeechManager.swift` — 5s sleep, 1 retry, then `.error("Voice unavailable — Retry")` |
| 5  | No TTS voice installed yields specific error with Settings guidance | VERIFIED | `speak()` checks `AVSpeechSynthesisVoice.speechVoices().filter { langPrefix }` before enqueuing; empty → yields `.error("No voice installed — Go to Settings...")` |
| 6  | Enhanced voice quality preferred, compact fallback | VERIFIED | `preferredVoice()`: `.enhanced` first, `.default` second, `AVSpeechSynthesisVoice(language:)` fallback |
| 7  | Free-tier user auto-plays with Kindred Voice, no picker required | VERIFIED | `startPlayback` else-branch: `.send(.selectVoice("kindred-default"))` immediately + background subscription fetch; Pro picker shown only after `case .pro = status` |
| 8  | Pro user sees ElevenLabs path unchanged | VERIFIED | `selectVoice` branches at `if voiceId == "kindred-default"` — else path is existing ElevenLabs/AVPlayer code untouched |
| 9  | Voice picker has "Free" + "Pro Voices" sections with correct styling | VERIFIED | `VoicePickerView.swift`: `freeProfiles` / `sortedProProfiles` split; `sectionHeader()` helper; "Free" and "Pro Voices" headers present |
| 10 | Kindred Voice shows "On-device narration" subtitle and app icon avatar | VERIFIED | `VoiceCardView(isKindredVoice: true)`: `UIImage(named:"AppIcon")` avatar, `Text("On-device narration")` subtitle |
| 11 | Step index changes from AVSpeech update currentPlayback.currentStepIndex | VERIFIED | `avSpeechStepChanged(Int)` action + AppReducer syncs `currentStepIndex` to `RecipeDetailReducer.State` |
| 12 | Current step highlighted bold + accent bg, auto-scroll, tap-to-jump | VERIFIED | `StepTimelineView` has `onStepTapped` callback; `isCurrentStep` triggers bold + accent background; `onChange(of: currentStepIndex)` triggers `ScrollViewReader.scrollTo` |
| 13 | Lock screen shows "Kindred Voice" as artist for AVSpeech playback | VERIFIED | `NowPlayingManager.updateNowPlaying(artist: playback.speakerName)` called from `onChange(of: \.currentPlayback)`; AVSpeech `currentPlayback.speakerName = "Kindred Voice"` |
| 14 | Audio session deactivated cleanly before engine switch (VOICE-05) | VERIFIED | `AVSpeechManager.cleanup()` calls `AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)`; cross-engine transitions call cleanup before switching |
| 15 | Pro AVSpeech failure auto-fallbacks to ElevenLabs silently | VERIFIED | `statusChanged(.error)` handler: `if state.isAVSpeechActive, case .pro = state.subscriptionStatus` → `.send(.selectVoice(firstProVoiceId))` |

**Score:** 15/15 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechClient.swift` | TCA DependencyKey struct with @Sendable closures | VERIFIED | `DependencyKey` conformance, `liveValue` delegates to `AVSpeechManager.shared`, `testValue` no-ops, `DependencyValues` extension |
| `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechManager.swift` | @MainActor NSObject singleton with delegate, timeout, retry | VERIFIED | `@MainActor final class AVSpeechManager: NSObject`, `AVSpeechSynthesizerDelegate`, 5-second timeout, retry logic, rate mapping, language detection |
| `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/TextPreprocessor.swift` | Static enum with 6-stage preprocessing pipeline | VERIFIED | `expandAbbreviations`, `expandFractions`, `stripHTML`, `stripMarkdown`, `normalizeAmounts`, step prefix — all present |
| `Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift` | Branched reducer with AVSpeech + ElevenLabs paths | VERIFIED | `@Dependency(\.avSpeechClient)`, `isAVSpeechActive` flag, all actions branched; `+317/-53` lines |
| `Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePickerView.swift` | Sectioned view with Free/Pro headers | VERIFIED | "On-device narration" text present, `sectionHeader()` helper, `isKindredVoice` parameter |
| `Kindred/Packages/FeedFeature/Sources/RecipeDetail/StepTimelineView.swift` | Tap-to-jump callback + bold active step | VERIFIED | `onStepTapped: ((Int) -> Void)?`, bold text on `isCurrentStep`, VoiceOver hint, `UIAccessibility.post(notification: .announcement)` |
| `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift` | Passes currentStepIndex + onStepTapped from playback state | VERIFIED | `StepTimelineView(steps:, currentStepIndex: store.currentStepIndex, onStepTapped: store.isAVSpeechActive ? { ... }` |
| `Kindred/Packages/VoicePlaybackFeature/Sources/NowPlaying/NowPlayingManager.swift` | DependencyKey, shared singleton, lock screen updates | VERIFIED | `DependencyKey` conformance, `public static let shared`, `@unchecked Sendable`, `updateNowPlaying(title:artist:...)` |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AVSpeechClient.swift` | `AVSpeechManager.swift` | `liveValue` delegates to `AVSpeechManager.shared` | WIRED | All 9 methods delegate to `manager.*` calls on shared singleton |
| `AVSpeechManager.swift` | `PlaybackStatus` | `statusContinuation?.yield(PlaybackStatus)` | WIRED | `PlaybackStatus.playing/.paused/.stopped/.error(String)` yielded in all delegate methods |
| `VoicePlaybackReducer.swift` | `AVSpeechClient.swift` | `@Dependency(\.avSpeechClient)` injection | WIRED | Line 201: `@Dependency(\.avSpeechClient) var avSpeechClient` |
| `VoicePlaybackReducer.swift` | `TextPreprocessor.swift` | `TextPreprocessor.prepareSteps()` called before `speak()` | WIRED | Line 380: `let preprocessedSteps = TextPreprocessor.prepareSteps(state.recipeSteps)` |
| `VoicePlaybackReducer.swift` | `SubscriptionClient` | `subscriptionClient.currentEntitlement()` for routing | WIRED | Lines 298-302: subscription fetch in `startPlayback` else-branch |
| `RecipeDetailView.swift` | `StepTimelineView.swift` | `currentStepIndex` and `onStepTapped` parameters | WIRED | `StepTimelineView(steps:, currentStepIndex: store.currentStepIndex, onStepTapped: ...)` |
| `RecipeDetailView.swift` | `VoicePlaybackReducer.swift` | AppReducer syncs `currentStepIndex` + `isAVSpeechActive` | WIRED | `AppReducer.swift` lines 563-585: derived state sync on every voicePlayback action |
| `NowPlayingManager.swift` | `VoicePlaybackReducer.swift` | `onChange(of: \.currentPlayback)` calls `updateNowPlaying` | WIRED | Lines 1144-1167: `nowPlayingManager.updateNowPlaying(title: playback.recipeName, artist: playback.speakerName, ...)` |
| `RootView.swift` | `NowPlayingManager.swift` | `setupRemoteCommands` called in `.onAppear` | WIRED | Line 141-142: `NowPlayingManager.shared.setupRemoteCommands(...)` in `onAppear` |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| VOICE-01 | Plans 01, 02 | Free-tier user can listen via AVSpeechSynthesizer | SATISFIED | AVSpeechClient + AVSpeechManager built; `startPlayback` auto-routes free/unknown/guest to `kindred-default`; TextPreprocessor prepares steps |
| VOICE-02 | Plans 02, 03 | Narration plays step-by-step with current step highlighting | SATISFIED | `avSpeechStepChanged` action updates `currentPlayback.currentStepIndex`; `StepTimelineView` highlights active step with bold text + accent bg + auto-scroll |
| VOICE-03 | Plan 01 | Gracefully handles iOS 17 silent failure with retry/fallback | SATISFIED | 5-second timeout in `AVSpeechManager`, 1 auto-retry via `handleSilentFailure()`; Pro users get ElevenLabs fallback via reducer `statusChanged(.error)` handler |
| VOICE-04 | Plan 02 | Voice tier routing: AVSpeech for free, ElevenLabs for Pro | SATISFIED | `selectVoice("kindred-default")` routes to `avSpeechClient.speak()`; any other voiceId follows existing AVPlayer path; `isAVSpeechActive` flag routes all engine operations |
| VOICE-05 | Plans 01, 03 | Audio session handoff between AVSpeech and AVPlayer without corruption | SATISFIED | `AVSpeechManager.cleanup()` deactivates `AVAudioSession` with `.notifyOthersOnDeactivation`; cross-engine transitions in reducer call `avSpeechClient.cleanup()` before switching to AVPlayer |

No orphaned requirements — VOICE-06, VOICE-07, VOICE-08 are listed as deferred items in REQUIREMENTS.md and are not assigned to Phase 30.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `VoicePickerView.swift` | 270 | `.placeholder { }` | Info | Kingfisher image loading placeholder — legitimate UI pattern, not a stub |

No blocking or warning anti-patterns found.

---

## Human Verification Required

### 1. Free-tier narration end-to-end

**Test:** Open a recipe as a free-tier user, tap Listen/Play.
**Expected:** Mini player appears immediately showing "Kindred Voice", system TTS begins narrating recipe steps within ~1 second.
**Why human:** AVSpeech audio output cannot be verified programmatically; requires real device (Simulator may behave differently).

### 2. Step highlighting and tap-to-jump

**Test:** During narration, observe step list. Tap a step that is NOT the current step.
**Expected:** Active step is bold with accent background and visible in scroll view. Tapping a non-active step jumps narration to that step.
**Why human:** Visual styling + TCA action dispatch chain requires on-device confirmation.

### 3. Lock screen NowPlaying

**Test:** Start AVSpeech narration, lock the device.
**Expected:** Lock screen shows recipe name as title and "Kindred Voice" as artist. Play/pause buttons work.
**Why human:** MPNowPlayingInfoCenter cannot be inspected programmatically from test context.

### 4. iOS 17 silent failure (deferred to Phase 32)

**Test:** Run on real iOS 17.0-17.4 hardware.
**Expected:** If TTSErrorDomain -4010 occurs, error appears within 5 seconds with retry button.
**Why human:** TTSErrorDomain -4010 does not reproduce on Simulator or iOS 18+ hardware. Deferred to Phase 32 per PLAN.

### 5. Audio session handoff

**Test:** Play narration via AVSpeech, then switch to ElevenLabs voice (or let narration finish and play music app).
**Expected:** No audio glitches, corruption, or ducking artifacts on switch.
**Why human:** Audio session state cannot be verified programmatically.

---

## Commits

All changes are committed and verified in git:

| Commit | Plan | Description |
|--------|------|-------------|
| `4e4f38e` | 01 Task 1 | Create AVSpeechClient and AVSpeechManager |
| `b02d335` | 01 Task 2 | Create TextPreprocessor |
| `eadf094` | 02 Task 1 | Branch VoicePlaybackReducer for AVSpeech tier routing |
| `3568b0e` | 02 Task 2 | Update VoicePickerView with Free/Pro sections |
| `8c3a8c3` | 03 Task 1 | Wire step highlighting, tap-to-jump, NowPlaying, accessibility |
| `bf80286` | 03 Task 2 | Device verification fixes (6 functional issues resolved) |

---

## Summary

All 15 observable truths verified. All 8 required artifacts exist and are substantive. All 9 key links are wired. All 5 requirement IDs (VOICE-01 through VOICE-05) are satisfied with direct implementation evidence. No blocking anti-patterns found.

The phase goal is achieved: AVSpeechClient TCA dependency is built and wired, tier-based voice routing functions (free users auto-play with Kindred Voice via AVSpeech, Pro users use ElevenLabs via AVPlayer), and the voice picker shows sectioned Free/Pro layout with Kindred Voice customization.

Automated verification status: **PASSED** (15/15).
Human verification items flagged: 5 items (audio output quality, visual styling, lock screen, iOS 17 hardware, audio handoff) — these are correctness confirmations, not blockers.

---

_Verified: 2026-04-13T12:45:00Z_
_Verifier: Claude (gsd-verifier)_
