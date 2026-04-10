import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin/futsal_details_modal.dart';
import '../../widgets/admin/admin_edit_profile_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AdminProvider>(context, listen: false)
                .loadDashboardStats(),
            tooltip: 'Refresh',
          ),

          // Admin Profile Popup Menu
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final name = authProvider.user?.fullName ?? 'A';
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'profile') {
                    await authProvider.loadAdminProfile();
                    if (mounted) {
                      _showProfileDialog(context, authProvider);
                    }
                  } else if (value == 'logout') {
                    _showLogoutConfirmation(context, authProvider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.green,),
                        SizedBox(width: 12),
                        Text('Profile'),
                        
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.error != null) {
            return Center(
              child: Text(
                adminProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadDashboardStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard Statistics",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _statCard(
                          "Total Users",
                          adminProvider.totalUsers.toString(),
                          Icons.people,
                          Colors.blue),
                      _statCard(
                          "Total Futsals",
                          adminProvider.totalFutsals.toString(),
                          Icons.sports_soccer,
                          Colors.green),
                      _statCard(
                          "Pending Approvals",
                          adminProvider.pendingApprovals.toString(),
                          Icons.pending_actions,
                          Colors.orange),
                      _statCard(
                          "Today's Bookings",
                          adminProvider.todayBookings.toString(),
                          Icons.book_online,
                          Colors.purple),
                      _statCard(
                          "Total Revenue",
                          "Rs ${adminProvider.totalRevenue.toStringAsFixed(0)}",
                          Icons.attach_money,
                          Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Quick Actions
                  const Text("Quick Actions",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(),

                  const SizedBox(height: 30),

                  // Recent Activities
                  const Text("Recent Activities",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (adminProvider.recentActivities.isEmpty)
                    const Text("No recent activities"),
                  ...adminProvider.recentActivities.map((activity) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(activity['user']?['fullName'] ?? 'User'),
                        subtitle:
                            Text("Booking on ${activity['bookingDate'] ?? ''}"),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  // Pending Futsals Preview
                  const Text("Pending Futsal Approvals",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: adminProvider.pendingFutsals.length,
                    itemBuilder: (_, index) {
                      final futsal = adminProvider.pendingFutsals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text(futsal['name'] ?? 'Futsal'),
                          subtitle:
                              Text(futsal['owner']?['fullName'] ?? 'Owner'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => FutsalDetailsModal(
                                futsal: futsal,
                                onApprove: () async {
                                  final result = await adminProvider
                                      .approveFutsal(futsal['id']);
                                  if (result['status'] == 'success') {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(result['message'])),
                                    );
                                  }
                                  return result; // ✅ Always return Map<String, dynamic>
                                },
                                onReject: (reason) async {
                                  final result = await adminProvider
                                      .rejectFutsal(futsal['id'], reason);
                                  if (result['status'] == 'success') {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(result['message'])),
                                    );
                                  }
                                  return result; // ✅ Always return Map<String, dynamic>
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (MediaQuery.of(context).size.width - 48) / 2;
        return SizedBox(
          width: width,
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 28, color: color),
                  const SizedBox(height: 8),
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(title,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 36) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionButton(
                "Pending Futsals",
                Icons.approval,
                Colors.orange,
                () => Navigator.pushNamed(context, "/admin/futsal-approvals"),
                itemWidth),
            _actionButton("Manage Users", Icons.people_alt, Colors.blue,
                () => Navigator.pushNamed(context, "/admin/users"), itemWidth),
            _actionButton(
                "All Futsals",
                Icons.sports_soccer,
                Colors.green,
                () => Navigator.pushNamed(context, "/admin/futsals"),
                itemWidth),
            _actionButton(
                "All Bookings",
                Icons.book_online,
                Colors.teal,
                () => Navigator.pushNamed(context, "/admin/bookings"),
                itemWidth),
            _actionButton(
                "Settings",
                Icons.settings,
                Colors.grey,
                () => Navigator.pushNamed(context, "/admin/settings"),
                itemWidth),
            _actionButton(
                "Analytics",
                Icons.analytics,
                Colors.indigo,
                () => Navigator.pushNamed(context, "/admin/analytics"),
                itemWidth),
          ],
        );
      },
    );
  }

  Widget _actionButton(String title, IconData icon, Color color,
      VoidCallback onTap, double width) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider authProvider) {
    final profile = authProvider.adminProfile;
    final user = authProvider.user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Remove the default title
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.red.shade400, // Red close button
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    (user?.fullName ?? 'A')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Center(
                child: Text(
                  user?.fullName ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Role Badge
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role ?? 'ADMIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 12),

              // Email
              _buildInfoRow(Icons.email_outlined, user?.email ?? 'No email'),
              const SizedBox(height: 12),

              // Phone
              _buildInfoRow(
                  Icons.phone_outlined, user?.phoneNumber ?? 'No phone'),
              const SizedBox(height: 12),

              // Join Date
              _buildInfoRow(Icons.calendar_today, _formatDate(user?.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close profile dialog
              showDialog(
                context: context,
                builder: (_) => const AdminEditProfileDialog(),
              );
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await authProvider.logout(); // Call AuthProvider logout
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Not available';
    }
  }
}
