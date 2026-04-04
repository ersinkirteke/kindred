-- CreateTable: ScanJob model for AI scan result persistence
CREATE TABLE "ScanJob" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "scanType" TEXT NOT NULL,
    "photoUrl" TEXT,
    "ocrText" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PROCESSING',
    "results" JSONB,
    "error" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "contentHash" TEXT,

    CONSTRAINT "ScanJob_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: User lookup
CREATE INDEX "ScanJob_userId_idx" ON "ScanJob"("userId");

-- CreateIndex: User + scanType lookup
CREATE INDEX "ScanJob_userId_scanType_idx" ON "ScanJob"("userId", "scanType");

-- CreateIndex: Composite index for dedup lookups
CREATE INDEX "ScanJob_userId_contentHash_idx" ON "ScanJob"("userId", "contentHash");

-- AddForeignKey
ALTER TABLE "ScanJob" ADD CONSTRAINT "ScanJob_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

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
