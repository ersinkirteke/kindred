-- AlterTable NarrationAudio: Add durationMs field
ALTER TABLE "NarrationAudio" ADD COLUMN "durationMs" INTEGER;

-- CreateTable TransactionHistory
CREATE TABLE "TransactionHistory" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "transactionId" TEXT,
    "originalTransactionId" TEXT,
    "productId" TEXT,
    "jwsPayload" TEXT NOT NULL,
    "environment" TEXT NOT NULL,
    "verificationResult" TEXT NOT NULL,
    "errorMessage" TEXT,
    "expiresDate" TIMESTAMP(3),
    "notificationType" TEXT,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TransactionHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable NotificationPreferences
CREATE TABLE "NotificationPreferences" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expiryAlerts" BOOLEAN NOT NULL DEFAULT true,
    "voiceReady" BOOLEAN NOT NULL DEFAULT true,
    "engagement" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NotificationPreferences_pkey" PRIMARY KEY ("id")
);

-- CreateTable NotificationLog
CREATE TABLE "NotificationLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "sentAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "NotificationLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TransactionHistory_userId_idx" ON "TransactionHistory"("userId");

-- CreateIndex
CREATE INDEX "TransactionHistory_transactionId_idx" ON "TransactionHistory"("transactionId");

-- CreateIndex
CREATE INDEX "TransactionHistory_environment_idx" ON "TransactionHistory"("environment");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationPreferences_userId_key" ON "NotificationPreferences"("userId");

-- CreateIndex
CREATE INDEX "NotificationPreferences_userId_idx" ON "NotificationPreferences"("userId");

-- CreateIndex
CREATE INDEX "NotificationLog_userId_type_sentAt_idx" ON "NotificationLog"("userId", "type", "sentAt");
