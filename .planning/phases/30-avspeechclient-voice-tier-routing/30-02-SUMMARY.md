---
phase: 30-avspeechclient-voice-tier-routing
plan: 02
subsystem: ui
tags: [avspeech, tts, ios, tca, voice-picker, tier-routing, free-tier]

# Dependency graph
requires:
  - phase: 30-avspeechclient-voice-tier-routing plan 01
    provides: AVSpeechClient TCA dependency + TextPreprocessor
  - VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift (existing ElevenLabs path)
provides:
  - Branched VoicePlaybackReducer routing "kindred-default" to AVSpeechClient + ElevenLabs to AVPlayer
  - Sectioned VoicePickerView with Free/Pro headers and Kindred Voice customization
affects: [30-03 (MiniPlayerView offline fallback note UI), 30-04 (end-to-end testing)]

# Tech tracking
tech-stack:
  added: [Network framework (NWPathMonitor for offline detection)]
  patterns: [isAVSpeechActive flag as engine routing switch, cancellable stream separation per engine]

key-files:
  created: []
  modified:
    - Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePickerView.swift

key-decisions:
  - "Free/unknown/guest users auto-play with kindred-default on first play (no picker shown)"
  - "Pro users see voice picker on first play (existing behavior preserved)"
  - "isAVSpeechActive flag routes play/pause/cycleSpeed/dismiss/showVoiceSwitcher to correct engine"
  - "Pro user AVSpeech error auto-fallbacks to first Pro ElevenLabs voice silently"
  - "Offline + uncached Pro voice falls back to Kindred Voice with offlineFallbackNote string"
  - "NWPathMonitor used inline in .run effect for offline detection (no new dependency)"

# Metrics
duration: 11min
completed: 2026-04-13
---

# Phase 30 Plan 02: VoicePlaybackReducer Tier Routing + VoicePickerView Sections Summary

**AVSpeech tier routing wired into VoicePlaybackReducer with isAVSpeechActive engine flag and VoicePickerView restructured into Free/Pro sections with Kindred Voice on-device narration branding**

## Performance

- **Duration:** 11 min
- **Started:** 2026-04-13T11:20:08Z
- **Completed:** 2026-04-13T11:31:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `VoicePlaybackReducer`: `@Dependency(\.avSpeechClient)` injected alongside existing `audioPlayerClient`
- New CancelIDs `avSpeechStepObserver` / `avSpeechStatusObserver` separate from AVPlayer cancel IDs
- New State fields: `isAVSpeechActive: Bool` (engine routing flag), `offlineFallbackNote: String?`
- New actions: `avSpeechStepChanged(Int)`, `showVoicePickerForNewPlayback`, `offlineFallbackToKindredVoice`
- `selectVoice("kindred-default")`: cancels AVPlayer streams, starts AVSpeech with TextPreprocessor-prepared steps, observes status + step streams
- `startPlayback` else-branch: fetches subscription status + voice profiles, then routes — free/unknown/guest auto-select kindred-default; Pro shows picker
- `play`/`pause`/`cycleSpeed` all branch on `isAVSpeechActive` to call correct engine
- `dismiss`/`showVoiceSwitcher`: cancel correct stream set and call correct cleanup
- `switchVoiceMidPlayback`: handles TO-kindred-default and FROM-kindred-default cross-engine transitions
- `statusChanged(.stopped)`: cancels correct observers per active engine
- `statusChanged(.error)` + currentPlayback `.error` guard: Pro AVSpeech error silently falls back to first ElevenLabs voice
- ElevenLabs path: `NWPathMonitor` inline offline check before network fetch; offline + uncached sends `.offlineFallbackToKindredVoice`
- `VoicePickerView`: flat `ForEach` replaced with `freeProfiles` / `sortedProProfiles` sections
- `sectionHeader()` helper renders title in `.kindredCaption()` + `.kindredTextSecondary`, uppercased, with `.isHeader` accessibility trait
- `VoiceCardView` gains `isKindredVoice` parameter — renders app icon avatar (`UIImage(named:"AppIcon")` with waveform fallback) and "On-device narration" subtitle
- Accessibility: Kindred Voice labeled "Free voice"; locked Pro voices labeled "Pro voice, locked"
- Updated previews: Free user view (locked Pro voices) + Pro user view

## Task Commits

1. **Task 1: Branch VoicePlaybackReducer for AVSpeech tier routing** - `eadf094` (feat)
2. **Task 2: Update VoicePickerView with section headers and Kindred Voice customization** - `3568b0e` (feat)

## Files Created/Modified

- `Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift` — +317/-53 lines: AVSpeechClient dependency, engine routing, all action handlers branched on isAVSpeechActive
- `Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePickerView.swift` — +158/-20 lines: Free/Pro sections, Kindred Voice avatar, sectionHeader helper, accessibility labels

## Decisions Made

- `isAVSpeechActive` is the canonical engine routing flag; set to `true` in `selectVoice("kindred-default")`, `false` in all cleanup paths
- `NWPathMonitor` used inline in `.run` effect (no persistent monitor needed; one-shot offline check)
- `offlineFallbackNote` is reducer State (not local var) so MiniPlayerView can display it as a transient UI note in Plan 03
- `showVoicePickerForNewPlayback` action exists to decouple the async subscription fetch from the sync state mutation that shows the picker

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed SubscriptionStatus.pro pattern matching**
- **Found during:** Task 1 (first build)
- **Issue:** `state.subscriptionStatus == .pro` does not compile because `.pro` has associated values `(expiresDate: Date, isInGracePeriod: Bool)` — equality comparison fails
- **Fix:** Replaced with `case .pro = state.subscriptionStatus` pattern in `if` guards; `switch status { case .pro: }` already worked correctly
- **Files modified:** `VoicePlaybackReducer.swift`
- **Committed in:** eadf094 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Single pattern-match fix, no scope change.

## Issues Encountered

- `swift build --package-path` returns platform-compatibility errors for iOS-only packages built on macOS — expected, confirmed in Plan 01 SUMMARY. Correct verification is `xcodebuild -project Kindred.xcodeproj -scheme Kindred`. Build succeeded.

## Self-Check: PASSED

- `eadf094` exists in git log: confirmed
- `3568b0e` exists in git log: confirmed
- `VoicePlaybackReducer.swift` contains `@Dependency(\.avSpeechClient)`: confirmed
- `VoicePlaybackReducer.swift` contains `avSpeechClient`: confirmed
- `VoicePickerView.swift` contains `On-device narration`: confirmed
- `VoicePickerView.swift` contains `Pro Voices` section header: confirmed

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 30-03 can proceed: MiniPlayerView needs `offlineFallbackNote` toast UI and AVSpeech step indicator
- Plan 30-04 (end-to-end testing) requires real iOS 17 hardware for silent failure TTSErrorDomain -4010 validation

---
*Phase: 30-avspeechclient-voice-tier-routing*
*Completed: 2026-04-13*
