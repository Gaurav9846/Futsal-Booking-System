import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../models/match.dart';

class FixturesScreen extends StatefulWidget {
  final int tournamentId;

  const FixturesScreen({super.key, required this.tournamentId});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TournamentProvider>(context, listen: false)
          .loadMatches(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixtures'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<TournamentProvider>(context, listen: false)
                    .loadMatches(widget.tournamentId),
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          if (provider.matches.isEmpty) {
            return const Center(child: Text('No fixtures yet'));
          }

          final groupedMatches = <String, List<Match>>{};
          for (final match in provider.matches) {
            final round = match.round?.toString() ?? 'Round 1';
            groupedMatches.putIfAbsent(round, () => []).add(match);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: groupedMatches.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Round ${entry.key}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...entry.value.map((match) => _buildMatchTile(match)),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMatchTile(Match match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(match.team1Name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                match.scoreDisplay,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(match.team2Name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}