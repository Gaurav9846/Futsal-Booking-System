import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tournament.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_screen.dart';
import 'tournament_list/widgets/stat_card.dart';
import 'tournament_list/widgets/tournament_card.dart';
import 'tournament_list/widgets/tournament_empty_state.dart';

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
    _tabController = TabController(length: 4, vsync: this);
    _loadTournaments();
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
    if (mounted) setState(() {});
  }

  List<Tournament> _getFilteredTournaments(List<Tournament> tournaments) {
    if (_searchQuery.isEmpty) return tournaments;
    return tournaments.where((t) {
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<Tournament> _getTournamentsByStatus(TournamentStatus status) {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    return provider.myTournaments.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildSearchBar(),
          _buildStatsRow(provider),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoading && provider.myTournaments.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : provider.myTournaments.isEmpty
                    ? _buildEmptyState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(TournamentStatus.draft))),
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(TournamentStatus.ongoing))),
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(TournamentStatus.completed))),
                          _buildTournamentsList(_getFilteredTournaments(
                              _getTournamentsByStatus(TournamentStatus.cancelled))),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
          ).then((_) => _loadTournaments());
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildStatsRow(TournamentProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = 8;
        int numberOfCards = 5;
        double totalSpacing = spacing * (numberOfCards - 1);
        double availableWidth = constraints.maxWidth - totalSpacing - 32;
        double cardWidth = availableWidth / numberOfCards;
        cardWidth = cardWidth.clamp(65.0, 90.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: spacing,
            runSpacing: 8,
            children: [
              StatCard(
                label: 'Total',
                value: provider.myTournaments.length.toString(),
                icon: Icons.tour,
                color: Colors.blue,
                width: cardWidth,
              ),
              StatCard(
                label: 'Draft',
                value: _getTournamentsByStatus(TournamentStatus.draft).length.toString(),
                icon: Icons.edit,
                color: Colors.grey,
                width: cardWidth,
              ),
              StatCard(
                label: 'Ongoing',
                value: _getTournamentsByStatus(TournamentStatus.ongoing).length.toString(),
                icon: Icons.play_circle,
                color: Colors.green,
                width: cardWidth,
              ),
              StatCard(
                label: 'Completed',
                value: _getTournamentsByStatus(TournamentStatus.completed).length.toString(),
                icon: Icons.emoji_events,
                color: Colors.orange,
                width: cardWidth,
              ),
              StatCard(
                label: 'Cancelled',
                value: _getTournamentsByStatus(TournamentStatus.cancelled).length.toString(),
                icon: Icons.cancel,
                color: Colors.red,
                width: cardWidth,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return TournamentEmptyState(
      message: 'No tournaments yet',
      onCreateTournament: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
        ).then((_) => _loadTournaments());
      },
      onClearSearch: () {},
    );
  }

  Widget _buildTournamentsList(List<Tournament> tournaments) {
    final filtered = _getFilteredTournaments(tournaments);

    if (filtered.isEmpty) {
      return TournamentEmptyState(
        message: _searchQuery.isEmpty
            ? 'No tournaments in this category'
            : 'No matching tournaments found',
        searchQuery: _searchQuery,
        onClearSearch: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
        onCreateTournament: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
          ).then((_) => _loadTournaments());
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final tournament = filtered[index];
        return TournamentCard(
          tournament: tournament,
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
        );
      },
    );
  }
}