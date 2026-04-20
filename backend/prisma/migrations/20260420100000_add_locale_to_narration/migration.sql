-- Add locale to narration tables so translations can be cached per language

ALTER TABLE "NarrationScript" ADD COLUMN "locale" TEXT NOT NULL DEFAULT 'en';
DROP INDEX "NarrationScript_recipeId_key";
CREATE UNIQUE INDEX "NarrationScript_recipeId_locale_key" ON "NarrationScript"("recipeId", "locale");

ALTER TABLE "NarrationAudio" ADD COLUMN "locale" TEXT NOT NULL DEFAULT 'en';
DROP INDEX "NarrationAudio_recipeId_voiceProfileId_key";
CREATE UNIQUE INDEX "NarrationAudio_recipeId_voiceProfileId_locale_key" ON "NarrationAudio"("recipeId", "voiceProfileId", "locale");
