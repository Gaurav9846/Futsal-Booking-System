import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../models/tournament.dart';
import '../../models/team.dart';
import 'tournament/knockout_bracket.dart';
import 'tournament/round_robin_leaderboard.dart';

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
  final List<Team> _teams = [];
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _captainPhoneController = TextEditingController();
  final _jerseyColorController = TextEditingController();
  final List<TextEditingController> _playerControllers = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
    for (int i = 0; i < 5; i++) {
      _addPlayerField();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _captainNameController.dispose();
    _captainPhoneController.dispose();
    _jerseyColorController.dispose();
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await provider.loadTeams(widget.tournamentId);
    debugPrint('🏆 Teams loaded: ${provider.teams.length}');
    for (var team in provider.teams) {
      debugPrint('🏆 Team: ${team.name}, players: ${team.players}');
    }
    setState(() {
      _teams.clear();
      _teams.addAll(provider.teams);
    });
  }

  void _addPlayerField() {
    setState(() {
      _playerControllers.add(TextEditingController());
    });
  }

  void _removePlayerField(int index) {
    setState(() {
      _playerControllers[index].dispose();
      _playerControllers.removeAt(index);
    });
  }

  Future<void> _addTeam() async {
    if (!_formKey.currentState!.validate()) return;

    List<String> players = _playerControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (players.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 5 players'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final teamData = {
      'name': _nameController.text.trim(),
      'captainName': _captainNameController.text.trim(),
      'captainPhone': _captainPhoneController.text.trim(),
      'jerseyColor': _jerseyColorController.text.trim(),
      'players': players,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.addTeam(widget.tournamentId, teamData);

    if (!mounted) return;
    Navigator.pop(context);

    if (response['status'] == 'success') {
      _nameController.clear();
      _captainNameController.clear();
      _captainPhoneController.clear();
      _jerseyColorController.clear();
      for (var controller in _playerControllers) {
        controller.clear();
      }
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.generateFixtures(widget.tournamentId);

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fixtures generated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Get the current navigation stack
      final tournamentDetailsContext = context;

      // First, pop the AddTeamsScreen to go back to TournamentDetails
      Navigator.pop(
          tournamentDetailsContext); // This takes us to TournamentDetails

      // THEN push the bracket screen on top of TournamentDetails
      if (widget.tournamentType == TournamentType.knockout) {
        Navigator.push(
          tournamentDetailsContext,
          MaterialPageRoute(
            builder: (_) => KnockoutBracket(
              tournamentId: widget.tournamentId,
            ),
          ),
        );
      } else {
        Navigator.push(
          tournamentDetailsContext,
          MaterialPageRoute(
            builder: (_) => RoundRobinLeaderboard(
              tournamentId: widget.tournamentId,
            ),
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
          // Only show Generate Fixtures button if:
          // 1. There are at least 2 teams
          // 2. Tournament is NOT cancelled
          // 3. Tournament is in DRAFT or ONGOING (but not completed)
          if (_teams.length >= 2 &&
              widget.tournamentStatus != TournamentStatus.cancelled &&
              widget.tournamentStatus != TournamentStatus.completed)
            TextButton.icon(
              onPressed: _generateFixtures,
              icon: const Icon(Icons.sports_soccer, color: Colors.white),
              label: const Text(
                'Generate Fixtures',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teams Added: ${_teams.length}/${widget.maxTeams}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.tournamentType == TournamentType.knockout
                            ? 'Knockout: needs 2, 4, 8, 16, or 32 teams'
                            : 'Round robin: all teams play each other',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!canAddMore)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Max teams reached',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
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

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Add Team Form
                  if (canAddMore)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Team',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Team Name
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Team Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.group,
                                    color: Colors.green),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter team name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Captain Name
                            TextFormField(
                              controller: _captainNameController,
                              decoration: InputDecoration(
                                labelText: 'Captain Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.person,
                                    color: Colors.green),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter captain name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Captain Phone
                            TextFormField(
                              controller: _captainPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Captain Phone',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.phone,
                                    color: Colors.green),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Jersey Color
                            TextFormField(
                              controller: _jerseyColorController,
                              decoration: InputDecoration(
                                labelText: 'Jersey Color',
                                hintText: 'e.g., Red, Blue, Green',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.color_lens,
                                    color: Colors.green),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Players
                            const Text(
                              'Players (minimum 5)',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),

                            ..._playerControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: 'Player ${index + 1} name',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          prefixIcon: const Icon(
                                              Icons.person_outline,
                                              size: 20),
                                        ),
                                      ),
                                    ),
                                    if (_playerControllers.length > 5)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _removePlayerField(index),
                                      ),
                                  ],
                                ),
                              );
                            }),

                            TextButton.icon(
                              onPressed: _addPlayerField,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Player'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.green),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addTeam,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Add Team'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Teams List
                  if (_teams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.group_add,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No teams added yet',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add teams to start the tournament',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teams (${_teams.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._teams.map((team) => _buildTeamCard(team)),
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

  Widget _buildTeamCard(Team team) {
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (team.captainName != null)
                    Text(
                      'Captain: ${team.captainName}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (team.players != null && team.players!.isNotEmpty)
                    Text(
                      '${team.players!.length} players',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteTeam(team.id),
            ),
          ],
        ),
      ),
    );
  }

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
}
