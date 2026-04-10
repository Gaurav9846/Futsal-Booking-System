import 'package:flutter/material.dart';

class ResponsiveTestHelper extends StatelessWidget {
  final Widget child;
  
  const ResponsiveTestHelper({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Usage in main.dart for testing:
// runApp(ResponsiveTestHelper(child: const PlayerHomeScreen()));