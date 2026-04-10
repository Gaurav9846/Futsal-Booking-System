import 'package:flutter/material.dart';

class RoundHeader extends StatelessWidget {
  final String roundName;
  final int completedMatches;
  final int totalMatches;
  final bool isCompleted;

  const RoundHeader({
    super.key,
    required this.roundName,
    required this.completedMatches,
    required this.totalMatches,
    required this.isCompleted,
  });

  String _formatRoundName(String round) {
    switch (round) {
      case 'QUARTER_FINAL':
        return 'Quarter Finals';
      case 'SEMI_FINAL':
        return 'Semi Finals';
      case 'FINAL':
        return 'Final';
      case 'GROUP_STAGE':
        return 'Group Stage';
      default:
        return round
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.green.shade700, Colors.green.shade500]
              : [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            roundName == 'FINAL'
                ? Icons.emoji_events
                : roundName == 'SEMI_FINAL'
                    ? Icons.account_tree
                    : Icons.sports_soccer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _formatRoundName(roundName),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$completedMatches/$totalMatches',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}