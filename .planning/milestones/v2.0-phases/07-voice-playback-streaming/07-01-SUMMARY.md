---
phase: 07-voice-playback-streaming
plan: 01
type: execute
wave: 1
subsystem: voice-playback-infrastructure
tags: [voice, audio-playback, tca-dependencies, avplayer, cache, lru-eviction]
dependency_graph:
  requires: []
  provides:
    - VoicePlaybackFeature package (AudioPlayerClient, VoiceCacheClient, StepSyncEngine)
    - PlaybackState models (PlaybackStatus, PlaybackSpeed, CurrentPlayback)
    - Domain models (VoiceProfile, NarrationMetadata, CacheEntry)
  affects:
    - Plan 07-02 (player UI will consume AudioPlayerClient and PlaybackState)
    - Plan 07-03 (app integration will use VoiceCacheClient)
    - Plan 07-04 (system controls will integrate with AudioPlayerClient)
tech_stack:
  added:
    - AVFoundation (AVPlayer for audio streaming)
    - TCA Dependencies pattern for testable clients
    - FileManager.cachesDirectory for audio caching
    - UserDefaults for cache metadata persistence
  patterns:
    - TCA @DependencyClient pattern with liveValue and testValue
    - Actor-based AudioPlayerManager for thread-safe AVPlayer management
    - LRU cache eviction with binary search for timestamp-to-step mapping
    - AsyncStream for reactive playback state updates
key_files:
  created:
    - Kindred/Packages/VoicePlaybackFeature/Package.swift (SPM package definition)
    - Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerClient.swift (TCA dependency)
    - Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerManager.swift (AVPlayer wrapper)
    - Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/PlaybackState.swift (playback state models)
    - Kindred/Packages/VoicePlaybackFeature/Sources/VoiceCache/VoiceCacheClient.swift (TCA dependency)
    - Kindred/Packages/VoicePlaybackFeature/Sources/VoiceCache/LRUCache.swift (disk cache with LRU eviction)
    - Kindred/Packages/VoicePlaybackFeature/Sources/VoiceCache/CacheEntry.swift (cache metadata model)
    - Kindred/Packages/VoicePlaybackFeature/Sources/StepSync/StepSyncEngine.swift (timestamp-to-step mapping)
    - Kindred/Packages/VoicePlaybackFeature/Sources/Models/VoiceProfile.swift (voice domain model)
    - Kindred/Packages/VoicePlaybackFeature/Sources/Models/NarrationMetadata.swift (narration domain model)
  modified: []
decisions:
  - decision: "Use AVPlayer (not AVAudioPlayer) for streaming capability"
    rationale: "AVPlayer supports HTTP streaming, progressive download, and adaptive bitrates"
    alternatives: "AVAudioPlayer requires full file download"
  - decision: "Actor-based AudioPlayerManager for thread safety"
    rationale: "AVPlayer requires main queue access, actor ensures safe async/await usage"
    alternatives: "@MainActor annotation, but actor provides better isolation"
  - decision: "Store timeObserverToken and remove in cleanup() to prevent memory leaks"
    rationale: "Per research pitfall 1, failing to remove observer causes retain cycles"
    alternatives: "None - this is a requirement"
  - decision: "Set rate AFTER play() call, not before"
    rationale: "Per research pitfall, setting rate before play() is ignored by AVPlayer"
    alternatives: "None - this is an AVPlayer API requirement"
  - decision: "Use .cachesDirectory (not .documentDirectory) for audio files"
    rationale: "Per research anti-pattern, caches directory is correct for ephemeral data"
    alternatives: ".documentDirectory would persist across app updates and show in Files app"
  - decision: "Binary search O(log n) for timestamp-to-step mapping"
    rationale: "Per research Don't Hand-Roll, efficient algorithm for sorted timestamps"
    alternatives: "Linear search would be O(n) and degrade with many steps"
  - decision: "File naming: {voiceId}_{recipeId}.m4a for per-voice-per-recipe caching"
    rationale: "Supports multiple voices cached for same recipe per user decision"
    alternatives: "Single voice per recipe would limit flexibility"
  - decision: "500MB cache limit with LRU eviction"
    rationale: "Balances storage with user experience, matches Kingfisher image cache strategy"
    alternatives: "Smaller limit would cause more re-downloads, larger would consume storage"
metrics:
  tasks_completed: 2
  files_created: 10
  loc_added: 726
  duration_minutes: 3
  completed_at: "2026-03-03T07:52:36Z"
---

# Phase 07 Plan 01: VoicePlaybackFeature Foundation Infrastructure Summary

**One-liner:** Created VoicePlaybackFeature SPM package with AVPlayer-based streaming client, 500MB LRU disk cache, and O(log n) step sync engine—providing all TCA dependency contracts for voice playback UI, app integration, and system controls.

## What Was Built

Built the complete foundation infrastructure for voice narration playback in a new VoicePlaybackFeature SPM package. This "contracts first" layer provides three core TCA dependencies:

1. **AudioPlayerClient** - TCA dependency wrapping AVPlayer for HTTP audio streaming with async streams for playback time, status, and duration updates
2. **VoiceCacheClient** - TCA dependency for disk-based audio caching with LRU eviction at 500MB limit
3. **StepSyncEngine** - Pure function using binary search to map playback timestamps to recipe step indices

All clients follow TCA @DependencyClient pattern with liveValue and testValue implementations. Domain models (VoiceProfile, NarrationMetadata, PlaybackState) are public, Equatable, and Sendable.

**Critical implementation details:**
- AudioPlayerManager is an actor wrapping AVPlayer with proper observer cleanup (timeObserverToken stored and removed in cleanup())
- Rate changes require play() call FIRST, then set rate (AVPlayer API requirement)
- Cache uses .cachesDirectory (not .documentDirectory) per iOS best practices
- Cache metadata persisted via UserDefaults with JSON encoding for LRU tracking
- StepSyncEngine uses binary search for O(log n) performance on sorted timestamps

## Deviations from Plan

None - plan executed exactly as written. All 10 files created with correct dependencies, patterns, and infrastructure.

## Tasks Completed

| Task | Commit | Files | Duration |
|------|--------|-------|----------|
| Task 1: Create VoicePlaybackFeature package with AudioPlayerClient and PlaybackState models | e9731f6 | 6 files (Package.swift, AudioPlayerClient, AudioPlayerManager, PlaybackState, VoiceProfile, NarrationMetadata) | 2 min |
| Task 2: Create VoiceCacheClient with LRU eviction and StepSyncEngine | 9a98ba2 | 4 files (VoiceCacheClient, LRUCache, CacheEntry, StepSyncEngine) | 1 min |

**Total:** 2 tasks, 10 files created, 726 LOC, 3 minutes

## Verification Results

All verification checks passed:

1. ✅ Directory structure created: AudioPlayer/, VoiceCache/, StepSync/, Models/
2. ✅ 10 Swift files exist (6 from Task 1 + 4 from Task 2)
3. ✅ Package.swift has correct dependencies (TCA, DesignSystem, NetworkClient, KindredAPI, Kingfisher)
4. ✅ AudioPlayerClient has DependencyKey conformance with liveValue and testValue
5. ✅ VoiceCacheClient has DependencyKey conformance with liveValue and testValue
6. ✅ AudioPlayerManager stores and removes time observer token in cleanup()
7. ✅ StepSyncEngine uses binary search algorithm (while loop with left/right pointers)
8. ✅ LRUCache uses .cachesDirectory (not .documentDirectory)
9. ✅ All public types are Equatable and Sendable

## Key Technical Decisions

**AudioPlayer Architecture:**
- **AVPlayer over AVAudioPlayer:** Enables HTTP streaming, progressive download, adaptive bitrates
- **Actor-based manager:** Ensures thread-safe async/await access to AVPlayer (which requires main queue)
- **Observer cleanup protocol:** Store timeObserverToken and remove in cleanup() to prevent memory leaks
- **Rate timing:** Call play() BEFORE setting rate (AVPlayer ignores rate changes when paused)
- **AsyncStream observers:** Yield time/status/duration updates reactively for TCA reducers

**Cache Strategy:**
- **LRU eviction at 500MB:** Balances storage with UX, prevents unbounded growth
- **.cachesDirectory location:** Correct for ephemeral data (not backed up, auto-cleaned by OS)
- **Per-voice-per-recipe caching:** File naming {voiceId}_{recipeId}.m4a supports multiple voices
- **UserDefaults metadata:** JSON-encoded [CacheEntry] persists LRU access times
- **Eviction algorithm:** Sort by lastAccessTime ascending, remove oldest until under limit

**Step Sync:**
- **Binary search:** O(log n) performance for timestamp-to-step mapping (sorted array assumption)
- **Pure function:** No state, reducer calls with current time and NarrationMetadata timestamps
- **Edge cases:** Returns nil if empty or before first timestamp, last index if >= last timestamp

## Integration Points

**For Plan 07-02 (Player UI):**
- AudioPlayerClient provides `play()`, `pause()`, `resume()`, `seek()`, `setRate()` actions
- AsyncStreams: `currentTimeStream()`, `statusStream()`, `durationStream()` drive UI updates
- PlaybackState models: PlaybackStatus enum for UI state, PlaybackSpeed enum with .next for speed toggle
- CurrentPlayback struct aggregates all playback metadata for UI display

**For Plan 07-03 (App Integration):**
- VoiceCacheClient provides `cacheAudio()`, `getCachedAudio()`, `isCached()`, `clearCache()`
- Cache operations throw errors for reducer error handling
- StepSyncEngine.currentStepIndex() maps playback time to step for recipe detail highlighting

**For Plan 07-04 (System Controls):**
- AudioPlayerClient.statusStream() drives MPNowPlayingInfoCenter updates
- CurrentPlayback.artworkURL, recipeName, speakerName populate lock screen metadata
- PlaybackSpeed enum provides rate values for AVPlayer

## Dependencies Added

**SPM Package:**
- swift-composable-architecture (from: "1.0.0")
- Kingfisher (from: "8.0.0")
- DesignSystem (path: "../DesignSystem")
- NetworkClient (path: "../NetworkClient")
- KindredAPI (path: "../KindredAPI")

**iOS Frameworks:**
- AVFoundation (AVPlayer, AVPlayerItem, CMTime, audioTimePitchAlgorithm)
- Foundation (FileManager, UserDefaults, JSONEncoder/Decoder, AsyncStream)

## Self-Check: PASSED

**Files created:**
```
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Package.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerClient.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerManager.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/PlaybackState.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/VoiceCache/VoiceCacheClient.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/VoiceCache/LRUCache.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/VoiceCache/CacheEntry.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/StepSync/StepSyncEngine.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/Models/VoiceProfile.swift
FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/VoicePlaybackFeature/Sources/Models/NarrationMetadata.swift
```

**Commits verified:**
```
FOUND: e9731f6 (Task 1: VoicePlaybackFeature package with AudioPlayerClient and domain models)
FOUND: 9a98ba2 (Task 2: VoiceCacheClient and StepSyncEngine with LRU eviction)
```

All files exist and commits are in git history.

## Next Steps

**Plan 07-02:** Build voice player UI component consuming AudioPlayerClient and PlaybackState models for in-recipe narration playback controls.

**Plan 07-03:** Integrate voice playback into app flow with cache-first loading strategy using VoiceCacheClient.

**Plan 07-04:** Add MPNowPlayingInfoCenter and MPRemoteCommandCenter for lock screen controls and background audio.
