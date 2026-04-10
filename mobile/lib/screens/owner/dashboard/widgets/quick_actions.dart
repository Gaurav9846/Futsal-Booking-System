import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_theme.dart';

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

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (futsalCount > 1 && !isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Text(
                    currentFutsal.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
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
      runSpacing: 16,
      children: _buildActionButtons(isActive, true),
    );
  }

  Widget _buildTabletGrid(bool isActive) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _buildActionButtons(isActive, false),
    );
  }

  Widget _buildDesktopGrid(bool isActive) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: _buildActionButtons(isActive, false),
    );
  }

  List<Widget> _buildActionButtons(bool isActive, bool isMobile) {
    return [
      _buildActionButton(
        icon: Icons.sports_soccer,
        label: 'Courts',
        onTap: onCourts,
        color: AppTheme.info,
        isEnabled: isActive,
        isMobile: isMobile,
      ),
      _buildActionButton(
        icon: Icons.calendar_month,
        label: 'Bookings',
        onTap: onBookings,
        color: AppTheme.primary,
        isEnabled: isActive,
        isMobile: isMobile,
      ),
      _buildActionButton(
        icon: Icons.emoji_events,
        label: 'Tournaments',
        onTap: onTournaments,
        color: Color(0xFF9C27B0),
        isEnabled: true,
        isMobile: isMobile,
      ),
      _buildActionButton(
        icon: Icons.bar_chart,
        label: 'Analytics',
        onTap: onAnalytics,
        color: AppTheme.accent,
        isEnabled: isActive,
        isMobile: isMobile,
      ),
      _buildActionButton(
        icon: Icons.star,
        label: 'Reviews',
        onTap: onReviews,
        color: AppTheme.warning,
        isEnabled: isActive,
        isMobile: isMobile,
      ),
      _buildActionButton(
        icon: Icons.block,
        label: 'Blocked',
        onTap: onBlocked,
        color: AppTheme.error,
        isEnabled: true,
        isMobile: isMobile,
      ),
    ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isEnabled,
    required bool isMobile,
  }) {
    final iconSize = isMobile ? 22.0 : 28.0;
    final labelSize = isMobile ? 11.0 : 13.0;
    final padding = isMobile ? 12.0 : 16.0;
    final borderRadius = isMobile ? 12.0 : 16.0;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
