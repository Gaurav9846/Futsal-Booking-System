import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../models/match.dart';

class KnockoutBracket extends StatefulWidget {
  final int tournamentId;

  const KnockoutBracket({super.key, required this.tournamentId});

  @override
  State<KnockoutBracket> createState() => _KnockoutBracketState();
}

class _KnockoutBracketState extends State<KnockoutBracket> {
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
        title: const Text('Bracket'),
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
            return const Center(child: Text('No bracket yet'));
          }

          // Group by round
          final rounds = <String, List<Match>>{};
          for (final match in provider.matches) {
            final round = match.round?.toString() ?? 'Round 1';
            rounds.putIfAbsent(round, () => []).add(match);
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rounds.entries.map((entry) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Round header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Matches in this round
                      ...entry.value.map((match) =>
                          _buildBracketMatch(match)),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBracketMatch(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTeamRow(
            match.team1Name,
            match.team1Score,
            match.winner == match.team1Name,
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildTeamRow(
            match.team2Name,
            match.team2Score,
            match.winner == match.team2Name,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String name, int? score, bool isWinner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          if (isWinner)
            const Icon(Icons.emoji_events, size: 14, color: Colors.amber)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.green : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isWinner
                    ? Colors.green.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.green : Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}