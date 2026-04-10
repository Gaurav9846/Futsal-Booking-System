import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Theme
import 'utils/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/futsal_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/court_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/review_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/block_provider.dart'; 
import 'providers/settings_provider.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
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
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Futsal Arena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
        
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
