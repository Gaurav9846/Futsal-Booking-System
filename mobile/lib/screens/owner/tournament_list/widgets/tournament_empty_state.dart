import 'package:flutter/material.dart';

class TournamentEmptyState extends StatelessWidget {
  final String message;
  final String? searchQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onCreateTournament;

  const TournamentEmptyState({
    super.key,
    required this.message,
    this.searchQuery,
    required this.onClearSearch,
    required this.onCreateTournament,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery != null && searchQuery!.isNotEmpty
                ? Icons.search_off
                : Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (searchQuery != null && searchQuery!.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClearSearch,
              child: const Text('Clear Search'),
            ),
          ],
          if (searchQuery == null || searchQuery!.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateTournament,
              icon: const Icon(Icons.add),
              label: const Text('Create Tournament'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}