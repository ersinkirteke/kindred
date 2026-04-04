-- CreateEnum
CREATE TYPE "VoiceStatus" AS ENUM ('PENDING', 'PROCESSING', 'READY', 'FAILED', 'DELETED');

-- AlterTable
ALTER TABLE "Ingredient" ADD COLUMN     "normalizedName" TEXT;

-- AlterTable
ALTER TABLE "Recipe" ADD COLUMN     "plainText" TEXT,
ADD COLUMN     "popularityScore" INTEGER DEFAULT 0,
ADD COLUMN     "sourceName" TEXT,
ADD COLUMN     "sourceUrl" TEXT,
ADD COLUMN     "spoonacularId" INTEGER,
ALTER COLUMN "location" DROP NOT NULL;

-- CreateTable
CREATE TABLE "VoiceProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "VoiceStatus" NOT NULL DEFAULT 'PENDING',
    "elevenLabsVoiceId" TEXT,
    "audioSampleUrl" TEXT NOT NULL,
    "speakerName" TEXT NOT NULL,
    "relationship" TEXT NOT NULL,
    "consentedAt" TIMESTAMP(3),
    "consentIpAddress" TEXT,
    "consentAppVersion" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VoiceProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NarrationScript" (
    "id" TEXT NOT NULL,
    "recipeId" TEXT NOT NULL,
    "conversationalText" TEXT NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "NarrationScript_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL,
    "originalTransactionId" TEXT NOT NULL,
    "expiresDate" TIMESTAMP(3) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "jwsPayload" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Subscription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PantryItem" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "normalizedName" TEXT,
    "quantity" TEXT NOT NULL,
    "unit" TEXT,
    "storageLocation" TEXT NOT NULL,
    "foodCategory" TEXT,
    "photoUrl" TEXT,
    "notes" TEXT,
    "source" TEXT NOT NULL DEFAULT 'manual',
    "expiryDate" TIMESTAMP(3),
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PantryItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IngredientCatalog" (
    "id" TEXT NOT NULL,
    "canonicalName" TEXT NOT NULL,
    "canonicalNameTR" TEXT NOT NULL,
    "aliases" TEXT[],
    "defaultCategory" TEXT NOT NULL,
    "defaultShelfLifeDays" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "IngredientCatalog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SearchCache" (
    "id" TEXT NOT NULL,
    "normalizedKey" TEXT NOT NULL,
    "recipeIds" TEXT[],
    "cachedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SearchCache_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApiQuotaUsage" (
    "id" TEXT NOT NULL,
    "date" TEXT NOT NULL,
    "pointsUsed" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ApiQuotaUsage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "VoiceProfile_userId_status_idx" ON "VoiceProfile"("userId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "NarrationScript_recipeId_key" ON "NarrationScript"("recipeId");

-- CreateIndex
CREATE INDEX "NarrationScript_recipeId_idx" ON "NarrationScript"("recipeId");

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_userId_key" ON "Subscription"("userId");

-- CreateIndex
CREATE INDEX "Subscription_userId_idx" ON "Subscription"("userId");

-- CreateIndex
CREATE INDEX "Subscription_isActive_idx" ON "Subscription"("isActive");

-- CreateIndex
CREATE INDEX "PantryItem_userId_isDeleted_idx" ON "PantryItem"("userId", "isDeleted");

-- CreateIndex
CREATE INDEX "PantryItem_normalizedName_idx" ON "PantryItem"("normalizedName");

-- CreateIndex
CREATE INDEX "PantryItem_expiryDate_idx" ON "PantryItem"("expiryDate");

-- CreateIndex
CREATE UNIQUE INDEX "IngredientCatalog_canonicalName_key" ON "IngredientCatalog"("canonicalName");

-- CreateIndex
CREATE INDEX "IngredientCatalog_canonicalName_idx" ON "IngredientCatalog"("canonicalName");

-- CreateIndex
CREATE INDEX "IngredientCatalog_canonicalNameTR_idx" ON "IngredientCatalog"("canonicalNameTR");

-- CreateIndex
CREATE UNIQUE INDEX "SearchCache_normalizedKey_key" ON "SearchCache"("normalizedKey");

-- CreateIndex
CREATE INDEX "SearchCache_cachedAt_idx" ON "SearchCache"("cachedAt");

-- CreateIndex
CREATE UNIQUE INDEX "ApiQuotaUsage_date_key" ON "ApiQuotaUsage"("date");

-- CreateIndex
CREATE INDEX "ApiQuotaUsage_date_idx" ON "ApiQuotaUsage"("date");

-- CreateIndex
CREATE INDEX "Ingredient_normalizedName_idx" ON "Ingredient"("normalizedName");

-- CreateIndex
CREATE UNIQUE INDEX "Recipe_spoonacularId_key" ON "Recipe"("spoonacularId");

-- CreateIndex
CREATE INDEX "Recipe_spoonacularId_idx" ON "Recipe"("spoonacularId");

-- CreateIndex
CREATE INDEX "Recipe_popularityScore_idx" ON "Recipe"("popularityScore");

-- AddForeignKey
ALTER TABLE "VoiceProfile" ADD CONSTRAINT "VoiceProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PantryItem" ADD CONSTRAINT "PantryItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
