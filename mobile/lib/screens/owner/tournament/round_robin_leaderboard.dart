import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../services/api_service.dart';
import '../../../models/tournament.dart';

class RoundRobinLeaderboard extends StatefulWidget {
  final int tournamentId;

  const RoundRobinLeaderboard({super.key, required this.tournamentId});

  @override
  State<RoundRobinLeaderboard> createState() => _RoundRobinLeaderboardState();
}

class _RoundRobinLeaderboardState extends State<RoundRobinLeaderboard> {
  List<Map<String, dynamic>> _standings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStandings(); // Refresh when screen is shown
  }

  Future<void> _loadStandings() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService.get('tournaments/${widget.tournamentId}/standings');
      setState(() {
        _standings =
            List<Map<String, dynamic>>.from(response['standings'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Add this method to check if we need to refresh when screen is focused
  Future<void> _checkForUpdates() async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    
    // Check if tournament status changed to COMPLETED
    if (provider.currentTournament?.status == TournamentStatus.completed) {
      // Refresh standings
      _loadStandings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return true to allow pop, and pass data back
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Standings'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.pop(context, true), // Go back to tournament details
          ),
          actions: [
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadStandings,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _standings.isEmpty
                ? const Center(child: Text('No standings yet'))
                : Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: Colors.green.shade700,
                        child: const Row(
                          children: [
                            SizedBox(
                                width: 32,
                                child: Text('#',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                child: Text('Team',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 32,
                                child: Text('P',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 32,
                                child: Text('W',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 32,
                                child: Text('D',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 32,
                                child: Text('L',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 40,
                                child: Text('GD',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 40,
                                child: Text('Pts',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),

                      // Standings list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _standings.length,
                          itemBuilder: (_, index) {
                            final standing = _standings[index];
                            final isTop3 = index < 3;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isTop3
                                    ? Colors.green.shade50
                                    : index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isTop3
                                            ? Colors.green
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (index == 0) const Text('🥇 '),
                                        if (index == 1) const Text('🥈 '),
                                        if (index == 2) const Text('🥉 '),
                                        Expanded(
                                          child: Text(
                                            standing['teamName'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _standingCell('${standing['played'] ?? 0}'),
                                  _standingCell('${standing['wins'] ?? 0}',
                                      color: Colors.green),
                                  _standingCell('${standing['draws'] ?? 0}',
                                      color: Colors.orange),
                                  _standingCell('${standing['losses'] ?? 0}',
                                      color: Colors.red),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${standing['goalDifference'] ?? 0}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: (standing['goalDifference'] ?? 0) >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${standing['points'] ?? 0}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Tournament Completion Banner
                      if (_standings.isNotEmpty)
                        _buildCompletionBanner(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCompletionBanner() {
    // Calculate if all matches are played
    final totalTeams = _standings.length;
    final expectedMatches = (totalTeams * (totalTeams - 1)) ~/ 2;
    
    // Count total played matches from standings
    int totalPlayed = 0;
    for (var standing in _standings) {
      final played = standing['played'];
    if (played != null) {
      totalPlayed += (played is int ? played : (played as num).toInt());
    }
    }
    totalPlayed = totalPlayed ~/ 2; // Each match counted twice
    
    final isComplete = totalPlayed >= expectedMatches;
    
    if (!isComplete) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Tournament Complete!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Winner: ${_standings.first['teamName']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_standings.first['points']} points',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Go back to tournament details
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _standingCell(String value, {Color? color}) {
    return SizedBox(
      width: 32,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(color: color ?? Colors.grey.shade700),
      ),
    );
  }
}