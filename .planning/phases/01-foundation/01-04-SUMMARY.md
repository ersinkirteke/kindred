---
phase: 01-foundation
plan: 04
subsystem: infra
tags: [imagen-4-fast, cloudflare-r2, vertex-ai, s3, image-generation, background-processing]

# Dependency graph
requires:
  - phase: 01-01
    provides: Backend foundation with NestJS, Prisma, GraphQL API
  - phase: 01-03
    provides: Recipe scraping pipeline with X API and Gemini parser

provides:
  - AI hero image generation using Imagen 4 Fast via Vertex AI
  - Cloudflare R2 storage with S3-compatible API for CDN delivery
  - Background image processing queue with rate limiting (10 images/min)
  - Recipe imageStatus lifecycle: PENDING → GENERATING → COMPLETED/FAILED
  - Non-blocking image generation integrated with scraping pipeline

affects: [02-feed-engine, 04-ios-app, 09-android-app]

# Tech tracking
tech-stack:
  added:
    - "@google-cloud/aiplatform": "Imagen 4 Fast image generation via Vertex AI"
    - "@aws-sdk/client-s3": "S3-compatible client for Cloudflare R2 uploads"
  patterns:
    - "Background job queue with in-memory processing (MVP pattern, BullMQ-ready)"
    - "Rate limiting for external API quotas (10 images/min for Imagen)"
    - "Non-blocking async processing for expensive operations"
    - "Flat lay editorial food photography prompt engineering"

key-files:
  created:
    - "backend/src/images/images.service.ts": "Imagen 4 Fast client with prompt generation"
    - "backend/src/images/r2-storage.service.ts": "Cloudflare R2 upload service"
    - "backend/src/images/image-generation.processor.ts": "Background queue processor"
    - "backend/src/images/images.module.ts": "Images module with all services"
  modified:
    - "backend/src/scraping/scraping.service.ts": "Queue image generation after recipe creation"
    - "backend/src/scraping/scraping.module.ts": "Import ImagesModule"
    - "backend/src/app.module.ts": "Register ImagesModule globally"
    - "backend/.env.example": "Add R2 and Google Cloud env vars"

key-decisions:
  - "Imagen 4 Fast (imagegeneration@006) for cost-effective hero image generation"
  - "Cloudflare R2 for zero-egress CDN delivery (matches cost strategy)"
  - "In-memory queue processor for MVP (deferred BullMQ until multi-instance scaling)"
  - "Non-blocking image generation: recipes available immediately, images populate asynchronously"
  - "Rate limiting at 10 images/min to stay within Imagen API quotas"
  - "Flat lay editorial style prompts for consistent food photography aesthetic"

patterns-established:
  - "Background processing pattern: enqueue job → process asynchronously → update status"
  - "Rate-limited batch processing: reset window, enforce limits, log metrics"
  - "Non-blocking enrichment: core entity available immediately, enrichment happens async"
  - "Image generation prompt template: 'Professional flat lay top-down food photograph...'"

requirements-completed: [INFR-03]

# Metrics
duration: 6min
completed: 2026-02-28
---

# Phase 01 Plan 04: AI Image Generation Summary

**Imagen 4 Fast generates flat lay hero images with R2 CDN storage and background processing queue with 10/min rate limiting**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-28T21:29:39Z
- **Completed:** 2026-02-28T21:35:39Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Imagen 4 Fast integration via Vertex AI with flat lay editorial prompts
- Cloudflare R2 storage with S3-compatible uploads and CDN URLs
- Background image processor with 10 images/min rate limiting and 3-parallel concurrency
- Non-blocking integration with scraping pipeline (recipes available immediately)
- Recipe imageStatus lifecycle tracking (PENDING → GENERATING → COMPLETED/FAILED)

## Task Commits

Each task was committed atomically:

1. **Task 1: Imagen 4 Fast client and Cloudflare R2 storage service** - `8ed2970` (feat)
2. **Task 2: Background image processor and scraping pipeline integration** - `2ecfb45` (feat - bundled with 01-05)

_Note: Task 2 was bundled into commit 2ecfb45 which also included 01-05 CI/CD work_

## Files Created/Modified

- `backend/src/images/images.service.ts` - Imagen 4 Fast client with prompt generation and R2 upload
- `backend/src/images/r2-storage.service.ts` - S3-compatible R2 storage service for CDN uploads
- `backend/src/images/image-generation.processor.ts` - Background queue processor with rate limiting
- `backend/src/images/images.module.ts` - Images module with service exports
- `backend/src/scraping/scraping.service.ts` - Enqueue image generation after recipe creation
- `backend/src/scraping/scraping.module.ts` - Import ImagesModule for processor access
- `backend/src/app.module.ts` - Register ImagesModule globally
- `backend/.env.example` - Add R2_BUCKET_NAME, R2_PUBLIC_URL, GOOGLE_APPLICATION_CREDENTIALS

## Decisions Made

1. **Imagen 4 Fast (imagegeneration@006):** Cost-effective model for hero image generation (~$0.01/image vs $0.04 for standard Imagen)
2. **Cloudflare R2 for storage:** Zero-egress fees for CDN delivery aligns with cost strategy (vs S3 $0.09/GB egress)
3. **In-memory queue for MVP:** Simple background processing without Redis/BullMQ complexity. Upgrade path documented for multi-instance scaling.
4. **Non-blocking enrichment pattern:** Recipes available immediately with imageStatus=PENDING. Images populate asynchronously without blocking scraping or feed loading.
5. **Rate limiting at 10/min:** Prevents Imagen API quota exhaustion. Configurable for production scaling.
6. **Flat lay editorial prompts:** Consistent food photography style: "Professional flat lay top-down food photograph... Clean white marble surface, natural soft lighting, warm tones, Instagram-worthy editorial style."

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - implementation proceeded smoothly with all dependencies pre-installed.

## User Setup Required

**External services require manual configuration.** See plan frontmatter for:

### Google Cloud (Imagen 4 Fast)
- **Service:** google-cloud
- **Why:** Imagen 4 Fast for AI hero image generation
- **Environment variables:**
  - `GOOGLE_CLOUD_PROJECT`: Project ID from Google Cloud Console
  - `GOOGLE_APPLICATION_CREDENTIALS`: Path to service account JSON key
- **Dashboard configuration:**
  - Enable Vertex AI API in Google Cloud Console → APIs & Services

### Cloudflare R2 (Image Storage)
- **Service:** cloudflare-r2
- **Why:** Zero-egress CDN delivery for recipe images
- **Environment variables:**
  - `CLOUDFLARE_ACCOUNT_ID`: From Cloudflare Dashboard → Overview
  - `R2_ACCESS_KEY_ID`: From R2 → Manage R2 API Tokens
  - `R2_SECRET_ACCESS_KEY`: From R2 → Manage R2 API Tokens
  - `R2_BUCKET_NAME`: Create bucket named 'kindred-images'
  - `R2_PUBLIC_URL`: Custom domain or r2.dev subdomain from bucket settings
- **Dashboard configuration:**
  - Create R2 bucket named 'kindred-images' with public access enabled

## Next Phase Readiness

**Ready for Phase 2 (Feed Engine):**
- AI-generated hero images available for recipe cards
- CDN URLs ready for GraphQL imageUrl field
- Background processing ensures no feed loading delays

**Blockers:** None

**Future enhancements:**
- Upgrade to BullMQ with Redis when scaling to multiple backend instances
- Add image regeneration endpoint for updating existing recipe images
- Implement image quality verification (detect generation failures)

---

## Self-Check: PASSED

All claimed files and commits verified:

**Files:**
- ✓ backend/src/images/images.service.ts
- ✓ backend/src/images/r2-storage.service.ts
- ✓ backend/src/images/image-generation.processor.ts
- ✓ backend/src/images/images.module.ts

**Commits:**
- ✓ 8ed2970 (Task 1: Imagen 4 Fast client and R2 storage)
- ✓ 2ecfb45 (Task 2: Background processor integration - bundled with 01-05)

---
*Phase: 01-foundation*
*Completed: 2026-02-28*
