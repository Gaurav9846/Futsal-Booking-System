-- CreateTable
CREATE TABLE "SystemSettings" (
    "id" SERIAL NOT NULL,
    "autoApproveOwners" BOOLEAN NOT NULL DEFAULT false,
    "autoApproveFutsals" BOOLEAN NOT NULL DEFAULT false,
    "maintenanceMode" BOOLEAN NOT NULL DEFAULT false,
    "bookingCancellationHours" INTEGER NOT NULL DEFAULT 2,
    "slotLockMinutes" INTEGER NOT NULL DEFAULT 5,
    "slotGenerationDays" INTEGER NOT NULL DEFAULT 30,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SystemSettings_pkey" PRIMARY KEY ("id")
);
