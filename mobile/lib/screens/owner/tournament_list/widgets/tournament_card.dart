import 'package:flutter/material.dart';
import '../../../../models/tournament.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            _buildStatusHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMainContent(),
                  const SizedBox(height: 16),
                  if (tournament.isOngoing && tournament.progressPercentage > 0)
                    _buildProgressBar(),
                  const SizedBox(height: 12),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tournament.statusColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            tournament.statusIcon,
            size: 16,
            color: tournament.statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            tournament.statusDisplay,
            style: TextStyle(
              color: tournament.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: tournament.type == TournamentType.knockout
                  ? Colors.purple.shade100
                  : Colors.teal.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tournament.typeDisplay,
              style: TextStyle(
                fontSize: 10,
                color: tournament.type == TournamentType.knockout
                    ? Colors.purple.shade700
                    : Colors.teal.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.green,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (tournament.description != null) ...[
                Text(
                  tournament.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.people,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tournament.numberOfTeams} teams',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              tournament.progressText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: tournament.progressPercentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            tournament.statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (tournament.isDraft)
          _buildActionButton(
            onPressed: onTap,
            icon: Icons.edit,
            label: 'Edit',
            color: Colors.blue,
          ),
        if (tournament.isOngoing) ...[
          _buildActionButton(
            onPressed: onTap,
            icon: Icons.scoreboard,
            label: 'Update Scores',
            color: Colors.green,
          ),
          const SizedBox(width: 8),
        ],
        if (tournament.isCompleted)
          _buildActionButton(
            onPressed: onTap,
            icon: Icons.emoji_events,
            label: 'Results',
            color: Colors.orange,
          ),
        if (tournament.isCancelled)
          _buildActionButton(
            onPressed: onTap,
            icon: Icons.cancel,
            label: 'View',
            color: Colors.red,
          ),
        const SizedBox(width: 8),
        if (!tournament.isCancelled)
          _buildActionButton(
            onPressed: onTap,
            icon: Icons.visibility,
            label: 'View',
            color: Colors.green,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: color),
    );
  }
}