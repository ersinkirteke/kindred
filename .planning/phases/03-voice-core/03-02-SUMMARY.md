---
phase: 03
plan: 02
subsystem: voice-upload-pipeline
tags: [voice-cloning, multer, graphql, tier-enforcement, push-notifications]
dependency_graph:
  requires: [03-01-voice-foundation, 01-04-image-generation, 01-05-push-notifications]
  provides: [voice-upload-api, voice-cloning-queue, voice-management-graphql]
  affects: [03-03-voice-narration]
tech_stack:
  added: [multer-file-upload]
  patterns: [background-queue-processing, tier-enforcement, rest-file-upload]
key_files:
  created:
    - backend/src/voice/voice-cloning.processor.ts
    - backend/src/voice/voice.service.ts
    - backend/src/voice/voice.controller.ts
    - backend/src/voice/voice.resolver.ts
  modified:
    - backend/src/voice/voice.module.ts
    - backend/src/voice/dto/voice-profile.dto.ts
    - backend/src/voice/narration.controller.ts
    - backend/package.json
decisions:
  - In-memory queue for voice cloning (same pattern as ImageGenerationProcessor)
  - FREE tier limited to 1 active voice profile (PRO tier unlimited)
  - Tier enforcement via ForbiddenException with VOICE_SLOT_LIMIT error code
  - REST endpoints for file upload (GraphQL doesn't support multipart/form-data natively)
  - GraphQL resolver for voice profile queries and non-file mutations
  - Push notification sent on voice clone completion (VOICE_READY event)
  - Re-record flow via replaceVoice() updates existing profile instead of creating new
  - Consent validation on server side (consentGiven must be true)
  - IP address tracking for legal compliance (consentIpAddress field)
  - Prisma VoiceStatus enum used in DTOs (not duplicate GraphQL enum)
metrics:
  duration_minutes: 5
  tasks_completed: 2
  files_created: 4
  files_modified: 4
  commits: 2
  completed_at: "2026-03-01T12:20:00Z"
---

# Phase 03 Plan 02: Voice Upload Pipeline Summary

**Built complete voice upload-to-clone pipeline: REST file upload → R2 storage → background cloning → push notification, with tier enforcement and GraphQL management API.**

## Tasks Completed

### Task 1: Voice cloning processor and voice upload service with tier enforcement
**Commit:** 4367be8

Implemented the voice upload pipeline with background cloning:
- **VoiceCloningProcessor**: Background queue for async voice cloning
  - In-memory queue pattern (same as ImageGenerationProcessor from Phase 1)
  - `enqueue()`: Add job to queue, update status to PROCESSING, start processing
  - `processQueue()`: Process jobs one at a time with 100ms delay
  - `processJob()`: Download audio from R2 → clone with ElevenLabs → update status → send push
  - Push notification sent on success: "Your voice is ready!" with VOICE_READY event
  - Status updated to FAILED on error (logged for debugging)

- **VoiceService**: Voice profile CRUD with tier enforcement
  - `uploadVoice()`: Validate consent → check tier limits → upload to R2 → create profile → enqueue cloning
  - Tier enforcement: FREE tier allows 1 active voice (status NOT IN [DELETED, FAILED])
  - ForbiddenException with VOICE_SLOT_LIMIT code when limit exceeded (includes upgrade CTA)
  - `getVoiceProfiles()`: Return all non-DELETED profiles for user (newest first)
  - `getVoiceProfile()`: Get single profile with ownership validation
  - `deleteVoiceProfile()`: Delete ElevenLabs voice + R2 sample + update status to DELETED
  - `replaceVoice()`: Re-record flow (VOICE-07) - delete old assets, upload new audio, re-enqueue

- **VoiceController**: REST endpoints for file upload
  - `POST /voice/upload`: Multipart file upload with Multer (max 10MB, audio-only filter)
  - `POST /voice/:id/replace`: Re-record endpoint for VOICE-07 flow
  - ClerkAuthGuard protects both endpoints (authentication required)
  - IP address extraction from request for consent tracking
  - Form data handling (consentGiven string → boolean conversion)

- Installed `@types/multer` for TypeScript file upload types

**Files created:**
- `backend/src/voice/voice-cloning.processor.ts`
- `backend/src/voice/voice.service.ts`
- `backend/src/voice/voice.controller.ts`

**Files modified:**
- `backend/package.json` (added @types/multer)
- `backend/package-lock.json`

### Task 2: Voice profile GraphQL resolver and module wiring
**Commit:** 333ca8b

Implemented GraphQL resolver and wired all services:
- **VoiceResolver**: GraphQL queries and mutations for voice profile management
  - `myVoiceProfiles`: Query all non-DELETED voice profiles for current user
  - `voiceProfile(id)`: Query single profile with ownership validation
  - `deleteVoiceProfile(id)`: Mutation to delete voice profile
  - `updateVoiceProfileName(id, speakerName, relationship)`: Mutation to update metadata without re-cloning
  - All endpoints protected by ClerkAuthGuard
  - Uses CurrentUser decorator for auth context

- **VoiceModule**: Complete module wiring
  - Imports: ImagesModule (R2StorageService), PrismaModule, PushModule (PushService)
  - Providers: ElevenLabsService, NarrationService, VoiceService, VoiceCloningProcessor, VoiceResolver
  - Controllers: NarrationController, VoiceController
  - Exports: ElevenLabsService, NarrationService, VoiceService

- **Bug fixes:**
  - Fixed VoiceProfileDto to use Prisma VoiceStatus enum (removed duplicate GraphQL enum)
  - Fixed narration.controller.ts import paths (auth.guard, current-user.decorator)

**Files created:**
- `backend/src/voice/voice.resolver.ts`

**Files modified:**
- `backend/src/voice/voice.module.ts`
- `backend/src/voice/dto/voice-profile.dto.ts`
- `backend/src/voice/narration.controller.ts`

## Verification Results

### Automated Tests
```bash
✓ npx tsc --noEmit - All TypeScript compiles without errors
✓ npx prisma generate - Prisma client updated with VoiceProfile model
```

### Manual Verification
- [x] VoiceCloningProcessor follows ImageGenerationProcessor pattern
- [x] Tier enforcement: FREE tier limited to 1 active voice
- [x] ForbiddenException includes VOICE_SLOT_LIMIT code and currentVoiceId
- [x] Push notification integration with PushService
- [x] REST upload endpoint with Multer for audio files (10MB limit)
- [x] GraphQL resolver with ClerkAuthGuard on all queries/mutations
- [x] Consent validation on server side (consentGiven required)
- [x] Re-record flow updates existing profile (doesn't create new)
- [x] VoiceModule imports PushModule and ImagesModule
- [x] All providers and controllers registered in VoiceModule

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added Prisma client regeneration**
- **Found during:** Task 1 verification
- **Issue:** TypeScript compilation failed because Prisma client didn't have VoiceProfile model
- **Fix:** Ran `npx prisma generate` to regenerate Prisma client with VoiceProfile types
- **Files modified:** `node_modules/@prisma/client` (generated)
- **Commit:** N/A (build step, not committed)

**2. [Rule 2 - Missing Critical Functionality] Installed @types/multer**
- **Found during:** Task 1 verification
- **Issue:** TypeScript compilation failed with "Namespace 'global.Express' has no exported member 'Multer'"
- **Fix:** Installed `@types/multer` dev dependency for Multer type definitions
- **Files modified:** `backend/package.json`, `backend/package-lock.json`
- **Commit:** 4367be8 (included in Task 1 commit)

**3. [Rule 1 - Bug] Fixed VoiceProfileDto enum conflict**
- **Found during:** Task 2 verification
- **Issue:** VoiceProfileDto defined its own VoiceStatus enum, causing type mismatch with Prisma VoiceStatus
- **Fix:** Import VoiceStatus from @prisma/client instead of defining duplicate enum
- **Files modified:** `backend/src/voice/dto/voice-profile.dto.ts`
- **Commit:** 333ca8b (included in Task 2 commit)

**4. [Rule 1 - Bug] Fixed narration.controller.ts import paths**
- **Found during:** Task 2 verification
- **Issue:** Import paths for ClerkAuthGuard and CurrentUser were incorrect (clerk-auth.guard, auth/current-user.decorator)
- **Fix:** Updated paths to auth.guard and common/decorators/current-user.decorator
- **Files modified:** `backend/src/voice/narration.controller.ts`
- **Commit:** 333ca8b (included in Task 2 commit)

## Key Decisions Made

1. **In-memory queue pattern**: Following ImageGenerationProcessor from Phase 1, using simple in-memory queue for MVP. Future upgrade path to BullMQ documented in code comments.

2. **Tier enforcement strategy**: FREE tier limited to 1 active voice profile (status NOT IN [DELETED, FAILED]). PRO tier unlimited. Error response includes VOICE_SLOT_LIMIT code and currentVoiceId for upgrade flow.

3. **REST for file uploads**: Multer file upload requires REST endpoints (GraphQL doesn't support multipart/form-data natively). Voice profile management uses GraphQL for queries/mutations.

4. **Push notification on completion**: Voice cloning is async (can take 10-30 seconds). Push notification sent when status changes to READY, improving UX by alerting user when voice is ready to use.

5. **Re-record flow**: `replaceVoice()` updates existing profile instead of creating new one. Deletes old ElevenLabs voice and R2 sample, uploads new audio, re-enqueues cloning. Implements VOICE-07 requirement.

6. **Consent tracking**: Server-side validation (consentGiven must be true) plus IP address tracking (consentIpAddress field) for legal compliance (Tennessee ELVIS Act, California AB 1836).

7. **Ownership validation**: All voice operations validate userId matches profile.userId to prevent unauthorized access.

8. **Prisma enum usage**: Use Prisma-generated VoiceStatus enum in DTOs to avoid type mismatches. Register Prisma enum for GraphQL schema with registerEnumType.

## Dependencies

### Requires
- 03-01: VoiceProfile schema, ElevenLabsService, R2 voice sample storage, UploadVoiceInput DTO
- 01-04: ImageGenerationProcessor pattern (in-memory queue)
- 01-05: PushService for VOICE_READY notifications

### Provides
- Voice upload REST API (`POST /voice/upload`, `POST /voice/:id/replace`)
- Background voice cloning queue (VoiceCloningProcessor)
- Voice profile management GraphQL API (queries, mutations)
- Tier enforcement (FREE tier limit)

### Affects
- 03-03: Voice narration will use VoiceService to fetch profiles and check READY status

## Technical Notes

### Voice Upload Pipeline Flow
1. **Client uploads audio** → `POST /voice/upload` with multipart/form-data
2. **Server validates** → Consent check, tier limit check
3. **Upload to R2** → `r2StorageService.uploadVoiceSample()` returns CDN URL
4. **Create profile** → Prisma creates VoiceProfile with status=PENDING
5. **Enqueue cloning** → `voiceCloningProcessor.enqueue()` adds to queue
6. **Background processing** → Download audio → Call ElevenLabs → Update status → Send push
7. **Client polls or receives push** → Status changed to READY, voice usable for narration

### Tier Enforcement
- **FREE tier**: 1 active voice profile (status NOT IN [DELETED, FAILED])
- **PRO tier**: Unlimited (not enforced)
- **Error response**:
  ```json
  {
    "statusCode": 403,
    "message": "Free tier allows 1 voice. Upgrade to Pro for unlimited voices.",
    "code": "VOICE_SLOT_LIMIT",
    "currentVoiceId": "cuid123"
  }
  ```
- Client can use `currentVoiceId` to navigate to existing voice or show upgrade CTA

### Re-record Flow (VOICE-07)
1. User previews new audio in client (not implemented in backend)
2. Client confirms replacement → `POST /voice/:id/replace` with new audio
3. Server deletes old ElevenLabs voice (swallow errors)
4. Server deletes old R2 audio sample (swallow errors)
5. Server uploads new audio to R2
6. Server updates profile: new audioSampleUrl, status=PENDING, new consent timestamp
7. Server re-enqueues cloning job
8. Background processing continues as normal

### GraphQL vs REST Separation
- **REST**: File uploads (voice recording) - requires multipart/form-data
- **GraphQL**: Queries (myVoiceProfiles, voiceProfile) and non-file mutations (deleteVoiceProfile, updateVoiceProfileName)
- Both protected by ClerkAuthGuard

### Module Dependencies
```
VoiceModule
├── ImagesModule (R2StorageService for voice sample upload)
├── PrismaModule (PrismaService for database access)
└── PushModule (PushService for VOICE_READY notifications)
```

## Self-Check: PASSED

### Created Files Verification
```bash
✓ backend/src/voice/voice-cloning.processor.ts exists
✓ backend/src/voice/voice.service.ts exists
✓ backend/src/voice/voice.controller.ts exists
✓ backend/src/voice/voice.resolver.ts exists
```

### Commits Verification
```bash
✓ 4367be8: feat(03-02): add voice cloning processor and voice upload service
✓ 333ca8b: feat(03-02): add voice profile GraphQL resolver and module wiring
```

### Modified Files Verification
```bash
✓ backend/src/voice/voice.module.ts imports PushModule and registers all providers/controllers
✓ backend/src/voice/dto/voice-profile.dto.ts uses Prisma VoiceStatus enum
✓ backend/src/voice/narration.controller.ts has correct import paths
✓ backend/package.json includes @types/multer
```

### TypeScript Compilation
```bash
✓ npx tsc --noEmit passes without errors
```

All files created, commits recorded, and modifications verified. Plan 03-02 completed successfully.
