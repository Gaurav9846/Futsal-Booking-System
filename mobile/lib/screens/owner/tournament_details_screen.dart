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
import 'tournament_details/widgets/status_card.dart';
import 'tournament_details/widgets/info_card.dart';
import 'tournament_details/widgets/team_card.dart';
import 'tournament_details/widgets/match_card.dart';
import 'tournament_details/widgets/update_score_dialog.dart';
import 'tournament_details/widgets/progress_card.dart';
import 'tournament_details/widgets/round_header.dart';

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
        content: Text('Are you sure you want to ${action} this tournament?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == TournamentStatus.cancelled
                  ? Colors.red
                  : Colors.green,
            ),
            child: Text('YES, ${action.toUpperCase()}'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.updateTournamentStatus(widget.tournamentId, newStatus);

    if (mounted) {
      if (result['action'] == 'add_teams') {
        _showAddTeamsDialog(provider);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['status'] == 'success'
            ? (newStatus == TournamentStatus.cancelled ? Colors.orange : Colors.green)
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

      if (result['status'] == 'success') {
        await provider.loadTournament(widget.tournamentId);
      }
    }
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('LATER')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToAddTeams(provider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ADD TEAMS NOW'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTeams(TournamentProvider provider) {
    if (provider.currentTournament == null) return;
    final tournament = provider.currentTournament!;
    final int maxTeams = tournament.maxTeams ?? 8;

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

  void _navigateToEditTournament(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTournamentScreen(tournamentToEdit: tournament),
      ),
    ).then((_) {
      Provider.of<TournamentProvider>(context, listen: false)
          .loadTournament(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final tournament = provider.currentTournament;

        if (provider.isLoading && tournament == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.green, foregroundColor: Colors.white),
            body: const Center(child: CircularProgressIndicator(color: Colors.green)),
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

  // ============================================
  // OVERVIEW TAB
  // ============================================
  Widget _buildOverviewTab(Tournament tournament, TournamentProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatusCard(tournament: tournament),
        const SizedBox(height: 16),
        InfoCard(tournament: tournament),
        if (tournament.description != null) ...[
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(tournament.description!, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        ],
        if (tournament.rules != null) ...[
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rules',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(tournament.rules!, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        ],
        if (tournament.isOngoing && provider.matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          ProgressCard(
            completedMatches: provider.matches.where((m) => m.isCompleted).length,
            totalMatches: provider.matches.length,
          ),
        ],
        if (tournament.isRoundRobin && provider.matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoundRobinLeaderboard(tournamentId: widget.tournamentId),
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
        if (tournament.isKnockout && provider.matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KnockoutBracket(tournamentId: widget.tournamentId),
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
            Text('No teams yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            if (tournament.isDraft)
              ElevatedButton.icon(
                onPressed: () => _navigateToAddTeams(provider),
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
      itemBuilder: (_, index) => TeamCard(team: provider.teams[index]),
    );
  }

  // ============================================
  // FIXTURES TAB
  // ============================================
  Widget _buildFixturesTab(Tournament tournament, TournamentProvider provider) {
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
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                  final result = await provider.generateFixtures(widget.tournamentId);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['status'] == 'success'
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                    if (result['status'] == 'success') {
                      await provider.loadTournament(widget.tournamentId);
                      await provider.loadMatches(widget.tournamentId);
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
                          builder: (_) => KnockoutBracket(tournamentId: widget.tournamentId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree),
                    label: const Text('View Bracket'),
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
                    label: const Text('View Standings'),
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

    final Map<String, List<Match>> groupedMatches = {};
    for (final match in provider.matches) {
      String round = match.round ?? 'GROUP_STAGE';
      groupedMatches.putIfAbsent(round, () => []).add(match);
    }

    const Map<String, int> roundOrder = {
      'QUARTER_FINAL': 1,
      'SEMI_FINAL': 2,
      'FINAL': 3,
      'GROUP_STAGE': 0,
    };

    final sortedRounds = groupedMatches.keys.toList()..sort((a, b) {
      final aOrder = roundOrder[a] ?? 99;
      final bOrder = roundOrder[b] ?? 99;
      return aOrder.compareTo(bOrder);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sortedRounds.expand((round) {
        final matches = groupedMatches[round]!;
        final allCompleted = matches.every((m) => m.isCompleted);

        return [
          RoundHeader(
            roundName: round,
            completedMatches: matches.where((m) => m.isCompleted).length,
            totalMatches: matches.length,
            isCompleted: allCompleted,
          ),
          ...matches.map((match) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MatchCard(
              match: match,
              tournament: tournament,
              onUpdateScore: () => UpdateScoreDialog.show(
                context: context,
                match: match,
                provider: provider,
                tournamentId: widget.tournamentId,
                onRefresh: () => provider.loadTournament(widget.tournamentId),
              ),
            ),
          )),
          const SizedBox(height: 16),
        ];
      }).toList(),
    );
  }

  // ============================================
  // FAB
  // ============================================
  Widget? _buildFAB(Tournament tournament, TournamentProvider provider) {
    if (!tournament.isDraft) return null;

    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddTeams(provider),
      icon: const Icon(Icons.group_add),
      label: const Text('Manage Teams'),
      backgroundColor: Colors.green,
    );
  }
}