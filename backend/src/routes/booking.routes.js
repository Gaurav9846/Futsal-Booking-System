import { Router } from 'express';
import { 
  createBooking, 
  getUserBookings,
  getBookingById,
  initiatePayment,
  verifyPayment,
  userCancelBooking,
  paymentCallback,
  getOwnerTodayBookings,
  getOwnerUpcomingBookings,
  getOwnerMonthBookings,
  getOwnerBookings,
  checkInBooking,
  ownerCancelBooking,
} from '../controllers/booking.controller.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

// ============================================
// PLAYER BOOKING ROUTES
// ============================================

/**
 * @route   POST /api/bookings
 * @desc    Create a new booking
 * @access  Private
 */
router.post('/', authenticate, createBooking);

/**
 * @route   GET /api/bookings/my-bookings
 * @desc    Get current user's bookings
 * @access  Private
 */
router.get('/my-bookings', authenticate, getUserBookings);

/**
 * @route   GET /api/bookings/:bookingId
 * @desc    Get booking by ID
 * @access  Private
 */
router.get('/:bookingId', authenticate, getBookingById);

/**
 * @route   PUT /api/bookings/:bookingId/cancel
 * @desc    User cancels their own booking
 * @access  Private
 */
router.put('/:bookingId/cancel', authenticate, userCancelBooking);

// ============================================
// PAYMENT ROUTES
// ============================================

/**
 * @route   POST /api/bookings/payment/initiate
 * @desc    Initiate Khalti payment for a booking
 * @access  Private
 */
router.post('/payment/initiate', authenticate, initiatePayment);

/**
 * @route   GET /api/bookings/payment/callback
 * @desc    Khalti payment callback URL (Khalti redirects here)
 * @access  Public
 */
router.get('/payment/callback', paymentCallback);

/**
 * @route   POST /api/bookings/payment/verify
 * @desc    Verify Khalti payment
 * @access  Public
 */
router.post('/payment/verify', verifyPayment);

// ============================================
// OWNER BOOKING ROUTES
// ============================================

/**
 * @route   PUT /api/bookings/owner/:bookingId/checkin
 * @desc    Owner checks in a customer
 * @access  Private (Owner only)
 */
router.put('/owner/:bookingId/checkin', authenticate, authorize('OWNER'), checkInBooking);

/**
 * @route   DELETE /api/bookings/owner/:bookingId/cancel
 * @desc    Owner cancels a booking
 * @access  Private (Owner only)
 */
router.delete('/owner/:bookingId/cancel', authenticate, authorize('OWNER'), ownerCancelBooking);

// ============================================
// OWNER DASHBOARD ROUTES
// ============================================

/**
 * @route   GET /api/bookings/owner/today
 * @desc    Get today's bookings for owner dashboard
 * @access  Private (Owner only)
 */
router.get('/owner/today', authenticate, authorize('OWNER'), getOwnerTodayBookings);

/**
 * @route   GET /api/bookings/owner/upcoming
 * @desc    Get upcoming bookings for owner dashboard
 * @access  Private (Owner only)
 */
router.get('/owner/upcoming', authenticate, authorize('OWNER'), getOwnerUpcomingBookings);

/**
 * @route   GET /api/bookings/owner/month/:year/:month
 * @desc    Get month bookings for calendar view
 * @access  Private (Owner only)
 */
router.get('/owner/month/:year/:month', authenticate, authorize('OWNER'), getOwnerMonthBookings);

/**
 * @route   GET /api/bookings/owner/all
 * @desc    Get all bookings with filters
 * @access  Private (Owner only)
 */
router.get('/owner/all', authenticate, authorize('OWNER'), getOwnerBookings);

export default router;