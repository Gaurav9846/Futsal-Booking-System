import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/futsal.dart';
import '../../utils/app_theme.dart';
import 'add_futsal_screen.dart';
import 'court_management_screen.dart';
import 'bookings_screen.dart';
import '../owner/tournament_list_screen.dart';
import 'owner_reviews_screen.dart';
import 'analytics_screen.dart';
import 'blocked_players_screen.dart';
import 'dashboard/widgets/dashboard_futsal_card.dart';
import 'dashboard/widgets/stats_card.dart';
import 'dashboard/widgets/quick_actions.dart';
import 'dashboard/widgets/today_schedule.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  Futsal? _selectedFutsal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);

    await futsalProvider.fetchMyFutsals();

    if (futsalProvider.myFutsals.isNotEmpty) {
      if (_selectedFutsal == null) {
        setState(() {
          _selectedFutsal = futsalProvider.myFutsals.first;
        });
      } else {
        final updated = futsalProvider.myFutsals.firstWhere(
          (f) => f.id == _selectedFutsal!.id,
          orElse: () => futsalProvider.myFutsals.first,
        );
        setState(() {
          _selectedFutsal = updated;
        });
      }
      await dashboardProvider.loadStatistics(_selectedFutsal!.id);
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await auth.logout();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _navigateToAddFutsal([Futsal? futsalToEdit]) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFutsalScreen(futsalToEdit: futsalToEdit?.toJson()),
      ),
    );

    if (shouldRefresh == true) {
      _loadAllData();
    }
  }

  void _navigateToCourtManagement(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courts can only be managed for active futsals'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourtManagementScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToBookings(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookings are only available for active futsals'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingsScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToReviews(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reviews are only available for active futsals'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerReviewsScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToAnalytics(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analytics available for active futsals only'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToBlockedPlayers(Futsal futsal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockedPlayersScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  Future<void> _deleteFutsal(Futsal futsal) async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await futsalProvider.deleteFutsal(futsal.id);
    if (mounted) Navigator.pop(context);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      _loadAllData();
    } else {
      String errorMessage = response['message'];
      if (errorMessage.contains('bookings') ||
          errorMessage.contains('favorites')) {
        errorMessage =
            'Cannot delete this futsal.\n\nIt has existing bookings or favorites.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDeleteDialog(Futsal futsal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Futsal'),
        content: Text('Are you sure you want to delete "${futsal.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteFutsal(futsal);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Futsal futsal) async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);

    final response = await futsalProvider.updateFutsal(futsal.id, {
      'toggleActive': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );

    if (response['status'] == 'success') {
      _loadAllData();
    }
  }

  void _showFutsalSelector() {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Futsal'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: futsalProvider.myFutsals.map((futsal) {
              return ListTile(
                leading: const Icon(Icons.sports_soccer, color: Colors.green),
                title: Text(futsal.name),
                trailing: _selectedFutsal?.id == futsal.id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFutsal = futsal;
                  });
                  Provider.of<DashboardProvider>(context, listen: false)
                      .loadStatistics(futsal.id);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final futsalProvider = Provider.of<FutsalProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Dashboard'),
            content: const Text('Do you want to logout?'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: const Text('STAY'),
              ),
              TextButton(
                onPressed: () async {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  await auth.logout();
                  if (mounted) {
                    Navigator.pop(ctx, true);
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          backgroundColor: AppTheme.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            // Owner badge
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    'OWNER',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Switch to player mode
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: IconButton(
                icon: const Icon(Icons.sports_soccer, color: AppTheme.primary, size: 20),
                onPressed: () => Navigator.pushReplacementNamed(context, '/player/home'),
                tooltip: 'Switch to Player Mode',
              ),
            ),
            // Refresh button
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
                onPressed: _loadAllData,
                tooltip: 'Refresh all data',
              ),
            ),
            // Logout button
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: Icon(Icons.logout, color: AppTheme.error, size: 20),
                onPressed: _showLogoutConfirmation,
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          child: _buildBody(futsalProvider, dashboardProvider),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _navigateToAddFutsal(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Futsal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            tooltip: 'Add new futsal',
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      FutsalProvider futsalProvider, DashboardProvider dashboardProvider) {
    if (futsalProvider.isLoading && futsalProvider.myFutsals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading your futsals...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (futsalProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 20),
              Text(
                futsalProvider.error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: ElevatedButton(
                  onPressed: _loadAllData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (futsalProvider.myFutsals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Icon(
                Icons.sports_soccer,
                size: 64,
                color: AppTheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No futsals yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first futsal',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedFutsal == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth > 800;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActiveFutsalCard(futsalProvider),
        const SizedBox(height: 16),
        StatsCard(
          totalCourts: dashboardProvider.totalCourts,
          todayBookings: dashboardProvider.todayBookings,
          todayRevenue: dashboardProvider.todayRevenue,
          pendingApprovals: dashboardProvider.pendingApprovals,
          isLoading: dashboardProvider.isLoading,
          error: dashboardProvider.error,
          onRetry: _loadAllData,
        ),
        const SizedBox(height: 16),

        // Quick Actions + Today Schedule - Side by side with equal heights
        isTabletOrDesktop
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: QuickActions(
                        currentFutsal: _selectedFutsal!,
                        futsalCount: futsalProvider.myFutsals.length,
                        onCourts: () =>
                            _navigateToCourtManagement(_selectedFutsal!),
                        onBookings: () => _navigateToBookings(_selectedFutsal!),
                        onTournaments: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const TournamentListScreen()));
                        },
                        onAnalytics: () =>
                            _navigateToAnalytics(_selectedFutsal!),
                        onReviews: () => _navigateToReviews(_selectedFutsal!),
                        onBlocked: () =>
                            _navigateToBlockedPlayers(_selectedFutsal!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TodaySchedule(
                        bookings: dashboardProvider.todayBookingsList,
                        onViewAll: () => _navigateToBookings(_selectedFutsal!),
                        maxBookingsToShow: 3,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  QuickActions(
                    currentFutsal: _selectedFutsal!,
                    futsalCount: futsalProvider.myFutsals.length,
                    onCourts: () =>
                        _navigateToCourtManagement(_selectedFutsal!),
                    onBookings: () => _navigateToBookings(_selectedFutsal!),
                    onTournaments: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TournamentListScreen()));
                    },
                    onAnalytics: () => _navigateToAnalytics(_selectedFutsal!),
                    onReviews: () => _navigateToReviews(_selectedFutsal!),
                    onBlocked: () =>
                        _navigateToBlockedPlayers(_selectedFutsal!),
                  ),
                  const SizedBox(height: 16),
                  TodaySchedule(
                    bookings: dashboardProvider.todayBookingsList,
                    onViewAll: () => _navigateToBookings(_selectedFutsal!),
                    maxBookingsToShow: 3,
                  ),
                ],
              ),

        const SizedBox(height: 16),

        // My Futsals Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'My Futsals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

// Responsive Wrap layout - cards take height based on content
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final itemCount = futsalProvider.myFutsals.length;

            // Calculate card width based on screen size
            double cardWidth;
            double spacing = 16;

            if (screenWidth > 1200) {
              // Desktop: 3 cards per row
              cardWidth = (screenWidth - (spacing * 2)) / 3;
            } else if (screenWidth > 800) {
              // Tablet: 2 cards per row
              cardWidth = (screenWidth - spacing) / 2;
            } else {
              // Mobile: 1 card per row
              cardWidth = screenWidth;
            }

            // Build cards list
            final List<Widget> cards = [];
            for (int i = 0; i < itemCount; i++) {
              final futsal = futsalProvider.myFutsals[i];
              cards.add(
                SizedBox(
                  width: cardWidth,
                  child: DashboardFutsalCard(
                    futsal: futsal,
                    onEdit: () => _navigateToAddFutsal(futsal),
                    onDelete: () => _showDeleteDialog(futsal),
                    onManageCourts: () => _navigateToCourtManagement(futsal),
                    onViewBookings: () => _navigateToBookings(futsal),
                    onViewReviews: () => _navigateToReviews(futsal),
                    onToggleActive: () => _toggleActive(futsal),
                  ),
                ),
              );
            }

            return Wrap(
              spacing: spacing,
              runSpacing: 16,
              children: cards,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveFutsalCard(FutsalProvider futsalProvider) {
    final hasMultipleFutsals = futsalProvider.myFutsals.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.primaryLight.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: hasMultipleFutsals ? _showFutsalSelector : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE FUTSAL',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFutsal?.name ?? 'None',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasMultipleFutsals)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      'Switch',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.swap_vert,
                      size: 18,
                      color: AppTheme.primary,
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
