import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';

class StatsCard extends StatelessWidget {
  final int totalCourts;
  final int todayBookings;
  final double todayRevenue;
  final int pendingApprovals;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const StatsCard({
    super.key,
    required this.totalCourts,
    required this.todayBookings,
    required this.todayRevenue,
    required this.pendingApprovals,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
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
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Responsive.adaptiveLayout(
            context: context,
            mobile: _buildMobileStats(),
            tablet: _buildDesktopStats(),
            desktop: _buildDesktopStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.sports_soccer,
                value: totalCourts.toString(),
                label: 'Total Courts',
                color: Colors.blue,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.calendar_today,
                value: todayBookings.toString(),
                label: "Today's Bookings",
                color: Colors.green,
                isMobile: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.currency_rupee,
                value: 'रू $todayRevenue',
                label: "Today's Revenue",
                color: Colors.orange,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.hourglass_empty,
                value: pendingApprovals.toString(),
                label: 'Pending Approval',
                color: Colors.purple,
                isMobile: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.sports_soccer,
            value: totalCourts.toString(),
            label: 'Total Courts',
            color: Colors.blue,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.calendar_today,
            value: todayBookings.toString(),
            label: "Today's Bookings",
            color: Colors.green,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.currency_rupee,
            value: 'रू $todayRevenue',
            label: "Today's Revenue",
            color: Colors.orange,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.hourglass_empty,
            value: pendingApprovals.toString(),
            label: 'Pending Approval',
            color: Colors.purple,
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isMobile,
  }) {
    final iconSize = isMobile ? 20.0 : 24.0;
    final valueFontSize = isMobile ? 16.0 : 18.0;
    final labelFontSize = isMobile ? 11.0 : 13.0;
    final padding = isMobile ? 12.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
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
          Icon(icon, color: color, size: iconSize),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}