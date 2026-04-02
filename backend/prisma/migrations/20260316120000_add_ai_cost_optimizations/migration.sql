-- AlterTable: Add contentHash to ScanJob for scan deduplication
ALTER TABLE "ScanJob" ADD COLUMN "contentHash" TEXT;

-- CreateIndex: Composite index for dedup lookups
CREATE INDEX "ScanJob_userId_contentHash_idx" ON "ScanJob"("userId", "contentHash");

-- CreateTable: NarrationAudio cache for TTS audio in R2
CREATE TABLE "NarrationAudio" (
    "id" TEXT NOT NULL,
    "recipeId" TEXT NOT NULL,
    "voiceProfileId" TEXT NOT NULL,
    "r2Url" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "NarrationAudio_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: Unique constraint on recipe+voice combo
CREATE UNIQUE INDEX "NarrationAudio_recipeId_voiceProfileId_key" ON "NarrationAudio"("recipeId", "voiceProfileId");

-- CreateIndex: Index for recipe lookups
CREATE INDEX "NarrationAudio_recipeId_idx" ON "NarrationAudio"("recipeId");
