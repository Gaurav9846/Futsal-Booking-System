import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.checkAuth();

    if (!mounted) return;

    // Debug logs
    debugPrint('🔄 SplashScreen - Auth check completed');
    debugPrint('   isAuthenticated: ${auth.isAuthenticated}');
    debugPrint('   isAdmin: ${auth.isAdmin}');
    debugPrint('   isOwner: ${auth.isOwner}');
    debugPrint('   isPlayer: ${auth.isPlayer}');

    if (auth.isAuthenticated) {
      if (auth.isAdmin) {
        debugPrint('   ➡️ Navigating to Admin Dashboard');
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else if (auth.isOwner) {
        debugPrint('   ➡️ Navigating to Owner Dashboard');
        Navigator.pushReplacementNamed(context, '/owner/dashboard');
      } else if (auth.isPlayer) {
        debugPrint('   ➡️ Navigating to Player Home');
        Navigator.pushReplacementNamed(context, '/player/home');
      } else {
        debugPrint('   ⚠️ Unknown role, logging out');
        await auth.logout();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      debugPrint('   ➡️ Not authenticated, going to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.lightGreen],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Futsal Booking',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
