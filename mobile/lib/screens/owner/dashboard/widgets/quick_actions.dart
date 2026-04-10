import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';
import '../../../../utils/responsive.dart';

class QuickActions extends StatelessWidget {
  final Futsal currentFutsal;
  final int futsalCount;
  final VoidCallback onCourts;
  final VoidCallback onBookings;
  final VoidCallback onTournaments;
  final VoidCallback onAnalytics;
  final VoidCallback onReviews;
  final VoidCallback onBlocked;

  const QuickActions({
    super.key,
    required this.currentFutsal,
    required this.futsalCount,
    required this.onCourts,
    required this.onBookings,
    required this.onTournaments,
    required this.onAnalytics,
    required this.onReviews,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentFutsal.status == 'ACTIVE';
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 20.0;
    final titleFontSize = isMobile ? 16.0 : 18.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
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
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (futsalCount > 1 && !isMobile)
                Text(
                  'Current: ${currentFutsal.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Responsive.adaptiveLayout(
            context: context,
            mobile: _buildMobileGrid(isActive),
            tablet: _buildTabletGrid(isActive),
            desktop: _buildDesktopGrid(isActive),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGrid(bool isActive) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.sports_soccer,
          label: 'Courts',
          onTap: onCourts,
          color: Colors.blue,
          isEnabled: isActive,
          isMobile: true,
        ),
        _buildActionButton(
          icon: Icons.calendar_month,
          label: 'Bookings',
          onTap: onBookings,
          color: Colors.green,
          isEnabled: isActive,
          isMobile: true,
        ),
        _buildActionButton(
          icon: Icons.emoji_events,
          label: 'Tournaments',
          onTap: onTournaments,
          color: Colors.purple,
          isEnabled: true,
          isMobile: true,
        ),
        _buildActionButton(
          icon: Icons.bar_chart,
          label: 'Analytics',
          onTap: onAnalytics,
          color: Colors.orange,
          isEnabled: isActive,
          isMobile: true,
        ),
        _buildActionButton(
          icon: Icons.star,
          label: 'Reviews',
          onTap: onReviews,
          color: Colors.amber,
          isEnabled: isActive,
          isMobile: true,
        ),
        _buildActionButton(
          icon: Icons.block,
          label: 'Blocked',
          onTap: onBlocked,
          color: Colors.red,
          isEnabled: true,
          isMobile: true,
        ),
      ],
    );
  }

  Widget _buildTabletGrid(bool isActive) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildActionButton(
          icon: Icons.sports_soccer,
          label: 'Courts',
          onTap: onCourts,
          color: Colors.blue,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.calendar_month,
          label: 'Bookings',
          onTap: onBookings,
          color: Colors.green,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.emoji_events,
          label: 'Tournaments',
          onTap: onTournaments,
          color: Colors.purple,
          isEnabled: true,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.bar_chart,
          label: 'Analytics',
          onTap: onAnalytics,
          color: Colors.orange,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.star,
          label: 'Reviews',
          onTap: onReviews,
          color: Colors.amber,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.block,
          label: 'Blocked',
          onTap: onBlocked,
          color: Colors.red,
          isEnabled: true,
          isMobile: false,
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(bool isActive) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _buildActionButton(
          icon: Icons.sports_soccer,
          label: 'Courts',
          onTap: onCourts,
          color: Colors.blue,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.calendar_month,
          label: 'Bookings',
          onTap: onBookings,
          color: Colors.green,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.emoji_events,
          label: 'Tournaments',
          onTap: onTournaments,
          color: Colors.purple,
          isEnabled: true,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.bar_chart,
          label: 'Analytics',
          onTap: onAnalytics,
          color: Colors.orange,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.star,
          label: 'Reviews',
          onTap: onReviews,
          color: Colors.amber,
          isEnabled: isActive,
          isMobile: false,
        ),
        _buildActionButton(
          icon: Icons.block,
          label: 'Blocked',
          onTap: onBlocked,
          color: Colors.red,
          isEnabled: true,
          isMobile: false,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isEnabled,
    required bool isMobile,
  }) {
    final iconSize = isMobile ? 20.0 : 28.0;
    final labelSize = isMobile ? 11.0 : 14.0;
    final padding = isMobile ? 10.0 : 16.0;
    final borderRadius = isMobile ? 10.0 : 14.0;
    
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}