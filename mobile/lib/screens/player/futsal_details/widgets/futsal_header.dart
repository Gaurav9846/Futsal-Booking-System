import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/futsal.dart';
import '../../../../providers/review_provider.dart';

class FutsalHeader extends StatelessWidget {
  final Futsal futsal;

  const FutsalHeader({
    super.key,
    required this.futsal,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    futsal.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildRatingBadge(context),
              ],
            ),
            const SizedBox(height: 8),
            _buildAddressRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            futsal.averageRating?.toStringAsFixed(1) ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Consumer<ReviewProvider>(
            builder: (_, rp, __) => Text(
              ' (${rp.reviews.length})',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            futsal.address,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}