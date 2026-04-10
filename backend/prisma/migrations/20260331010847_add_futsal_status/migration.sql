-- CreateEnum
CREATE TYPE "FutsalStatus" AS ENUM ('PENDING', 'ACTIVE', 'DEACTIVATED');

-- AlterTable
ALTER TABLE "Futsal" ADD COLUMN     "status" "FutsalStatus" NOT NULL DEFAULT 'PENDING';

-- CreateTable
CREATE TABLE "Favorite" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "futsalId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Favorite_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Favorite_userId_futsalId_key" ON "Favorite"("userId", "futsalId");

-- AddForeignKey
ALTER TABLE "Favorite" ADD CONSTRAINT "Favorite_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Favorite" ADD CONSTRAINT "Favorite_futsalId_fkey" FOREIGN KEY ("futsalId") REFERENCES "Futsal"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
