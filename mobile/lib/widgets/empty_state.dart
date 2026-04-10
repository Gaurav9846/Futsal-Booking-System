import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  factory EmptyState.noFutsals({VoidCallback? onClearFilters}) {
    return EmptyState(
      icon: Icons.sports_soccer,
      title: 'No futsals available',
      subtitle: 'Check back later for new venues',
      buttonText: onClearFilters != null ? 'Clear Filters' : null,
      onButtonPressed: onClearFilters,
    );
  }

  factory EmptyState.noSearchResults({required VoidCallback onClearFilters}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No matching futsals found',
      subtitle: 'Try adjusting your search or filters',
      buttonText: 'Clear Filters',
      onButtonPressed: onClearFilters,
    );
  }

  factory EmptyState.error(String error, {VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: error,
      buttonText: onRetry != null ? 'Try Again' : null,
      onButtonPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}