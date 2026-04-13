# Phase 30: AVSpeechClient + Voice Tier Routing - Research

**Researched:** 2026-04-13
**Domain:** AVSpeechSynthesizer, TCA dependency client, voice tier routing, step highlighting
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Voice Selection UX:**
- Show all voices in picker (free + Pro). Pro voices display a lock icon/badge. Tapping a locked voice opens the existing paywall immediately
- Voice picker has section headers: "Free" section with Kindred Voice, "Pro Voices" section with ElevenLabs cloned voices
- Free-tier system voice is called "Kindred Voice" (keep current name)
- Kindred Voice shows subtitle "On-device narration" in the picker to set expectations
- Kindred Voice avatar uses the Kindred app icon/logo
- Voice upload (clone your voice) visible for free users with Pro badge — another upsell surface
- Free user taps play: auto-play with Kindred Voice immediately (no picker required). Voice picker available but not mandatory
- Pro subscriber downgrades: silent fallback to Kindred Voice on next play — no toast or explanation
- AVSpeech voice language matches device locale automatically (if Turkish device, Turkish accent/pronunciation)

**TTS Playback Experience:**
- Continuous narration with brief pauses between steps (1-2 seconds). Not step-by-step with user advance
- All existing speed controls (0.5x to 2x) work with AVSpeech. Map AVSpeechUtterance.rate to match
- Mini player and expanded player look/behave identically for AVSpeech and ElevenLabs — no visual distinction
- Background audio supported — AVSpeech continues when screen locks or app backgrounded
- Step highlighting: auto-scroll RecipeDetailView to keep the highlighted step visible
- Step highlight style: bold text + subtle accent-colored background on active step. Non-active steps stay normal
- Tap a step during narration to jump playback to that step
- Prefer enhanced (downloaded) TTS voice if available, fallback to compact default
- No caching of AVSpeech output — synthesis is instant, re-synthesize each time
- NowPlaying (lock screen / Control Center) shows "Kindred Voice" as artist
- Auto-dismiss mini player after ~3 second delay when narration completes (match ElevenLabs behavior)

**Failure & Fallback Behavior:**
- 5 second timeout for AVSpeech silent failure detection (TTSErrorDomain -4010 on iOS 17)
- On failure: show error in mini player with retry button. "Voice unavailable — Retry"
- 1 automatic retry after timeout. If second attempt also fails, show manual retry button
- If AVSpeech fails for a Pro subscriber: auto-fallback to ElevenLabs narration silently
- If device has no TTS voice installed: show error with guidance to download a voice from Settings > Accessibility > Spoken Content > Voices
- No limit on step count — narrate all steps regardless of recipe length
- No persistent failure tracking — each session is independent
- Auto-resume after phone call / Siri interruption (resume from where it left off)

**Audio Session Handoff:**
- Pro upgrade mid-session: wait until next recipe to offer ElevenLabs. Don't interrupt current AVSpeech narration
- Switching voice types mid-recipe (AVSpeech to ElevenLabs): resume from current step position, not from beginning
- Voice switch transition: abrupt stop-then-start (no crossfade, no loading indicator)
- Playing a different recipe while AVSpeech is active: stop AVSpeech immediately (cancel mid-sentence)
- Other apps' audio: pause (standard .playback behavior). Other app resumes when Kindred stops
- Cached ElevenLabs audio plays offline — don't force AVSpeech when cache has the audio
- Offline + uncached Pro voice: auto-fallback to Kindred Voice with brief note "Using Kindred Voice — no internet connection"

**Step Text Preprocessing:**
- Expand common cooking abbreviations before TTS: tbsp → tablespoon, tsp → teaspoon, oz → ounce, lb → pound, ml → milliliter, g → gram
- Strip HTML/markdown formatting from step text (tags, bold/italic markers, bullets)
- Prefix each step with step number: "Step 1: Preheat the oven..."
- Temperature values: read as-is from recipe, no F↔C conversion
- Expand Unicode fractions: ½ → "one half", ¼ → "one quarter", ¾ → "three quarters"
- Normalize ingredient amounts: ranges (2-3 → "two to three"), approximations (~500 → "approximately 500")
- Narrate everything including parenthetical notes — don't strip parentheses
- No SSML — feed plain preprocessed text to AVSpeech. Use postUtteranceDelay for inter-step pauses
- English-only abbreviation expansion for now (Spoonacular recipes are in English)

**Accessibility:**
- Pause VoiceOver announcements during AVSpeech narration to avoid dual-voice confusion
- Announce step transitions to VoiceOver: "Step 3" accessibility announcement between steps
- Narration speed: use app's own speed control, not system Spoken Content rate
- Listen button: add accessibility hint "Reads recipe steps aloud using Kindred Voice"
- Full VoiceOver custom actions on mini/expanded player: speed cycling, skip forward/backward via swipe
- Step highlighting respects Dynamic Type — highlight area scales with text size

### Claude's Discretion
- Exact inter-step pause duration (1-2 seconds range given)
- AVSpeechUtterance.rate mapping formula for speed controls
- Enhanced voice selection API (AVSpeechSynthesisVoice quality check)
- AudioPlayerClient protocol extension vs new AVSpeechClient protocol
- Step timestamp calculation for AVSpeech (derive from utterance callbacks vs estimate from text length)
- VoiceOver pause mechanism (UIAccessibility notification vs audio session category)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VOICE-01 | Free-tier user can listen to recipe instructions narrated via on-device AVSpeechSynthesizer | AVSpeechSynthesizer + TCA AVSpeechClient pattern; tier routing in selectVoice action |
| VOICE-02 | AVSpeechSynthesizer narration plays step-by-step with current step highlighting | Utterance-per-step queue with didFinish callback; StepTimelineView already has currentStepIndex param |
| VOICE-03 | Free-tier narration gracefully handles iOS 17 silent failure with automatic retry/fallback | 5-second Task timeout race; synthesizer dealloc/realloc between retries; TTSErrorDomain -4010 pattern |
| VOICE-04 | Voice tier routing selects AVSpeech for free users and ElevenLabs for Pro users automatically | selectVoice action branch on voiceId == "kindred-default"; subscriptionStatus already in state |
| VOICE-05 | Audio session handoff between AVSpeech and AVPlayer works cleanly without corruption | usesApplicationAudioSession = true; call synthesizer.stopSpeaking() + dealloc before AVPlayer; deactivate session between engines |
</phase_requirements>

---

## Summary

Phase 30 adds a parallel narration engine alongside the existing ElevenLabs/AVPlayer pipeline. The existing `VoicePlaybackReducer` already has the tier routing scaffolding: "kindred-default" voiceId is already inserted as the first profile and gated by `isVoiceLocked`. What's missing is: (1) an `AVSpeechClient` TCA dependency that wraps `AVSpeechSynthesizer` in an actor and emits `AsyncStream` events, (2) a branch in `narrationReady`/`selectVoice` that routes to AVSpeech instead of AVPlayer when `voiceId == "kindred-default"`, (3) per-step utterance queuing with a `didFinish` delegate feeding the step index back to the reducer, and (4) a text preprocessing pipeline run before utterances are enqueued.

The hardest technical problem is iOS 17.0–17.4's TTSErrorDomain -4010 silent failure: `AVSpeechSynthesizer` queues the utterance, calls no delegate, and hangs. The detection strategy is a `Task`-based 5-second timeout that races against the first delegate callback (didStart or didFinish). The audio session handoff between AVSpeech and AVPlayer is the second tricky area: `AVSpeechSynthesizer` does NOT deactivate the audio session after finishing, so the session must be explicitly deactivated before the first AVPlayer `play()` call to avoid routing corruption.

**Primary recommendation:** Create a new `AVSpeechClient` TCA dependency (not an extension of `AudioPlayerClient`) backed by an `@MainActor` class that wraps `AVSpeechSynthesizer`, manages the utterance queue per-step, and yields status/stepIndex events over an `AsyncStream`. Branch the existing `VoicePlaybackReducer` at the `selectVoice` → `narrationReady` path to call AVSpeechClient instead of audioPlayerClient when voiceId == "kindred-default".

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| AVSpeechSynthesizer | iOS 7+ (stable) | On-device TTS engine | Zero cost, offline, no new packages |
| AVSpeechUtterance | iOS 7+ | Per-step text container with rate/delay/voice | postUtteranceDelay enables inter-step pauses |
| AVSpeechSynthesisVoice | iOS 7+ | Voice selection by language/quality | quality property (.enhanced/.default) for quality preference |
| AVSpeechSynthesizerDelegate | iOS 7+ | willSpeakRangeOfSpeechString, didFinish callbacks | Only way to know when each utterance finishes |
| ComposableArchitecture | already used | TCA reducer + dependency injection | Established project pattern |
| swift-dependencies | already used | @DependencyKey for AVSpeechClient | Same pattern as AudioPlayerClient |

### Supporting
| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| AVSpeechSynthesisVoiceQuality | iOS 9+ | .enhanced / .default quality enum | Prefer .enhanced if downloaded, fall back to .default |
| UIAccessibility | already used | VoiceOver announcement between steps | Announce "Step N" via `.announcement` notification |
| NowPlayingManager | already exists | Lock screen metadata for AVSpeech | Pass "Kindred Voice" as artist; update elapsed manually |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate AVSpeechClient | Extend AudioPlayerClient | Extension muddies the protocol: AVSpeech has no URL, seek is utterance-index, not TimeInterval. Separate client is cleaner |
| Per-utterance delegate class | Continuation-based async | Delegate must be NSObject subclass; AsyncStream-over-delegate is the correct bridge pattern |
| Global AVSpeechSynthesizer singleton | Actor-owned instance | Actor-owned: cleaner dealloc/reinit for iOS 17 retry; avoids stale delegate references |

---

## Architecture Patterns

### Recommended Project Structure

```
VoicePlaybackFeature/Sources/
├── AVSpeech/
│   ├── AVSpeechClient.swift          # TCA dependency protocol + liveValue
│   ├── AVSpeechManager.swift         # @MainActor class, synthesizer owner, delegate
│   └── TextPreprocessor.swift        # Abbreviation expansion, fraction/HTML normalization
├── Player/
│   └── VoicePlaybackReducer.swift    # Branch selectVoice: AVSpeech vs ElevenLabs
├── VoiceCache/                       # unchanged
└── StepSync/                         # unchanged (StepSyncEngine used differently for AVSpeech)
```

### Pattern 1: AVSpeechClient as TCA Dependency

**What:** A struct with `@Sendable` closures matching the existing `AudioPlayerClient` shape, but adapted for utterance-based TTS. Backed by an `@MainActor` class (`AVSpeechManager`) that owns the synthesizer.

**When to use:** AVSpeech path — when voiceId == "kindred-default".

```swift
// Source: Matches existing AudioPlayerClient.swift pattern
public struct AVSpeechClient {
    public var speak: @Sendable ([String], PlaybackSpeed) async throws -> Void
    public var pause: @Sendable () async -> Void
    public var resume: @Sendable () async -> Void
    public var stopSpeaking: @Sendable () async -> Void
    public var jumpToStep: @Sendable (Int) async -> Void
    public var setRate: @Sendable (Float) async -> Void
    public var statusStream: @Sendable () async -> AsyncStream<PlaybackStatus>
    public var stepIndexStream: @Sendable () async -> AsyncStream<Int>
    public var cleanup: @Sendable () async -> Void
}

extension AVSpeechClient: DependencyKey {
    public static var liveValue: AVSpeechClient {
        let manager = AVSpeechManager.shared
        return AVSpeechClient(
            speak: { steps, speed in try await manager.speak(steps: steps, speed: speed) },
            pause: { await manager.pause() },
            resume: { await manager.resume() },
            stopSpeaking: { await manager.stopSpeaking() },
            jumpToStep: { index in await manager.jumpToStep(index) },
            setRate: { rate in await manager.setRate(rate) },
            statusStream: { await manager.statusStream() },
            stepIndexStream: { await manager.stepIndexStream() },
            cleanup: { await manager.cleanup() }
        )
    }
}
```

### Pattern 2: AVSpeechManager — @MainActor class with Delegate

**What:** `@MainActor` class that conforms to `AVSpeechSynthesizerDelegate`. The delegate protocol requires NSObject inheritance. Owns the synthesizer as a stored property (not global, not local — avoids dealloc bugs).

**Why @MainActor:** `AVSpeechSynthesizerDelegate` callbacks arrive on an unspecified queue. Isolating to MainActor eliminates data races without explicit dispatch.

```swift
// Source: Apple Developer Forums thread/738048 (iOS 17 fix pattern)
@MainActor
final class AVSpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = AVSpeechManager()

    private var synthesizer: AVSpeechSynthesizer?
    private var steps: [String] = []
    private var currentStepIndex: Int = 0
    private var speed: Float = 1.0
    private var statusContinuation: AsyncStream<PlaybackStatus>.Continuation?
    private var stepContinuation: AsyncStream<Int>.Continuation?
    private var retryCount: Int = 0
    private var timeoutTask: Task<Void, Never>?

    private override init() { super.init() }

    func speak(steps: [String], speed: Float) async throws {
        self.steps = steps
        self.speed = speed
        self.currentStepIndex = 0
        self.retryCount = 0
        enqueueUtterances(from: 0)
    }

    private func enqueueUtterances(from index: Int) {
        // Dealloc and recreate synthesizer (iOS 17 -4010 fix)
        synthesizer?.stopSpeaking(at: .immediate)
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
        synthesizer?.usesApplicationAudioSession = true  // Use app's .playback session

        for (i, text) in steps.enumerated().dropFirst(index) {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = preferredVoice()
            utterance.rate = mappedRate(speed)
            utterance.postUtteranceDelay = 1.2  // ~1.2s inter-step pause
            synthesizer?.speak(utterance)
        }

        // Start 5-second timeout for iOS 17 silent failure detection
        startSilentFailureTimeout()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        timeoutTask?.cancel()  // Speech started: cancel silent-failure timeout
        statusContinuation?.yield(.playing)
        stepContinuation?.yield(currentStepIndex)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let nextIndex = currentStepIndex + 1
        if nextIndex < steps.count {
            currentStepIndex = nextIndex
            stepContinuation?.yield(nextIndex)
        } else {
            statusContinuation?.yield(.stopped)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        statusContinuation?.yield(.paused)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        statusContinuation?.yield(.playing)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Only emit stopped if all steps cancelled (not mid-switch)
    }
}
```

### Pattern 3: iOS 17 Silent Failure Timeout

**What:** Race a 5-second `Task.sleep` against the first delegate callback. If timeout fires first, retry once (dealloc + reinit synthesizer). After 2 failures, emit `.error`.

```swift
// Source: Apple Developer Forums thread/738048 — reinit synthesizer between retries
private func startSilentFailureTimeout() {
    timeoutTask?.cancel()
    timeoutTask = Task { [weak self] in
        guard let self else { return }
        try? await Task.sleep(for: .seconds(5))
        guard !Task.isCancelled else { return }
        await self.handleSilentFailure()
    }
}

private func handleSilentFailure() {
    if retryCount < 1 {
        retryCount += 1
        enqueueUtterances(from: currentStepIndex)  // Reinit + retry same step
    } else {
        statusContinuation?.yield(.error("Voice unavailable — Retry"))
    }
}
```

### Pattern 4: VoicePlaybackReducer Branch

**What:** In `selectVoice` and `narrationReady`, branch on `voiceId == "kindred-default"` to take the AVSpeech path instead of fetching from backend.

```swift
// Branch point in selectVoice (after cache check)
case let .selectVoice(voiceId):
    if voiceId == "kindred-default" {
        return .send(.avSpeechStartRequested)
    } else {
        // existing ElevenLabs/AVPlayer path
    }

// New action for AVSpeech path
case .avSpeechStartRequested:
    state.isLoadingNarration = false
    state.currentPlayback = CurrentPlayback(
        recipeId: ...,
        voiceId: "kindred-default",
        speakerName: "Kindred Voice",
        duration: 0,           // AVSpeech has no pre-known duration
        currentTime: 0,
        speed: .normal,
        status: .loading,
        currentStepIndex: 0
    )
    let preprocessedSteps = state.recipeSteps.map(TextPreprocessor.prepare)
    return .concatenate(
        .run { send in
            do {
                try await avSpeechClient.speak(preprocessedSteps, .normal)
            } catch {
                await send(.narrationFailed(error.localizedDescription))
            }
        },
        .merge(
            .run { send in
                for await status in await avSpeechClient.statusStream() {
                    await send(.statusChanged(status))
                }
            }.cancellable(id: CancelID.statusObserver),
            .run { send in
                for await index in await avSpeechClient.stepIndexStream() {
                    await send(.avSpeechStepChanged(index))
                }
            }.cancellable(id: CancelID.avSpeechStepObserver)
        )
    )
```

### Pattern 5: Rate Mapping (Claude's Discretion — Recommended)

AVSpeechUtterance.rate range is [AVSpeechUtteranceMinimumSpeechRate (0.0) .. AVSpeechUtteranceMaximumSpeechRate (1.0)] where `AVSpeechUtteranceDefaultSpeechRate` = 0.5.

App speed controls: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x (PlaybackSpeed enum).

Recommended linear mapping:
```swift
// Source: AVSpeechUtterance Apple docs + empirical range
// App 1.0x → AVSpeech 0.5 (default), App 2.0x → AVSpeech 0.65, App 0.5x → AVSpeech 0.35
static func mappedRate(_ appSpeed: Float) -> Float {
    // Linear interpolation: [0.5x..2.0x] → [0.35..0.65]
    let normalized = (appSpeed - 0.5) / 1.5  // 0..1
    return 0.35 + normalized * 0.30
}
```

### Pattern 6: Voice Selection (Claude's Discretion — Recommended)

```swift
// Source: AVSpeechSynthesisVoice Apple docs
// Prefer enhanced quality for current locale; fall back to default quality; fall back to nil (system default)
private func preferredVoice() -> AVSpeechSynthesisVoice? {
    let languageCode = AVSpeechSynthesisVoice.currentLanguageCode()
    let voices = AVSpeechSynthesisVoice.speechVoices()
        .filter { $0.language.hasPrefix(languageCode.prefix(2)) }
    return voices.first(where: { $0.quality == .enhanced })
        ?? voices.first(where: { $0.quality == .default })
        ?? AVSpeechSynthesisVoice(language: languageCode)
}
```

### Pattern 7: Audio Session Handoff (AVSpeech → AVPlayer)

**Critical:** AVSpeechSynthesizer does NOT deactivate the audio session after finishing. If AVPlayer tries to play immediately after, the session routing can be corrupted.

```swift
// Source: Apple Developer Forums — usesApplicationAudioSession + explicit cleanup
// In AVSpeechManager.cleanup():
func cleanup() async {
    synthesizer?.stopSpeaking(at: .immediate)
    synthesizer?.delegate = nil
    synthesizer = nil
    timeoutTask?.cancel()
    // Explicit session deactivation so AVPlayer gets a clean slate
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    statusContinuation?.finish()
    stepContinuation?.finish()
}
```

### Pattern 8: VoiceOver Pause During AVSpeech (Claude's Discretion — Recommended)

The recommended approach is to NOT use the audio session category change (too disruptive). Instead:
- Before starting AVSpeech, call `UIAccessibility.post(notification: .announcement, argument: "")` with empty string to interrupt any running VoiceOver announcement.
- Between steps, post the step number: `UIAccessibility.post(notification: .announcement, argument: "Step \(stepIndex + 1)")`.
- VoiceOver and AVSpeech will naturally interleave since VoiceOver uses the same TTS stack — they won't truly overlap.

### Pattern 9: StepTimelineView Tap-to-Jump

`StepTimelineView` already accepts `currentStepIndex: Int?`. Add a `onStepTapped: ((Int) -> Void)?` parameter and call `avSpeechClient.jumpToStep(index)` which stops the current utterance queue and re-enqueues from the target index.

### Anti-Patterns to Avoid

- **Don't use a local AVSpeechSynthesizer in a closure:** Synthesizer gets deallocated before speaking. Must be stored as a property of a retained object.
- **Don't set delegate to nil before stopSpeaking:** Delegate callbacks needed for cleanup; nil the delegate AFTER stopSpeaking returns.
- **Don't call AVSpeechSynthesizer.speak() from a background actor:** `speak()` and delegate methods must be on MainActor or an `NSObject` that is not actor-isolated. Use `@MainActor` class, not a `actor`.
- **Don't rely on postUtteranceDelay for step tracking:** `didFinish` fires at end of utterance speech, BEFORE postUtteranceDelay completes. Use `didStart` for step index advances, not `didFinish`.
- **Don't call avSpeechClient.speak() without cancelling active ElevenLabs streams first:** The existing CancelID pattern handles this — cancel `.statusObserver`, `.timeObserver`, `.durationObserver` before starting AVSpeech, and add a new `.avSpeechStepObserver` CancelID.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Abbreviation expansion | Custom regex engine | Simple `String.replacingOccurrences` with word-boundary regex | Cooking abbreviations are a fixed small set |
| HTML stripping | Manual parser | `NSAttributedString(data:options:documentAttributes:)` with `.html` type | Handles edge cases in HTML entities |
| Unicode fraction expansion | Character iteration | Dictionary lookup `["½": "one half", "¼": "one quarter", "¾": "three quarters"]` | Only 3 relevant fractions in cooking |
| Step timestamp tracking | Float math estimation | `didStart`/`didFinish` delegate callbacks | Exact, no estimation needed |
| Background audio enable | Custom session logic | `usesApplicationAudioSession = true` (already set in `AudioSessionConfigurator`) | Already configured; no additional work |

**Key insight:** AVSpeechSynthesizer's delegate is the only reliable step-tracking mechanism. Do not estimate timestamps from text length — character counts and speech rate don't account for prosody, pauses, or word complexity.

---

## Common Pitfalls

### Pitfall 1: AVSpeechSynthesizer Deallocation During Speech
**What goes wrong:** Synthesizer is created in a `run` block closure, goes out of scope, gets deallocated — speech silently stops.
**Why it happens:** Swift ARC; no strong reference maintained.
**How to avoid:** Synthesizer must be a stored property of a retained object (`AVSpeechManager.shared`).
**Warning signs:** Speech starts but stops after first word; no delegate callbacks after initial start.

### Pitfall 2: iOS 17.0–17.4 TTSErrorDomain -4010 Silent Failure
**What goes wrong:** `speak()` is called, no delegate callbacks fire, synthesizer hangs indefinitely.
**Why it happens:** iOS 17 regression in the TTS daemon with certain voice identifiers. Fixed in later iOS 17.x patches but still affects some devices.
**How to avoid:** 5-second timeout Task races against first `didStart` callback. On timeout, dealloc and reinit the synthesizer before retrying.
**Warning signs:** No `didStart` callback within 5 seconds of enqueuing utterances on a real device (not Simulator — Simulator doesn't reproduce this).

### Pitfall 3: Delegate Not Called After Synthesizer Reinit
**What goes wrong:** After reinit for retry, delegate is nil or pointing to released object.
**Why it happens:** `synthesizer.delegate = self` must be re-assigned after every `AVSpeechSynthesizer()` init.
**How to avoid:** `enqueueUtterances` always does: `synthesizer = AVSpeechSynthesizer(); synthesizer?.delegate = self` before any `speak()`.

### Pitfall 4: Audio Session Not Deactivated After AVSpeech Completion
**What goes wrong:** AVPlayer starts after AVSpeech finishes, but audio is silently ducked or routed wrong.
**Why it happens:** AVSpeechSynthesizer activates the session but does not call `setActive(false)` when done.
**How to avoid:** `AVSpeechManager.cleanup()` explicitly calls `setActive(false, options: .notifyOthersOnDeactivation)` before returning. `AudioPlayerManager.play()` then calls `setActive(true)` fresh.
**Warning signs:** First ElevenLabs play after AVSpeech is silent or very quiet; subsequent plays work fine.

### Pitfall 5: NSObject + @MainActor Initializer Conflict
**What goes wrong:** Swift 6 strict concurrency rejects `@MainActor` isolation on `NSObject` subclasses with `override init()`.
**Why it happens:** `NSObject.init()` is not `@MainActor`, so subclass override violates isolation.
**How to avoid:** Use `nonisolated(unsafe)` on the synthesizer property, or mark the entire class `@MainActor` and suppress the init warning with `@preconcurrency`. Alternatively, use `MainActor.assumeIsolated` in the init. The `@MainActor` class approach (not `actor`) is preferred — `AVSpeechSynthesizerDelegate` cannot be adopted by a Swift `actor`.
**Warning signs:** Build error: "Main actor-isolated instance method 'speechSynthesizer(_:didStart:)' cannot be used to satisfy nonisolated protocol requirement".

### Pitfall 6: willSpeakRangeOfSpeechString Is Word-Level, Not Step-Level
**What goes wrong:** Developer uses `willSpeakRangeOfSpeechString` for step index tracking, gets per-word callbacks.
**Why it happens:** The delegate fires for every word boundary, not per utterance.
**How to avoid:** Use `didStart utterance:` for step start detection. Track step index by matching utterance reference to enqueued utterance array, or track by counter incremented on `didFinish`.

### Pitfall 7: jumpToStep Leaves Previous Utterances Queued
**What goes wrong:** User taps step 5; old utterances for steps 2-4 are still in the queue and play first.
**Why it happens:** AVSpeechSynthesizer maintains its own internal queue. You cannot selectively remove utterances; only `stopSpeaking(at: .immediate)` clears it.
**How to avoid:** `jumpToStep` calls `stopSpeaking(at: .immediate)` then re-enqueues from the target step index.

### Pitfall 8: Free User Auto-Play Bypasses Voice Picker
**What goes wrong:** `startPlayback` always shows voice picker (current code path); free users should skip picker.
**Why it happens:** Current `VoicePlaybackReducer.startPlayback` shows picker when no `lastUsedVoicePerRecipe` entry exists.
**How to avoid:** In `startPlayback`, check subscription status: if `.free`, automatically call `selectVoice("kindred-default")` without showing picker. Only show picker if `.pro` or `.unknown`.

---

## Code Examples

### TextPreprocessor: Cooking Abbreviation Expansion

```swift
// Source: Implementation per CONTEXT.md locked decision
enum TextPreprocessor {
    static func prepare(_ rawText: String) -> String {
        var text = rawText
        text = stripHTML(text)
        text = stripMarkdown(text)
        text = expandFractions(text)
        text = expandAbbreviations(text)
        text = normalizeAmounts(text)
        return text
    }

    private static let abbreviations: [(pattern: String, replacement: String)] = [
        ("\\btbsp\\.?\\b", "tablespoon"),
        ("\\btbsps?\\.?\\b", "tablespoons"),
        ("\\btsp\\.?\\b", "teaspoon"),
        ("\\btsps?\\.?\\b", "teaspoons"),
        ("\\boz\\.?\\b", "ounce"),
        ("\\blb\\.?\\b", "pound"),
        ("\\blbs\\.?\\b", "pounds"),
        ("\\bml\\.?\\b", "milliliter"),
        ("\\bg\\.?\\b(?=\\s)", "gram"),
        ("\\bkg\\.?\\b", "kilogram"),
        ("\\bcm\\.?\\b", "centimeter"),
        ("\\bmin\\.?\\b", "minute"),
        ("\\bhr?\\.?\\b", "hour"),
    ]

    private static func expandAbbreviations(_ text: String) -> String {
        var result = text
        for (pattern, replacement) in abbreviations {
            result = result.replacingOccurrences(of: pattern,
                                                  with: replacement,
                                                  options: [.regularExpression, .caseInsensitive])
        }
        return result
    }

    private static func expandFractions(_ text: String) -> String {
        text
            .replacingOccurrences(of: "½", with: "one half")
            .replacingOccurrences(of: "¼", with: "one quarter")
            .replacingOccurrences(of: "¾", with: "three quarters")
            .replacingOccurrences(of: "⅓", with: "one third")
            .replacingOccurrences(of: "⅔", with: "two thirds")
    }

    private static func stripHTML(_ text: String) -> String {
        // Fast path: no < means no HTML
        guard text.contains("<") else { return text }
        return text.replacingOccurrences(of: "<[^>]+>",
                                          with: "",
                                          options: .regularExpression)
    }

    private static func stripMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "^#{1,6}\\s", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^[-*+]\\s", with: "", options: .regularExpression)
    }

    private static func normalizeAmounts(_ text: String) -> String {
        // 2-3 → "two to three", ~500 → "approximately 500"
        var result = text
        result = result.replacingOccurrences(of: "(\\d+)-(\\d+)", with: "$1 to $2", options: .regularExpression)
        result = result.replacingOccurrences(of: "~(\\d+)", with: "approximately $1", options: .regularExpression)
        return result
    }
}
```

### VoicePickerView Section Headers

```swift
// The existing VoicePickerView needs section headers. Use List/Section or manual VStack grouping.
// "Free" section: profiles where id == "kindred-default"
// "Pro Voices" section: all other profiles (ElevenLabs cloned voices)
// Lock badge already implemented via isVoiceLocked() — just add section headers and subtitle/avatar for Kindred Voice
```

### Kindred Voice Card Customization

```swift
// In VoiceCardView, detect kindred-default and show Kindred app icon + "On-device narration" subtitle
if profile.id == "kindred-default" {
    Image("AppIcon")  // from Assets.xcassets
        .resizable()
        .frame(width: 44, height: 44)
        .clipShape(Circle())
} else {
    // existing avatar logic
}

// Subtitle
if profile.id == "kindred-default" {
    Text("On-device narration")
        .font(.kindredCaption())
        .foregroundStyle(.kindredTextSecondary)
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manually tracking word ranges via willSpeakRangeOfSpeechString | Per-utterance tracking via didStart/didFinish | iOS 7+ stable | Use didStart for step index; willSpeakRange for word-level only if needed |
| Global AVSpeechSynthesizer singleton | Actor/class-owned retained instance | Swift concurrency adoption | Allows dealloc+reinit for iOS 17 retry without affecting other callers |
| usesApplicationAudioSession = false (system-managed) | usesApplicationAudioSession = true (app-managed) | WWDC 2020 | App controls session lifecycle; required for clean handoff to AVPlayer |

**Deprecated/outdated:**
- `AVSpeechSynthesizer.speak(at:)` with `.word` boundary: Not deprecated but use `didStart utterance` for step tracking — more reliable than boundary events for coarse step granularity.
- `SSML` in AVSpeechUtterance: Available iOS 16+ but per CONTEXT.md decision: use plain text + postUtteranceDelay instead. SSML adds complexity for marginal benefit in cooking narration.

---

## Open Questions

1. **Does `didStart utterance:` reliably map utterance identity to step index on iOS 17?**
   - What we know: `didStart` receives the specific `AVSpeechUtterance` object. We can match by object identity or use a counter.
   - What's unclear: Whether iOS 17 reorders utterances in the queue in edge cases.
   - Recommendation: Use a counter (`currentStepIndex`) incremented in `didFinish`, advanced in `didStart`. Object identity matching is fragile if utterances are recreated on retry.

2. **Does `usesApplicationAudioSession = true` fully prevent session routing bugs on all iOS 17 devices?**
   - What we know: This property tells the synthesizer to use the app's session (`.playback`, `.spokenAudio`). Apple recommends `true` for apps with their own audio sessions.
   - What's unclear: Whether iOS 17.0 has bugs with this property specifically.
   - Recommendation: Set to `true`. If handoff bugs appear, add `setActive(false)` in cleanup before falling through to AVPlayer.

3. **Is the TextPreprocessor fast enough to run synchronously before enqueuing utterances?**
   - What we know: Operations are String replacements — O(n) where n is text length. Recipe steps are typically 50-200 characters each.
   - What's unclear: Performance impact of regex on first invocation.
   - Recommendation: Run synchronously in `avSpeechClient.speak()` before creating utterances. No async needed. Lazy-compile regexes as static let.

---

## Validation Architecture

> nyquist_validation is not enabled in .planning/config.json — skipping formal test matrix.

Key verification behaviors for manual UAT (per success criteria):
1. Free-tier user taps play → AVSpeech narrates step-by-step with step highlight scrolling
2. Pro user taps play → ElevenLabs narrates (not AVSpeech)
3. AVSpeech → ElevenLabs switch: cancel observers, call cleanup, resume from step index
4. iOS 17 silent failure: error state surfaces within 5 seconds
5. Lock screen shows "Kindred Voice" as artist; controls work

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `AVSpeechSynthesizer` — https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer
- Apple Developer Documentation — `AVSpeechSynthesizerDelegate.speechSynthesizer(_:didFinish:)` — https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/1619700-speechsynthesizer
- Apple Developer Documentation — `AVSpeechSynthesizerDelegate.speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:)` — https://developer.apple.com/documentation/avfoundation/avspeechsynthesizerdelegate/1619681-speechsynthesizer
- Apple Developer Documentation — `AVSpeechSynthesisVoiceQuality` — https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality
- Apple Developer Documentation — `usesApplicationAudioSession` — https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/usesapplicationaudiosession
- Apple Developer Documentation — `postUtteranceDelay` — https://developer.apple.com/documentation/avfoundation/avspeechutterance/1619694-postutterancedelay
- Existing project codebase — `AudioPlayerClient.swift`, `AudioPlayerManager.swift`, `VoicePlaybackReducer.swift`, `StepTimelineView.swift` — live code reference

### Secondary (MEDIUM confidence)
- Apple Developer Forums — iOS 17 TTSErrorDomain -4010 + synthesizer reinit workaround — https://developer.apple.com/forums/thread/738048
- Apple Developer Forums — AVSpeechSynthesizer broken on iOS 17 — https://developer.apple.com/forums/thread/737685
- Hacking with Swift — Word highlighting via willSpeakRangeOfSpeechString — https://www.hackingwithswift.com/example-code/media/how-to-highlight-text-to-speech-words-being-read-using-avspeechsynthesizer
- GitHub: renaudjenny/swift-tts — TCA-compatible AVSpeechSynthesizer dependency pattern — https://github.com/renaudjenny/swift-tts

### Tertiary (LOW confidence)
- WWDC 2020 — "Create a seamless speech experience in your apps" — session discusses usesApplicationAudioSession; accessed via search reference only
- General Swift concurrency + NSObject delegate isolation patterns — multiple forum threads, unverified for Swift 6 specifically

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — AVSpeechSynthesizer is a stable iOS framework; all APIs verified via Apple docs
- Architecture: HIGH — Pattern mirrors existing AudioPlayerClient/AudioPlayerManager; TCA dependency injection is established project pattern
- Pitfalls: HIGH (iOS 17 bug) / MEDIUM (session handoff) — iOS 17 bug confirmed by multiple Apple dev forum threads; session handoff pattern confirmed by Apple docs but project-specific interaction needs real-device validation

**Research date:** 2026-04-13
**Valid until:** 2026-10-13 (6 months — AVSpeechSynthesizer is stable; iOS 18 introduced no breaking changes to the API)
