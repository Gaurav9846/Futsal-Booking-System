import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  final String? title;
  final double? iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AuthLogo({
    super.key,
    this.title,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = iconColor ?? Colors.green;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.sports_soccer,
              size: iconSize ?? 60,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'Futsal Booking',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}