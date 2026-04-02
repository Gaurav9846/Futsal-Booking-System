-- CreateTable
CREATE TABLE "Block" (
    "id" SERIAL NOT NULL,
    "ownerId" INTEGER NOT NULL,
    "playerId" INTEGER NOT NULL,
    "futsalId" INTEGER NOT NULL,
    "reason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Block_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Block_ownerId_playerId_futsalId_key" ON "Block"("ownerId", "playerId", "futsalId");

-- AddForeignKey
ALTER TABLE "Block" ADD CONSTRAINT "Block_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Block" ADD CONSTRAINT "Block_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Block" ADD CONSTRAINT "Block_futsalId_fkey" FOREIGN KEY ("futsalId") REFERENCES "Futsal"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
