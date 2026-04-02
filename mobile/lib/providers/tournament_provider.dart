import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../services/api_service.dart';

class TournamentProvider with ChangeNotifier {
  // Lists
  List<Tournament> _tournaments = [];
  List<Tournament> _myTournaments = []; // For owners
  List<Team> _teams = [];
  List<Match> _matches = [];

  // Single items
  Tournament? _currentTournament;
  Team? _currentTeam;
  Match? _currentMatch;

  // Loading states
  bool isLoading = false;
  String? error;

  // Getters
  List<Tournament> get tournaments => _tournaments;
  List<Tournament> get myTournaments => _myTournaments;
  List<Team> get teams => _teams;
  List<Match> get matches => _matches;
  Tournament? get currentTournament => _currentTournament;
  Team? get currentTeam => _currentTeam;
  Match? get currentMatch => _currentMatch;

  // ============================================
  // TOURNAMENT METHODS
  // ============================================

  // Load all tournaments (for players)
  Future<void> loadTournaments() async {
    debugPrint('🏆 TournamentProvider: Loading all tournaments');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final tournaments = await ApiService.getAllTournaments();
      _tournaments =
          tournaments.map((json) => Tournament.fromJson(json)).toList();

      debugPrint('🏆 Loaded ${_tournaments.length} tournaments');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error loading tournaments: $e');
    }
  }

  // Load owner's tournaments (for dashboard)
  Future<void> loadMyTournaments() async {
    debugPrint('🏆 TournamentProvider: Loading my tournaments');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final tournaments = await ApiService.getMyTournaments();
      _myTournaments =
          tournaments.map((json) => Tournament.fromJson(json)).toList();

      debugPrint('🏆 Loaded ${_myTournaments.length} my tournaments');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error loading my tournaments: $e');
    }
  }

  // In tournament_provider.dart - REPLACE the loadTournament method

  Future<void> loadTournament(int tournamentId) async {
    debugPrint('🏆 Loading tournament $tournamentId');
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.getTournamentById(tournamentId);
      debugPrint('🏆 Full tournament response: $response');

      // Check if response contains tournament data
      if (response != null) {
        // The API returns { status: 'success', tournament: {...} }
        // So we need to extract the tournament object
        Map<String, dynamic> tournamentData;

        if (response['tournament'] != null) {
          // If response has tournament wrapper
          tournamentData = response['tournament'];
        } else {
          // If response is directly the tournament object
          tournamentData = response;
        }

        debugPrint('🏆 Tournament data extracted: $tournamentData');
        _currentTournament = Tournament.fromJson(tournamentData);

        // Log the parsed data to verify
        debugPrint('🏆 Tournament loaded: ${_currentTournament?.name}');
        debugPrint('🏆 Max Teams: ${_currentTournament?.maxTeams}');
        debugPrint('🏆 Start Date: ${_currentTournament?.startDate}');
      } else {
        debugPrint('🏆 Tournament response is null');
        error = 'Tournament not found';
      }

      // Load teams and matches regardless
      await Future.wait([
        loadTeams(tournamentId),
        loadMatches(tournamentId),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error loading tournament: $e');
      debugPrint('🏆 Stack trace: ${StackTrace.current}');
    }
  }

  // Create new tournament
  Future<Map<String, dynamic>> createTournament(
      Map<String, dynamic> tournamentData) async {
    debugPrint('🏆 TournamentProvider: Creating tournament');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.createTournament(tournamentData);

      if (response['status'] == 'success') {
        // Refresh my tournaments list
        await loadMyTournaments();

        isLoading = false;
        notifyListeners();

        return {
          'status': 'success',
          'message': response['message'] ?? 'Tournament created successfully',
          'tournamentId': response['tournament']?['id'],
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to create tournament',
        };
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update tournament
// In tournament_provider.dart - Update updateTournament method

  Future<Map<String, dynamic>> updateTournament(
      int tournamentId, Map<String, dynamic> tournamentData) async {
    debugPrint('🏆 TournamentProvider: Updating tournament $tournamentId');
    debugPrint('🏆 Tournament data: $tournamentData');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.updateTournament(tournamentId, tournamentData);
      debugPrint('🏆 Update response: $response');

      if (response['status'] == 'success') {
        if (_currentTournament?.id == tournamentId) {
          await loadTournament(tournamentId);
        }
        await loadMyTournaments();
        isLoading = false;
        notifyListeners();
        return {
          'status': 'success',
          'message': response['message'] ?? 'Tournament updated successfully',
        };
      } else {
        isLoading = false;
        notifyListeners();

        // Check if it's a 500 error
        if (response.toString().contains('500')) {
          return {
            'status': 'error',
            'message':
                'Server error: Unable to update tournament. The tournament might have been modified or started.',
          };
        }

        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update tournament',
        };
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      debugPrint('🏆 Error updating tournament: $e');

      return {
        'status': 'error',
        'message': 'Network error: Could not update tournament',
      };
    }
  }

  // Delete tournament
  Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
    debugPrint('🏆 TournamentProvider: Deleting tournament $tournamentId');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteTournament(tournamentId);

      if (response['status'] == 'success') {
        // Remove from lists
        _tournaments.removeWhere((t) => t.id == tournamentId);
        _myTournaments.removeWhere((t) => t.id == tournamentId);

        if (_currentTournament?.id == tournamentId) {
          _currentTournament = null;
        }

        isLoading = false;
        notifyListeners();

        return {
          'status': 'success',
          'message': response['message'] ?? 'Tournament deleted successfully',
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to delete tournament',
        };
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update tournament status
  // In tournament_provider.dart - REPLACE the updateTournamentStatus method

// In tournament_provider.dart - REPLACE the updateTournamentStatus method

  // In tournament_provider.dart - REPLACE the updateTournamentStatus method

  Future<Map<String, dynamic>> updateTournamentStatus(
      int tournamentId, TournamentStatus status) async {
    String actionMessage = '';
    switch (status) {
      case TournamentStatus.ongoing:
        actionMessage = 'start';
        break;
      case TournamentStatus.completed:
        actionMessage = 'complete';
        break;
      case TournamentStatus.cancelled:
        actionMessage = 'cancel';
        break;
      default:
        actionMessage = 'update';
    }

    debugPrint('🏆 ===== UPDATE TOURNAMENT STATUS START =====');
    debugPrint('🏆 Tournament ID: $tournamentId');
    debugPrint('🏆 Action: $actionMessage');
    debugPrint('🏆 New Status: $status');

    isLoading = true;
    notifyListeners();

    try {
      // First, check if tournament has teams before starting
      if (status == TournamentStatus.ongoing) {
        // Load fresh teams data
        await loadTeams(tournamentId);
        if (_teams.isEmpty) {
          isLoading = false;
          notifyListeners();
          debugPrint('🏆 Cannot start tournament: No teams added');
          return {
            'status': 'error',
            'message': 'Cannot start tournament: Please add teams first',
            'action': 'add_teams',
          };
        }

        // Check minimum teams (at least 2)
        if (_teams.length < 2) {
          isLoading = false;
          notifyListeners();
          return {
            'status': 'error',
            'message': 'Cannot start tournament: Need at least 2 teams',
            'action': 'add_teams',
          };
        }
      }

      // Convert status to string that backend expects
      String statusString = _tournamentStatusToString(status);
      debugPrint('🏆 Status string for API: $statusString');

      // Log the exact endpoint being called
      debugPrint('🏆 Calling API: tournaments/$tournamentId/status');

      final response =
          await ApiService.updateTournamentStatus(tournamentId, statusString);

      debugPrint('🏆 Full API Response: $response');
      debugPrint('🏆 Response status: ${response['status']}');
      debugPrint('🏆 Response message: ${response['message']}');

      if (response['status'] == 'success') {
        debugPrint('🏆 Status update successful!');

        // Update local tournament status immediately for UI feedback
        if (_currentTournament?.id == tournamentId) {
          _currentTournament = _currentTournament?.copyWith(status: status);
          debugPrint(
              '🏆 Updated current tournament status to: ${_currentTournament?.status}');
        }

        // Also update in lists
        _updateTournamentInLists(
            tournamentId, (t) => t.copyWith(status: status));

        // Refresh the tournament data from server to ensure everything is in sync
        debugPrint('🏆 Refreshing tournament data...');
        await loadTournament(tournamentId);

        isLoading = false;
        notifyListeners();
        debugPrint('🏆 ===== UPDATE TOURNAMENT STATUS END (SUCCESS) =====');

        String successMessage = '';
        switch (status) {
          case TournamentStatus.ongoing:
            successMessage = 'Tournament started successfully!';
            break;
          case TournamentStatus.completed:
            successMessage = 'Tournament marked as completed!';
            break;
          case TournamentStatus.cancelled:
            successMessage = 'Tournament cancelled successfully.';
            break;
          default:
            successMessage = response['message'] ?? 'Tournament status updated';
        }

        return {
          'status': 'success',
          'message': successMessage,
        };
      } else {
        debugPrint('🏆 Status update failed: ${response['message']}');
        isLoading = false;
        notifyListeners();
        debugPrint('🏆 ===== UPDATE TOURNAMENT STATUS END (FAILED) =====');

        return {
          'status': 'error',
          'message':
              response['message'] ?? 'Failed to ${actionMessage} tournament',
        };
      }
    } catch (e) {
      debugPrint('🏆 EXCEPTION in updateTournamentStatus: $e');
      debugPrint('🏆 Stack trace: ${StackTrace.current}');
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 ===== UPDATE TOURNAMENT STATUS END (EXCEPTION) =====');

      return {
        'status': 'error',
        'message': 'Network error: Could not ${actionMessage} tournament',
      };
    }
  }
  // ============================================
  // TEAM METHODS
  // ============================================

  // Load teams for a tournament
  Future<void> loadTeams(int tournamentId) async {
    debugPrint(
        '🏆 TournamentProvider: Loading teams for tournament $tournamentId');

    try {
      final teams = await ApiService.getTeams(tournamentId);
      _teams = teams.map((json) => Team.fromJson(json)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('🏆 Error loading teams: $e');
    }
  }

  // Add team to tournament
  Future<Map<String, dynamic>> addTeam(
      int tournamentId, Map<String, dynamic> teamData) async {
    debugPrint(
        '🏆 TournamentProvider: Adding team to tournament $tournamentId');

    try {
      final response = await ApiService.addTeam(tournamentId, teamData);

      if (response['status'] == 'success') {
        // Refresh teams
        await loadTeams(tournamentId);

        return {
          'status': 'success',
          'message': response['message'] ?? 'Team added successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to add team',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error adding team: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update team
  Future<Map<String, dynamic>> updateTeam(
      int teamId, Map<String, dynamic> teamData) async {
    debugPrint('🏆 TournamentProvider: Updating team $teamId');

    try {
      final response = await ApiService.updateTeam(teamId, teamData);

      if (response['status'] == 'success') {
        // Update in local list
        final index = _teams.indexWhere((t) => t.id == teamId);
        if (index != -1) {
          _teams[index] = Team.fromJson({
            ..._teams[index].toJson(),
            ...teamData,
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': response['message'] ?? 'Team updated successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update team',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating team: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Delete team
  Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    debugPrint('🏆 TournamentProvider: Deleting team $teamId');

    try {
      final response = await ApiService.deleteTeam(teamId);

      if (response['status'] == 'success') {
        _teams.removeWhere((t) => t.id == teamId);
        notifyListeners();

        return {
          'status': 'success',
          'message': response['message'] ?? 'Team deleted successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to delete team',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error deleting team: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // MATCH METHODS
  // ============================================

  // Load matches for a tournament
  Future<void> loadMatches(int tournamentId) async {
    debugPrint(
        '🏆 TournamentProvider: Loading matches for tournament $tournamentId');

    try {
      final matches = await ApiService.getMatches(tournamentId);
      _matches = matches.map((json) => Match.fromJson(json)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('🏆 Error loading matches: $e');
    }
  }

  // Generate fixtures (for owner)
  Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
    debugPrint(
        '🏆 TournamentProvider: Generating fixtures for tournament $tournamentId');

    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.generateFixtures(tournamentId);

      if (response['status'] == 'success') {
        // Refresh matches
        await loadMatches(tournamentId);
        await loadTournament(tournamentId);

        isLoading = false;
        notifyListeners();

        return {
          'status': 'success',
          'message': response['message'] ?? 'Fixtures generated successfully',
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to generate fixtures',
        };
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error generating fixtures: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update match score
  Future<Map<String, dynamic>> updateMatchScore(
      int matchId, int team1Score, int team2Score,
      {int? team1Penalty, int? team2Penalty}) async {
    debugPrint('🏆 TournamentProvider: Updating score for match $matchId');

    try {
      final scoreData = {
        'homeScore': team1Score,
        'awayScore': team2Score,
        if (team1Penalty != null) 'homePenalty': team1Penalty,
        if (team2Penalty != null) 'awayPenalty': team2Penalty,
      };

      final response = await ApiService.updateMatchScore(matchId, scoreData);

      if (response['status'] == 'success') {
        // Update match in list
        final index = _matches.indexWhere((m) => m.id == matchId);
        if (index != -1) {
          _matches[index] = Match.fromJson({
            ..._matches[index].toJson(),
            'team1Score': team1Score,
            'team2Score': team2Score,
            'team1Penalty': team1Penalty,
            'team2Penalty': team2Penalty,
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': response['message'] ?? 'Score updated successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update score',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating score: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update match status
  Future<Map<String, dynamic>> updateMatchStatus(
      int matchId, MatchStatus status) async {
    debugPrint(
        '🏆 TournamentProvider: Updating match $matchId status to $status');

    try {
      final response = await ApiService.updateMatchStatus(
          matchId, _matchStatusToString(status));

      if (response['status'] == 'success') {
        // Update match in list
        final index = _matches.indexWhere((m) => m.id == matchId);
        if (index != -1) {
          _matches[index] = Match.fromJson({
            ..._matches[index].toJson(),
            'status': _matchStatusToString(status),
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': response['message'] ?? 'Match status updated',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update match status',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating match status: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  void _updateTournamentInLists(int tournamentId, Function(Tournament) update) {
    // Update in myTournaments
    final myIndex = _myTournaments.indexWhere((t) => t.id == tournamentId);
    if (myIndex != -1) {
      _myTournaments[myIndex] = update(_myTournaments[myIndex]);
    }

    // Update in tournaments list
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index != -1) {
      _tournaments[index] = update(_tournaments[index]);
    }
  }

  // Clear all data (for logout)
  void clearData() {
    _tournaments = [];
    _myTournaments = [];
    _teams = [];
    _matches = [];
    _currentTournament = null;
    _currentTeam = null;
    _currentMatch = null;
    error = null;
    notifyListeners();
  }

  // Get tournament statistics
  Map<String, dynamic> getTournamentStats(int tournamentId) {
    final tournament = _tournaments.firstWhere(
      (t) => t.id == tournamentId,
      orElse: () => _myTournaments.firstWhere(
        (t) => t.id == tournamentId,
        orElse: () => Tournament(
          id: 0,
          futsalId: 0,
          futsalName: '',
          name: '',
          type: TournamentType.knockout,
          status: TournamentStatus.draft,
          startDate: DateTime.now(),
          numberOfTeams: 0,
          isPublished: false,
          createdAt: DateTime.now(),
        ),
      ),
    );

    final tournamentMatches =
        _matches.where((m) => m.tournamentId == tournamentId).toList();
    final totalMatches = tournamentMatches.length;
    final completedMatches =
        tournamentMatches.where((m) => m.isCompleted).length;

    // Calculate top scorer (would come from backend in real app)

    return {
      'tournament': tournament,
      'totalTeams': _teams.length,
      'totalMatches': totalMatches,
      'completedMatches': completedMatches,
      'progressPercentage':
          totalMatches > 0 ? completedMatches / totalMatches : 0,
    };
  }
}

// Helper functions (duplicated from models to avoid import issues)
String _tournamentStatusToString(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.draft:
      return 'DRAFT';
    case TournamentStatus.ongoing:
      return 'ONGOING';
    case TournamentStatus.completed:
      return 'COMPLETED';
    case TournamentStatus.cancelled:
      return 'CANCELLED';
  }
}

String _matchStatusToString(MatchStatus status) {
  switch (status) {
    case MatchStatus.scheduled:
      return 'scheduled';
    case MatchStatus.ongoing:
      return 'ongoing';
    case MatchStatus.completed:
      return 'completed';
    case MatchStatus.postponed:
      return 'postponed';
    case MatchStatus.cancelled:
      return 'cancelled';
  }
}
