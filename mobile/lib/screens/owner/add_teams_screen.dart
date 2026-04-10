import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../models/tournament.dart';
import '../../models/team.dart';
import 'tournament/knockout_bracket.dart';
import 'tournament/round_robin_leaderboard.dart';
import 'add_teams/widgets/team_form.dart';
import 'add_teams/widgets/team_list_card.dart';
import 'add_teams/widgets/teams_header.dart';

class AddTeamsScreen extends StatefulWidget {
  final int tournamentId;
  final int maxTeams;
  final TournamentType tournamentType;
  final TournamentStatus tournamentStatus;

  const AddTeamsScreen({
    super.key,
    required this.tournamentId,
    required this.maxTeams,
    required this.tournamentType,
    required this.tournamentStatus,
  });

  @override
  State<AddTeamsScreen> createState() => _AddTeamsScreenState();
}

class _AddTeamsScreenState extends State<AddTeamsScreen> {
  List<Team> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await provider.loadTeams(widget.tournamentId);
    setState(() {
      _teams = List.from(provider.teams);
      _isLoading = false;
    });
  }

  Future<void> _addTeam(Map<String, dynamic> teamData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.addTeam(widget.tournamentId, teamData);

    if (!mounted) return;
    Navigator.pop(context);

    if (response['status'] == 'success') {
      await _loadTeams();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team added successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteTeam(int teamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text('Are you sure you want to delete this team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.deleteTeam(teamId);

    if (!mounted) return;
    Navigator.pop(context);

    if (response['status'] == 'success') {
      await _loadTeams();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team deleted'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _generateFixtures() async {
    if (_teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 teams to generate fixtures'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Fixtures'),
        content: Text(
          'Generate ${widget.tournamentType == TournamentType.knockout ? 'knockout bracket' : 'round robin fixtures'} with ${_teams.length} teams?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.generateFixtures(widget.tournamentId);

    if (!mounted) return;
    Navigator.pop(context);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fixtures generated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);

      if (widget.tournamentType == TournamentType.knockout) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KnockoutBracket(tournamentId: widget.tournamentId),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoundRobinLeaderboard(tournamentId: widget.tournamentId),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _canGenerateFixtures {
    return _teams.length >= 2 &&
        widget.tournamentStatus != TournamentStatus.cancelled &&
        widget.tournamentStatus != TournamentStatus.completed;
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = _teams.length < widget.maxTeams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teams'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_canGenerateFixtures)
            TextButton.icon(
              onPressed: _generateFixtures,
              icon: const Icon(Icons.sports_soccer, color: Colors.white),
              label: const Text('Generate Fixtures', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          TeamsHeader(
            teamCount: _teams.length,
            maxTeams: widget.maxTeams,
            tournamentType: widget.tournamentType,
          ),
          if (widget.tournamentStatus == TournamentStatus.cancelled)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This tournament has been cancelled. No further changes can be made.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        TeamForm(
                          onSubmit: _addTeam,
                          isEnabled: canAddMore && widget.tournamentStatus != TournamentStatus.cancelled,
                        ),
                        if (_teams.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teams (${_teams.length})',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ..._teams.map((team) => TeamListCard(
                                  team: team,
                                  onDelete: () => _deleteTeam(team.id),
                                )),
                              ],
                            ),
                          ),
                        if (_teams.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.group_add, size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No teams added yet',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add teams to start the tournament',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}