-- AlterTable
ALTER TABLE "Booking" ADD COLUMN     "duration" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "groupId" TEXT,
ADD COLUMN     "paymentMethod" TEXT NOT NULL DEFAULT 'COD';

-- CreateIndex
CREATE INDEX "Booking_groupId_idx" ON "Booking"("groupId");
