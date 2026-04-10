import 'package:flutter/material.dart';
import '../../../../models/tournament.dart';

class TypeSelectionCard extends StatelessWidget {
  final TournamentType selectedType;
  final Function(TournamentType) onTypeSelected;
  final bool isEditing;
  final bool isDisabled;

  const TypeSelectionCard({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.isEditing,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    type: TournamentType.knockout,
                    title: 'Knockout',
                    icon: Icons.emoji_events,
                    description: 'Single elimination bracket',
                    isSelected: selectedType == TournamentType.knockout,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    type: TournamentType.roundRobin,
                    title: 'Round Robin',
                    icon: Icons.people,
                    description: 'Everyone plays everyone',
                    isSelected: selectedType == TournamentType.roundRobin,
                  ),
                ),
              ],
            ),
            if (isEditing && isDisabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tournament type cannot be changed after creation',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required TournamentType type,
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
  }) {
    final bool canChangeType = !isEditing || !isDisabled;

    return GestureDetector(
      onTap: canChangeType ? () => onTypeSelected(type) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}