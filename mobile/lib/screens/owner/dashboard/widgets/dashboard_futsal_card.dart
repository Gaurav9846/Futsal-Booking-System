import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_theme.dart';

class DashboardFutsalCard extends StatelessWidget {
  final Futsal futsal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageCourts;
  final VoidCallback onViewBookings;
  final VoidCallback onViewReviews;
  final VoidCallback onToggleActive;

  const DashboardFutsalCard({
    super.key,
    required this.futsal,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCourts,
    required this.onViewBookings,
    required this.onViewReviews,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = futsal.status == 'PENDING';
    final isDeactivated = futsal.status == 'DEACTIVATED';
    final isActive = futsal.status == 'ACTIVE';
    final hasCourts = futsal.courts != null && futsal.courts!.isNotEmpty;
    final isMobile = Responsive.isMobile(context);

    final cardPadding = isMobile ? 14.0 : 18.0;
    final logoSize = isMobile ? 56.0 : 64.0;
    final iconSize = isMobile ? 28.0 : 32.0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Status Banner
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Pending Approval',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (isDeactivated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Deactivated',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Image
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: futsal.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1),
                          child: Image.network(
                            futsal.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.sports_soccer,
                                color: AppTheme.primary,
                                size: iconSize,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.sports_soccer,
                          color: AppTheme.primary,
                          size: iconSize,
                        ),
                ),
                SizedBox(width: isMobile ? 14 : 18),

                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        futsal.name,
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 19,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              futsal.address,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sports_soccer,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${futsal.courts?.length ?? 0} courts',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (futsal.averageRating != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: AppTheme.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    futsal.averageRating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppTheme.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                isMobile
                    ? _buildMobileActions(futsal, hasCourts, isActive, isDeactivated)
                    : _buildDesktopActions(futsal, hasCourts, isActive, isDeactivated),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActions(Futsal futsal, bool hasCourts, bool isActive, bool isDeactivated) {
    return PopupMenuButton<String>(
      iconSize: 22,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
      ),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
          case 'manage_courts':
            onManageCourts();
            break;
          case 'view_bookings':
            onViewBookings();
            break;
          case 'view_reviews':
            onViewReviews();
            break;
          case 'toggle_active':
            onToggleActive();
            break;
        }
      },
      itemBuilder: (ctx) => [
        _buildMenuItem('manage_courts', Icons.sports_soccer, 'Manage Courts', AppTheme.info, isActive),
        _buildMenuItem('view_bookings', Icons.calendar_month, 'View Bookings', AppTheme.primary, isActive),
        _buildMenuItem('view_reviews', Icons.star, 'View Reviews', AppTheme.warning, isActive),
        _buildMenuItem('edit', Icons.edit, 'Edit', AppTheme.textSecondary, true),
        if (futsal.status == 'PENDING' && !hasCourts)
          _buildMenuItem('delete', Icons.delete, 'Delete', AppTheme.error, true),
        if (isActive || isDeactivated)
          _buildMenuItem(
            'toggle_active',
            isActive ? Icons.visibility_off : Icons.visibility,
            isActive ? 'Deactivate' : 'Activate',
            isActive ? AppTheme.warning : AppTheme.success,
            true,
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label,
    Color color,
    bool enabled,
  ) {
    return PopupMenuItem(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 18, color: enabled ? color : AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(Futsal futsal, bool hasCourts, bool isActive, bool isDeactivated) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(
          icon: Icons.sports_soccer,
          onTap: onManageCourts,
          color: AppTheme.info,
          enabled: isActive,
        ),
        const SizedBox(width: 6),
        _buildIconButton(
          icon: Icons.calendar_month,
          onTap: onViewBookings,
          color: AppTheme.primary,
          enabled: isActive,
        ),
        const SizedBox(width: 6),
        _buildIconButton(
          icon: Icons.star,
          onTap: onViewReviews,
          color: AppTheme.warning,
          enabled: isActive,
        ),
        const SizedBox(width: 6),
        _buildIconButton(
          icon: Icons.edit,
          onTap: onEdit,
          color: AppTheme.textSecondary,
          enabled: true,
        ),
        if (isActive || isDeactivated) ...[
          const SizedBox(width: 6),
          _buildIconButton(
            icon: isActive ? Icons.visibility_off : Icons.visibility,
            onTap: onToggleActive,
            color: isActive ? AppTheme.warning : AppTheme.success,
            enabled: true,
          ),
        ],
        if (futsal.status == 'PENDING' && !hasCourts) ...[
          const SizedBox(width: 6),
          _buildIconButton(
            icon: Icons.delete,
            onTap: onDelete,
            color: AppTheme.error,
            enabled: true,
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled ? color.withOpacity(0.1) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: enabled ? color.withOpacity(0.3) : AppTheme.surfaceBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? color : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
