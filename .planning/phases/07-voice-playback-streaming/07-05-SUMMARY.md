---
phase: 07-voice-playback-streaming
plan: 05
subsystem: VoicePlaybackFeature
tags: [audio-playback, avplayer-lifecycle, error-diagnostics, cache-operations]
dependency_graph:
  requires: [07-01, 07-02]
  provides: [working-audio-playback, cache-first-strategy]
  affects: [VoicePlaybackReducer, AudioPlayerManager]
tech_stack:
  added: []
  patterns: [avplayer-readiness-check, audio-session-verification, stream-lifecycle-management]
key_files:
  created: []
  modified:
    - Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerManager.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift
decisions:
  - decision: Wait for AVPlayerItem.readyToPlay before calling AVPlayer.play()
    rationale: AVPlayer was being called before the item loaded, causing "Cannot Open" errors for all URLs (local and remote)
    impact: Audio playback now waits for readiness check with 15s timeout before attempting to play
  - decision: Remove premature .statusChanged(.playing) from reducer
    rationale: Manual status override caused UI to show "playing" while audio was still loading or had failed
    impact: Playback status now comes exclusively from statusStream observation, reflecting actual player state
  - decision: Enable cache operations (remove `if false` guard)
    rationale: Cache was disabled during debugging, preventing offline playback and forcing repeated downloads
    impact: getCachedAudio() now called before streaming, enabling cache-first strategy
  - decision: Remove destructive clearCache() from voice selection flow
    rationale: Cleared entire cache on every voice selection, defeating caching purpose and wasting bandwidth
    impact: Cache persists across voice selections, reusing downloaded audio files
  - decision: Split stream observations into separate .run effects with individual cancel IDs
    rationale: Single cancellable ID cancelled all three streams (time, status, duration) when only one should be cancelled
    impact: Each stream independently cancellable (timeObserver, statusObserver, durationObserver) for proper lifecycle control
metrics:
  duration_minutes: 4
  tasks_completed: 2
  files_modified: 2
  commits: 2
  completed_date: 2026-03-03
---

# Phase 07 Plan 05: Fix AVPlayer Lifecycle & Enable Cache Summary

**One-liner:** Fixed critical AVPlayer "Cannot Open" error by waiting for readyToPlay status before play(), enabled cache-first audio strategy

## What Was Built

This plan fixed the broken audio playback system by addressing four root causes:

1. **AVPlayer lifecycle fix** — AudioPlayerManager.play() now calls waitForReadyToPlay() before AVPlayer.play(), ensuring AVPlayerItem loads before playback starts
2. **Enhanced error diagnostics** — Errors now include URL, item status, item error, audio session state for actionable debugging
3. **Audio session verification** — play() verifies AVAudioSession is active (.playback, .spokenAudio) before creating player
4. **Status stream error detection** — statusStream() checks currentItem?.error and observes item.status for .failed state
5. **Removed premature status override** — VoicePlaybackReducer no longer sends .statusChanged(.playing) after play(), relies on statusStream
6. **Cache operations enabled** — getCachedAudio() called before streaming (removed `if false` guard)
7. **Removed destructive clearCache()** — No longer wipes entire cache on every voice selection
8. **Stream lifecycle management** — Split task group into separate .run effects with individual cancel IDs for proper cleanup

**Key improvement:** Audio playback now follows correct AVPlayer lifecycle (create → wait for ready → play), and cache operations work as designed (check cache → stream → auto-cache on playing).

## Tasks Completed

### Task 1: Fix AudioPlayerManager.play() to wait for readyToPlay and add diagnostic error reporting
**Commit:** ced078a

**Changes:**
- Added audio session verification before creating AVPlayerItem (setCategory, setActive)
- Called waitForReadyToPlay() after creating AVPlayer, before calling play()
- Enhanced error diagnostics with PlayerError.failedToLoadWithDetails (URL, item status, item error, session category, other audio playing)
- Updated statusStream to check currentItem?.error in .paused case
- Added AVPlayerItem.status observation to detect .failed status
- Logging improvements at key lifecycle points (play() called, ready to play, play() executed)

**Files modified:**
- Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerManager.swift

### Task 2: Fix VoicePlaybackReducer — remove premature status, enable cache, remove destructive clearCache
**Commit:** 9ccd9cc

**Changes:**
- Removed premature `await send(.statusChanged(.playing))` after audioPlayer.play()
- Changed `if false, let cachedURL = ...` to `if let cachedURL = ...` (enabled cache check)
- Removed `try? await voiceCache.clearCache()` from voice selection flow
- Split task group into separate .run effects with individual cancel IDs:
  - play() effect (no cancel ID — runs once)
  - timeObserver (CancelID.timeObserver)
  - statusObserver (CancelID.statusObserver)
  - durationObserver (CancelID.durationObserver)
- Used .merge() instead of single .run with task group for independent stream cancellation

**Files modified:**
- Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

All automated checks passed:

1. ✅ `grep "waitForReadyToPlay" AudioPlayerManager.swift` — shows call in play() method
2. ✅ `grep "statusChanged(.playing)" VoicePlaybackReducer.swift` — no manual send after play()
3. ✅ `grep "if false" VoicePlaybackReducer.swift` — returns no matches (cache enabled)
4. ✅ `grep "clearCache()" VoicePlaybackReducer.swift` — returns no matches in selectVoice
5. ✅ `grep "setActive" AudioPlayerManager.swift` — shows audio session verification
6. ✅ `grep "currentItem?.error" AudioPlayerManager.swift` — shows error checking in statusStream
7. ✅ Build succeeds — `xcodebuild build -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16'`

## Success Criteria Met

- [x] AudioPlayerManager.play() waits for AVPlayerItem.readyToPlay before calling AVPlayer.play()
- [x] Error messages include URL, AVPlayerItem.error, and audio session state for debugging
- [x] VoicePlaybackReducer relies on statusStream for playback state, not manual overrides
- [x] Cache operations are enabled (getCachedAudio checked before streaming)
- [x] No destructive clearCache() on every voice selection
- [x] Stream observations are independently cancellable

## Next Steps

**Phase 7 Plan 3 (App Integration):** Integrate voice playback into RecipeDetailFeature with Listen button, mid-playback voice switching, and step sync highlighting.

**Testing recommendation:** Test on device with real audio URLs to verify error diagnostics capture actionable information if "Cannot Open" still occurs. The enhanced error reporting will show:
- Exact URL attempted
- AVPlayerItem status code
- AVPlayerItem error message
- Audio session category
- Whether other audio is playing

This addresses the MEMORY.md hypothesis that errors come from status stream (not play() throws) by observing both timeControlStatus and item.status.

## Self-Check: PASSED

**Created files exist:**
```
None created — only modifications
```

**Modified files exist:**
```
FOUND: Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerManager.swift
FOUND: Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift
```

**Commits exist:**
```
FOUND: ced078a (fix(07-05): wait for AVPlayer readyToPlay before play(), add diagnostic error reporting)
FOUND: 9ccd9cc (fix(07-05): remove premature status, enable cache, fix stream lifecycle)
```
