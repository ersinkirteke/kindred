---
phase: 03
plan: 01
subsystem: voice-foundation
tags: [prisma, graphql, elevenlabs, r2-storage, voice-cloning]
dependency_graph:
  requires: [01-01-foundation, 01-04-image-generation]
  provides: [voice-profile-schema, elevenlabs-client, voice-storage]
  affects: [03-02-voice-upload, 03-03-voice-narration]
tech_stack:
  added: [elevenlabs-api]
  patterns: [graceful-service-initialization, formdata-multipart]
key_files:
  created:
    - backend/src/voice/voice.module.ts
    - backend/src/voice/elevenlabs.service.ts
    - backend/src/voice/dto/voice-profile.dto.ts
    - backend/src/voice/dto/upload-voice.input.ts
  modified:
    - backend/prisma/schema.prisma
    - backend/src/app.module.ts
    - backend/src/images/r2-storage.service.ts
    - backend/.env.example
decisions:
  - VoiceStatus enum with lifecycle states (PENDING → PROCESSING → READY → FAILED → DELETED)
  - GraphQL DTOs exclude internal fields (elevenLabsVoiceId, audioSampleUrl, consent data)
  - Graceful initialization pattern when ELEVENLABS_API_KEY is missing (log warning, don't crash)
  - eleven_flash_v2_5 model for ultra-low latency TTS (~75ms)
  - Swallow 404 errors when deleting voices (idempotent cleanup)
  - R2 voice sample storage follows same pattern as image storage
  - consentGiven is a required boolean in UploadVoiceInput (backend validation)
metrics:
  duration_minutes: 4
  tasks_completed: 2
  files_created: 4
  files_modified: 4
  commits: 2
  completed_at: "2026-03-01T12:10:57Z"
---

# Phase 03 Plan 01: Voice Foundation Summary

**Established foundational data models, ElevenLabs API client, and R2 storage for voice cloning pipeline with consent tracking and status lifecycle.**

## Tasks Completed

### Task 1: VoiceProfile Prisma Schema, VoiceModule Scaffold, and GraphQL DTOs
**Commit:** ad418af

Created the foundational schema and module structure:
- Added `VoiceStatus` enum with lifecycle states (PENDING, PROCESSING, READY, FAILED, DELETED)
- Added `VoiceProfile` model with status tracking, speaker metadata, and legal consent fields
- Added `voiceProfiles` relation to User model
- Created VoiceModule and registered in AppModule
- Created GraphQL DTOs (VoiceProfileDto, UploadVoiceInput)
- VoiceProfileDto excludes internal fields (elevenLabsVoiceId, audioSampleUrl, consent data)
- UploadVoiceInput requires consentGiven boolean for legal compliance

**Files created:**
- `backend/src/voice/voice.module.ts`
- `backend/src/voice/dto/voice-profile.dto.ts`
- `backend/src/voice/dto/upload-voice.input.ts`

**Files modified:**
- `backend/prisma/schema.prisma`
- `backend/src/app.module.ts`

### Task 2: ElevenLabs REST API Service and R2 Voice Sample Storage
**Commit:** ea78d24

Implemented ElevenLabs API client and extended R2 storage:
- Created ElevenLabsService with 4 methods:
  - `cloneVoice()`: POST to /voices/add with FormData multipart upload
  - `deleteVoice()`: DELETE to /voices/{voiceId} with 404 swallowing
  - `generateSpeechStream()`: POST to /text-to-speech/{voiceId}/stream with eleven_flash_v2_5 model
  - `getVoice()`: GET to /voices/{voiceId} for status checking
- Graceful initialization when ELEVENLABS_API_KEY is missing (log warning, don't crash)
- Extended R2StorageService with voice sample methods:
  - `uploadVoiceSample()`: Store audio at `voice-samples/{userId}/{timestamp}.mp3`
  - `deleteVoiceSample()`: Extract key from URL and delete (swallow errors)
- Wired ElevenLabsService into VoiceModule with ImagesModule import
- Added ELEVENLABS_API_KEY to .env.example

**Files created:**
- `backend/src/voice/elevenlabs.service.ts`

**Files modified:**
- `backend/src/voice/voice.module.ts`
- `backend/src/images/r2-storage.service.ts`
- `backend/.env.example`

## Verification Results

### Automated Tests
```bash
✓ npx prisma validate - Schema is valid
✓ npx tsc --noEmit - All TypeScript compiles without errors
```

### Manual Verification
- [x] VoiceProfile model exists with all required fields
- [x] VoiceStatus enum registered in Prisma and GraphQL
- [x] User.voiceProfiles relation exists
- [x] VoiceModule registered in AppModule
- [x] ElevenLabsService is injectable with all 4 methods
- [x] R2StorageService has voice sample upload/delete methods
- [x] GraphQL DTOs properly decorated
- [x] Graceful initialization when ELEVENLABS_API_KEY is missing

## Deviations from Plan

None - plan executed exactly as written.

## Key Decisions Made

1. **VoiceStatus lifecycle:** PENDING → PROCESSING → READY → FAILED → DELETED provides clear state tracking for async cloning operations.

2. **GraphQL security:** VoiceProfileDto excludes internal fields (elevenLabsVoiceId, audioSampleUrl, consent data) to prevent leaking sensitive data to clients.

3. **Graceful initialization:** Following Mapbox/Firebase pattern from Phase 1/2, ElevenLabsService logs warning when ELEVENLABS_API_KEY is missing instead of crashing. Enables local development without API credentials.

4. **eleven_flash_v2_5 model:** Ultra-low latency model (~75ms) chosen per research for real-time TTS streaming.

5. **Idempotent cleanup:** Swallowing 404 errors when deleting voices/samples prevents race conditions and enables safe retry logic.

6. **Buffer to Uint8Array conversion:** FormData requires BlobPart types, so Buffer is converted to Uint8Array before Blob construction.

7. **Consent enforcement:** consentGiven is a required boolean in UploadVoiceInput, ensuring backend validation (not just frontend checkbox).

## Dependencies

### Requires
- 01-01: Prisma schema, User model, database connection
- 01-04: R2StorageService for voice sample backup

### Provides
- VoiceProfile Prisma model with status lifecycle
- ElevenLabsService for voice cloning and TTS
- R2 voice sample storage capability
- GraphQL DTOs for voice profile operations

### Affects
- 03-02: Voice upload resolver will use UploadVoiceInput and ElevenLabsService
- 03-03: Voice narration will use generateSpeechStream for TTS

## Technical Notes

### ElevenLabs API Integration
- Base URL: `https://api.elevenlabs.io/v1`
- Authentication: `xi-api-key` header
- Voice cloning: POST /voices/add with multipart/form-data
- TTS streaming: POST /text-to-speech/{voiceId}/stream with model_id: eleven_flash_v2_5
- Voice settings: stability=0.5, similarity_boost=0.75 (balanced quality/naturalness)

### Voice Sample Storage
- Storage path: `voice-samples/{userId}/{timestamp}.mp3`
- Content-Type: `audio/mpeg`
- Public CDN URL returned for backup/compliance
- Deletion swallows errors (file may already be deleted)

### Legal Compliance Fields
- `consentedAt`: DateTime timestamp when user consented
- `consentIpAddress`: IP address when consent given
- Tennessee ELVIS Act and California AB 1836 compliance

## Self-Check: PASSED

### Created Files Verification
```bash
✓ backend/src/voice/voice.module.ts exists
✓ backend/src/voice/elevenlabs.service.ts exists
✓ backend/src/voice/dto/voice-profile.dto.ts exists
✓ backend/src/voice/dto/upload-voice.input.ts exists
```

### Commits Verification
```bash
✓ ad418af: feat(03-01): add VoiceProfile Prisma model and GraphQL DTOs
✓ ea78d24: feat(03-01): add ElevenLabs API client and R2 voice sample storage
```

### Modified Files Verification
```bash
✓ backend/prisma/schema.prisma contains VoiceProfile model and VoiceStatus enum
✓ backend/src/app.module.ts imports and registers VoiceModule
✓ backend/src/images/r2-storage.service.ts has uploadVoiceSample and deleteVoiceSample methods
✓ backend/.env.example has ELEVENLABS_API_KEY entry
```

All files created, commits recorded, and modifications verified. Plan 03-01 completed successfully.
