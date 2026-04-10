import 'package:flutter/material.dart';

class BookingsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const BookingsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  factory BookingsEmptyState.today() {
    return const BookingsEmptyState(
      icon: Icons.event_busy,
      title: 'No bookings for today',
      subtitle: 'Check back later or view upcoming bookings',
    );
  }

  factory BookingsEmptyState.upcoming() {
    return const BookingsEmptyState(
      icon: Icons.event_note,
      title: 'No upcoming bookings',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}