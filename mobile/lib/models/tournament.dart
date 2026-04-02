import 'package:flutter/material.dart';

enum TournamentType {
  knockout,     // Basic knockout tournament
  roundRobin,   // Round robin league
}

enum TournamentStatus {
  draft,        // Being created, not started
  ongoing,      // Matches in progress
  completed,    // Tournament finished
  cancelled,    // Tournament cancelled
}

class Tournament {
  final int id;
  final int futsalId;
  final String futsalName;
  final String name;
  final String? description;
  final TournamentType type;
  final TournamentStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final int numberOfTeams;
  final int? maxTeams;
  final double? entryFee;
  final double? prizePool;
  final String? rules;
  final List<String>? prizes;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Statistics (computed or from backend)
  final int? totalMatches;
  final int? completedMatches;
  final int? totalGoals;
  final String? leadingTeam;

  Tournament({
    required this.id,
    required this.futsalId,
    required this.futsalName,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.numberOfTeams,
    this.maxTeams,
    this.entryFee,
    this.prizePool,
    this.rules,
    this.prizes,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
    this.totalMatches,
    this.completedMatches,
    this.totalGoals,
    this.leadingTeam,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? 0,
      futsalId: json['futsalId'] ?? 0,
      futsalName: json['futsalName'] ?? json['futsal']?['name'] ?? 'Unknown Futsal',
      name: json['name'] ?? 'Unnamed Tournament',
      description: json['description'],
      type: _parseTournamentType(json['type']),
      status: _parseTournamentStatus(json['status']),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      numberOfTeams: json['numberOfTeams'] ?? 0,
      maxTeams: json['maxTeams'],
      entryFee: json['entryFee'] != null 
          ? (json['entryFee'] as num).toDouble() 
          : null,
      prizePool: json['prizePool'] != null 
          ? (json['prizePool'] as num).toDouble() 
          : null,
      rules: json['rules'],
      prizes: json['prizes'] != null 
          ? List<String>.from(json['prizes']) 
          : null,
      isPublished: json['isPublished'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      totalMatches: json['totalMatches'],
      completedMatches: json['completedMatches'],
      totalGoals: json['totalGoals'],
      leadingTeam: json['leadingTeam'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'futsalId': futsalId,
      'futsalName': futsalName,
      'name': name,
      'description': description,
      'type': _tournamentTypeToString(type),
      'status': _tournamentStatusToString(status),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'numberOfTeams': numberOfTeams,
      'maxTeams': maxTeams,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'rules': rules,
      'prizes': prizes,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalMatches': totalMatches,
      'completedMatches': completedMatches,
      'totalGoals': totalGoals,
      'leadingTeam': leadingTeam,
    };
  }

  Tournament copyWith({
    int? id,
    int? futsalId,
    String? futsalName,
    String? name,
    String? description,
    TournamentType? type,
    TournamentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfTeams,
    int? maxTeams,
    double? entryFee,
    double? prizePool,
    String? rules,
    List<String>? prizes,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalMatches,
    int? completedMatches,
    int? totalGoals,
    String? leadingTeam,
  }) {
    return Tournament(
      id: id ?? this.id,
      futsalId: futsalId ?? this.futsalId,
      futsalName: futsalName ?? this.futsalName,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      maxTeams: maxTeams ?? this.maxTeams,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      rules: rules ?? this.rules,
      prizes: prizes ?? this.prizes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalMatches: totalMatches ?? this.totalMatches,
      completedMatches: completedMatches ?? this.completedMatches,
      totalGoals: totalGoals ?? this.totalGoals,
      leadingTeam: leadingTeam ?? this.leadingTeam,
    );
  }

  // Helper getters for UI
  String get typeDisplay {
    switch (type) {
      case TournamentType.knockout:
        return 'Knockout';
      case TournamentType.roundRobin:
        return 'Round Robin';
    }
  }

  String get statusDisplay {
    switch (status) {
      case TournamentStatus.draft:
        return 'Draft';
      case TournamentStatus.ongoing:
        return 'Ongoing';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case TournamentStatus.draft:
        return Colors.grey;
      case TournamentStatus.ongoing:
        return Colors.green;
      case TournamentStatus.completed:
        return Colors.blue;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TournamentStatus.draft:
        return Icons.edit;
      case TournamentStatus.ongoing:
        return Icons.play_circle;
      case TournamentStatus.completed:
        return Icons.emoji_events;
      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

  String get progressText {
    if (totalMatches == null || completedMatches == null) return 'Not started';
    return '$completedMatches/$totalMatches matches played';
  }

  double get progressPercentage {
    if (totalMatches == null || totalMatches == 0) return 0;
    return (completedMatches ?? 0) / totalMatches!;
  }

  bool get isKnockout => type == TournamentType.knockout;
  bool get isRoundRobin => type == TournamentType.roundRobin;
  bool get isDraft => status == TournamentStatus.draft;
  bool get isOngoing => status == TournamentStatus.ongoing;
  bool get isCompleted => status == TournamentStatus.completed;
  bool get isCancelled => status == TournamentStatus.cancelled;
  bool get hasEntryFee => entryFee != null && entryFee! > 0;
  bool get hasPrizePool => prizePool != null && prizePool! > 0;
}

// Helper functions for parsing
TournamentType _parseTournamentType(String? type) {
  if (type == null) return TournamentType.knockout;
  switch (type.toLowerCase()) {
    case 'knockout':
    case 'knock_out':
    case 'elimination':
      return TournamentType.knockout;
    case 'roundrobin':
    case 'round_robin':
    case 'league':
      return TournamentType.roundRobin;
    default:
      return TournamentType.knockout;
  }
}

TournamentStatus _parseTournamentStatus(String? status) {
  if (status == null) return TournamentStatus.draft;
  switch (status.toLowerCase()) {
    case 'draft':
    case 'pending':
      return TournamentStatus.draft;
    case 'ongoing':
    case 'active':
    case 'in_progress':
      return TournamentStatus.ongoing;
    case 'completed':
    case 'finished':
    case 'done':
      return TournamentStatus.completed;
    case 'cancelled':
    case 'canceled':
      return TournamentStatus.cancelled;
    default:
      return TournamentStatus.draft;
  }
}

String _tournamentTypeToString(TournamentType type) {
  switch (type) {
    case TournamentType.knockout:
      return 'knockout';
    case TournamentType.roundRobin:
      return 'round_robin';
  }
}

String _tournamentStatusToString(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.draft:
      return 'draft';
    case TournamentStatus.ongoing:
      return 'ongoing';
    case TournamentStatus.completed:
      return 'completed';
    case TournamentStatus.cancelled:
      return 'cancelled';
  }
}