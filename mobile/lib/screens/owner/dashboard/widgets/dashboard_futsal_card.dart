import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';
import '../../../../utils/responsive.dart';

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
    final hasCourts = futsal.courts != null && futsal.courts!.isNotEmpty;
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    
    // Responsive values
    final cardMargin = isMobile ? 16.0 : 12.0;
    final cardElevation = isMobile ? 2.0 : 3.0;
    final cardPadding = isMobile ? 12.0 : 16.0;
    final logoSize = isMobile ? 60.0 : 70.0;
    final iconSize = isMobile ? 30.0 : 36.0;
    final titleFontSize = isMobile ? 18.0 : 20.0;
    final addressFontSize = isMobile ? 12.0 : 13.0;
    final priceFontSize = isMobile ? 12.0 : 13.0;

    return Card(
      margin: EdgeInsets.only(bottom: cardMargin),
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Status Banner
          if (isPending)
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (isDeactivated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Deactivated',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  ),
                  child: Icon(Icons.sports_soccer, color: Colors.green, size: iconSize),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                
                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        futsal.name,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: isMobile ? 14 : 15, color: Colors.grey),
                          SizedBox(width: isMobile ? 4 : 6),
                          Expanded(
                            child: Text(
                              futsal.address,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: addressFontSize,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price varies by court',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.normal,
                          fontSize: priceFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons - Different for Mobile and Desktop
                isMobile
                    ? PopupMenuButton<String>(
                        iconSize: 24,
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
                          PopupMenuItem(
                            value: 'manage_courts',
                            enabled: futsal.status == 'ACTIVE',
                            child: Row(
                              children: [
                                Icon(Icons.sports_soccer, size: 18, color: futsal.status == 'ACTIVE' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Manage Courts', style: TextStyle(color: futsal.status == 'ACTIVE' ? Colors.black : Colors.grey)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view_bookings',
                            enabled: futsal.status == 'ACTIVE',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, size: 18, color: futsal.status == 'ACTIVE' ? Colors.green : Colors.grey),
                                const SizedBox(width: 8),
                                Text('View Bookings', style: TextStyle(color: futsal.status == 'ACTIVE' ? Colors.black : Colors.grey)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view_reviews',
                            enabled: futsal.status == 'ACTIVE',
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 18, color: futsal.status == 'ACTIVE' ? Colors.amber : Colors.grey),
                                const SizedBox(width: 8),
                                Text('View Reviews', style: TextStyle(color: futsal.status == 'ACTIVE' ? Colors.black : Colors.grey)),
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
                          PopupMenuItem(
                            value: 'delete',
                            enabled: futsal.status == 'PENDING' && !hasCourts,
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: futsal.status == 'PENDING' && !hasCourts ? Colors.red : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: futsal.status == 'PENDING' && !hasCourts ? Colors.red : Colors.grey)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_active',
                            enabled: futsal.status == 'ACTIVE' || futsal.status == 'DEACTIVATED',
                            child: Row(
                              children: [
                                Icon(futsal.status == 'ACTIVE' ? Icons.visibility_off : Icons.visibility, size: 18, color: futsal.status == 'ACTIVE' ? Colors.orange : Colors.green),
                                const SizedBox(width: 8),
                                Text(futsal.status == 'ACTIVE' ? 'Deactivate' : 'Activate'),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconButton(
                            icon: Icons.sports_soccer,
                            onTap: onManageCourts,
                            color: Colors.blue,
                            enabled: futsal.status == 'ACTIVE',
                          ),
                          const SizedBox(width: 4),
                          _buildIconButton(
                            icon: Icons.calendar_month,
                            onTap: onViewBookings,
                            color: Colors.green,
                            enabled: futsal.status == 'ACTIVE',
                          ),
                          const SizedBox(width: 4),
                          _buildIconButton(
                            icon: Icons.star,
                            onTap: onViewReviews,
                            color: Colors.amber,
                            enabled: futsal.status == 'ACTIVE',
                          ),
                          const SizedBox(width: 4),
                          _buildIconButton(
                            icon: Icons.edit,
                            onTap: onEdit,
                            color: Colors.grey,
                            enabled: true,
                          ),
                          if (futsal.status == 'ACTIVE' || futsal.status == 'DEACTIVATED')
                            _buildIconButton(
                              icon: futsal.status == 'ACTIVE' ? Icons.visibility_off : Icons.visibility,
                              onTap: onToggleActive,
                              color: futsal.status == 'ACTIVE' ? Colors.orange : Colors.green,
                              enabled: true,
                            ),
                          if (futsal.status == 'PENDING' && !hasCourts)
                            _buildIconButton(
                              icon: Icons.delete,
                              onTap: onDelete,
                              color: Colors.red,
                              enabled: true,
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}