import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingState({
    super.key,
    this.message,
    this.color,
  });

  factory LoadingState.futsals() {
    return const LoadingState(
      message: 'Loading amazing futsals...',
      color: Colors.green,
    );
  }

  factory LoadingState.bookings() {
    return const LoadingState(
      message: 'Loading bookings...',
      color: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? Colors.green,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}