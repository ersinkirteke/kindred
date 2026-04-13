---
phase: 30-avspeechclient-voice-tier-routing
plan: 03
subsystem: ui
tags: [tca, swiftui, avspeech, nowplaying, accessibility, voiceover, mpremotemandcenter]

# Dependency graph
requires:
  - phase: 30-02
    provides: VoicePlaybackReducer AVSpeech tier routing, isAVSpeechActive flag, avSpeechStepChanged action

provides:
  - StepTimelineView with onStepTapped callback and bold active step highlight
  - RecipeDetailView passes currentStepIndex + onStepTapped from playback state
  - AppReducer syncs currentStepIndex and isAVSpeechActive to RecipeDetailReducer
  - VoicePlaybackReducer jumpToStepRequested action routes tap-to-jump to AVSpeech
  - NowPlayingManager wired as TCA dependency, updates lock screen on currentPlayback change
  - MPRemoteCommandCenter set up in RootView.onAppear for lock screen controls
  - ExpandedPlayerView VoiceOver custom actions for speed/skip forward/backward
  - VoiceOver step transition announcements via UIAccessibility.post in StepTimelineView

affects:
  - 30-04 (final integration + Phase 32 hardware verification)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NowPlayingManager as TCA DependencyKey with shared singleton"
    - "AppReducer syncs derived state (currentStepIndex, isAVSpeechActive) to child reducer state"
    - "Delegate action pattern for cross-module routing (RecipeDetailReducer.Delegate.jumpToStep)"

key-files:
  created: []
  modified:
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/StepTimelineView.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/Player/ExpandedPlayerView.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/NowPlaying/NowPlayingManager.swift
    - Kindred/Sources/App/AppReducer.swift
    - Kindred/Sources/App/RootView.swift

key-decisions:
  - "NowPlaying metadata updated via onChange(of: currentPlayback) in VoicePlaybackReducer — single wiring point for both AVSpeech and AVPlayer"
  - "MPRemoteCommandCenter setup in RootView.onAppear — once on app launch, idempotent"
  - "currentStepIndex synced to RecipeDetailReducer.State via AppReducer for RecipeDetailView access"
  - "ElevenLabs tap-to-jump uses stepTimestamps array index directly (no StepSyncEngine reverse lookup needed)"
  - "AVSpeech artwork intentionally nil in NowPlaying (no recipe image needed for TTS-only playback)"

patterns-established:
  - "Child reducer state fields (currentStepIndex, isAVSpeechActive) populated by parent AppReducer sync on every voicePlayback action"
  - "Tap-to-jump routes: RecipeDetailView tap -> RecipeDetailReducer.jumpToStep -> delegate -> AppReducer -> voicePlayback.jumpToStepRequested (AVSpeech) or seekTo (AVPlayer)"

requirements-completed:
  - VOICE-02
  - VOICE-05

# Metrics
duration: 9min
completed: 2026-04-13
---

# Phase 30 Plan 03: Step Highlighting + Tap-to-Jump + NowPlaying Summary

**StepTimelineView with tap-to-jump + bold active step, NowPlayingManager wired to lock screen with Kindred Voice metadata, VoiceOver custom actions on expanded player**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-13T11:37:04Z
- **Completed:** 2026-04-13T11:46:21Z
- **Tasks:** 1 of 2 (Task 2 is human-verify checkpoint — awaiting device verification)
- **Files modified:** 8

## Accomplishments
- StepTimelineView enhanced: bold text on active step, tap-to-jump callback (only active during narration), VoiceOver hint + custom action, step transition UIAccessibility announcements
- RecipeDetailView wired to pass `currentStepIndex` and `onStepTapped` closure from playback state; AppReducer now syncs both `currentStepIndex` and `isAVSpeechActive` fields to RecipeDetailReducer
- VoicePlaybackReducer: `jumpToStepRequested(Int)` action added, routes to `avSpeechClient.jumpToStep`; `NowPlayingManager` wired as TCA dependency and called in `onChange(of: \.currentPlayback)` to update lock screen metadata on every playback change
- NowPlayingManager made `@unchecked Sendable`, added `shared` singleton, added `DependencyKey` conformance
- MPRemoteCommandCenter set up once in `RootView.onAppear` with correct TCA action dispatch callbacks
- ExpandedPlayerView: VoiceOver custom actions for "Change speed", "Skip forward", "Skip backward"

## Task Commits

1. **Task 1: Wire step highlighting, tap-to-jump, NowPlaying, accessibility** - `8c3a8c3` (feat)

## Files Created/Modified
- `StepTimelineView.swift` - onStepTapped callback, bold active step text, VoiceOver hint/action, step announcement
- `RecipeDetailView.swift` - StepTimelineView call passes currentStepIndex and onStepTapped
- `RecipeDetailReducer.swift` - currentStepIndex + isAVSpeechActive state; jumpToStep action; Delegate.jumpToStep(Int)
- `VoicePlaybackReducer.swift` - jumpToStepRequested action; nowPlayingManager dependency; NowPlaying update in onChange
- `ExpandedPlayerView.swift` - VoiceOver accessibilityAction for speed/skip
- `NowPlayingManager.swift` - shared singleton, @unchecked Sendable, DependencyKey conformance
- `AppReducer.swift` - sync currentStepIndex + isAVSpeechActive to RecipeDetailReducer; route Delegate.jumpToStep
- `RootView.swift` - MPRemoteCommandCenter setup in onAppear

## Decisions Made
- NowPlaying artwork is `nil` for AVSpeech playback — Kindred Voice has no dedicated artwork, and the plan explicitly states no artwork URL needed; recipe image not loaded for TTS
- Remote commands set up in `RootView.onAppear` rather than reducer — cleanest way to give the command callbacks access to the TCA store reference

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] NowPlayingManager had no DependencyKey / was never called**
- **Found during:** Task 1 (NowPlayingManager wiring)
- **Issue:** NowPlayingManager existed but was never called anywhere in the codebase — lock screen would show nothing
- **Fix:** Added DependencyKey conformance, shared singleton, @unchecked Sendable; wired via `@Dependency(\.nowPlayingManager)` in VoicePlaybackReducer; called in `onChange(of: \.currentPlayback)`
- **Files modified:** NowPlayingManager.swift, VoicePlaybackReducer.swift
- **Verification:** Build succeeded
- **Committed in:** 8c3a8c3

**2. [Rule 2 - Missing Critical] MPRemoteCommandCenter never configured — lock screen controls non-functional**
- **Found during:** Task 1 (NowPlayingManager.setupRemoteCommands review)
- **Issue:** setupRemoteCommands was defined but never called; lock screen play/pause buttons would do nothing
- **Fix:** Called setupRemoteCommands once in RootView.onAppear with TCA store action dispatch closures
- **Files modified:** RootView.swift
- **Verification:** Build succeeded
- **Committed in:** 8c3a8c3

---

**Total deviations:** 2 auto-fixed (both Rule 2 - missing critical functionality)
**Impact on plan:** Both auto-fixes essential for lock screen functionality. No scope creep.

## Issues Encountered
- `StepSyncEngine` has no reverse lookup (`timestamp(forStep:)`) — used direct `stepTimestamps[stepIndex]` array index for ElevenLabs tap-to-jump instead

## Next Phase Readiness
- All Phase 30 Plans 01-03 code complete; awaiting human verification on real device (Task 2 checkpoint)
- Phase 30 Plan 04 (if any) or Phase 32 hardware verification is next

---
*Phase: 30-avspeechclient-voice-tier-routing*
*Completed: 2026-04-13*
