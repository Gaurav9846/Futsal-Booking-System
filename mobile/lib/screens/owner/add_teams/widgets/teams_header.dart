import 'package:flutter/material.dart';
import '../../../../models/tournament.dart';

class TeamsHeader extends StatelessWidget {
  final int teamCount;
  final int maxTeams;
  final TournamentType tournamentType;

  const TeamsHeader({
    super.key,
    required this.teamCount,
    required this.maxTeams,
    required this.tournamentType,
  });

  @override
  Widget build(BuildContext context) {
    final canAddMore = teamCount < maxTeams;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teams Added: $teamCount/$maxTeams',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tournamentType == TournamentType.knockout
                      ? 'Knockout: needs 2, 4, 8, 16, or 32 teams'
                      : 'Round robin: all teams play each other',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!canAddMore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Max teams reached',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}