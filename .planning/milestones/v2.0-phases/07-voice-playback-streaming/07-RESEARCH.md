# Phase 07: Voice Playback & Streaming - Research

**Researched:** 2026-03-03
**Domain:** iOS Audio Playback with AVFoundation, Background Audio, Media Controls
**Confidence:** HIGH

## Summary

Voice playback requires implementing a robust audio player architecture using AVFoundation's AVPlayer for streaming, AVAudioSession for background playback, and MediaPlayer framework for lock screen controls. The phase integrates streaming audio from Cloudflare R2, persistent mini-player UI, offline caching with LRU eviction, and full accessibility support.

The architecture should follow TCA patterns with an AudioPlayerClient as a dependency-injected service, a VoicePlaybackReducer for state management, and VoiceCacheClient for local storage. The mini-player lives at app root level (AppReducer) to persist across screens, while the expanded player uses SwiftUI's presentation detents for bottom sheet modal display.

Critical success factors: proper AVAudioSession configuration (.playback category), MPNowPlayingInfoCenter integration for lock screen metadata, MPRemoteCommandCenter for playback controls, KVO observer cleanup to prevent memory leaks, and FileManager-based disk cache with LRU eviction in cachesDirectory.

**Primary recommendation:** Use AVPlayer (not AVAudioPlayer) for streaming support, implement audio player as a TCA dependency client for testability, store cached audio in FileManager.SearchPathDirectory.cachesDirectory with LRU eviction, and integrate MPNowPlayingInfoCenter + MPRemoteCommandCenter for iOS system-level controls.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Player UI & Placement**
- Bottom mini-player bar (Spotify/Podcasts-style) that persists globally across all screens
- Mini-player shows: play/pause button, thin progress bar, recipe name — tap anywhere to expand
- Expanded view is a bottom sheet (half-screen, ~60% of screen)
- 64dp play button in expanded view only; mini-player uses standard ~44dp tap target
- Visual style matches existing DesignSystem: CardSurface, kindredAccent for controls, same typography (18sp+ labels)
- Speaker name and avatar displayed prominently at top of expanded bottom sheet
- Seek bar shows elapsed time (left) and remaining time (right)
- 15-second skip back and 30-second skip forward buttons in expanded player
- Current step text displayed in expanded bottom sheet alongside controls

**Narration & Step Sync**
- One continuous audio file per recipe (not per-step segments)
- Narration includes brief intro (recipe name, total time) then step-by-step instructions — no ingredient readout
- StepTimelineView highlights the current step being narrated (accent border/background), auto-scrolls into view
- Playback speed control: 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x
- When narration finishes: auto-stop, mini-player fades/dismisses after brief pause

**Voice Profile Selection**
- Pre-playback inline card list showing available voice profiles
- Each voice card has a small play button for 3-5 second voice sample preview
- Voice list ordered: user's own voice first, then family members alphabetically
- App remembers last-used voice per recipe — auto-starts with that voice on subsequent listens, shows picker only on first listen
- User can switch voices mid-playback via voice button in expanded player
- Mid-playback voice switch: pause current audio, show spinner on play button, generate/fetch new voice audio, resume from same position
- If no cloned voice profiles exist: show message prompting user to create a voice profile, with navigation to voice cloning flow

**Offline Caching & Downloads**
- Auto-cache on first listen — streamed audio automatically saved locally, no explicit download step
- LRU eviction with configurable size cap (e.g., 500MB) — oldest/least recently used audio removed when full
- Cache stores audio per voice per recipe (multiple voices cached for same recipe if listened)
- Subtle icon indicator on Listen button showing cached/available offline status
- Offline + uncached: show friendly error message with guidance ("Listen while connected to save for later")
- Cache management section in app settings: shows total cache size, "Clear Cache" button
- Buffering/loading state: SkeletonShimmer on player controls while initial streaming loads (consistent with app patterns)

### Claude's Discretion

- Mini-player animation/transition details (slide up, fade, etc.)
- Bottom sheet drag-to-dismiss gesture behavior
- Exact step highlighting visual treatment (accent border color, background opacity)
- Step boundary detection approach for highlighting (timestamp markers in audio metadata)
- Audio format choice (MP3, AAC, etc.) and streaming chunk sizes
- Cache size default value
- Lock screen Now Playing artwork and metadata formatting
- AVAudioSession category and routing configuration

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VOICE-01 | User can listen to any recipe's instructions narrated in their cloned voice | AVPlayer streaming from R2 presigned URLs, AudioPlayerClient dependency for playback control |
| VOICE-02 | Voice narration displays play/pause/seek controls (64dp play button, 18sp+ text labels) with speaker name prominently shown | SwiftUI custom player UI with AVPlayer.seek(to:), rate property for speed control, presentation detents for bottom sheet |
| VOICE-03 | Voice narration displays the speaker's name prominently during playback | MPNowPlayingInfoCenter nowPlayingInfo dictionary with MPMediaItemPropertyArtist for speaker name |
| VOICE-04 | Voice playback continues in background with lock screen controls | AVAudioSession .playback category, MPNowPlayingInfoCenter metadata, MPRemoteCommandCenter for playback/seek commands, UIBackgroundModes audio in Info.plist |
| VOICE-05 | Voice profiles cache locally for offline narration playback | FileManager cachesDirectory storage, LRU cache implementation tracking access times, VoiceCacheClient dependency |
| VOICE-06 | User can upload a 30-60 second voice clip to create a voice profile | GraphQL mutation for voice profile creation (backend integration), file upload to R2 (Phase 5/6 dependency) |
| ACCS-02 | All body text is minimum 18sp with Dynamic Type support | SwiftUI Dynamic Type with .font(.body) or custom text styles supporting accessibility sizes |
| ACCS-03 | Full VoiceOver support with meaningful labels on all custom controls and gestures | .accessibilityLabel, .accessibilityHint, .accessibilityAddTraits for custom player controls, proper focus ordering |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AVFoundation | iOS 17.0+ | Audio playback, streaming, seek controls | Apple's native framework for media playback, required for background audio and system integration |
| MediaPlayer | iOS 17.0+ | Lock screen controls, Now Playing metadata | Only framework for MPNowPlayingInfoCenter and MPRemoteCommandCenter integration |
| SwiftUI | iOS 17.0+ | Player UI, bottom sheet presentation | Project uses SwiftUI + TCA architecture throughout |
| TCA (swift-composable-architecture) | 1.0+ | State management, dependency injection | Established project pattern for reducers and clients |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Kingfisher | 8.0+ | Lock screen artwork loading | Already in use for image caching, reuse for MPMediaItemArtwork |
| FileManager | iOS 17.0+ | Local audio cache storage | Native iOS API for cachesDirectory management |
| Combine | iOS 17.0+ | Reactive streams for playback time updates | Native framework for observing AVPlayer.timeControlStatus and currentTime |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AVPlayer | AVAudioPlayer | AVAudioPlayer doesn't support streaming URLs or HLS; causes background jitter/static. AVPlayer is required for streaming. |
| FileManager cache | URLCache | URLCache clears entire cache at capacity; custom FileManager-based LRU gives fine-grained control over eviction. |
| TCA dependency client | Singleton AudioManager | Breaks testability and composability; TCA clients enable mock implementations for tests. |

**Installation:**

No additional packages required beyond existing project dependencies (TCA, Kingfisher already installed).

## Architecture Patterns

### Recommended Project Structure

```
Kindred/Packages/
├── VoicePlaybackFeature/
│   ├── Sources/
│   │   ├── AudioPlayer/
│   │   │   ├── AudioPlayerClient.swift          # TCA dependency for AVPlayer control
│   │   │   ├── AudioPlayerManager.swift         # AVPlayer wrapper, observer management
│   │   │   └── PlaybackState.swift              # Playback state models
│   │   ├── VoiceCache/
│   │   │   ├── VoiceCacheClient.swift           # TCA dependency for cache operations
│   │   │   ├── LRUCache.swift                   # LRU eviction logic
│   │   │   └── CacheEntry.swift                 # Cache metadata (access time, size)
│   │   ├── Player/
│   │   │   ├── VoicePlaybackReducer.swift       # TCA reducer for player state
│   │   │   ├── MiniPlayerView.swift             # Bottom bar mini-player
│   │   │   ├── ExpandedPlayerView.swift         # Bottom sheet full player
│   │   │   └── VoicePickerView.swift            # Voice profile selection
│   │   ├── StepSync/
│   │   │   ├── StepSyncEngine.swift             # Timestamp → step index mapping
│   │   │   └── StepHighlighter.swift            # Auto-scroll logic
│   │   └── Models/
│   │       ├── VoiceProfile.swift               # Voice profile data model
│   │       └── NarrationMetadata.swift          # Timestamps, duration, etc.
│   └── Package.swift
```

### Pattern 1: TCA Audio Player Dependency Client

**What:** Wrap AVPlayer in a TCA dependency client for testability and lifecycle management.

**When to use:** All playback operations (play, pause, seek, observe time).

**Example:**

```swift
// Source: TCA patterns + AVPlayer best practices
import ComposableArchitecture
import AVFoundation

struct AudioPlayerClient {
    var play: @Sendable (URL) async throws -> Void
    var pause: @Sendable () async -> Void
    var seek: @Sendable (TimeInterval) async -> Void
    var setRate: @Sendable (Float) async -> Void
    var currentTimeStream: @Sendable () -> AsyncStream<TimeInterval>
    var statusStream: @Sendable () -> AsyncStream<PlaybackStatus>
    var cleanup: @Sendable () async -> Void
}

extension AudioPlayerClient: DependencyKey {
    static let liveValue: AudioPlayerClient = {
        let manager = AudioPlayerManager.shared

        return AudioPlayerClient(
            play: { url in try await manager.play(url: url) },
            pause: { await manager.pause() },
            seek: { time in await manager.seek(to: time) },
            setRate: { rate in await manager.setRate(rate) },
            currentTimeStream: { manager.currentTimeStream() },
            statusStream: { manager.statusStream() },
            cleanup: { await manager.cleanup() }
        )
    }()

    static let testValue = AudioPlayerClient(
        play: unimplemented("AudioPlayerClient.play"),
        pause: unimplemented("AudioPlayerClient.pause"),
        seek: unimplemented("AudioPlayerClient.seek"),
        setRate: unimplemented("AudioPlayerClient.setRate"),
        currentTimeStream: { AsyncStream { continuation in continuation.finish() } },
        statusStream: { AsyncStream { continuation in continuation.finish() } },
        cleanup: unimplemented("AudioPlayerClient.cleanup")
    )
}

extension DependencyValues {
    var audioPlayerClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
```

### Pattern 2: AVAudioSession Configuration for Background Audio

**What:** Configure audio session for background playback with interruption handling.

**When to use:** On app launch (AppDelegate) and before first playback.

**Example:**

```swift
// Source: Apple Developer Documentation - Configuring Audio Session
import AVFoundation

final class AudioSessionConfigurator {
    static func configure() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Set category to .playback for background audio
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)

            // Register for interruption notifications (phone calls, Siri)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    @objc private static func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Pause playback - AVPlayer handles this automatically
            break
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Resume playback only if user didn't pause via Siri
                // Check app state before auto-resuming
            }
        @unknown default:
            break
        }
    }
}
```

### Pattern 3: MPNowPlayingInfoCenter + MPRemoteCommandCenter Integration

**What:** Update lock screen metadata and handle remote commands (play/pause/seek).

**When to use:** When playback starts, when seeking, when metadata changes.

**Example:**

```swift
// Source: Apple Developer Documentation - MPNowPlayingInfoCenter
import MediaPlayer

final class NowPlayingInfoManager {
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let infoCenter = MPNowPlayingInfoCenter.default()

    func setupRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSkipForward: @escaping (TimeInterval) -> Void,
        onSkipBackward: @escaping (TimeInterval) -> Void
    ) {
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            onPlay()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            onPause()
            return .success
        }

        // Skip forward 30 seconds
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { _ in
            onSkipForward(30)
            return .success
        }

        // Skip backward 15 seconds
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { _ in
            onSkipBackward(15)
            return .success
        }

        // Change playback position (seek bar on lock screen)
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            onSkipForward(positionEvent.positionTime)
            return .success
        }
    }

    func updateNowPlaying(
        title: String,
        artist: String, // Speaker name
        artwork: UIImage?,
        duration: TimeInterval,
        elapsedTime: TimeInterval,
        rate: Float
    ) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist // Speaker name prominent
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate

        if let artwork = artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: artwork.size,
                requestHandler: { _ in artwork }
            )
        }

        infoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func cleanup() {
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        infoCenter.nowPlayingInfo = nil
    }
}
```

### Pattern 4: LRU Cache with FileManager

**What:** Disk-based audio cache with LRU eviction when size limit exceeded.

**When to use:** After streaming audio completes, before playing cached audio.

**Example:**

```swift
// Source: iOS caching best practices + LRU algorithm
import Foundation

struct CacheEntry: Codable {
    let voiceId: String
    let recipeId: String
    let fileURL: URL
    let sizeBytes: Int64
    var lastAccessTime: Date
    let createdAt: Date
}

final class VoiceCache {
    private let fileManager = FileManager.default
    private let maxCacheSizeBytes: Int64 = 500 * 1024 * 1024 // 500MB default
    private let metadataKey = "voiceCache_metadata"

    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoiceNarrations", isDirectory: true)
    }

    func cacheAudio(voiceId: String, recipeId: String, data: Data) async throws -> URL {
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Save audio file
        let fileName = "\(voiceId)_\(recipeId).m4a"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)

        // Update metadata
        let entry = CacheEntry(
            voiceId: voiceId,
            recipeId: recipeId,
            fileURL: fileURL,
            sizeBytes: Int64(data.count),
            lastAccessTime: Date(),
            createdAt: Date()
        )
        try addEntry(entry)

        // Enforce size limit with LRU eviction
        try await evictIfNeeded()

        return fileURL
    }

    func getCachedAudio(voiceId: String, recipeId: String) async throws -> URL? {
        guard let entry = findEntry(voiceId: voiceId, recipeId: recipeId) else {
            return nil
        }

        // Update access time (LRU)
        var updatedEntry = entry
        updatedEntry.lastAccessTime = Date()
        try updateEntry(updatedEntry)

        return entry.fileURL
    }

    private func evictIfNeeded() async throws {
        let entries = loadMetadata()
        let totalSize = entries.reduce(0) { $0 + $1.sizeBytes }

        guard totalSize > maxCacheSizeBytes else { return }

        // Sort by last access time (oldest first)
        let sortedEntries = entries.sorted { $0.lastAccessTime < $1.lastAccessTime }

        var currentSize = totalSize
        for entry in sortedEntries {
            guard currentSize > maxCacheSizeBytes else { break }

            // Delete file
            try? fileManager.removeItem(at: entry.fileURL)

            // Remove from metadata
            try removeEntry(entry)

            currentSize -= entry.sizeBytes
        }
    }

    func getTotalCacheSize() -> Int64 {
        loadMetadata().reduce(0) { $0 + $1.sizeBytes }
    }

    func clearAll() throws {
        try fileManager.removeItem(at: cacheDirectory)
        UserDefaults.standard.removeObject(forKey: metadataKey)
    }

    // Metadata persistence helpers
    private func loadMetadata() -> [CacheEntry] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let entries = try? JSONDecoder().decode([CacheEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func saveMetadata(_ entries: [CacheEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        UserDefaults.standard.set(data, forKey: metadataKey)
    }

    private func addEntry(_ entry: CacheEntry) throws {
        var entries = loadMetadata()
        entries.append(entry)
        try saveMetadata(entries)
    }

    private func updateEntry(_ entry: CacheEntry) throws {
        var entries = loadMetadata()
        if let index = entries.firstIndex(where: {
            $0.voiceId == entry.voiceId && $0.recipeId == entry.recipeId
        }) {
            entries[index] = entry
            try saveMetadata(entries)
        }
    }

    private func removeEntry(_ entry: CacheEntry) throws {
        var entries = loadMetadata()
        entries.removeAll { $0.voiceId == entry.voiceId && $0.recipeId == entry.recipeId }
        try saveMetadata(entries)
    }

    private func findEntry(voiceId: String, recipeId: String) -> CacheEntry? {
        loadMetadata().first { $0.voiceId == voiceId && $0.recipeId == recipeId }
    }
}
```

### Pattern 5: SwiftUI Bottom Sheet with Presentation Detents

**What:** Half-screen bottom sheet for expanded player using iOS 16+ presentation detents.

**When to use:** When user taps mini-player to expand.

**Example:**

```swift
// Source: SwiftUI presentation detents documentation
import SwiftUI

struct MiniPlayerView: View {
    @Binding var isExpanded: Bool
    let playbackState: PlaybackState

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: playbackState.artworkURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(playbackState.recipeName)
                    .font(.kindredBodyBold())
                    .lineLimit(1)
                Text(playbackState.speakerName)
                    .font(.kindredBody())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { /* toggle play/pause */ }) {
                Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.kindredAccent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(playbackState.isPlaying ? "Pause" : "Play")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onTapGesture {
            isExpanded = true
        }
        .sheet(isPresented: $isExpanded) {
            ExpandedPlayerView(playbackState: playbackState)
                .presentationDetents([.fraction(0.6), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }
}
```

### Pattern 6: Automatic Step Highlighting with ScrollViewReader

**What:** Auto-scroll StepTimelineView to current step and highlight with accent border.

**When to use:** When audio playback time crosses step boundary timestamp.

**Example:**

```swift
// Source: SwiftUI ScrollViewReader + programmatic scrolling
import SwiftUI

struct StepTimelineView: View {
    let steps: [RecipeStep]
    let currentStepIndex: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(steps.enumerated()), id: \.element.orderIndex) { index, step in
                        StepRow(
                            step: step,
                            isHighlighted: index == currentStepIndex
                        )
                        .id(step.orderIndex)
                    }
                }
                .padding()
            }
            .onChange(of: currentStepIndex) { oldValue, newValue in
                guard let newIndex = newValue else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(steps[newIndex].orderIndex, anchor: .center)
                }
            }
        }
    }
}

struct StepRow: View {
    let step: RecipeStep
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isHighlighted ? Color.kindredAccent : Color.secondary)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(step.orderIndex + 1)")
                        .font(.caption)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(step.text)
                    .font(.kindredBody())

                if let duration = step.duration {
                    Text("\(duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.kindredAccent.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.kindredAccent : Color.clear, lineWidth: 2)
        )
    }
}
```

### Anti-Patterns to Avoid

- **Global singleton audio player:** Breaks TCA composability and testability. Use dependency injection instead.
- **AVAudioPlayer for streaming:** Doesn't support HTTP URLs or HLS. Always use AVPlayer for streaming.
- **Manually managing KVO observers without cleanup:** Causes memory leaks. Use Combine publishers or ensure removeObserver in deinit.
- **Storing audio in .documentDirectory:** Files appear in user storage metrics and backups. Use .cachesDirectory for transient audio.
- **Setting AVPlayer.rate before calling play():** Rate must be set after play() for speed control to work reliably.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LRU cache eviction | Custom linked list + dictionary | FileManager + sorted metadata by lastAccessTime | Cache eviction logic is error-prone; simple sort-and-delete approach is reliable and maintainable |
| Audio session interruption | Custom notification observers | AVAudioSession.interruptionNotification + MPRemoteCommandCenter | Missing edge cases (Siri, phone calls, route changes) causes playback bugs; system APIs handle all scenarios |
| Lock screen artwork loading | Custom image downloader | Kingfisher (already in project) | Image caching, memory management, and async loading already solved; reuse existing dependency |
| Time-to-step mapping | Linear search per time update | Binary search on sorted timestamps | O(n) search every second kills performance; O(log n) binary search is standard algorithm |
| Playback progress UI updates | Timer-based polling | Combine publisher from AVPlayer.periodicTimeObserver | Polling wastes CPU; Combine streams are reactive and efficient |

**Key insight:** Audio playback on iOS has many edge cases (interruptions, route changes, background transitions, seek accuracy) that AVFoundation's APIs handle natively. Custom implementations miss subtle bugs that ship with production apps. Use system frameworks directly.

## Common Pitfalls

### Pitfall 1: AVPlayer Time Observers Leak Memory

**What goes wrong:** Adding periodic time observers without storing token and removing them causes memory leaks.

**Why it happens:** `addPeriodicTimeObserver(forInterval:queue:using:)` returns a token that must be explicitly removed with `removeTimeObserver(_:)` in deinit.

**How to avoid:**
```swift
class AudioPlayerManager {
    private var player: AVPlayer?
    private var timeObserverToken: Any?

    func startObserving() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdate(time)
        }
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
```

**Warning signs:** Memory debugger shows AVPlayer instances not being deallocated; time callbacks continue firing after view dismissal.

### Pitfall 2: Background Audio Stops When Locking Device

**What goes wrong:** Audio stops when screen locks or user switches apps.

**Why it happens:** Missing `UIBackgroundModes` audio in Info.plist or AVAudioSession not set to `.playback` category.

**How to avoid:**

1. Add to Info.plist:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

2. Configure audio session before playback:
```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .spokenAudio)
try session.setActive(true)
```

**Warning signs:** Audio pauses when locking device; control center shows no now-playing info.

### Pitfall 3: Seek Bar Jumps Erratically During Playback

**What goes wrong:** Seek bar position jumps around instead of smoothly progressing.

**Why it happens:** Mixing `AVPlayer.currentTime()` (wall-clock time) with periodic observer updates (player time) without accounting for buffering.

**How to avoid:** Always use time from periodic observer for UI updates; use `player.currentItem?.currentTime()` for single queries:

```swift
// CORRECT: Use time from observer
timeObserverToken = player?.addPeriodicTimeObserver(
    forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
    queue: .main
) { [weak self] time in
    let seconds = CMTimeGetSeconds(time)
    self?.updateSeekBar(currentTime: seconds)
}

// WRONG: Polling currentTime() in a timer
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    let time = player?.currentTime() // Don't do this
}
```

**Warning signs:** Seek bar stutters; time displays jump backward; progress doesn't match audio.

### Pitfall 4: Cache Size Grows Unbounded

**What goes wrong:** Audio cache consumes gigabytes of disk space; app gets slow or crashes.

**Why it happens:** No eviction strategy implemented; files keep accumulating in cachesDirectory.

**How to avoid:** Implement LRU eviction with size cap (see Pattern 4). Track total cache size and evict oldest entries when limit exceeded.

**Warning signs:** Users report "storage full" warnings; cache directory shows hundreds of audio files; app storage in Settings shows high "Documents & Data" usage.

### Pitfall 5: Playback Speed Doesn't Work

**What goes wrong:** Setting `AVPlayer.rate = 2.0` has no effect; audio plays at normal speed.

**Why it happens:** Rate must be set *after* calling `play()`, and `audioTimePitchAlgorithm` property affects quality.

**How to avoid:**

```swift
func setPlaybackSpeed(_ speed: Float) {
    player?.currentItem?.audioTimePitchAlgorithm = .timePitch // Preserve pitch
    player?.play()
    player?.rate = speed // MUST be after play()
}
```

**Warning signs:** Speed control UI updates but audio speed unchanged; rate reverts to 1.0 unexpectedly.

### Pitfall 6: Lock Screen Artwork Doesn't Update

**What goes wrong:** Lock screen shows old recipe image or no image.

**Why it happens:** MPMediaItemArtwork must be recreated every time metadata updates; updating nowPlayingInfo dictionary doesn't automatically refresh artwork.

**How to avoid:** Always create new MPMediaItemArtwork instance when updating nowPlayingInfo:

```swift
func updateNowPlaying(title: String, artwork: UIImage?) {
    var nowPlayingInfo = infoCenter.nowPlayingInfo ?? [:]
    nowPlayingInfo[MPMediaItemPropertyTitle] = title

    if let artwork = artwork {
        // Create NEW artwork instance every time
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
            boundsSize: artwork.size,
            requestHandler: { _ in artwork }
        )
    }

    infoCenter.nowPlayingInfo = nowPlayingInfo
}
```

**Warning signs:** Lock screen shows previous recipe image after switching narrations.

## Code Examples

Verified patterns from official sources:

### AVPlayer Seek with Tolerance

```swift
// Source: Apple Developer Documentation - seek(to:toleranceBefore:toleranceAfter:)
func seekToTime(_ seconds: TimeInterval) {
    let time = CMTime(seconds: seconds, preferredTimescale: 600)
    let tolerance = CMTime(seconds: 0.5, preferredTimescale: 600)

    player?.seek(
        to: time,
        toleranceBefore: tolerance,
        toleranceAfter: tolerance
    ) { [weak self] finished in
        if finished {
            self?.updateNowPlayingElapsedTime(seconds)
        }
    }
}
```

### Combine Stream for Playback Time

```swift
// Source: Combine + AVPlayer patterns
func currentTimeStream() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let token = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { time in
            let seconds = CMTimeGetSeconds(time)
            continuation.yield(seconds)
        }

        continuation.onTermination = { @Sendable [weak player, token] _ in
            if let token = token {
                player?.removeTimeObserver(token)
            }
        }
    }
}
```

### VoiceOver Accessibility Labels

```swift
// Source: iOS accessibility best practices
struct PlayerControls: View {
    @State var isPlaying = false
    @State var currentSpeed: Float = 1.0

    var body: some View {
        HStack(spacing: 24) {
            // Skip backward
            Button(action: { skipBackward() }) {
                Image(systemName: "gobackward.15")
                    .font(.title2)
            }
            .accessibilityLabel("Skip back 15 seconds")
            .accessibilityHint("Double tap to go back 15 seconds")
            .frame(width: 56, height: 56)

            // Play/Pause
            Button(action: { togglePlayback() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }
            .accessibilityLabel(isPlaying ? "Pause" : "Play")
            .accessibilityHint(isPlaying ? "Double tap to pause narration" : "Double tap to play narration")

            // Skip forward
            Button(action: { skipForward() }) {
                Image(systemName: "goforward.30")
                    .font(.title2)
            }
            .accessibilityLabel("Skip forward 30 seconds")
            .accessibilityHint("Double tap to skip ahead 30 seconds")
            .frame(width: 56, height: 56)

            // Speed control
            Button(action: { cycleSpeed() }) {
                Text("\(currentSpeed, specifier: "%.2f")×")
                    .font(.kindredBodyBold())
            }
            .accessibilityLabel("Playback speed \(currentSpeed, specifier: "%.2f") times")
            .accessibilityHint("Double tap to cycle through playback speeds")
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AVAudioPlayer for all playback | AVPlayer for streaming, AVQueuePlayer for queues | iOS 14+ (2020) | AVPlayer supports HLS, progressive download, and background stability; AVAudioPlayer causes jitter in background |
| Manual KVO for playback state | Combine publishers | iOS 13+ (2019) | Reactive streams prevent observer leaks and simplify time updates |
| Fixed detents (.medium, .large) | Custom detents (.fraction, .height) | iOS 16+ (2022) | Allows precise 60% screen height for bottom sheet per user requirements |
| Static MPMediaItemArtwork | MPMediaItemAnimatedArtwork | iOS 26 (2025) | Animated artwork on lock screen (optional enhancement, not required for phase) |
| Manual interruption handling | AVAudioSession.interruptionNotification | iOS 6+ (stable) | System handles phone calls, Siri, route changes automatically |

**Deprecated/outdated:**
- `AVAudioPlayer` for streaming: Doesn't support URLs, causes background audio issues. Use AVPlayer.
- `.playerItemDidReachEndNotification` (AVFoundation): Deprecated in iOS 15+. Use Combine publisher `publisher(for: \.status)` instead.
- Manual background mode configuration: Still required in Info.plist, but Xcode 14+ has capabilities UI for easier setup.

## Open Questions

1. **Backend API for narration generation**
   - What we know: Phase 5/6 established voice profile storage in R2 and GraphQL schema
   - What's unclear: Exact endpoint for generating narration audio from recipe text + voice profile (likely ElevenLabs API integration in NestJS backend)
   - Recommendation: Verify GraphQL mutation exists for `generateNarration(recipeId: ID!, voiceId: ID!): NarrationResult` or coordinate with backend team

2. **Step timestamp metadata format**
   - What we know: One continuous audio file per recipe with step-by-step instructions
   - What's unclear: How step boundaries are encoded (separate JSON metadata? embedded in audio container? timing algorithm?)
   - Recommendation: Define `NarrationMetadata` model with `stepTimestamps: [TimeInterval]` array; coordinate with backend on storage format (likely JSON sidecar file in R2 alongside audio)

3. **Voice sample preview playback**
   - What we know: Each voice card shows preview play button for 3-5 second sample
   - What's unclear: Are sample URLs pre-generated and stored with voice profile, or generated on-demand?
   - Recommendation: Assume sample URLs exist in VoiceProfile model (`sampleAudioURL: String?`); reuse AudioPlayerClient with separate player instance for preview playback to avoid interrupting main narration

4. **Cache size default value**
   - What we know: LRU eviction with configurable size cap
   - What's unclear: Optimal default (user decision: "e.g., 500MB")
   - Recommendation: Start with 500MB as suggested; add app settings UI in Phase 9 (Monetization) to adjust; Pro tier could offer larger cache limits

## Validation Architecture

> Note: workflow.nyquist_validation is not configured in .planning/config.json, but test infrastructure exists

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (native iOS testing) |
| Config file | none — no test targets currently configured |
| Quick run command | `swift test` (from package directory) |
| Full suite command | `xcodebuild test -scheme VoicePlaybackFeature` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VOICE-01 | Audio streams from R2 presigned URL | unit | `swift test --filter AudioPlayerClientTests.testStreamFromURL` | ❌ Wave 0 |
| VOICE-02 | Play/pause/seek controls update playback state | unit | `swift test --filter VoicePlaybackReducerTests.testPlaybackControls` | ❌ Wave 0 |
| VOICE-03 | MPNowPlayingInfoCenter displays speaker name | unit | `swift test --filter NowPlayingInfoManagerTests.testSpeakerNameDisplay` | ❌ Wave 0 |
| VOICE-04 | Background audio continues after screen lock | integration | Manual test: lock device during playback | Manual only |
| VOICE-05 | LRU cache evicts oldest entries at size limit | unit | `swift test --filter VoiceCacheTests.testLRUEviction` | ❌ Wave 0 |
| VOICE-06 | GraphQL mutation creates voice profile | integration | Backend integration test (outside iOS scope) | N/A |
| ACCS-02 | Dynamic Type scales text to 200% | UI test | `swift test --filter AccessibilityTests.testDynamicTypeScaling` | ❌ Wave 0 |
| ACCS-03 | VoiceOver reads accessibility labels | UI test | `swift test --filter AccessibilityTests.testVoiceOverLabels` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `swift test --filter [FeatureName]Tests` (unit tests for modified feature)
- **Per wave merge:** `xcodebuild test -scheme VoicePlaybackFeature` (full feature test suite)
- **Phase gate:** Full suite green + manual background audio verification before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `Tests/AudioPlayerClientTests.swift` — covers VOICE-01 (streaming), time observers, cleanup
- [ ] `Tests/VoicePlaybackReducerTests.swift` — covers VOICE-02 (playback controls), state transitions
- [ ] `Tests/VoiceCacheTests.swift` — covers VOICE-05 (LRU eviction), cache size tracking
- [ ] `Tests/NowPlayingInfoManagerTests.swift` — covers VOICE-03 (lock screen metadata)
- [ ] `Tests/AccessibilityTests.swift` — covers ACCS-02, ACCS-03 (Dynamic Type, VoiceOver)
- [ ] `Tests/StepSyncEngineTests.swift` — covers timestamp-to-step-index mapping logic
- [ ] `Package.swift` — add test target with dependencies on Testing library

## Sources

### Primary (HIGH confidence)

- [Apple Developer: Configuring your app for media playback](https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback) - AVAudioSession setup, background modes
- [Apple Developer: MPNowPlayingInfoCenter](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter) - Lock screen metadata
- [Apple Developer: AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession) - Audio session categories, interruption handling
- [Apple Developer: seek(to:toleranceBefore:toleranceAfter:)](https://developer.apple.com/documentation/avfoundation/avplayer/1387741-seektotime) - Precise seek control
- [Apple Developer: FileManager.cachesDirectory](https://developer.apple.com/documentation/foundation/filemanager/searchpathdirectory/cachesdirectory) - Cache storage location
- [GitHub: Raidansz/AudioPlayer-SwiftUI-TCA](https://github.com/Raidansz/AudioPlayer-SwiftUI-TCA) - TCA audio player example

### Secondary (MEDIUM confidence)

- [Background Audio Player Sync Control Center - Medium](https://medium.com/@quangtqag/background-audio-player-sync-control-center-516243c2cdd1) - MPNowPlayingInfoCenter + MPRemoteCommandCenter integration patterns
- [Bottom Sheet in SwiftUI on iOS 16 with presentationDetents - Sarunw](https://sarunw.com/posts/swiftui-bottom-sheet/) - Bottom sheet implementation with custom detents
- [Mastering Multilayer Caching in Swift - Medium](https://medium.com/@khachatur.hakobyan2023/mastering-multilayer-caching-in-ios-nscache-urlcache-filemanager-cdn-beyond-6b5e70d9fb3e) - LRU cache strategies with FileManager
- [SwiftUI Cookbook: Customizing Audio & Video Playback - Kodeco](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/3-customizing-audio-video-playback-in-swiftui) - AVPlayer rate control, speed adjustment
- [How to synchronize animations with matchedGeometryEffect - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-synchronize-animations-from-one-view-to-another-with-matchedgeometryeffect) - Card-to-detail transition animation
- [Auto-Scrolling with ScrollViewReader - Medium](https://medium.com/@mikeusru/auto-scrolling-with-scrollviewreader-in-swiftui-10f16dce7dbb) - Programmatic scroll for step highlighting
- [ElevenLabs Documentation: Text to Speech](https://elevenlabs.io/docs/overview/capabilities/text-to-speech) - Voice cloning API capabilities, streaming support

### Tertiary (LOW confidence)

- [iOS AVFoundation Playback Benchmarks - Shakuro](https://shakuro.com/blog/ios-avfoundation-playback-benchmarks) - AVPlayer vs AVAudioPlayer performance (dated 2021, verify current best practices)
- [Cloudflare R2 Presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/) - R2 URL generation (no iOS-specific guidance)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple native frameworks verified from official documentation
- Architecture: HIGH - TCA patterns match existing project structure (FeedFeature, ProfileFeature)
- Pitfalls: HIGH - Common issues documented in Apple forums and production experience reports
- Caching: MEDIUM - LRU algorithm well-established but implementation details require testing
- Backend integration: LOW - Voice narration generation API not yet verified with backend team

**Research date:** 2026-03-03
**Valid until:** 2026-04-03 (30 days - stable frameworks, but iOS updates may introduce new APIs)
