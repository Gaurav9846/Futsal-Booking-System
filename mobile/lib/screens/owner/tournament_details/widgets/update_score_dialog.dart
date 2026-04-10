import 'package:flutter/material.dart';
import '../../../../models/match.dart';
import '../../../../providers/tournament_provider.dart';

class UpdateScoreDialog {
  static Future<void> show({
    required BuildContext context,
    required Match match,
    required TournamentProvider provider,
    required int tournamentId,
    required VoidCallback onRefresh,
  }) async {
    int team1Score = match.team1Score ?? 0;
    int team2Score = match.team2Score ?? 0;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${match.team1Name} vs ${match.team2Name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Team 1 score
                  Column(
                    children: [
                      Text(match.team1Name, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: team1Score > 0
                                ? () => setDialogState(() => team1Score--)
                                : null,
                            color: Colors.green,
                          ),
                          Text(
                            '$team1Score',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setDialogState(() => team1Score++),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('vs', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ),
                  // Team 2 score
                  Column(
                    children: [
                      Text(match.team2Name, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: team2Score > 0
                                ? () => setDialogState(() => team2Score--)
                                : null,
                            color: Colors.green,
                          ),
                          Text(
                            '$team2Score',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setDialogState(() => team2Score++),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await provider.updateMatchScore(
                  match.id,
                  team1Score,
                  team2Score,
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['status'] == 'success'
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                  if (result['status'] == 'success') {
                    onRefresh();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Score'),
            ),
          ],
        ),
      ),
    );
  }
}