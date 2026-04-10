import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int completedMatches;
  final int totalMatches;

  const ProgressCard({
    super.key,
    required this.completedMatches,
    required this.totalMatches,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalMatches > 0 ? completedMatches / totalMatches : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedMatches/$totalMatches matches played',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}