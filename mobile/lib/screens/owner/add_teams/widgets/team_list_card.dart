import 'package:flutter/material.dart';
import '../../../../models/team.dart';

class TeamListCard extends StatelessWidget {
  final Team team;
  final VoidCallback onDelete;

  const TeamListCard({
    super.key,
    required this.team,
    required this.onDelete,
  });

  Color _getColorFromString(String? colorName) {
    if (colorName == null) return Colors.green.shade300;
    switch (colorName.toLowerCase()) {
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
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade300;
      default:
        return Colors.green.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getColorFromString(team.jerseyColor),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  team.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (team.captainName != null)
                    Text(
                      'Captain: ${team.captainName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (team.players != null && team.players!.isNotEmpty)
                    Text(
                      '${team.players!.length} players',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}