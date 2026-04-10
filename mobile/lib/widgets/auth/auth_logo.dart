import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Animated logo container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                // Icon
                Icon(
                  Icons.sports_soccer,
                  size: iconSize ?? 50,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Brand name
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFB3B3B3)],
            ).createShader(bounds),
            child: Text(
              'FUTSAL',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ARENA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
                letterSpacing: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
