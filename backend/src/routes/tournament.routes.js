import { Router } from 'express';
import {
  // Tournament CRUD
  createTournament,
  getAllTournaments,
  getMyTournaments,
  getTournamentById,
  updateTournament,
  deleteTournament,
  updateTournamentStatus,
  
  // Team Management
  addTeam,
  getTeams,
  updateTeam,
  deleteTeam,
  
  // Fixture Generation
  generateFixtures,
  getMatches,
  updateMatchScore,
  updateMatchStatus,
  
  // Statistics
  getTournamentStandings
} from '../controllers/tournament.controller.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

// ============================================
// TOURNAMENT ROUTES
// ============================================

/**
 * @route   POST /api/tournaments
 * @desc    Create a new tournament
 * @access  Private (Owner/Admin)
 */
router.post('/', authenticate, authorize('OWNER', 'ADMIN'), createTournament);

/**
 * @route   GET /api/tournaments
 * @desc    Get all published tournaments
 * @access  Public
 */
router.get('/', getAllTournaments);

/**
 * @route   GET /api/tournaments/my-tournaments
 * @desc    Get owner's tournaments
 * @access  Private (Owner/Admin)
 */
router.get('/my-tournaments', authenticate, authorize('OWNER', 'ADMIN'), getMyTournaments);

/**
 * @route   GET /api/tournaments/:id
 * @desc    Get tournament by ID
 * @access  Public
 */
router.get('/:id', getTournamentById);

/**
 * @route   PUT /api/tournaments/:id
 * @desc    Update tournament
 * @access  Private (Owner/Admin)
 */
router.put('/:id', authenticate, authorize('OWNER', 'ADMIN'), updateTournament);

/**
 * @route   DELETE /api/tournaments/:id
 * @desc    Delete tournament
 * @access  Private (Owner/Admin)
 */
router.delete('/:id', authenticate, authorize('OWNER', 'ADMIN'), deleteTournament);

/**
 * @route   PATCH /api/tournaments/:id/status
 * @desc    Update tournament status
 * @access  Private (Owner/Admin)
 */
router.patch('/:id/status', authenticate, authorize('OWNER', 'ADMIN'), updateTournamentStatus);

// ============================================
// TEAM ROUTES
// ============================================

/**
 * @route   POST /api/tournaments/:tournamentId/teams
 * @desc    Add team to tournament
 * @access  Private (Owner/Admin)
 */
router.post('/:tournamentId/teams', authenticate, authorize('OWNER', 'ADMIN'), addTeam);

/**
 * @route   GET /api/tournaments/:tournamentId/teams
 * @desc    Get teams for a tournament
 * @access  Public
 */
router.get('/:tournamentId/teams', getTeams);

/**
 * @route   PUT /api/teams/:teamId
 * @desc    Update team
 * @access  Private (Owner/Admin)
 */
router.put('/teams/:teamId', authenticate, authorize('OWNER', 'ADMIN'), updateTeam);

/**
 * @route   DELETE /api/teams/:teamId
 * @desc    Delete team
 * @access  Private (Owner/Admin)
 */
router.delete('/teams/:teamId', authenticate, authorize('OWNER', 'ADMIN'), deleteTeam);

// ============================================
// FIXTURE ROUTES
// ============================================

/**
 * @route   POST /api/tournaments/:tournamentId/generate-fixtures
 * @desc    Generate fixtures for tournament
 * @access  Private (Owner/Admin)
 */
router.post('/:tournamentId/generate-fixtures', authenticate, authorize('OWNER', 'ADMIN'), generateFixtures);

/**
 * @route   GET /api/tournaments/:tournamentId/matches
 * @desc    Get matches for a tournament
 * @access  Public
 */
router.get('/:tournamentId/matches', getMatches);

/**
 * @route   PATCH /api/matches/:matchId/score
 * @desc    Update match score
 * @access  Private (Owner/Admin)
 */
router.patch('/matches/:matchId/score', authenticate, authorize('OWNER', 'ADMIN'), updateMatchScore);

/**
 * @route   PATCH /api/matches/:matchId/status
 * @desc    Update match status
 * @access  Private (Owner/Admin)
 */
router.patch('/matches/:matchId/status', authenticate, authorize('OWNER', 'ADMIN'), updateMatchStatus);

// ============================================
// STATISTICS ROUTES
// ============================================

/**
 * @route   GET /api/tournaments/:tournamentId/standings
 * @desc    Get tournament standings/leaderboard
 * @access  Public
 */
router.get('/:tournamentId/standings', getTournamentStandings);

export default router;