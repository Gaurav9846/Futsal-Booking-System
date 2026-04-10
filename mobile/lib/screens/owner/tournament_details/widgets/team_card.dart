import 'package:flutter/material.dart';
import '../../../../models/team.dart';

class TeamCard extends StatelessWidget {
  final Team team;

  const TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.shade100,
              child: Text(
                team.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (team.captainName != null)
                    Text('Captain: ${team.captainName}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  if (team.players != null && team.players!.isNotEmpty)
                    Text('${team.players!.length} players',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (team.jerseyColor != null)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getColor(team.jerseyColor),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.green.shade300;
    }
  }
}