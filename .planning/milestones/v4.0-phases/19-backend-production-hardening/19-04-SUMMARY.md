---
phase: 19-backend-production-hardening
plan: 04
subsystem: voice-narration
tags: [graphql, caching, r2, cascade-delete]
requirements: [VOICE-03]
dependency_graph:
  requires: [19-01]
  provides: [narration-url-query, duration-metadata, hash-cache-keys, cascade-delete]
  affects: [voice-resolver, narration-service, r2-storage-service]
tech_stack:
  added: [get-mp3-duration]
  patterns: [hash-based-cache-invalidation, cascade-delete]
key_files:
  created:
    - backend/src/voice/dto/narration-url.dto.ts
  modified:
    - backend/src/voice/voice.resolver.ts
    - backend/src/voice/narration.service.ts
    - backend/src/images/r2-storage.service.ts
    - backend/src/voice/voice.service.ts
    - backend/src/voice/narration.controller.ts
    - backend/package.json
decisions:
  - title: MD5 hash for cache invalidation
    rationale: 8-char MD5 hash provides collision-resistant cache keys while keeping URLs short
  - title: get-mp3-duration for duration computation
    rationale: Lightweight library (1 dependency) computes duration from MP3 buffer without spawning ffmpeg
  - title: Cascade delete before status update
    rationale: Delete narration audio before marking profile DELETED to ensure cleanup completes even if status update fails
metrics:
  duration_seconds: 223
  tasks_completed: 2
  files_modified: 6
  commits: 2
  completed_at: "2026-03-30T18:12:46Z"
---

# Phase 19 Plan 04: Narration Cache with Duration & GraphQL Query Summary

**One-liner:** GraphQL narrationUrl query with MP3 duration metadata, hash-based R2 cache keys, and cascade delete of narration audio on voice profile deletion.

## What Was Built

### Task 1: NarrationUrlDto and narrationUrl Query (Commit 67d74be)

**Created NarrationUrlDto GraphQL type:**
- `url: string | null` - R2 CDN URL (null if not cached)
- `speakerName: string` - Voice profile speaker name
- `relationship: string` - Relationship to user
- `recipeName: string` - Recipe name
- `durationMs: number | null` - Audio duration in milliseconds

**Added narrationUrl query to VoiceResolver:**
- Optional `voiceProfileId` parameter - falls back to user's primary (first READY) voice profile
- Validates ownership via `voiceService.getVoiceProfile`
- Returns null URL when no cached audio exists (client triggers REST stream)
- Uses GraphQLError with structured error codes (USER_NOT_FOUND, VOICE_PROFILE_NOT_FOUND, RECIPE_NOT_FOUND)

**Installed get-mp3-duration:** Lightweight package (1.0.0) for MP3 duration computation from buffer.

### Task 2: Enhanced Caching with Duration, Hash Keys, and Cascade Delete (Commit ce96e37)

**Enhanced cacheNarrationAudio method:**
- Made public (was private) for potential external callers
- Computes MP3 duration via `get-mp3-duration` package
- Generates 8-char MD5 hash from audio buffer for cache invalidation
- R2 key pattern: `narration/{recipeId}/{voiceProfileId}-{hash}.mp3`
- Stores `durationMs` in NarrationAudio database record
- Logs duration and hash in cache completion message

**Updated R2StorageService:**
- `uploadNarrationAudio` accepts optional `customKey` parameter (defaults to old pattern if not provided)
- Added `deleteNarrationAudio(url: string)` method for cleanup
- Swallows errors if file already deleted (idempotent)

**Added cascade delete to VoiceService.deleteVoiceProfile:**
- Queries all NarrationAudio records for the voice profile
- Deletes R2 files via `r2Storage.deleteNarrationAudio`
- Deletes NarrationAudio database records
- Logs count of deleted narration audios
- Runs before ElevenLabs voice deletion and status update

**Added rate limiting to stream endpoint:**
- `@Throttle({ expensive: { limit: 10, ttl: 60000 } })` on `/narration/:recipeId/stream`
- Protects ElevenLabs API from abuse
- Uses "expensive" named context from Phase 19-01 throttler configuration

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification checks passed:

1. ✅ `npm ls get-mp3-duration` confirms installation (v1.0.0)
2. ✅ TypeScript compilation passes for all modified files
3. ✅ `narrationUrl` query present in voice.resolver.ts
4. ✅ `durationMs` computation in narration.service.ts (lines 311-315)
5. ✅ Hash-based key generation in narration.service.ts (lines 306-308)
6. ✅ `deleteNarrationAudio` cascade in voice.service.ts (line 165)
7. ✅ `customKey` parameter in r2-storage.service.ts (lines 140, 147, 149)
8. ✅ `@Throttle({ expensive })` on stream endpoint in narration.controller.ts (line 44)

## Out-of-Scope Pre-existing Errors

TypeScript compilation revealed 4 pre-existing errors in `backend/src/subscription/subscription.service.ts`:
- Lines 263, 291: `originalTransactionId` typed as `string | undefined` (not `string`)
- Lines 334, 351: `AppTransaction` type not found

**Decision:** These errors are in unrelated subscription code and existed before this plan. Per Deviation Rule scope boundary, they are logged here but NOT fixed. No grep patterns in modified files (narration, voice, r2-storage) show any errors.

## Impact

**For iOS client:**
- Can query `narrationUrl` to check cache status before triggering expensive REST stream
- Receives `durationMs` for progress bar display
- Fallback to primary voice profile simplifies UX (no voiceProfileId required)

**For backend:**
- Hash-based R2 keys enable cache invalidation when narration changes (e.g., Gemini prompt update, voice re-clone)
- Cascade delete prevents orphaned R2 files when voice profiles are deleted
- Rate limiting protects ElevenLabs API from abuse
- Duration metadata enables analytics (e.g., "users listen to X minutes of narration per day")

**Cache invalidation scenario:**
- User re-records voice → new `elevenLabsVoiceId` → new narration audio → different hash → new R2 key
- Old R2 file remains (immutable CDN), but database points to new URL
- Future enhancement: background job to clean up orphaned R2 files

## Next Steps

**Immediate (Phase 19):**
- Plan 19-02: StoreKit 2 JWS verification (BILL-01)
- Plan 19-03: Push notification device token registration (PUSH-01, PUSH-02)

**iOS Integration (Phase 21):**
- iOS client to call `narrationUrl` query before streaming
- Display duration in playback UI
- Handle null URL by triggering REST stream

**Future Optimizations:**
- Background job to delete orphaned R2 files (files not referenced in NarrationAudio table)
- Pre-generate narration for trending recipes (async job after recipe creation)
- Track cache hit rate via analytics

## Self-Check

### Files Created
```bash
✅ backend/src/voice/dto/narration-url.dto.ts exists
```

### Commits
```bash
✅ Commit 67d74be exists (Task 1: narrationUrl query)
✅ Commit ce96e37 exists (Task 2: duration, hash keys, cascade delete)
```

### Key Patterns
```bash
✅ narrationUrl query in voice.resolver.ts
✅ durationMs computation in narration.service.ts
✅ Hash-based key generation in narration.service.ts
✅ Cascade delete in voice.service.ts
✅ @Throttle({ expensive }) in narration.controller.ts
```

## Self-Check: PASSED

All files created, commits exist, and key patterns verified.
