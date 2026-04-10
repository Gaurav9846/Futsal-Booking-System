import { Router } from 'express';
import {
  getDashboardStats,
  getTodayBookings,
  getWeeklyRevenue,
  getPeakHours,
  getOwnerUpcomingBookings,
  getMonthBookings
} from '../controllers/owner.controller.js';
import {
  checkInBooking,
  confirmCodPayment,
  userCancelBooking
} from '../controllers/booking.controller.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.use(authenticate, authorize('OWNER', 'ADMIN'));

// Dashboard
router.get('/dashboard/stats', getDashboardStats);
router.get('/dashboard/today-bookings', getTodayBookings);
router.get('/dashboard/weekly-revenue', getWeeklyRevenue);
router.get('/dashboard/peak-hours', getPeakHours);

// Bookings list
router.get('/bookings/upcoming', getOwnerUpcomingBookings);
router.get('/bookings/month', getMonthBookings);

// ✅ Booking actions
router.put('/bookings/:bookingId/checkin', checkInBooking);
router.put('/bookings/:bookingId/cod-confirm', confirmCodPayment);
router.put('/bookings/:bookingId/cancel', userCancelBooking);  // reuse same cancel logic

export default router;