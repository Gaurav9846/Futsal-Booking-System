import 'package:flutter/material.dart';

enum MatchStatus {
  scheduled,
  ongoing,
  completed,
  postponed,
  cancelled,
}

class Match {
  final int id;
  final int tournamentId;
  final String tournamentName;
  final String? round; // For knockout: round number
  final String? groupName; // For round robin: group name
  final int? matchNumber; // Match number in tournament

  // Teams
  final int? team1Id;
  final String team1Name;
  final String? team1Logo;
  final int? team2Id;
  final String team2Name;
  final String? team2Logo;

  // Scores
  final int? team1Score;
  final int? team2Score;
  final int? team1Penalty; // For penalty shootouts
  final int? team2Penalty;

  // Details
  final DateTime scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? venue;
  final String? referee;
  final MatchStatus status;
  final String? winnerTeam;
  final String? manOfTheMatch;
  final String? notes;

  // For round robin points
  final int? team1Points;
  final int? team2Points;

  Match({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    this.round,
    this.groupName,
    this.matchNumber,
    this.team1Id,
    required this.team1Name,
    this.team1Logo,
    this.team2Id,
    required this.team2Name,
    this.team2Logo,
    this.team1Score,
    this.team2Score,
    this.team1Penalty,
    this.team2Penalty,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.venue,
    this.referee,
    required this.status,
    this.winnerTeam,
    this.manOfTheMatch,
    this.notes,
    this.team1Points,
    this.team2Points,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? 0,
      tournamentId: json['tournamentId'] ?? 0,
      tournamentName:
          json['tournamentName'] ?? json['tournament']?['name'] ?? 'Unknown',
      round: json['round'],
      team1Id: json['team1Id'] ?? json['homeTeamId'], // ← ADD fallback
      team1Name: json['team1Name'] ??
          json['homeTeam']?['name'] ??
          'TBD', // ← ADD fallback
      team2Id: json['team2Id'] ?? json['awayTeamId'], // ← ADD fallback
      team2Name: json['team2Name'] ??
          json['awayTeam']?['name'] ??
          'TBD', // ← ADD fallback
      team1Score: json['team1Score'] ?? json['homeScore'], // ← ADD fallback
      team2Score: json['team2Score'] ?? json['awayScore'], // ← ADD fallback
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : json['matchDate'] != null // ← ADD fallback
              ? DateTime.parse(json['matchDate'])
              : DateTime.now(),
      status: _parseMatchStatus(json['status']),
      team1Penalty: json['team1Penalty'] ?? json['homePenalty'],
      team2Penalty: json['team2Penalty'] ?? json['awayPenalty'],
      groupName: json['groupName'],
      matchNumber: json['matchNumber'],
      team1Logo: json['team1Logo'] ?? json['homeTeam']?['logo'],
      team2Logo: json['team2Logo'] ?? json['awayTeam']?['logo'],
      startTime: null,
      endTime: null,
      venue: json['venue'],
      referee: json['referee'],
      winnerTeam: json['winnerTeam'],
      manOfTheMatch: json['manOfTheMatch'],
      notes: json['notes'],
      team1Points: json['team1Points'],
      team2Points: json['team2Points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'round': round,
      'groupName': groupName,
      'matchNumber': matchNumber,
      'team1Id': team1Id,
      'team1Name': team1Name,
      'team1Logo': team1Logo,
      'team2Id': team2Id,
      'team2Name': team2Name,
      'team2Logo': team2Logo,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'team1Penalty': team1Penalty,
      'team2Penalty': team2Penalty,
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'venue': venue,
      'referee': referee,
      'status': _matchStatusToString(status),
      'winnerTeam': winnerTeam,
      'manOfTheMatch': manOfTheMatch,
      'notes': notes,
      'team1Points': team1Points,
      'team2Points': team2Points,
    };
  }

  // Helper getters
  bool get isScheduled => status == MatchStatus.scheduled;
  bool get isOngoing => status == MatchStatus.ongoing;
  bool get isCompleted => status == MatchStatus.completed;
  bool get isPostponed => status == MatchStatus.postponed;
  bool get isCancelled => status == MatchStatus.cancelled;

  bool get hasScore => team1Score != null && team2Score != null;
  bool get hasPenalty => team1Penalty != null && team2Penalty != null;

  String get scoreDisplay {
    if (!hasScore) return 'vs';
    if (hasPenalty && team1Score == team2Score) {
      return '$team1Score ($team1Penalty) - ($team2Penalty) $team2Score';
    }
    return '$team1Score - $team2Score';
  }

  String? get winner {
    if (!hasScore) return null;
    if (team1Score! > team2Score!) return team1Name;
    if (team2Score! > team1Score!) return team2Name;
    if (hasPenalty && team1Penalty! > team2Penalty!) return team1Name;
    if (hasPenalty && team2Penalty! > team1Penalty!) return team2Name;
    return null; // Draw
  }

  bool get isDraw {
    if (!hasScore) return false;
    if (team1Score == team2Score) {
      if (hasPenalty) return team1Penalty == team2Penalty;
      return true;
    }
    return false;
  }

  Color get statusColor {
    switch (status) {
      case MatchStatus.scheduled:
        return Colors.blue;
      case MatchStatus.ongoing:
        return Colors.green;
      case MatchStatus.completed:
        return Colors.grey;
      case MatchStatus.postponed:
        return Colors.orange;
      case MatchStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case MatchStatus.scheduled:
        return Icons.schedule;
      case MatchStatus.ongoing:
        return Icons.play_circle;
      case MatchStatus.completed:
        return Icons.check_circle;
      case MatchStatus.postponed:
        return Icons.access_time;
      case MatchStatus.cancelled:
        return Icons.cancel;
    }
  }
}

// Helper functions
MatchStatus _parseMatchStatus(String? status) {
  if (status == null) return MatchStatus.scheduled;
  switch (status.toLowerCase()) {
    case 'scheduled':
    case 'upcoming':
      return MatchStatus.scheduled;
    case 'ongoing':
    case 'in_progress':
    case 'playing':
      return MatchStatus.ongoing;
    case 'completed':
    case 'finished':
    case 'done':
      return MatchStatus.completed;
    case 'postponed':
    case 'delayed':
      return MatchStatus.postponed;
    case 'cancelled':
    case 'canceled':
      return MatchStatus.cancelled;
    default:
      return MatchStatus.scheduled;
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
