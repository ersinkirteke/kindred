# Phase 03: Voice Core - Research

**Researched:** 2026-03-01
**Domain:** Voice cloning, AI text-to-speech, audio streaming
**Confidence:** MEDIUM-HIGH

## Summary

Phase 3 implements voice cloning and recipe narration using ElevenLabs API with streaming audio delivery. Users record 30-60 second voice samples, ElevenLabs clones them via Instant Voice Cloning (IVC), and Gemini rewrites recipe text into conversational narration before TTS generation. Audio streams to mobile apps with background playback support.

The technical foundation is solid: ElevenLabs provides production-ready voice cloning and streaming APIs, NestJS handles file upload and audio streaming patterns, R2 storage infrastructure exists from Phase 1, and Gemini integration patterns exist from recipe parsing. Key challenges are streaming latency optimization (<5s requirement), background audio implementation (mobile-side), and voice consent compliance (Tennessee ELVIS Act, California AB 1836).

**Primary recommendation:** Use ElevenLabs Instant Voice Cloning with 1-2 minute samples, stream TTS output via chunked transfer encoding, store voice samples in R2, cache generated narrations locally on mobile, and implement Gemini conversational rewriting before TTS generation.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Voice Upload Flow:**
- In-app recording only (no file upload) with a guided cooking passage script
- User reads a warm, food-related paragraph (~30-60 seconds) that captures cooking vocabulary naturally
- Live audio level meter during recording — warn if too quiet or too much background noise
- Background processing after upload: show "Your voice is being prepared", user continues browsing, push notification when clone is ready (~1-3 minutes)
- Non-blocking pattern matches image generation approach from Phase 1

**Narration Style:**
- Warm conversational tone: "Alright, now let's dice those tomatoes nice and small" — not clinical instructions
- AI-rewrite recipe text to conversational narration via Gemini before sending to ElevenLabs
- On-demand generation with streaming: generate when user taps Listen, ElevenLabs streaming starts audio within 1-2 seconds. No pre-generation, no storage cost for unplayed recipes
- Full guided experience: brief intro, ingredients overview, then step-by-step narration

**Playback Behavior:**
- Continuous audio flow with ~2 second pauses between steps
- Background audio playback: continues when phone is locked or app is backgrounded
- Cache last 5 played narrations locally for offline replay (~50MB for 5 recipes)
- Jump between steps for seek: Previous/Next step buttons, not a time scrub bar

**Voice Profile Management:**
- Store speaker's name (e.g., "Mom", "Nonna Maria") and relationship (e.g., "Mother", "Grandmother")
- Displayed during playback: "Narrated by Mom"
- Soft upgrade prompt when free tier user (1 voice slot) tries to add another
- Re-record flow: user records new sample, hears preview before confirming
- Explicit voice consent screen required before upload (Tennessee ELVIS Act, California AB 1836)
- Voice sample audio files stored in Cloudflare R2 (same as hero images)

### Claude's Discretion

- ElevenLabs API integration details (model selection, parameters, error handling)
- Gemini prompt engineering for conversational narration rewriting
- Audio format and encoding choices (mp3 vs m4a, bitrate)
- Voice cloning status polling vs webhook approach
- Narration text chunking strategy (per-step vs whole recipe)
- R2 folder structure for voice samples
- Database schema for VoiceProfile and NarrationCache models

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VOICE-01 | User can upload a 30-60 second voice clip of a loved one during onboarding or from profile | ElevenLabs IVC accepts 1-2 min samples; NestJS file upload with Multer; R2 storage for voice samples |
| VOICE-02 | App clones the uploaded voice using ElevenLabs API and stores the voice profile | ElevenLabs `/v1/voices/add` endpoint for IVC; background processing pattern from Phase 1 ImageGenerationProcessor |
| VOICE-03 | User can listen to any recipe's instructions narrated in their cloned voice | ElevenLabs `/v1/text-to-speech/{voice_id}/stream` endpoint; Gemini for conversational rewriting; streaming via chunked transfer encoding |
| VOICE-04 | Voice narration streams in real-time with play/pause/seek controls (64dp play button) | ElevenLabs streaming API with ~75ms latency (Flash v2.5); mobile-side controls (iOS/Android implementation) |
| VOICE-05 | Voice narration displays the speaker's name prominently during playback | VoiceProfile model stores speakerName and relationship; GraphQL API returns metadata with audio URL |
| VOICE-06 | Free tier users get 1 voice slot; Pro users get unlimited voice slots | Database schema with User.voiceProfiles relation; tier-based limits enforced in VoiceService |
| VOICE-07 | User can re-record or replace their voice clip to improve quality | Re-upload flow reuses VOICE-01 infrastructure; preview generation via ElevenLabs TTS with sample text; old voice deletion via `/v1/voices/{voice_id}` |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ElevenLabs API | v1 | Voice cloning and TTS streaming | Industry-leading voice quality, production-ready streaming API, commercially licensed output |
| @google/generative-ai | Latest | Conversational narration rewriting | Already integrated in Phase 1 for recipe parsing; Gemini 2.0 Flash is fast and cost-effective |
| @aws-sdk/client-s3 | ^3.x | R2 voice sample storage | Already used in Phase 1 for image storage; S3-compatible API works with Cloudflare R2 |
| Multer | ^1.4.x | Multipart file upload handling | NestJS standard for file uploads; handles streaming to prevent memory spikes |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BullMQ | ^5.x | Voice cloning queue (optional) | If scaling beyond single-instance in-memory queue from Phase 1 |
| node-ffmpeg | Latest | Audio format conversion (optional) | Only if ElevenLabs output format needs conversion for mobile compatibility |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ElevenLabs | Resemble.ai, PlayHT, Azure TTS | ElevenLabs has superior voice quality, streaming API, and simpler pricing model |
| Instant Voice Cloning | Professional Voice Cloning | PVC requires 30 min - 3 hours of audio (vs 1-2 min for IVC); user experience suffers with longer recording |
| On-demand generation | Pre-generation + storage | On-demand saves storage costs ($0/unplayed recipes) but adds 1-2s latency on first play |
| Multer | multer-s3 direct upload | Direct R2 upload skips server memory but complicates validation and audio quality checks |

**Installation:**
```bash
npm install @google/generative-ai
# ElevenLabs has no official Node SDK - use native fetch for REST API
# Multer already installed in NestJS projects
```

## Architecture Patterns

### Recommended Project Structure
```
backend/src/
├── voice/
│   ├── voice.module.ts              # VoiceModule with services and resolvers
│   ├── voice.service.ts             # Core voice cloning logic
│   ├── voice.resolver.ts            # GraphQL mutations/queries
│   ├── voice-cloning.processor.ts   # Background job for ElevenLabs cloning
│   ├── narration.service.ts         # TTS generation and streaming
│   ├── elevenlabs.service.ts        # ElevenLabs API client
│   ├── dto/
│   │   ├── voice-profile.dto.ts     # VoiceProfile GraphQL type
│   │   ├── upload-voice.input.ts    # uploadVoice mutation input
│   │   └── narration-request.dto.ts # Recipe narration request
│   └── entities/
│       └── voice-profile.entity.ts  # Prisma model wrapper
└── prisma/
    └── schema.prisma                # VoiceProfile, VoiceStatus models
```

### Pattern 1: Background Voice Cloning (Reuse Phase 1 Pattern)

**What:** Non-blocking voice clone creation with status tracking and push notification
**When to use:** VOICE-01, VOICE-02 - user uploads voice sample, processing happens in background

**Example:**
```typescript
// Reuse ImageGenerationProcessor pattern from Phase 1
// backend/src/voice/voice-cloning.processor.ts

@Injectable()
export class VoiceCloningProcessor {
  private queue: Array<{ userId: string; voiceProfileId: string; audioUrl: string }> = [];
  private processing = false;

  constructor(
    private elevenLabsService: ElevenLabsService,
    private prisma: PrismaService,
    private pushService: PushService,
  ) {}

  async enqueue(userId: string, voiceProfileId: string, audioUrl: string) {
    this.queue.push({ userId, voiceProfileId, audioUrl });

    // Update status to PROCESSING
    await this.prisma.voiceProfile.update({
      where: { id: voiceProfileId },
      data: { status: 'PROCESSING' },
    });

    if (!this.processing) {
      this.processQueue();
    }
  }

  private async processQueue() {
    if (this.queue.length === 0) {
      this.processing = false;
      return;
    }

    this.processing = true;
    const job = this.queue.shift();

    try {
      // Download audio from R2
      const audioBuffer = await this.downloadFromR2(job.audioUrl);

      // Clone voice via ElevenLabs
      const voiceId = await this.elevenLabsService.cloneVoice({
        name: `kindred_${job.voiceProfileId}`,
        files: [audioBuffer],
      });

      // Update database
      await this.prisma.voiceProfile.update({
        where: { id: job.voiceProfileId },
        data: {
          status: 'READY',
          elevenLabsVoiceId: voiceId,
        },
      });

      // Send push notification
      await this.pushService.sendToUser(job.userId, {
        title: 'Your voice is ready!',
        body: 'Start listening to recipes in your loved one\'s voice',
        data: { type: 'VOICE_READY', voiceProfileId: job.voiceProfileId },
      });

    } catch (error) {
      await this.prisma.voiceProfile.update({
        where: { id: job.voiceProfileId },
        data: { status: 'FAILED' },
      });
    }

    // Process next job
    setTimeout(() => this.processQueue(), 100);
  }
}
```

### Pattern 2: Streaming TTS Response

**What:** Stream ElevenLabs audio directly to client using chunked transfer encoding
**When to use:** VOICE-03, VOICE-04 - user taps Listen, audio streams immediately

**Example:**
```typescript
// backend/src/voice/narration.service.ts

@Injectable()
export class NarrationService {
  async streamRecipeNarration(
    recipeId: string,
    voiceId: string,
    response: Response, // Express response object
  ): Promise<void> {
    // 1. Get recipe steps
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: recipeId },
      include: { steps: { orderBy: { orderIndex: 'asc' } } },
    });

    // 2. Rewrite to conversational narration
    const narrationText = await this.rewriteToConversational(recipe);

    // 3. Stream from ElevenLabs
    const elevenLabsResponse = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}/stream`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': process.env.ELEVENLABS_API_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: narrationText,
          model_id: 'eleven_flash_v2_5', // Ultra-low latency ~75ms
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          },
        }),
      },
    );

    // 4. Set response headers for streaming
    response.setHeader('Content-Type', 'audio/mpeg');
    response.setHeader('Transfer-Encoding', 'chunked');
    response.setHeader('Cache-Control', 'no-cache');

    // 5. Pipe ElevenLabs stream to response
    const reader = elevenLabsResponse.body.getReader();
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      response.write(value);
    }

    response.end();
  }

  private async rewriteToConversational(recipe: Recipe): Promise<string> {
    const prompt = `Rewrite this recipe into warm, conversational narration as if a loved one is guiding you through cooking.

Recipe: ${recipe.title}
Steps:
${recipe.steps.map((s, i) => `${i + 1}. ${s.text}`).join('\n')}

Guidelines:
- Start with brief intro: "Today we're making [recipe name]"
- Include ingredients overview: "You'll need [ingredients]"
- Rewrite each step conversationally: "Chop onions" → "Now, let's chop up those onions"
- Add 2-second natural pauses between steps (use "..." or line breaks)
- Keep it warm and encouraging
- Total length: 2-5 minutes when spoken

Output only the narration script, no explanations.`;

    const model = this.genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    const result = await model.generateContent(prompt);
    return result.response.text();
  }
}
```

### Pattern 3: Tier-Based Voice Slot Enforcement

**What:** Enforce 1 voice for free tier, unlimited for Pro tier
**When to use:** VOICE-06 - prevent free users from creating multiple voices

**Example:**
```typescript
// backend/src/voice/voice.service.ts

async uploadVoice(userId: string, audioFile: Buffer): Promise<VoiceProfile> {
  const user = await this.prisma.user.findUnique({
    where: { id: userId },
    include: { voiceProfiles: { where: { status: { not: 'DELETED' } } } },
  });

  // Check tier limits
  if (user.tier === 'FREE' && user.voiceProfiles.length >= 1) {
    throw new ForbiddenException({
      code: 'VOICE_SLOT_LIMIT',
      message: 'Free tier allows 1 voice. Upgrade to Pro for unlimited voices.',
      currentVoiceId: user.voiceProfiles[0].id,
    });
  }

  // Upload to R2
  const audioUrl = await this.r2StorageService.uploadVoiceSample(
    userId,
    audioFile,
  );

  // Create VoiceProfile record
  const voiceProfile = await this.prisma.voiceProfile.create({
    data: {
      userId,
      status: 'PENDING',
      audioSampleUrl: audioUrl,
      speakerName: '', // Set later in separate mutation
      relationship: '',
    },
  });

  // Enqueue background cloning
  await this.voiceCloningProcessor.enqueue(userId, voiceProfile.id, audioUrl);

  return voiceProfile;
}
```

### Anti-Patterns to Avoid

- **Synchronous voice cloning:** NEVER await ElevenLabs cloning in the upload mutation — takes 1-3 minutes and blocks the request. Use background processing.
- **Pre-generating all narrations:** Don't generate TTS for all recipes upfront — storage costs explode. Generate on-demand when user taps Listen.
- **Storing full recipe text in narration cache:** Cache the audio file URL, not the text. Text regeneration is fast (~1s with Gemini), storage is expensive.
- **Loading entire audio file into memory:** Use streams for upload and download to prevent OOM errors with large audio files.
- **Skipping voice consent:** Legal requirement (Tennessee ELVIS Act, California AB 1836). Must have explicit consent checkbox before upload.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Voice cloning ML model | Custom voice cloning pipeline | ElevenLabs API | Voice cloning requires massive training data, specialized models, and ongoing quality improvements. ElevenLabs handles all this. |
| Audio format conversion | Custom ffmpeg wrapper | Use ElevenLabs mp3 output directly | ElevenLabs outputs mp3 at configurable bitrates (128-320kbps). MP3 has universal iOS/Android support. No conversion needed. |
| Streaming audio protocol | Custom chunking/buffering logic | HTTP chunked transfer encoding | Browsers and mobile HTTP clients handle chunked responses natively. Just pipe ElevenLabs stream to response. |
| Audio level detection during recording | Backend audio analysis | Client-side Web Audio API / iOS AVAudioRecorder | Audio level detection must be real-time (live feedback). Backend analysis adds latency and complexity. |
| Background audio playback | Custom audio service | iOS AVPlayer / Android MediaPlayer | Platform APIs handle background audio, lock screen controls, and interruptions (calls, notifications). |

**Key insight:** Voice cloning is an API-first domain. The ML models are commoditized via ElevenLabs. Your value is in the emotional UX (recording loved ones, conversational narration style), not in building audio infrastructure.

## Common Pitfalls

### Pitfall 1: Voice Sample Quality Not Validated

**What goes wrong:** Users upload low-quality audio (background noise, echo, multiple speakers), ElevenLabs clones it poorly, users blame the app.
**Why it happens:** No validation of audio quality before sending to ElevenLabs.
**How to avoid:**
- Client-side audio level meter during recording (CONTEXT.md requirement)
- Reject uploads with low average amplitude (too quiet)
- Warn about background noise using client-side noise detection
- Show example of good vs bad recording before user starts
**Warning signs:** User complaints about "robot voice" or "sounds weird"

### Pitfall 2: Streaming Latency >5 Seconds

**What goes wrong:** User taps Listen, waits 10-15 seconds before audio starts playing.
**Why it happens:** Gemini rewriting + ElevenLabs generation both happen before streaming starts.
**How to avoid:**
- Use ElevenLabs Flash v2.5 model (~75ms latency vs 500ms+ for standard models)
- Cache Gemini conversational rewrites per recipe (rewrite once, use many times)
- Stream audio immediately after first chunk arrives (don't wait for full generation)
- Consider pre-warming: generate conversational text when recipe is viewed, before user taps Listen
**Warning signs:** Mobile client timeout errors, user abandons before playback starts

### Pitfall 3: Free Tier Voice Slot Enforcement Race Condition

**What goes wrong:** Free tier user creates 2 voices by uploading simultaneously in two sessions/devices.
**Why it happens:** Voice slot check happens before VoiceProfile record is created, creating a race window.
**How to avoid:**
- Use database unique constraint: `@@unique([userId, status])` where status != 'DELETED' (requires Prisma raw SQL)
- Or use transaction with SELECT FOR UPDATE to lock user row during voice creation
- Return clear error with upgrade CTA when limit is hit
**Warning signs:** Free tier users with >1 active voice in production database

### Pitfall 4: R2 Voice Sample Storage Without Expiry

**What goes wrong:** Voice sample audio files accumulate in R2 even after voice is deleted or replaced, driving up storage costs.
**Why it happens:** VoiceProfile deletion doesn't clean up R2 files.
**How to avoid:**
- Implement soft delete pattern: status = 'DELETED' instead of hard delete
- Background job deletes R2 files for DELETED voices after 30 days (user can recover)
- When user replaces voice, mark old VoiceProfile as REPLACED and delete old R2 file
- R2 lifecycle policy: auto-delete files in `voice-samples/deleted/` after 30 days
**Warning signs:** R2 storage costs growing faster than active voice count

### Pitfall 5: ElevenLabs Voice ID Collision

**What goes wrong:** User deletes voice and creates new one, backend tries to reuse deleted ElevenLabs voice ID, gets 404 error.
**Why it happens:** VoiceProfile record stores elevenLabsVoiceId, but ElevenLabs API deletes voice when you call DELETE.
**How to avoid:**
- Always create new voice in ElevenLabs, never reuse IDs
- When user replaces voice: create new VoiceProfile record + new ElevenLabs voice, delete old after success
- Store voice deletion timestamp to track cleanup
**Warning signs:** "Voice not found" errors when generating narration for existing VoiceProfile

### Pitfall 6: Missing Voice Consent Legal Compliance

**What goes wrong:** App launches without voice consent checkbox, violates Tennessee ELVIS Act / California AB 1836, faces legal action.
**Why it happens:** Treating consent as UI/UX feature instead of legal requirement.
**How to avoid:**
- Store consent timestamp and IP address in VoiceProfile model
- Display full legal text: "I confirm this is my voice or I have permission from the person whose voice I'm recording"
- Block upload if checkbox not checked (backend validation too, not just frontend)
- Consult lawyer for exact compliance wording
**Warning signs:** No consentedAt field in database schema

## Code Examples

Verified patterns from official sources and established project patterns:

### Voice Upload with Multer Streaming

```typescript
// backend/src/voice/voice.controller.ts (REST endpoint for file upload)

import { Controller, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ClerkAuthGuard } from '../auth/clerk-auth.guard';

@Controller('voice')
export class VoiceController {
  constructor(private voiceService: VoiceService) {}

  @Post('upload')
  @UseGuards(ClerkAuthGuard)
  @UseInterceptors(
    FileInterceptor('audio', {
      limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max (2 min at 192kbps = ~3MB)
      fileFilter: (req, file, cb) => {
        if (!file.mimetype.startsWith('audio/')) {
          return cb(new BadRequestException('Only audio files allowed'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadVoice(
    @CurrentUser() user: User,
    @UploadedFile() file: Express.Multer.File,
  ) {
    // Validate audio duration (30-120 seconds) using ffprobe or similar
    const duration = await this.getAudioDuration(file.buffer);
    if (duration < 30 || duration > 120) {
      throw new BadRequestException('Audio must be 30-120 seconds');
    }

    return this.voiceService.uploadVoice(user.id, file.buffer);
  }
}
```

### ElevenLabs REST Client

```typescript
// backend/src/voice/elevenlabs.service.ts

@Injectable()
export class ElevenLabsService {
  private readonly apiKey = process.env.ELEVENLABS_API_KEY;
  private readonly baseUrl = 'https://api.elevenlabs.io/v1';

  async cloneVoice(params: {
    name: string;
    files: Buffer[];
  }): Promise<string> {
    const formData = new FormData();
    formData.append('name', params.name);

    params.files.forEach((buffer, i) => {
      formData.append('files', new Blob([buffer]), `sample_${i}.mp3`);
    });

    const response = await fetch(`${this.baseUrl}/voices/add`, {
      method: 'POST',
      headers: { 'xi-api-key': this.apiKey },
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`ElevenLabs cloning failed: ${await response.text()}`);
    }

    const data = await response.json();
    return data.voice_id;
  }

  async deleteVoice(voiceId: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/voices/${voiceId}`, {
      method: 'DELETE',
      headers: { 'xi-api-key': this.apiKey },
    });

    if (!response.ok) {
      throw new Error(`ElevenLabs deletion failed: ${await response.text()}`);
    }
  }

  async generateSpeech(voiceId: string, text: string): Promise<ReadableStream> {
    const response = await fetch(
      `${this.baseUrl}/text-to-speech/${voiceId}/stream`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': this.apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          model_id: 'eleven_flash_v2_5',
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          },
        }),
      },
    );

    if (!response.ok) {
      throw new Error(`ElevenLabs TTS failed: ${await response.text()}`);
    }

    return response.body;
  }
}
```

### Prisma Schema for Voice Models

```prisma
// prisma/schema.prisma

model VoiceProfile {
  id                  String        @id @default(cuid())
  userId              String
  user                User          @relation(fields: [userId], references: [id], onDelete: Cascade)

  status              VoiceStatus   @default(PENDING)
  elevenLabsVoiceId   String?       // Populated after cloning completes
  audioSampleUrl      String        // R2 URL for voice sample

  speakerName         String        // "Mom", "Nonna Maria"
  relationship        String        // "Mother", "Grandmother"

  consentedAt         DateTime?     // Legal compliance timestamp
  consentIpAddress    String?       // IP address when consent given

  createdAt           DateTime      @default(now())
  updatedAt           DateTime      @updatedAt

  @@index([userId, status])
}

enum VoiceStatus {
  PENDING       // Uploaded, not yet cloned
  PROCESSING    // ElevenLabs cloning in progress
  READY         // Clone complete, ready for TTS
  FAILED        // Cloning failed
  DELETED       // User deleted this voice
}

// Add to User model
model User {
  // ... existing fields
  voiceProfiles VoiceProfile[]
}
```

### R2 Voice Sample Upload

```typescript
// Extend backend/src/images/r2-storage.service.ts

export class R2StorageService {
  // ... existing image upload methods

  async uploadVoiceSample(userId: string, audioBuffer: Buffer): Promise<string> {
    const key = `voice-samples/${userId}/${Date.now()}.mp3`;

    await this.s3Client.send(
      new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: audioBuffer,
        ContentType: 'audio/mpeg',
        Metadata: {
          userId,
          uploadedAt: new Date().toISOString(),
        },
      }),
    );

    return `https://${this.publicDomain}/${key}`;
  }

  async deleteVoiceSample(url: string): Promise<void> {
    const key = new URL(url).pathname.slice(1); // Remove leading /

    await this.s3Client.send(
      new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      }),
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Professional Voice Cloning (30min-3hr samples) | Instant Voice Cloning (1-2 min samples) | ElevenLabs 2023 | IVC made voice cloning UX-feasible for consumer apps. PVC is still better quality but unusable for onboarding. |
| Pre-generate all TTS audio | On-demand streaming with chunked encoding | ElevenLabs streaming API 2024 | Eliminates storage costs for unplayed recipes. Flash v2.5 model makes latency acceptable (<2s). |
| Separate voice cloning services | Unified voice cloning + TTS API | ElevenLabs platform evolution | Single vendor simplifies integration. Voice ID carries across cloning → TTS seamlessly. |
| Manual text-to-narration conversion | AI rewriting for conversational tone | LLM maturity (Gemini, GPT) 2024-2025 | Transforms dry recipe steps into warm, natural narration. Critical for emotional UX. |

**Deprecated/outdated:**
- ElevenLabs V1 models: Use Flash v2.5 for streaming (75ms latency vs 500ms+ for older models)
- Character-based pricing: ElevenLabs now uses credit-based system (1 character = 1 credit for most models)
- Node.js SDK: ElevenLabs official SDKs (Python, JS) are immature. Use native fetch with REST API for better control.

## Open Questions

1. **Audio bitrate optimization for mobile**
   - What we know: ElevenLabs outputs mp3 at 128-192kbps. Mobile devices support this natively.
   - What's unclear: Optimal bitrate for balance between quality and bandwidth on cellular networks
   - Recommendation: Start with 128kbps (ElevenLabs default), monitor user feedback and bandwidth usage. Consider adaptive bitrate in v2.

2. **Voice cloning webhook vs polling**
   - What we know: ElevenLabs cloning takes 1-3 minutes. No official webhook support documented.
   - What's unclear: Whether polling every 10s is acceptable or if there's undocumented webhook support
   - Recommendation: Use polling for MVP (simpler). Background processor checks status every 10s. Acceptable for 1-3 min processing time.

3. **Narration caching strategy**
   - What we know: User requirement is "cache last 5 played narrations locally for offline replay"
   - What's unclear: Backend role in caching (pre-sign URLs? Store generated audio? Client-only caching?)
   - Recommendation: Client-side caching only. Backend returns streaming audio, client saves to local storage. Backend doesn't store generated narrations (cost savings). Client manages LRU cache of 5 most recent.

4. **Conversational narration caching**
   - What we know: Gemini rewrite takes ~1s per recipe. Same recipe → same narration text.
   - What's unclear: Should we cache rewritten narration text per recipe in database?
   - Recommendation: YES. Create NarrationScript model with recipeId + conversationalText. Cache after first generation. Saves Gemini API costs and reduces latency on subsequent plays.

## Sources

### Primary (HIGH confidence)
- [ElevenLabs Voice Cloning Documentation](https://elevenlabs.io/docs/creative-platform/voices/voice-cloning) - IVC sample duration (1-2 min), quality requirements
- [ElevenLabs Streaming API Documentation](https://elevenlabs.io/docs/api-reference/streaming) - Chunked transfer encoding, Flash v2.5 latency specs
- [ElevenLabs API Reference](https://elevenlabs.io/docs/api-reference/voices/ivc/create) - `/v1/voices/add` endpoint, voice cloning parameters
- [NestJS File Upload Documentation](https://docs.nestjs.com/techniques/file-upload) - Multer integration patterns
- [NestJS Streaming Files Documentation](https://docs.nestjs.com/techniques/streaming-files) - Chunked response streaming

### Secondary (MEDIUM confidence)
- [Audio Format Comparison: MP3 vs M4A](https://cloudinary.com/guides/video-formats/what-is-the-m4a-format-understanding-the-difference-between-m4a-mp3-and-wav) - Mobile compatibility, file size, quality tradeoffs
- [ElevenLabs Pricing Guide 2026](https://elevenlabs.io/pricing/api) - Credit system, voice cloning costs
- [NestJS Large File Upload Best Practices](https://medium.com/@duckweave/nestjs-large-uploads-stream-it-dont-spike-ram-a9cc4b0f1b74) - Memory management with streaming

### Tertiary (LOW confidence)
- Node.js audio streaming blog posts - General patterns, not ElevenLabs-specific

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ElevenLabs is industry standard for voice cloning APIs, well-documented
- Architecture: MEDIUM-HIGH - Patterns adapted from Phase 1 (proven), but voice streaming is new domain
- Pitfalls: MEDIUM - Based on ElevenLabs docs and general audio streaming experience, not Kindred-specific

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (30 days - AI API landscape is stable)
