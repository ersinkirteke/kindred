---
phase: 30-avspeechclient-voice-tier-routing
plan: 01
subsystem: ui
tags: [avspeech, tts, ios, tca, dependencies, voice-playback]

# Dependency graph
requires:
  - phase: 28-fastlane-release-automation
    provides: VoicePlaybackFeature package with AudioPlayerClient pattern to mirror
  - phase: 29-source-attribution-wiring
    provides: clean codebase baseline before free-tier TTS work
provides:
  - AVSpeechClient TCA dependency for free-tier TTS narration
  - AVSpeechManager backing class with delegate, timeout, retry
  - TextPreprocessor cooking abbreviation/fraction expansion pipeline
affects: [30-avspeechclient-voice-tier-routing plan 02, VoicePlaybackReducer tier routing]

# Tech tracking
tech-stack:
  added: [AVFoundation (AVSpeechSynthesizer)]
  patterns: [TCA dependency injection via DependencyKey, @MainActor singleton manager, AsyncStream for status/step events]

key-files:
  created:
    - Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechClient.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechManager.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/TextPreprocessor.swift
  modified: []

key-decisions:
  - "Rate mapping: app 1.0x maps to AVSpeech 0.50 (default), 0.5x to 0.35, 2.0x to 0.65 — linear interpolation across 0.35-0.65 range"
  - "setRate mid-playback stops and re-enqueues from currentStepIndex because AVSpeechSynthesizer cannot change rate on queued utterances"
  - "iOS 17 silent failure: 5-second timeout, 1 auto-retry, then error yielded to reducer which owns tier-aware fallback logic"
  - "TextPreprocessor uses (?m) inline regex flag for multi-line markdown stripping (anchorsMatchLines not available in Swift String.CompareOptions)"

patterns-established:
  - "AVSpeechClient: same DependencyKey/liveValue/testValue/DependencyValues pattern as AudioPlayerClient"
  - "AVSpeechManager: @preconcurrency import AVFoundation + nonisolated delegate methods dispatching to MainActor via Task"
  - "TextPreprocessor: static enum with compiled-pattern pipeline ordered HTML→markdown→fractions→abbrev→amounts→prefix"

requirements-completed: [VOICE-01, VOICE-03]

# Metrics
duration: 9min
completed: 2026-04-13
---

# Phase 30 Plan 01: AVSpeechClient & TextPreprocessor Summary

**AVSpeechSynthesizer TCA dependency client with iOS-17-safe silent-failure retry, language-aware voice selection, and cooking-recipe text preprocessing pipeline**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-13T11:04:09Z
- **Completed:** 2026-04-13T11:13:00Z
- **Tasks:** 2
- **Files modified:** 3 (created)

## Accomplishments
- `AVSpeechClient` TCA dependency with full speak/pause/resume/stop/jumpToStep/setRate/statusStream/stepIndexStream/cleanup interface — mirrors `AudioPlayerClient` pattern exactly
- `AVSpeechManager` @MainActor singleton: AVSpeechSynthesizer lifecycle management, delegate callbacks to AsyncStream continuations, 5-second silent failure timeout with 1 auto-retry, no-TTS-voice detection before utterance enqueue
- `TextPreprocessor` 6-stage pipeline: HTML strip, markdown strip, Unicode fraction expansion (½ ¼ ¾ ⅓ ⅔ and more), cooking abbreviation expansion (tbsp/tsp/oz/lb/ml/g/kg/min), amount normalization (ranges and approximations), step number prefix

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AVSpeechClient dependency and AVSpeechManager** - `4e4f38e` (feat)
2. **Task 2: Create TextPreprocessor for cooking abbreviation expansion** - `b02d335` (feat)

## Files Created/Modified
- `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechClient.swift` - TCA DependencyKey struct with @Sendable closures delegating to AVSpeechManager.shared
- `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/AVSpeechManager.swift` - @MainActor NSObject singleton owning AVSpeechSynthesizer with full delegate, timeout, retry, rate mapping, voice selection
- `Kindred/Packages/VoicePlaybackFeature/Sources/AVSpeech/TextPreprocessor.swift` - Static enum preprocessing pipeline for TTS-friendly recipe step text

## Decisions Made
- Rate mapping uses linear interpolation: `0.35 + ((appSpeed - 0.5) / 1.5) * 0.30`, placing app 1.0x at AVSpeech default 0.5
- `setRate` stops and re-enqueues from `currentStepIndex` because AVSpeechSynthesizer cannot change rate mid-queue
- Silent failure handling is in manager (5-sec timeout + 1 retry); tier-aware ElevenLabs fallback is the reducer's responsibility in Plan 02
- `@preconcurrency import AVFoundation` + `nonisolated` delegate methods dispatching via `Task { @MainActor in }` handles Swift 6 concurrency for NSObject delegate pattern

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed unavailable `anchorsMatchLines` option in Swift String.CompareOptions**
- **Found during:** Task 2 (TextPreprocessor compilation)
- **Issue:** Used `.anchorsMatchLines` in `replacingOccurrences` options, but this option does not exist in Swift's `String.CompareOptions` (only in `NSRegularExpression.Options`)
- **Fix:** Replaced with `(?m)` inline regex multiline mode flag in the pattern strings
- **Files modified:** `TextPreprocessor.swift`
- **Verification:** Build succeeded after fix
- **Committed in:** b02d335 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Minor fix required for regex multiline mode in Swift. No scope change.

## Issues Encountered
- `swift build --package-path` returns platform-compatibility errors for iOS-only packages built on macOS — this is expected. The correct verification is `xcodebuild -project Kindred.xcodeproj -scheme Kindred` which builds the full iOS target. Build succeeded.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 30-02 can proceed: AVSpeechClient + TextPreprocessor are the complete foundation for VoicePlaybackReducer tier routing
- iOS 17 silent failure still requires real device testing (Simulator does not reproduce TTSErrorDomain -4010) — flagged as a known concern in STATE.md

---
*Phase: 30-avspeechclient-voice-tier-routing*
*Completed: 2026-04-13*
