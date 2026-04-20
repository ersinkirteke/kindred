CREATE TABLE "RecipeTranslation" (
    "id" TEXT NOT NULL,
    "recipeId" TEXT NOT NULL,
    "locale" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "ingredients" JSONB NOT NULL,
    "steps" JSONB NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "RecipeTranslation_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "RecipeTranslation_recipeId_locale_key" ON "RecipeTranslation"("recipeId", "locale");
CREATE INDEX "RecipeTranslation_recipeId_idx" ON "RecipeTranslation"("recipeId");
