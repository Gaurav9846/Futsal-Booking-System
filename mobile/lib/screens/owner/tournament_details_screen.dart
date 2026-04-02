import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tournament.dart';
import '../../models/team.dart';
import '../../models/match.dart';
import 'add_teams_screen.dart';
import 'tournament/fixtures_screen.dart';
import 'tournament/round_robin_leaderboard.dart';
import 'tournament/knockout_bracket.dart';
import 'create_tournament_screen.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailsScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TournamentProvider>(context, listen: false)
          .loadTournament(widget.tournamentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

// In tournament_details_screen.dart - REPLACE the _updateStatus method

  Future<void> _updateStatus(
      TournamentProvider provider, TournamentStatus newStatus) async {
    String action = '';
    String actionTitle = '';
    switch (newStatus) {
      case TournamentStatus.ongoing:
        action = 'start';
        actionTitle = 'START TOURNAMENT';
        break;
      case TournamentStatus.completed:
        action = 'mark as completed';
        actionTitle = 'COMPLETE TOURNAMENT';
        break;
      case TournamentStatus.cancelled:
        action = 'cancel';
        actionTitle = 'CANCEL TOURNAMENT';
        break;
      default:
        action = 'update';
        actionTitle = 'UPDATE STATUS';
    }

    // For starting tournament, check if teams exist
    if (newStatus == TournamentStatus.ongoing) {
      if (provider.teams.isEmpty) {
        _showAddTeamsDialog(provider);
        return;
      }
      if (provider.teams.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need at least 2 teams to start tournament'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: Text(
          'Are you sure you want to ${action} this tournament?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == TournamentStatus.cancelled
                  ? Colors.red
                  : Colors.green,
            ),
            child: Text(
              'YES, ${action.toUpperCase()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    debugPrint(
        '🏆 Attempting to update tournament ${widget.tournamentId} to $newStatus');

    final result =
        await provider.updateTournamentStatus(widget.tournamentId, newStatus);

    debugPrint('🏆 Update status result: $result');

    if (mounted) {
      // Handle specific actions
      if (result['action'] == 'add_teams') {
        _showAddTeamsDialog(provider);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['status'] == 'success'
            ? (newStatus == TournamentStatus.cancelled
                ? Colors.orange
                : Colors.green)
            : Colors.red,
        duration: const Duration(seconds: 3),
        action: result['action'] == 'add_teams'
            ? SnackBarAction(
                label: 'ADD TEAMS',
                textColor: Colors.white,
                onPressed: () => _navigateToAddTeams(provider),
              )
            : null,
      ));

      // If successful, refresh the tournament data
      if (result['status'] == 'success') {
        await provider.loadTournament(widget.tournamentId);
      }
    }
  }

// Add this helper method
  void _showAddTeamsDialog(TournamentProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teams Required'),
        content: Text(
          'You need to add teams before starting the tournament.\n\n'
          'Current teams: ${provider.teams.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('LATER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToAddTeams(provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('ADD TEAMS NOW'),
          ),
        ],
      ),
    );
  }

// In tournament_details_screen.dart - REPLACE the _navigateToAddTeams method

  void _navigateToAddTeams(TournamentProvider provider) {
    if (provider.currentTournament == null) return;

    final tournament = provider.currentTournament!;

    // Provide a default value if maxTeams is null
    final int maxTeams = tournament.maxTeams ?? 8; // Default to 8 if null

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTeamsScreen(
          tournamentId: widget.tournamentId,
          maxTeams: maxTeams,
          tournamentType: tournament.type,
          tournamentStatus: tournament.status,
        ),
      ),
    ).then((_) => provider.loadTournament(widget.tournamentId));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final tournament = provider.currentTournament;

        if (provider.isLoading && tournament == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: const Center(
                child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tournament Details'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(tournament.name),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              // Add Edit button for DRAFT tournaments only
              if (tournament.isDraft)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditTournament(tournament),
                  tooltip: 'Edit Tournament',
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadTournament(widget.tournamentId),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'ongoing') {
                    await _updateStatus(provider, TournamentStatus.ongoing);
                  } else if (value == 'completed') {
                    await _updateStatus(provider, TournamentStatus.completed);
                  } else if (value == 'cancelled') {
                    await _updateStatus(provider, TournamentStatus.cancelled);
                  }
                },
                itemBuilder: (_) => [
                  if (tournament.isDraft)
                    const PopupMenuItem(
                      value: 'ongoing',
                      child: Row(children: [
                        Icon(Icons.play_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Start Tournament'),
                      ]),
                    ),
                  if (tournament.isOngoing)
                    const PopupMenuItem(
                      value: 'completed',
                      child: Row(children: [
                        Icon(Icons.emoji_events, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Mark Completed'),
                      ]),
                    ),
                  if (!tournament.isCompleted)
                    const PopupMenuItem(
                      value: 'cancelled',
                      child: Row(children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel Tournament'),
                      ]),
                    ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                const Tab(text: 'Overview', icon: Icon(Icons.info)),
                Tab(
                  text: 'Teams',
                  icon: Badge(
                    label: Text('${provider.teams.length}'),
                    child: const Icon(Icons.people),
                  ),
                ),
                Tab(
                  text: 'Fixtures',
                  icon: Badge(
                    label: Text('${provider.matches.length}'),
                    child: const Icon(Icons.sports_soccer),
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(tournament, provider),
              _buildTeamsTab(tournament, provider),
              _buildFixturesTab(tournament, provider),
            ],
          ),
          floatingActionButton: _buildFAB(tournament, provider),
        );
      },
    );
  }

  // Add this helper method
  String _formatRoundName(String round) {
    switch (round) {
      case 'QUARTER_FINAL':
        return 'Quarter Finals';
      case 'SEMI_FINAL':
        return 'Semi Finals';
      case 'FINAL':
        return 'Final';
      case 'GROUP_STAGE':
        return 'Group Stage';
      default:
        return round
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  // ============================================
  // OVERVIEW TAB
  // ============================================
  Widget _buildOverviewTab(Tournament tournament, TournamentProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tournament.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tournament.statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(tournament.statusIcon,
                  color: tournament.statusColor, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.statusDisplay,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tournament.statusColor,
                    ),
                  ),
                  Text(
                    tournament.typeDisplay,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              if (tournament.isPublished)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Public',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Info card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tournament Info',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                if (tournament.prizes != null &&
                    tournament.prizes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Prizes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        ),

        if (tournament.description != null) ...[
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(tournament.description!,
                      style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        ],

        if (tournament.rules != null) ...[
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rules',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(tournament.rules!, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        ],

        // Progress (for ongoing)
        if (tournament.isOngoing && provider.matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progress',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${provider.matches.where((m) => m.isCompleted).length}/${provider.matches.length} matches played',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${((provider.matches.where((m) => m.isCompleted).length / provider.matches.length) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: provider.matches.isEmpty
                        ? 0
                        : provider.matches.where((m) => m.isCompleted).length /
                            provider.matches.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
        ],

        // Standings button for round robin
        if (tournament.isRoundRobin && provider.matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RoundRobinLeaderboard(tournamentId: widget.tournamentId),
              ),
            ),
            icon: const Icon(Icons.leaderboard),
            label: const Text('View Standings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],

        // Bracket button for knockout
        if (tournament.isKnockout && provider.matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    KnockoutBracket(tournamentId: widget.tournamentId),
              ),
            ),
            icon: const Icon(Icons.account_tree),
            label: const Text('View Bracket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
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

  // ============================================
  // TEAMS TAB
  // ============================================
  Widget _buildTeamsTab(Tournament tournament, TournamentProvider provider) {
    if (provider.teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No teams yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            if (tournament.isDraft)
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTeamsScreen(
                      tournamentId: widget.tournamentId,
                      maxTeams: tournament.maxTeams ?? 0,
                      tournamentType: tournament.type,
                      tournamentStatus: tournament.status,
                    ),
                  ),
                ).then((_) => provider.loadTournament(widget.tournamentId)),
                icon: const Icon(Icons.add),
                label: const Text('Add Teams'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.teams.length,
      itemBuilder: (_, index) {
        final team = provider.teams[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(Team team) {
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

  // ============================================
  // FIXTURES TAB
  // ============================================
  Widget _buildFixturesTab(Tournament tournament, TournamentProvider provider) {
    // ADD THESE DEBUG PRINTS
    debugPrint('🏆 ===== FIXTURES TAB DEBUG =====');
    debugPrint('🏆 Total matches: ${provider.matches.length}');

    for (var i = 0; i < provider.matches.length; i++) {
      final match = provider.matches[i];
      debugPrint(
          '🏆 Match ${i + 1}: ID=${match.id}, Round="${match.round}", ${match.team1Name} vs ${match.team2Name}');
    }
    if (provider.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              provider.teams.length < 2
                  ? 'Add at least 2 teams first'
                  : 'No fixtures generated yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (provider.teams.length >= 2 && tournament.isDraft) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  debugPrint('🏆 Generate Fixtures button clicked');

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );

                  final result =
                      await provider.generateFixtures(widget.tournamentId);

                  if (mounted) {
                    // Close loading dialog
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['status'] == 'success'
                            ? Colors.green
                            : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    if (result['status'] == 'success') {
                      // Refresh all data
                      await provider.loadTournament(widget.tournamentId);
                      await provider.loadMatches(widget.tournamentId);

                      // Force UI to rebuild
                      setState(() {});
                    }
                  }
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Generate Fixtures'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            // In tournament_details_screen.dart, update the button section at the bottom:

            if (provider.matches.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (tournament.type == TournamentType.knockout)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KnockoutBracket(
                            tournamentId: widget.tournamentId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree),
                    label: const Text('View Bracket'), // 'label' is required
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (tournament.type == TournamentType.roundRobin)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoundRobinLeaderboard(
                            tournamentId: widget.tournamentId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('View Standings'), // 'label' is required
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    }

    // In _buildFixturesTab method, replace the grouping logic:

// Group matches by round
    final Map<String, List<Match>> groupedMatches = {};
    for (final match in provider.matches) {
      // Get round name from match
      String round = match.round ?? 'GROUP_STAGE';

      // Debug print to see what rounds are coming
      debugPrint('🏆 Match ${match.id} round: $round');

      if (!groupedMatches.containsKey(round)) {
        groupedMatches[round] = [];
      }
      groupedMatches[round]!.add(match);
    }

// Debug print all rounds found
    debugPrint('🏆 Rounds found: ${groupedMatches.keys.join(', ')}');

// Define round order for sorting
    const Map<String, int> roundOrder = {
      'QUARTER_FINAL': 1,
      'SEMI_FINAL': 2,
      'FINAL': 3,
      'GROUP_STAGE': 0,
    };

// Sort rounds in correct order
    final sortedRounds = groupedMatches.keys.toList()
      ..sort((a, b) {
        final aOrder = roundOrder[a] ?? 99;
        final bOrder = roundOrder[b] ?? 99;
        return aOrder.compareTo(bOrder);
      });

    debugPrint('🏆 Sorted rounds: ${sortedRounds.join(", ")}');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sortedRounds.expand((round) {
        final matches = groupedMatches[round]!;
        final allCompleted = matches.every((m) => m.isCompleted);

        return [
          // Round Header
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allCompleted
                    ? [Colors.green.shade700, Colors.green.shade500]
                    : [Colors.blue.shade700, Colors.blue.shade500],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  round == 'FINAL'
                      ? Icons.emoji_events
                      : round == 'SEMI_FINAL'
                          ? Icons.account_tree
                          : Icons.sports_soccer,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatRoundName(round),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matches.where((m) => m.isCompleted).length}/${matches.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Matches
          ...matches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMatchCard(match, provider, tournament),
              )),

          const SizedBox(height: 16),
        ];
      }).toList(),
    );
  }

  Widget _buildMatchCard(
      Match match, TournamentProvider provider, Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: match.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    match.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: match.statusColor,
                    ),
                  ),
                ),
                Text(
                  '${match.scheduledDate.day}/${match.scheduledDate.month}/${match.scheduledDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            // Add cancelled tournament indicator
            if (tournament.status == TournamentStatus.cancelled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cancel, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Tournament Cancelled - No Further Updates',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Teams and score
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.team1Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: match.isCompleted
                        ? Colors.grey.shade100
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.scoreDisplay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: match.isCompleted
                          ? Colors.grey.shade800
                          : Colors.green,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.team2Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            // Update score button
            if (!match.isCompleted &&
                !match.isCancelled &&
                tournament.status != TournamentStatus.cancelled) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showUpdateScoreDialog(match, provider),
                icon: const Icon(Icons.scoreboard, size: 16),
                label: const Text('Update Score'),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
            ],

            if (match.isCompleted && match.winner != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🏆 Winner: ${match.winner}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UPDATE SCORE DIALOG
  // ============================================
  void _showUpdateScoreDialog(Match match, TournamentProvider provider) {
    int team1Score = match.team1Score ?? 0;
    int team2Score = match.team2Score ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${match.team1Name} vs ${match.team2Name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Team 1 score
                  Column(
                    children: [
                      Text(match.team1Name,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: team1Score > 0
                                ? () => setDialogState(() => team1Score--)
                                : null,
                            color: Colors.green,
                          ),
                          Text(
                            '$team1Score',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setDialogState(() => team1Score++),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('vs',
                        style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ),

                  // Team 2 score
                  Column(
                    children: [
                      Text(match.team2Name,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: team2Score > 0
                                ? () => setDialogState(() => team2Score--)
                                : null,
                            color: Colors.green,
                          ),
                          Text(
                            '$team2Score',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setDialogState(() => team2Score++),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await provider.updateMatchScore(
                    match.id, team1Score, team2Score);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['status'] == 'success'
                        ? Colors.green
                        : Colors.red,
                  ));
                  if (result['status'] == 'success') {
                    provider.loadTournament(widget.tournamentId);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Save Score'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FAB
  // ============================================
  Widget? _buildFAB(Tournament tournament, TournamentProvider provider) {
    if (!tournament.isDraft) return null;

    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTeamsScreen(
            tournamentId: widget.tournamentId,
            maxTeams: tournament.maxTeams ?? 0,
            tournamentType: tournament.type,
            tournamentStatus: tournament.status,
          ),
        ),
      ).then((_) => provider.loadTournament(widget.tournamentId)),
      icon: const Icon(Icons.group_add),
      label: const Text('Manage Teams'),
      backgroundColor: Colors.green,
    );
  }

  void _navigateToEditTournament(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTournamentScreen(
          tournamentToEdit: tournament,
        ),
      ),
    ).then((_) {
      // Refresh tournament data after returning from edit
      Provider.of<TournamentProvider>(context, listen: false)
          .loadTournament(widget.tournamentId);
    });
  }
}
