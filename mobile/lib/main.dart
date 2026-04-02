import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/futsal_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/court_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/review_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/player/home_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/player/PaymentVerifyPage.dart';
import 'screens/admin/futsal_approval_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/admin_all_futsals_screen.dart';
import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FutsalProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CourtProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'Futsal Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Change this to test different screens
        home: const SplashScreen(),
        // home: const LoginScreen(),
        // home: const OwnerDashboard(),
        // home: const PlayerHomeScreen(),
        
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/player/home': (ctx) => const PlayerHomeScreen(),
          '/owner/dashboard': (ctx) => const OwnerDashboard(),
          '/admin/dashboard': (ctx) => const AdminDashboard(),
          '/payment-verify': (ctx) => const PaymentVerifyPage(),
          "/admin/futsal-approvals": (ctx) => const FutsalApprovalScreen(),
          "/admin/users": (ctx) => const AdminUsersScreen(),
          '/admin/futsals': (context) => const AdminAllFutsalsScreen(),
          '/admin/bookings': (context) => const AdminBookingsScreen(),
          '/admin/settings': (context) => const SystemSettingsScreen(),
          '/admin/analytics': (context) => const AdminAnalyticsScreen(),
        },
      ),
    );
  }
}