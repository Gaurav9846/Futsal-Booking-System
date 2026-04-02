import 'package:flutter/material.dart';

class Team {
  final int id;
  final int tournamentId;
  final String name;
  final String? logo;
  final String? captainName;
  final String? captainPhone;
  final List<String>? players;
  final String? jerseyColor;
  final DateTime registeredAt;

  // Tournament statistics
  final int? matchesPlayed;
  final int? wins;
  final int? draws;
  final int? losses;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? points;
  final String? groupName; // For group stage tournaments
  final int? groupPosition;

  Team({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.logo,
    this.captainName,
    this.captainPhone,
    this.players,
    this.jerseyColor,
    required this.registeredAt,
    this.matchesPlayed,
    this.wins,
    this.draws,
    this.losses,
    this.goalsFor,
    this.goalsAgainst,
    this.points,
    this.groupName,
    this.groupPosition,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    // Extract player names from TeamMember objects
    List<String>? playerNames;
    if (json['players'] != null) {
      final playersList = json['players'] as List;
      playerNames = playersList
          .map((p) {
            if (p is String) return p;
            // Backend returns TeamMember objects
            return p['playerName']?.toString() ?? '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
    }

    // Extract captain info from players list
    String? captainName;
    String? captainPhone;
    String? jerseyColor;
    if (json['players'] != null) {
      final playersList = json['players'] as List;
      final captain = playersList.firstWhere(
        (p) => p is Map && p['role'] == 'CAPTAIN',
        orElse: () => null,
      );
      if (captain != null) {
        captainName = captain['playerName'];
        captainPhone = captain['playerPhone'];
        jerseyColor = captain['jerseyColor'];
      }
    }

    return Team(
      id: json['id'] ?? 0,
      tournamentId: json['tournamentId'] ?? 0,
      name: json['name'] ?? 'Unnamed Team',
      logo: json['logo'],
      captainName: json['captainName'] ?? captainName,
      captainPhone: json['captainPhone'] ?? captainPhone,
      players: playerNames,
      jerseyColor: json['jerseyColor'] ?? jerseyColor,
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'])
          : DateTime.now(),
      matchesPlayed: json['matchesPlayed'],
      wins: json['wins'],
      draws: json['draws'],
      losses: json['losses'],
      goalsFor: json['goalsFor'],
      goalsAgainst: json['goalsAgainst'],
      points: json['points'],
      groupName: json['groupName'],
      groupPosition: json['groupPosition'],
    );
  }

  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'tournamentId': tournamentId,
    'name': name,
    'logo': logo,
    'captainName': captainName,
    'captainPhone': captainPhone,
    'players': players,
    'jerseyColor': jerseyColor,
    'registeredAt': registeredAt.toIso8601String(),
    'matchesPlayed': matchesPlayed,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'goalsFor': goalsFor,
    'goalsAgainst': goalsAgainst,
    'points': points,
    'groupName': groupName,
    'groupPosition': groupPosition,
  };
}

  Team copyWith({
    int? id,
    int? tournamentId,
    String? name,
    String? logo,
    String? captainName,
    String? captainPhone,
    List<String>? players,
    String? jerseyColor,
    DateTime? registeredAt,
    int? matchesPlayed,
    int? wins,
    int? draws,
    int? losses,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
    String? groupName,
    int? groupPosition,
  }) {
    return Team(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      captainName: captainName ?? this.captainName,
      captainPhone: captainPhone ?? this.captainPhone,
      players: players ?? this.players,
      jerseyColor: jerseyColor ?? this.jerseyColor,
      registeredAt: registeredAt ?? this.registeredAt,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
      groupName: groupName ?? this.groupName,
      groupPosition: groupPosition ?? this.groupPosition,
    );
  }

  // Helper getters
  int get goalDifference => (goalsFor ?? 0) - (goalsAgainst ?? 0);

  String get formDisplay {
    if (wins == null || draws == null || losses == null) return 'N/A';
    return 'W: $wins | D: $draws | L: $losses';
  }

  double? get winPercentage {
    if (matchesPlayed == null || matchesPlayed == 0) return null;
    return (wins ?? 0) / matchesPlayed!;
  }

  double? get pointsPerMatch {
    if (matchesPlayed == null || matchesPlayed == 0) return null;
    return (points ?? 0) / matchesPlayed!;
  }

  bool get hasStatistics => matchesPlayed != null && matchesPlayed! > 0;
}
