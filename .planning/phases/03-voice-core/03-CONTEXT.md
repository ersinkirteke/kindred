# Phase 3: Voice Core - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Backend API and services for voice cloning and recipe narration. Users upload a voice sample of a loved one, ElevenLabs clones it, and recipe instructions are narrated in that voice with streaming playback. This phase builds the voice pipeline API that mobile apps (Phase 4 iOS, Phase 9 Android) will consume. No mobile UI is built in this phase — playback controls and recording UI are mobile-side concerns in Phase 4/9.

</domain>

<decisions>
## Implementation Decisions

### Voice Upload Flow
- In-app recording only (no file upload) with a guided cooking passage script
- User reads a warm, food-related paragraph (~30-60 seconds) that captures cooking vocabulary naturally
- Live audio level meter during recording — warn if too quiet or too much background noise ("Speak a little louder" / "Try a quieter room")
- Background processing after upload: show "Your voice is being prepared", user continues browsing, push notification when clone is ready (~1-3 minutes)
- Non-blocking pattern matches image generation approach from Phase 1

### Narration Style
- Warm conversational tone: "Alright, now let's dice those tomatoes nice and small" — not clinical instructions
- AI-rewrite recipe text to conversational narration via Gemini before sending to ElevenLabs — transforms "Chop onions" into "Now, let's chop up those onions"
- On-demand generation with streaming: generate when user taps Listen, ElevenLabs streaming starts audio within 1-2 seconds while rest generates. No pre-generation, no storage cost for unplayed recipes
- Full guided experience: brief intro ("Today we're making Mom's Tuscan Chicken"), ingredients overview ("You'll need chicken breast, garlic..."), then step-by-step narration

### Playback Behavior
- Continuous audio flow with ~2 second pauses between steps — feels like someone talking you through it
- Background audio playback: continues when phone is locked or app is backgrounded. Lock screen shows playback controls. Essential for hands-free cooking
- Cache last 5 played narrations locally for offline replay (~50MB for 5 recipes). Automatic cleanup of oldest
- Jump between steps for seek: Previous/Next step buttons, not a time scrub bar. More useful for cooking ("wait, what did they say about the garlic?")

### Voice Profile Management
- Store speaker's name (e.g., "Mom", "Nonna Maria") and relationship (e.g., "Mother", "Grandmother")
- Displayed during playback: "Narrated by Mom"
- Soft upgrade prompt when free tier user (1 voice slot) tries to add another: "You're using your free voice slot. Upgrade to Pro for unlimited voices." Show current voice, let them replace OR upgrade. Never block
- Re-record flow: user records new sample, hears a short preview with the new voice before confirming. If satisfied, new voice replaces old. Old clone deleted from ElevenLabs. Prevents accidental loss
- Explicit voice consent screen required before upload: "I confirm this is my voice or I have permission from the person whose voice I'm recording." Checkbox + brief legal text. Required before upload (Tennessee ELVIS Act, California AB 1836)
- Voice sample audio files stored in Cloudflare R2 (same as hero images — zero-egress CDN, already set up in Phase 1). Provides backup independent of ElevenLabs

### Claude's Discretion
- ElevenLabs API integration details (model selection, parameters, error handling)
- Gemini prompt engineering for conversational narration rewriting
- Audio format and encoding choices (mp3 vs m4a, bitrate)
- Voice cloning status polling vs webhook approach
- Narration text chunking strategy (per-step vs whole recipe)
- R2 folder structure for voice samples
- Database schema for VoiceProfile and NarrationCache models

</decisions>

<specifics>
## Specific Ideas

- The guided recording passage should be food-themed and warm — "Imagine you're in the kitchen with someone you love" captures the emotional core
- Playback should feel like having a loved one in the kitchen with you, not like a podcast or audiobook
- The "Narrated by Mom" display during playback is the emotional moment that makes Kindred irreplaceable
- Voice consent is a legal necessity, not optional — Tennessee ELVIS Act and California AB 1836 govern voice cloning

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R2StorageService` (backend/src/images/r2-storage.service.ts): Cloudflare R2 upload/URL generation — reuse for voice sample storage
- `ImageGenerationProcessor` (backend/src/images/image-generation.processor.ts): In-memory background queue pattern — reuse for voice cloning background processing
- `PushService` (backend/src/push/push.service.ts): Push notification sending — use for "voice clone ready" notification
- `RecipeParserService` (backend/src/scraping/recipe-parser.service.ts): Gemini API integration — reuse patterns for narration text rewriting
- `RecipeStep` model: Has orderIndex, text, duration, techniqueTag — provides structured step data for narration

### Established Patterns
- Non-blocking background processing with status tracking (ImageStatus enum: PENDING → GENERATING → COMPLETED → FAILED)
- GraphQL code-first with NestJS decorators
- Prisma 7 with PostgreSQL for database
- Cloudflare R2 for file storage with S3-compatible API

### Integration Points
- User model (prisma/schema.prisma): Needs VoiceProfile relation (1 for free, unlimited for Pro)
- Recipe → RecipeStep: Step text is the source for narration content
- Auth guard: Voice features require authentication (not guest-accessible)
- Push notifications: Clone-ready notification via existing FCM infrastructure

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-voice-core*
*Context gathered: 2026-03-01*
