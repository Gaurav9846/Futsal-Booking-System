import 'package:flutter/material.dart';
import '../../../../models/court.dart';

class CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleMaintenance;
  final VoidCallback onEdit;
  final VoidCallback onSetPeakPrice;
  final VoidCallback onDelete;

  const CourtCard({
    super.key,
    required this.court,
    required this.onToggleActive,
    required this.onToggleMaintenance,
    required this.onEdit,
    required this.onSetPeakPrice,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (court.isUnderMaintenance)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.build, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Under Maintenance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (court.maintenanceUntil != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Until ${_formatDate(court.maintenanceUntil!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!court.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court Number with Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: court.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      court.courtNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: court.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Court Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Court ${court.courtNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: court.courtType == 'indoor'
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              court.courtType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                color: court.courtType == 'indoor'
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Price info
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            'रू ${court.basePrice}/hr',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (court.peakPrice != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 10,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Peak: रू ${court.peakPrice}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Amenities
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: court.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        court.isActive ? Icons.visibility : Icons.visibility_off,
                        color: court.isActive ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onToggleActive,
                      tooltip: court.isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.build,
                        color: court.isUnderMaintenance ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onToggleMaintenance,
                      tooltip: court.isUnderMaintenance
                          ? 'Mark Available'
                          : 'Mark Maintenance',
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.edit, size: 18),
                            title: Text('Edit Court'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: onEdit,
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.trending_up,
                                size: 18, color: Colors.orange),
                            title: Text('Set Peak Price'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: onSetPeakPrice,
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.delete, size: 18, color: Colors.red),
                            title: Text('Delete Court',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: onDelete,
                        ),
                      ],
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