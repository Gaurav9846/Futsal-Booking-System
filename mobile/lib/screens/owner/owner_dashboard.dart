import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/futsal.dart';
import '../../models/booking.dart';
import 'add_futsal_screen.dart';
import 'court_management_screen.dart';
import 'bookings_screen.dart';
import '../owner/tournament_list_screen.dart';
import 'owner_reviews_screen.dart';
import 'analytics_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    debugPrint('📍 Dashboard: Loading all data');
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);

    await futsalProvider.fetchMyFutsals();

    // If user has futsals, load their stats
    if (futsalProvider.myFutsals.isNotEmpty) {
      // For now, load stats for first futsal
      // Later we can add futsal selector
      await dashboardProvider.loadStatistics(futsalProvider.myFutsals.first.id);
    }
  }

  // ============================================
  // LOGOUT WITH CONFIRMATION
  // ============================================
  Future<void> _showLogoutConfirmation() async {
    debugPrint('📍 Logout: Dialog triggered');

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      debugPrint('📍 Logout: Starting logout process');

      final auth = Provider.of<AuthProvider>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      await auth.logout();
      debugPrint('📍 Logout: auth.logout() completed');

      if (mounted) {
        Navigator.pop(context);
        debugPrint('📍 Logout: Loading dialog closed');
        Navigator.pushReplacementNamed(context, '/login');
        debugPrint('📍 Logout: Navigation to login completed');
      }
    }
  }

  // ============================================
  // Navigate to Add/Edit screen
  // ============================================
  Future<void> _navigateToAddFutsal([Futsal? futsalToEdit]) async {
    debugPrint(
        '📍 Navigating to ${futsalToEdit == null ? 'Add' : 'Edit'} Futsal');

    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFutsalScreen(
          futsalToEdit: futsalToEdit?.toJson(),
        ),
      ),
    );

    if (shouldRefresh == true) {
      debugPrint(
          '🔄 Refreshing after ${futsalToEdit == null ? 'add' : 'edit'}');
      _loadAllData();
    }
  }

  // ============================================
  // Navigate to Court Management
  // ============================================
  void _navigateToCourtManagement(Futsal futsal) {
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

  // ============================================
  // Navigate to Bookings
  // ============================================
  void _navigateToBookings(Futsal futsal) {
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

  // ============================================
  // Handle delete
  // ============================================
  Future<void> _deleteFutsal(Futsal futsal) async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final response = await futsalProvider.deleteFutsal(futsal.id);

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    if (response['status'] == 'success') {
      _loadAllData();
    }
  }

  // ============================================
  // Show delete confirmation dialog
  // ============================================
  void _showDeleteDialog(Futsal futsal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Futsal'),
        content: Text('Are you sure you want to delete "${futsal.name}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
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

  void _navigateToReviews(Futsal futsal) {
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final futsalProvider = Provider.of<FutsalProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        debugPrint('📍 Back button pressed - showing logout dialog');

        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Dashboard'),
            content: const Text('Do you want to logout?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        );

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Futsals'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Container(),

          // Use Row for better control of spacing
          flexibleSpace: Container(), // This helps with spacing
          actions: [
            // Owner Mode Indicator - Make it more visible
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700, // Changed to amber for visibility
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'OWNER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // PLAYER MODE BUTTON - Made more prominent
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.sports_soccer,
                    color: Colors.white, size: 24),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/player/home');
                },
                tooltip: 'Switch to Player Mode',
              ),
            ),

            // Futsal selector dropdown (if multiple futsals)
            if (futsalProvider.myFutsals.length > 1)
              PopupMenuButton<Futsal>(
                icon: const Icon(Icons.swap_vert, color: Colors.white),
                tooltip: 'Switch Futsal',
                onSelected: (futsal) {
                  dashboardProvider.loadStatistics(futsal.id);
                },
                itemBuilder: (ctx) => futsalProvider.myFutsals.map((futsal) {
                  return PopupMenuItem(
                    value: futsal,
                    child: Text(futsal.name),
                  );
                }).toList(),
              ),

            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadAllData,
              tooltip: 'Refresh all data',
            ),

            // Logout button
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _showLogoutConfirmation,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          child: _buildBody(futsalProvider, dashboardProvider),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToAddFutsal(),
          icon: const Icon(Icons.add),
          label: const Text('Add Futsal'),
          backgroundColor: Colors.green,
          tooltip: 'Add new futsal',
        ),
      ),
    );
  }

  Widget _buildBody(
      FutsalProvider futsalProvider, DashboardProvider dashboardProvider) {
    if (futsalProvider.isLoading && futsalProvider.myFutsals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your futsals...'),
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
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                futsalProvider.error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllData,
                child: const Text('Try Again'),
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
            Icon(Icons.sports_soccer, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No futsals yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first futsal',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats Cards Section
        _buildStatsSection(dashboardProvider),

        const SizedBox(height: 16),

        // Quick Actions Section
       _buildQuickActions(futsalProvider.myFutsals.first, futsalProvider),

        const SizedBox(height: 16),

        // Today's Schedule Preview
        _buildTodaySchedule(dashboardProvider, futsalProvider),

        const SizedBox(height: 16),

        // My Futsals List Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'My Futsals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Futsal List
        ...futsalProvider.myFutsals
            .map((futsal) => _buildFutsalCard(futsal))
            .toList(),
      ],
    );
  }

  Widget _buildQuickActions(Futsal currentFutsal, FutsalProvider futsalProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.sports_soccer,
                label: 'Courts',
                onTap: () => _navigateToCourtManagement(currentFutsal),
                color: Colors.blue,
              ),
              _buildActionButton(
                icon: Icons.calendar_month,
                label: 'Bookings',
                onTap: () => _navigateToBookings(currentFutsal),
                color: Colors.green,
              ),
              _buildActionButton(
                icon: Icons.emoji_events,
                label: 'Tournaments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TournamentListScreen(),
                    ),
                  );
                },
                color: Colors.purple,
              ),
              _buildActionButton(
                icon: Icons.bar_chart,
                label: 'Analytics',
                onTap: () {
                  if (futsalProvider.myFutsals.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnalyticsScreen(
                          futsalId: futsalProvider.myFutsals.first.id,
                          futsalName: futsalProvider.myFutsals.first.name,
                        ),
                      ),
                    );
                  }
                },
                color: Colors.orange,
              ),
              // Find the Row with 4 action buttons, add Reviews as 5th:
              _buildActionButton(
                icon: Icons.star,
                label: 'Reviews',
                onTap: () => _navigateToReviews(currentFutsal),
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DashboardProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Could not load stats',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            TextButton(
              onPressed: () => _loadAllData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.sports_soccer,
                  value: provider.totalCourts.toString(),
                  label: 'Total Courts',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  value: provider.todayBookings.toString(),
                  label: 'Today\'s Bookings',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.currency_rupee,
                  value: 'रू ${provider.todayRevenue}',
                  label: 'Today\'s Revenue',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.hourglass_empty,
                  value: provider.pendingApprovals.toString(),
                  label: 'Pending Approval',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(
      DashboardProvider provider, FutsalProvider futsalProvider) {
    if (provider.todayBookingsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'No bookings today',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (provider.todayBookingsList.isNotEmpty &&
                      futsalProvider.myFutsals.isNotEmpty) {
                    final bookingFutsalId =
                        provider.todayBookingsList.first.futsalId;

                    Futsal? targetFutsal;
                    try {
                      targetFutsal = futsalProvider.myFutsals.firstWhere(
                        (f) => f.id == bookingFutsalId,
                      );
                    } catch (e) {
                      targetFutsal = futsalProvider.myFutsals.first;
                    }

                    _navigateToBookings(targetFutsal);
                  } else if (futsalProvider.myFutsals.isNotEmpty) {
                    _navigateToBookings(futsalProvider.myFutsals.first);
                  }
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...provider.todayBookingsList.take(3).map((booking) {
            return _buildBookingItem(booking);
          }).toList(),
          if (provider.todayBookingsList.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${provider.todayBookingsList.length - 3} more bookings',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(dynamic booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Court ${booking.courtNumber} • ${booking.startTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.paymentStatus == 'paid'
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              booking.paymentStatus ?? 'Pending',
              style: TextStyle(
                fontSize: 10,
                color: booking.paymentStatus == 'paid'
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutsalCard(Futsal futsal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (!futsal.isApproved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Pending Approval',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        futsal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              futsal.address,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'रू ${futsal.basePrice}/hour',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToAddFutsal(futsal);
                    } else if (value == 'delete') {
                      _showDeleteDialog(futsal);
                    } else if (value == 'manage_courts') {
                      _navigateToCourtManagement(futsal);
                    } else if (value == 'view_bookings') {
                      _navigateToBookings(futsal);
                    } else if (value == 'view_reviews') {
                      _navigateToReviews(futsal);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'manage_courts',
                      child: Row(
                        children: [
                          Icon(Icons.sports_soccer,
                              size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Manage Courts'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view_bookings',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month,
                              size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('View Bookings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view_reviews',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('View Reviews'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
