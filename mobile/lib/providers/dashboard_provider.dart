import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking.dart';

class DashboardProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;
  
  // Statistics
  int totalCourts = 0;
  int todayBookings = 0;
  double todayRevenue = 0;
  int pendingApprovals = 0;
  
  // Today's bookings list
  List<Booking> _todayBookingsList = [];
  List<Booking> get todayBookingsList => _todayBookingsList;
  
  // Weekly revenue data for charts
  List<double> _weeklyRevenue = [];
  List<double> get weeklyRevenue => _weeklyRevenue;
  
  // Peak hours data
  Map<String, int> _peakHours = {};
  Map<String, int> get peakHours => _peakHours;

  // Load dashboard statistics for a specific futsal
  Future<void> loadStatistics(int futsalId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    debugPrint('📊 Dashboard: Loading stats for futsal $futsalId');
    
    try {
      // Load all stats in parallel for better performance
      await Future.wait([
        _loadStats(futsalId),
        _loadTodayBookings(futsalId),
        _loadWeeklyRevenue(futsalId),
        _loadPeakHours(futsalId),
      ]);
      
      isLoading = false;
      notifyListeners();
      debugPrint('📊 Dashboard: Stats loaded successfully');
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('📊 Dashboard Error: $e');
    }
  }

  // Load main statistics
  Future<void> _loadStats(int futsalId) async {
    try {
      final response = await ApiService.getDashboardStats(futsalId);
      
      totalCourts = response['totalCourts'] ?? 0;
      todayBookings = response['todayBookings'] ?? 0;
      todayRevenue = (response['todayRevenue'] ?? 0).toDouble();
      pendingApprovals = response['pendingApprovals'] ?? 0;
      
      debugPrint('📊 Stats: Courts=$totalCourts, Bookings=$todayBookings, Revenue=$todayRevenue');
    } catch (e) {
      debugPrint('📊 Stats Error: $e');
      // Don't rethrow, just use defaults
    }
  }

  // Load today's bookings
  Future<void> _loadTodayBookings(int futsalId) async {
    try {
      final response = await ApiService.getDashboardTodayBookings(futsalId);
      
      if (response is List) {
        _todayBookingsList = response
            .map((json) => Booking.fromJson(json))
            .toList();
      }
      
      debugPrint('📊 Today\'s Bookings: ${_todayBookingsList.length} bookings');
    } catch (e) {
      debugPrint('📊 Today Bookings Error: $e');
      _todayBookingsList = [];
    }
  }

  // Load weekly revenue for chart
  Future<void> _loadWeeklyRevenue(int futsalId) async {
    try {
      final response = await ApiService.getWeeklyRevenue(futsalId);
      
      if (response is List) {
        _weeklyRevenue = response.map((value) {
          if (value is int) return value.toDouble();
          if (value is double) return value;
          return 0.0;
        }).toList();
      }
      
      debugPrint('📊 Weekly Revenue: $_weeklyRevenue');
    } catch (e) {
      debugPrint('📊 Weekly Revenue Error: $e');
      _weeklyRevenue = [0, 0, 0, 0, 0, 0, 0];
    }
  }

  // Load peak hours data
  Future<void> _loadPeakHours(int futsalId) async {
    try {
      final response = await ApiService.getPeakHours(futsalId);
      
      if (response is Map) {
        _peakHours = Map<String, int>.from(response);
      }
      
      debugPrint('📊 Peak Hours: $_peakHours');
    } catch (e) {
      debugPrint('📊 Peak Hours Error: $e');
      _peakHours = {};
    }
  }

  // Check-in a customer (owner action)
  Future<Map<String, dynamic>> checkInCustomer(int bookingId, int futsalId) async {
    try {
      final response = await ApiService.checkInBooking(bookingId);
      
      if (response['status'] == 'success') {
        await _loadTodayBookings(futsalId);
        notifyListeners();
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Check-in error: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Cancel a booking (owner action)
  // In dashboard_provider.dart, replace the cancelBooking method (around line 145-155) with:

// Cancel a booking (owner action) - UPDATED to use correct ApiService method
Future<Map<String, dynamic>> cancelBooking(int bookingId, int futsalId) async {
  try {
    // Use ApiService.cancelBooking which exists for owner actions
    final response = await ApiService.cancelUserBooking(bookingId);
    
    if (response['status'] == 'success') {
      await _loadTodayBookings(futsalId);
      notifyListeners();
    }
    
    return response;
  } catch (e) {
    debugPrint('❌ Cancel booking error: $e');
    return {
      'status': 'error',
      'message': e.toString()
    };
  }
}

  // Complete a booking (owner action)
  Future<Map<String, dynamic>> completeBooking(int bookingId, int futsalId) async {
    try {
      final response = await ApiService.completeBooking(bookingId);
      
      if (response['status'] == 'success') {
        await _loadTodayBookings(futsalId);
        notifyListeners();
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Complete booking error: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Update payment status (owner action)
  Future<Map<String, dynamic>> updatePaymentStatus(int bookingId, String status, int futsalId) async {
    try {
      final response = await ApiService.updatePaymentStatus(bookingId, status);
      
      if (response['status'] == 'success') {
        await _loadTodayBookings(futsalId);
        notifyListeners();
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Update payment error: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Clear data (useful for logout)
  void clearData() {
    totalCourts = 0;
    todayBookings = 0;
    todayRevenue = 0;
    pendingApprovals = 0;
    _todayBookingsList = [];
    _weeklyRevenue = [];
    _peakHours = {};
    error = null;
    notifyListeners();
  }
}