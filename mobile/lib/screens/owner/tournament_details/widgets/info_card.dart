import 'package:flutter/material.dart';
import '../../../../models/tournament.dart';

class InfoCard extends StatelessWidget {
  final Tournament tournament;

  const InfoCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Start Date',
                '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}'),
            if (tournament.endDate != null)
              _buildInfoRow(Icons.event, 'End Date',
                  '${tournament.endDate!.day}/${tournament.endDate!.month}/${tournament.endDate!.year}'),
            _buildInfoRow(
                Icons.people, 'Max Teams', '${tournament.maxTeams} teams'),
            _buildInfoRow(
                Icons.sports_soccer, 'Format', tournament.typeDisplay),
            if (tournament.entryFee != null && tournament.entryFee! > 0)
              _buildInfoRow(Icons.currency_rupee, 'Entry Fee',
                  'रू ${tournament.entryFee}'),
            if (tournament.prizePool != null && tournament.prizePool! > 0)
              _buildInfoRow(Icons.emoji_events, 'Prize Pool',
                  'रू ${tournament.prizePool}'),
            if (tournament.prizes != null && tournament.prizes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Prizes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...tournament.prizes!.map((prize) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events,
                            size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(prize)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}