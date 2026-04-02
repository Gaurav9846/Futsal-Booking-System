import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isOwner => _user?.role == 'OWNER';
  bool get isPlayer => _user?.role == 'PLAYER';
  bool get isAdmin => _user?.role == 'ADMIN'; // Added admin check

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      
      debugPrint('📦 AuthProvider login response: $response');

      // Check if login was successful
      if (response['status'] == 'success') {
        // Extract user data from different possible response structures
        if (response.containsKey('user')) {
          _user = User.fromJson(response['user']);
        } else if (response.containsKey('data') && response['data'].containsKey('user')) {
          _user = User.fromJson(response['data']['user']);
        } else if (response.containsKey('data') && response['data'] is Map) {
          // If data contains user fields directly
          _user = User.fromJson(response['data']);
        }
        
        _token = response['token'] ?? response['data']?['token'] ?? response['accessToken'];

        if (_token != null && _user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('user', jsonEncode(_user!.toJson()));
          
          // Log the user role for debugging
          debugPrint('👤 User role: ${_user!.role}');
          debugPrint('🔑 Is Admin: $isAdmin');
          debugPrint('🔑 Is Owner: $isOwner');
          debugPrint('🔑 Is Player: $isPlayer');
        }
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        "status": "error",
        "message": "Connection error: $e"
      };
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);
      
      debugPrint('📦 AuthProvider register response: $response');

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        "status": "error",
        "message": "Connection error: $e"
      };
    }
  }

  // Navigate based on user role
  Future<void> navigateBasedOnRole(BuildContext context) async {
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Navigate based on role
    if (isAdmin) {
      debugPrint('🚀 Navigating to Admin Dashboard');
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } else if (isOwner) {
      debugPrint('🚀 Navigating to Owner Dashboard');
      Navigator.pushReplacementNamed(context, '/owner/dashboard');
    } else if (isPlayer) {
      debugPrint('🚀 Navigating to Player Home');
      Navigator.pushReplacementNamed(context, '/player/home');
    } else {
      debugPrint('⚠️ Unknown role, navigating to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');
    
    if (token != null && userString != null) {
      _token = token;
      _user = User.fromJson(jsonDecode(userString));
      debugPrint('🔄 Restored user session: ${_user?.role}');
      notifyListeners();
    }
  }

  Future<void> saveAuthData(String token, Map<String, dynamic> userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
  await prefs.setString('user', json.encode(userData));
  _user = User.fromJson(userData);
  _token = token;
  notifyListeners();
}

  // Helper method to get role-based home route
  String get homeRoute {
    if (isAdmin) return '/admin/dashboard';
    if (isOwner) return '/owner/dashboard';
    if (isPlayer) return '/player/home';
    return '/login';
  }
}