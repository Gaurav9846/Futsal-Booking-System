import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  // Dashboard statistics
  int totalUsers = 0;
  int totalFutsals = 0;
  int pendingApprovals = 0;
  int todayBookings = 0;
  double totalRevenue = 0;

  // Lists
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  List<Map<String, dynamic>> _pendingFutsals = [];
  List<Map<String, dynamic>> get pendingFutsals => _pendingFutsals;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> get allUsers => _allUsers;

  List<Map<String, dynamic>> _allFutsals = [];
  List<Map<String, dynamic>> get allFutsals => _allFutsals;

  // Bookings
List<Map<String, dynamic>> _allBookings = [];
List<Map<String, dynamic>> get allBookings => _allBookings;
int totalBookingsCount = 0;
int totalPages = 0;

  /// =========================
  /// Load Dashboard Stats
  /// =========================
  Future<void> loadDashboardStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadStats(),
        _loadRecentActivities(),
        _loadPendingFutsals(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.get('admin/dashboard');
      final data = response['data'];

      totalUsers = data['totalUsers'] ?? 0;
      totalFutsals = data['totalFutsals'] ?? 0;
      pendingApprovals = data['pendingFutsals'] ?? 0;
      todayBookings = data['todayBookings'] ?? 0;
      totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
    } catch (e) {
      totalUsers = 0;
      totalFutsals = 0;
      pendingApprovals = 0;
      todayBookings = 0;
      totalRevenue = 0;
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final response = await ApiService.get('admin/dashboard');
      final data = response['data'];
      if (data['recentActivities'] != null) {
        _recentActivities = List<Map<String, dynamic>>.from(data['recentActivities']);
      } else {
        _recentActivities = [];
      }
      notifyListeners();
    } catch (e) {
      _recentActivities = [];
      notifyListeners();
    }
  }

  Future<void> _loadPendingFutsals() async {
    try {
      final response = await ApiService.get('admin/futsals/pending');
      if (response['data'] != null) {
        _pendingFutsals = List<Map<String, dynamic>>.from(response['data']);
      } else {
        _pendingFutsals = [];
      }
      notifyListeners();
    } catch (e) {
      _pendingFutsals = [];
      notifyListeners();
    }
  }

  /// =========================
  /// Users Management
  /// =========================
  Future<void> loadAllUsers() async {
    try {
      final response = await ApiService.get('admin/users');
      if (response['data'] != null) {
        _allUsers = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load Users Error: $e');
      _allUsers = [];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> approveOwner(int userId) async {
    try {
      final response = await ApiService.patch('admin/users/$userId/approve-owner', {});
      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _allUsers[index]['isApproved'] = true;
          notifyListeners();
        }
        return {'status': 'success', 'message': response['message'] ?? 'Owner approved'};
      } else {
        return {'status': 'error', 'message': response['message'] ?? 'Failed to approve'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(int userId, bool isActive) async {
    try {
      final response = await ApiService.patch('admin/users/$userId/toggle-status', {'isActive': isActive});
      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _allUsers[index]['isActive'] = isActive;
          notifyListeners();
        }
        return {
          'status': 'success',
          'message': isActive ? 'User activated' : 'User blocked',
        };
      } else {
        return {'status': 'error', 'message': response['message'] ?? 'Failed to update'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// =========================
  /// Futsal Management
  /// =========================
  Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    try {
      final response = await ApiService.patch('admin/futsals/$futsalId/approve', {});
      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);
        pendingApprovals--;
        await _loadRecentActivities();
        notifyListeners();
        return {'status': 'success', 'message': 'Futsal approved successfully'};
      } else {
        return {'status': 'error', 'message': response['message'] ?? 'Failed to approve'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectFutsal(int futsalId, String reason) async {
    try {
      final response = await ApiService.patch('admin/futsals/$futsalId/reject', {'reason': reason});
      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);
        pendingApprovals--;
        notifyListeners();
        return {'status': 'success', 'message': 'Futsal rejected'};
      } else {
        return {'status': 'error', 'message': response['message'] ?? 'Failed to reject'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// =========================
  /// All Futsals
  /// =========================
  Future<void> loadAllFutsals() async {
    try {
      final response = await ApiService.get('admin/futsals');
      if (response['data'] != null) {
        _allFutsals = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      } else {
        _allFutsals = [];
      }
    isLoading = false;
    notifyListeners();
    } catch (e) {
    debugPrint('👑 Load All Futsals Error: $e');
    _allFutsals = [];
    isLoading = false;
    notifyListeners();
    }
  }

  /// =========================
  /// Generate Reports
  /// =========================
  Future<Map<String, dynamic>> generateReport(String type, DateTime from, DateTime to) async {
    try {
      final response = await ApiService.get(
        'admin/reports?type=$type&from=${from.toIso8601String()}&to=${to.toIso8601String()}',
      );
      return {'status': 'success', 'data': response};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> loadAllBookings({
  String status = 'ALL',
  String? from,
  String? to,
  int page = 1,
}) async {
  try {
    final response = await ApiService.getAdminBookings(
      status: status,
      from: from,
      to: to,
      page: page,
    );
    _allBookings = List<Map<String, dynamic>>.from(
        response['bookings'] ?? []);
    totalBookingsCount = response['total'] ?? 0;
    totalPages = response['totalPages'] ?? 1;
    notifyListeners();
  } catch (e) {
    debugPrint('Load bookings error: $e');
    _allBookings = [];
    notifyListeners();
  }
}

// Analytics
Map<String, dynamic> _adminAnalytics = {};
Map<String, dynamic> get adminAnalytics => _adminAnalytics;

Future<void> loadAdminAnalytics() async {
  try {
    final response = await ApiService.getAdminAnalytics();
    _adminAnalytics = response;
    notifyListeners();
  } catch (e) {
    debugPrint('Load admin analytics error: $e');
  }
}

  /// =========================
  /// Clear Data
  /// =========================
  void clearData() {
    totalUsers = 0;
    totalFutsals = 0;
    pendingApprovals = 0;
    todayBookings = 0;
    totalRevenue = 0;
    _recentActivities = [];
    _pendingFutsals = [];
    _allUsers = [];
    _allFutsals = [];
    error = null;
    notifyListeners();
  }
}