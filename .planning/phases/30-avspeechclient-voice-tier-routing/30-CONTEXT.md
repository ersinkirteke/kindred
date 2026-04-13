# Phase 30: AVSpeechClient + Voice Tier Routing - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Build an AVSpeechSynthesizer-based TCA client for free-tier recipe narration, wire automatic voice tier routing (free = AVSpeech, Pro = ElevenLabs), and add step highlighting with tap-to-jump. No backend changes required — all data (recipe steps, subscription status, voice profiles) is already available in the app.

</domain>

<decisions>
## Implementation Decisions

### Voice Selection UX
- Show all voices in picker (free + Pro). Pro voices display a lock icon/badge. Tapping a locked voice opens the existing paywall immediately
- Voice picker has section headers: "Free" section with Kindred Voice, "Pro Voices" section with ElevenLabs cloned voices
- Free-tier system voice is called "Kindred Voice" (keep current name)
- Kindred Voice shows subtitle "On-device narration" in the picker to set expectations
- Kindred Voice avatar uses the Kindred app icon/logo
- Voice upload (clone your voice) visible for free users with Pro badge — another upsell surface
- Free user taps play: auto-play with Kindred Voice immediately (no picker required). Voice picker available but not mandatory
- Pro subscriber downgrades: silent fallback to Kindred Voice on next play — no toast or explanation
- AVSpeech voice language matches device locale automatically (if Turkish device, Turkish accent/pronunciation)

### TTS Playback Experience
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

### Failure & Fallback Behavior
- 5 second timeout for AVSpeech silent failure detection (TTSErrorDomain -4010 on iOS 17)
- On failure: show error in mini player with retry button. "Voice unavailable — Retry"
- 1 automatic retry after timeout. If second attempt also fails, show manual retry button
- If AVSpeech fails for a Pro subscriber: auto-fallback to ElevenLabs narration silently
- If device has no TTS voice installed: show error with guidance to download a voice from Settings > Accessibility > Spoken Content > Voices
- No limit on step count — narrate all steps regardless of recipe length
- No persistent failure tracking — each session is independent
- Auto-resume after phone call / Siri interruption (resume from where it left off)

### Audio Session Handoff
- Pro upgrade mid-session: wait until next recipe to offer ElevenLabs. Don't interrupt current AVSpeech narration
- Switching voice types mid-recipe (AVSpeech to ElevenLabs): resume from current step position, not from beginning
- Voice switch transition: abrupt stop-then-start (no crossfade, no loading indicator)
- Playing a different recipe while AVSpeech is active: stop AVSpeech immediately (cancel mid-sentence)
- Other apps' audio: pause (standard .playback behavior). Other app resumes when Kindred stops
- Cached ElevenLabs audio plays offline — don't force AVSpeech when cache has the audio
- Offline + uncached Pro voice: auto-fallback to Kindred Voice with brief note "Using Kindred Voice — no internet connection"

### Step Text Preprocessing
- Expand common cooking abbreviations before TTS: tbsp → tablespoon, tsp → teaspoon, oz → ounce, lb → pound, ml → milliliter, g → gram
- Strip HTML/markdown formatting from step text (tags, bold/italic markers, bullets)
- Prefix each step with step number: "Step 1: Preheat the oven..."
- Temperature values: read as-is from recipe, no F↔C conversion
- Expand Unicode fractions: ½ → "one half", ¼ → "one quarter", ¾ → "three quarters"
- Normalize ingredient amounts: ranges (2-3 → "two to three"), approximations (~500 → "approximately 500")
- Narrate everything including parenthetical notes — don't strip parentheses
- No SSML — feed plain preprocessed text to AVSpeech. Use postUtteranceDelay for inter-step pauses
- English-only abbreviation expansion for now (Spoonacular recipes are in English)

### Offline Behavior
- No explicit "Works offline" promotion for Kindred Voice
- Offline + Pro voice not cached: auto-fallback to Kindred Voice
- Offline + Pro voice cached: play the cached ElevenLabs audio

### Accessibility
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

</decisions>

<specifics>
## Specific Ideas

- Voice picker sections: "Free" header with Kindred Voice (app icon avatar + "On-device narration" subtitle), then "Pro Voices" header with ElevenLabs voices (each with lock badge for free users)
- Step highlighting: bold text + accent background, auto-scrolling, tap-to-jump — the cooking equivalent of a karaoke highlight
- Preprocessing pipeline: abbreviation expansion → fraction expansion → amount normalization → HTML stripping → step number prefix — in that order
- Failure cascade: try AVSpeech → auto-retry once → (if Pro) fallback to ElevenLabs → show error with manual retry

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VoicePlaybackReducer.swift`: Full TCA reducer with playback state, voice selection, subscription checks. Add AVSpeech branch alongside ElevenLabs
- `AudioPlayerClient.swift`: TCA dependency protocol for audio playback. Extend or create parallel AVSpeechClient
- `StepSyncEngine.swift`: Binary search step-to-timestamp mapping. Ready to use once step timestamps are provided
- `VoiceCacheClient.swift` + `LRUCache.swift`: Cache system for ElevenLabs audio. AVSpeech doesn't need caching
- `AudioSessionConfigurator.swift`: Already configured for .playback + .spokenAudio. Background audio, interruption handling, route changes all handled
- `NowPlayingManager.swift`: Lock screen metadata already uses speaker name as "artist" — just pass "Kindred Voice"
- `SubscriptionClient.swift`: `.currentEntitlement()` returns `.free` or `.pro` — tier routing decision point
- `VoicePickerView.swift`: Existing voice list UI. Needs section headers and lock badges added
- `MiniPlayerView.swift`: Already has error state rendering (red text). Add retry button
- `ExpandedPlayerView.swift`: Player controls. Add VoiceOver custom actions

### Established Patterns
- TCA reducer + dependency injection for all audio operations
- Actor-based `AudioPlayerManager.shared` singleton for AVPlayer
- AsyncStream-based status/time/duration streams from audio player to reducer
- `CurrentPlayback` struct tracks all playback state including `currentStepIndex`
- `switchVoiceMidPlayback` action pattern: pause → save position → fetch new voice → resume

### Integration Points
- `AppReducer` routes `.listenTapped` from `RecipeDetailReducer` to `VoicePlaybackReducer.startPlayback`
- `AppReducer` passes `steps: recipe.steps.map(\.text)` — recipe step text is already available
- `RecipeDetailView` has `.playbackStatus` synced from VoicePlaybackReducer via AppReducer
- `AppDelegate.didFinishLaunchingWithOptions()` calls `AudioSessionConfigurator.configure()`
- Step highlighting would go in `RecipeDetailView` keyed on `currentPlayback.currentStepIndex`

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 30-avspeechclient-voice-tier-routing*
*Context gathered: 2026-04-13*
