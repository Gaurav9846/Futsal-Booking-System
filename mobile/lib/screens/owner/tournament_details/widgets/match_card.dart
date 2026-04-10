import 'package:flutter/material.dart';
import '../../../../models/match.dart';
import '../../../../models/tournament.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final Tournament tournament;
  final VoidCallback onUpdateScore;

  const MatchCard({
    super.key,
    required this.match,
    required this.tournament,
    required this.onUpdateScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: match.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    match.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: match.statusColor,
                    ),
                  ),
                ),
                Text(
                  '${match.scheduledDate.day}/${match.scheduledDate.month}/${match.scheduledDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            // Cancelled indicator
            if (tournament.status == TournamentStatus.cancelled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cancel, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Tournament Cancelled - No Further Updates',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Teams and score
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.team1Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: match.isCompleted
                        ? Colors.grey.shade100
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.scoreDisplay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: match.isCompleted
                          ? Colors.grey.shade800
                          : Colors.green,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.team2Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            // Update score button
            if (!match.isCompleted &&
                !match.isCancelled &&
                tournament.status != TournamentStatus.cancelled) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onUpdateScore,
                icon: const Icon(Icons.scoreboard, size: 16),
                label: const Text('Update Score'),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
            ],

            if (match.isCompleted && match.winner != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🏆 Winner: ${match.winner}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}