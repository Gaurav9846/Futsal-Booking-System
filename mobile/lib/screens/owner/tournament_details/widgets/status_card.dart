import 'package:flutter/material.dart';
import '../../../../models/tournament.dart';

class StatusCard extends StatelessWidget {
  final Tournament tournament;

  const StatusCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tournament.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tournament.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(tournament.statusIcon, color: tournament.statusColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.statusDisplay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tournament.statusColor,
                ),
              ),
              Text(
                tournament.typeDisplay,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const Spacer(),
          if (tournament.isPublished)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Public',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}