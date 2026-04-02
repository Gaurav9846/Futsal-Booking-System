import { Router } from 'express';
import { register, login, getMe, verifyEmail, resendOtp, forgotPassword, resetPassword } from '../controllers/auth.controller.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', register);

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', login);

/**
 * @route   GET /api/auth/me
 * @desc    Get current user info
 * @access  Private
 */
router.get('/me', authenticate, getMe);

router.post('/verify-email', verifyEmail);       // ← NEW
router.post('/resend-otp', resendOtp);           // ← NEW
router.post('/forgot-password', forgotPassword); // ← NEW
router.post('/reset-password', resetPassword);   // ← NEW

export default router;