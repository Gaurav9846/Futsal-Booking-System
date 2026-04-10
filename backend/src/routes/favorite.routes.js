import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import {
  getFavorites,
  addFavorite,
  removeFavorite
} from '../controllers/favorite.controller.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Get all favorites for current user
router.get('/', getFavorites);

// Add a favorite
router.post('/', addFavorite);

// Remove a favorite
router.delete('/:futsalId', removeFavorite);

export default router;