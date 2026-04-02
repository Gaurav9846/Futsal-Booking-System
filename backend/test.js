// test.js - replace entire content with this
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

const bookedSlots = await prisma.timeSlot.findMany({
  where: { status: { in: ['BOOKED', 'LOCKED'] } },
  include: {
    bookings: {
      where: { status: { in: ['PENDING', 'CONFIRMED'] } }
    }
  }
});

const orphaned = bookedSlots.filter(s => s.bookings.length === 0);
console.log(`Found ${orphaned.length} orphaned slots:`, orphaned.map(s => s.id));

if (orphaned.length > 0) {
  await prisma.timeSlot.updateMany({
    where: { id: { in: orphaned.map(s => s.id) } },
    data: { status: 'AVAILABLE', lockedUntil: null }
  });
  console.log('✅ Cleaned up all orphaned slots');
} else {
  console.log('No orphaned slots found');
}

await prisma.$disconnect();
const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJQdXJuYUphbWVzMTBAZ21haWwuY29tIiwicm9sZSI6Ik9XTkVSIiwiaWF0IjoxNzcyODg1MDI4LCJleHAiOjE3NzM0ODk4Mjh9.2kCpH24vGyPntIPdKzMhXjnx5fgLCeb_nBa6IH-hk00'

// test.js
const res = await fetch('http://localhost:5000/api/futsals/1/reviews', {
  headers: { 'Authorization': `Bearer ${token}` }
});
console.log('REVIEWS:', await res.json());