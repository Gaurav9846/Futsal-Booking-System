import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_theme.dart';

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
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Could not load stats',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: AppTheme.primary)),
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
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today, size: 14, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Today',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                color: AppTheme.info,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.calendar_today,
                value: todayBookings.toString(),
                label: "Today's Bookings",
                color: AppTheme.primary,
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
                value: 'Rs ${todayRevenue.toStringAsFixed(0)}',
                label: "Today's Revenue",
                color: AppTheme.accent,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.hourglass_empty,
                value: pendingApprovals.toString(),
                label: 'Pending',
                color: AppTheme.warning,
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
            color: AppTheme.info,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.calendar_today,
            value: todayBookings.toString(),
            label: "Today's Bookings",
            color: AppTheme.primary,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.currency_rupee,
            value: 'Rs ${todayRevenue.toStringAsFixed(0)}',
            label: "Today's Revenue",
            color: AppTheme.accent,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.hourglass_empty,
            value: pendingApprovals.toString(),
            label: 'Pending',
            color: AppTheme.warning,
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
    final valueFontSize = isMobile ? 18.0 : 22.0;
    final labelFontSize = isMobile ? 11.0 : 13.0;
    final padding = isMobile ? 14.0 : 18.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
