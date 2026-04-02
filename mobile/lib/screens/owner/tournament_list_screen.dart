import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tournament.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Changed from 3 to 4 to include CANCELLED tab
    _tabController = TabController(length: 4, vsync: this);
    _loadTournaments().then((_) {
      _debugPrintStatusCounts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await provider.loadMyTournaments();
    if (mounted) {
      setState(() {}); // Force rebuild
    }
  }

  void _debugPrintStatusCounts() {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    debugPrint('🏆 TOTAL TOURNAMENTS: ${provider.myTournaments.length}');
    
    for (var status in TournamentStatus.values) {
      final count = provider.myTournaments.where((t) => t.status == status).length;
      debugPrint('🏆 $status: $count');
    }
  }

  List<Tournament> _getFilteredTournaments(List<Tournament> tournaments) {
    if (_searchQuery.isEmpty) return tournaments;

    return tournaments.where((t) {
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  List<Tournament> _getTournamentsByStatus(TournamentStatus status) {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    return provider.myTournaments.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<TournamentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'DRAFT', icon: Icon(Icons.edit)),
            Tab(text: 'ONGOING', icon: Icon(Icons.play_circle)),
            Tab(text: 'COMPLETED', icon: Icon(Icons.emoji_events)),
            Tab(text: 'CANCELLED', icon: Icon(Icons.cancel)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() => _isRefreshing = true);
                    await _loadTournaments();
                    if (mounted) {
                      setState(() => _isRefreshing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tournaments refreshed'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tournaments...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats Summary - Cards that grow, shrink, and wrap
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate card width based on available space
              // Each card minimum 70px, maximum 100px
              double spacing = 8;
              int numberOfCards = 5;

              // Calculate ideal card width
              double totalSpacing = spacing * (numberOfCards - 1);
              double availableWidth = constraints.maxWidth - totalSpacing - 32;
              double cardWidth = availableWidth / numberOfCards;

              // Constrain card width between min and max
              cardWidth = cardWidth.clamp(65.0, 90.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: 8,
                  children: [
                    _buildStatCard(
                      'Total',
                      provider.myTournaments.length.toString(),
                      Icons.tour,
                      Colors.blue,
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      'Draft',
                      _getTournamentsByStatus(TournamentStatus.draft)
                          .length
                          .toString(),
                      Icons.edit,
                      Colors.grey,
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      'Ongoing',
                      _getTournamentsByStatus(TournamentStatus.ongoing)
                          .length
                          .toString(),
                      Icons.play_circle,
                      Colors.green,
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      'Completed',
                      _getTournamentsByStatus(TournamentStatus.completed)
                          .length
                          .toString(),
                      Icons.emoji_events,
                      Colors.orange,
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      'Cancelled',
                      _getTournamentsByStatus(TournamentStatus.cancelled)
                          .length
                          .toString(),
                      Icons.cancel,
                      Colors.red,
                      width: cardWidth,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Tournaments List
          Expanded(
            child: provider.isLoading && provider.myTournaments.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                : provider.myTournaments.isEmpty
                    ? _buildEmptyState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(TournamentStatus.draft))),
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(
                                  TournamentStatus.ongoing))),
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(
                                  TournamentStatus.completed))),
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(
                                  TournamentStatus.cancelled))),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTournamentScreen(),
            ),
          ).then((_) => _loadTournaments());
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: width > 75 ? 14 : 12),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: width > 75 ? 12 : 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: width > 75 ? 8 : 7,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tournaments yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first tournament to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTournamentScreen(),
                ),
              ).then((_) => _loadTournaments());
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Tournament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentsList(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.info_outline : Icons.search_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No tournaments in this category'
                  : 'No matching tournaments found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Text('Clear Search'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return _buildTournamentCard(tournament);
      },
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentDetailsScreen(
                tournamentId: tournament.id,
              ),
            ),
          ).then((_) => _loadTournaments());
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Status Header
            Container(
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
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon
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

                      // Details
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
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar (for ongoing tournaments)
                  if (tournament.isOngoing && tournament.progressPercentage > 0)
                    Column(
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
                    ),

                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (tournament.isDraft)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentDetailsScreen(
                                  tournamentId: tournament.id,
                                ),
                              ),
                            ).then((_) => _loadTournaments());
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.blue),
                        ),
                      if (tournament.isOngoing) ...[
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentDetailsScreen(
                                  tournamentId: tournament.id,
                                ),
                              ),
                            ).then((_) => _loadTournaments());
                          },
                          icon: const Icon(Icons.scoreboard, size: 16),
                          label: const Text('Update Scores'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.green),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (tournament.isCompleted)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentDetailsScreen(
                                  tournamentId: tournament.id,
                                ),
                              ),
                            ).then((_) => _loadTournaments());
                          },
                          icon: const Icon(Icons.emoji_events, size: 16),
                          label: const Text('Results'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.orange),
                        ),
                      if (tournament.isCancelled)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentDetailsScreen(
                                  tournamentId: tournament.id,
                                ),
                              ),
                            ).then((_) => _loadTournaments());
                          },
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('View'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                        ),
                      const SizedBox(width: 8),
                      if (!tournament.isCancelled)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentDetailsScreen(
                                  tournamentId: tournament.id,
                                ),
                              ),
                            ).then((_) => _loadTournaments());
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.green),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}