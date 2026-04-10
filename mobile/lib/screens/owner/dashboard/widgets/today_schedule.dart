import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';

class TodaySchedule extends StatelessWidget {
  final List<dynamic> bookings;
  final VoidCallback onViewAll;
  final int? maxBookingsToShow;

  const TodaySchedule({
    super.key,
    required this.bookings,
    required this.onViewAll,
    this.maxBookingsToShow,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    // Use maxBookingsToShow if provided, otherwise default
    final maxBookings = maxBookingsToShow ?? (isMobile ? 3 : 5);
    final padding = isMobile ? 16.0 : 20.0;
    final titleFontSize = isMobile ? 16.0 : 18.0;

    if (bookings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, color: Colors.grey, size: isMobile ? 32 : 40),
              const SizedBox(height: 8),
              Text(
                'No bookings today',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate displayed count for placeholders
    final displayedCount = bookings.length < maxBookings ? bookings.length : maxBookings;
    final needsPlaceholders = bookings.length < maxBookings;

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
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 8,
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show actual bookings
          ...bookings.take(maxBookings).map((booking) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _buildBookingItem(booking, isMobile),
          )),
          // Add placeholder spaces if needed to maintain consistent height
          if (needsPlaceholders)
            ...List.generate(
              maxBookings - displayedCount,
              (index) => SizedBox(height: 70),
            ),
          if (bookings.length > maxBookings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${bookings.length - maxBookings} more bookings',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(dynamic booking, bool isMobile) {
    final iconSize = isMobile ? 16.0 : 18.0;
    final nameFontSize = isMobile ? 14.0 : 14.0;
    final detailFontSize = isMobile ? 12.0 : 12.0;
    final statusFontSize = isMobile ? 10.0 : 10.0;
    final padding = isMobile ? 12.0 : 12.0;
    final borderRadius = isMobile ? 8.0 : 10.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(Icons.person, color: Colors.green, size: iconSize),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: nameFontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Court ${booking.courtNumber} • ${booking.startTime}',
                  style: TextStyle(
                    fontSize: detailFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: isMobile ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: booking.paymentStatus == 'paid' ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            ),
            child: Text(
              booking.paymentStatus == 'paid' ? 'Paid' : 'Pending',
              style: TextStyle(
                fontSize: statusFontSize,
                color: booking.paymentStatus == 'paid' ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}