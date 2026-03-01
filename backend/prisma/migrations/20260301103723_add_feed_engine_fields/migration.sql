-- CreateEnum
CREATE TYPE "CuisineType" AS ENUM ('ITALIAN', 'MEXICAN', 'CHINESE', 'JAPANESE', 'SICHUAN', 'CANTONESE', 'INDIAN', 'THAI', 'KOREAN', 'VIETNAMESE', 'MEDITERRANEAN', 'FRENCH', 'SPANISH', 'GREEK', 'MIDDLE_EASTERN', 'LEBANESE', 'TURKISH', 'MOROCCAN', 'ETHIOPIAN', 'AMERICAN', 'SOUTHERN', 'TEX_MEX', 'BRAZILIAN', 'PERUVIAN', 'CARIBBEAN', 'BRITISH', 'GERMAN', 'FUSION', 'OTHER');

-- CreateEnum
CREATE TYPE "MealType" AS ENUM ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK', 'DESSERT', 'APPETIZER', 'DRINK');

-- AlterTable
ALTER TABLE "Recipe" ADD COLUMN     "cuisineType" "CuisineType" NOT NULL DEFAULT 'OTHER',
ADD COLUMN     "mealType" "MealType" NOT NULL DEFAULT 'DINNER',
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ADD COLUMN     "velocityScore" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "CityLocation" (
    "id" TEXT NOT NULL,
    "cityName" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "country" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CityLocation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CityLocation_cityName_key" ON "CityLocation"("cityName");

-- CreateIndex
CREATE INDEX "Recipe_cuisineType_idx" ON "Recipe"("cuisineType");

-- CreateIndex
CREATE INDEX "Recipe_mealType_idx" ON "Recipe"("mealType");

-- CreateIndex
CREATE INDEX "Recipe_velocityScore_idx" ON "Recipe"("velocityScore");
