import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/futsal.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart'; // Add this import
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class FutsalProvider extends ChangeNotifier {
  List<Futsal> _futsals = [];
  List<Futsal> _myFutsals = []; // For owners
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Futsal> get futsals => _futsals;
  List<Futsal> get myFutsals => _myFutsals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================
  // FETCH ALL FUTSALS - For players
  // ============================================
  Position? _playerPosition;
Position? get playerPosition => _playerPosition;

// Haversine distance calculation
double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
      sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

Future<void> _fetchPlayerLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    _playerPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  } catch (e) {
    debugPrint('📍 GPS unavailable: $e');
    _playerPosition = null;
  }
}

Future<void> fetchFutsals() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    debugPrint('📍 FETCHING FUTSALS - START');
    
    await Future.wait([
      _fetchPlayerLocation(),
      ApiService.getList('futsals').then((data) {
        debugPrint('📍 API RESPONSE DATA LENGTH: ${data.length}');
        _futsals = data
            .map((json) => Futsal.fromJson(json as Map<String, dynamic>))
            .where((f) => f.isApproved)
            .toList();
        debugPrint('📍 PARSED FUTSALS COUNT: ${_futsals.length}');
      }),
    ]);

    if (_playerPosition != null) {
      for (final futsal in _futsals) {
        if (futsal.latitude != null && futsal.longitude != null) {
          futsal.distance = _calculateDistance(
            _playerPosition!.latitude,
            _playerPosition!.longitude,
            futsal.latitude!,
            futsal.longitude!,
          );
        }
      }
      _futsals.sort((a, b) =>
        (a.distance ?? 999).compareTo(b.distance ?? 999)
      );
    }
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    debugPrint('❌ FETCH FUTSALS ERROR: $e');
    _isLoading = false;
    _error = 'Failed to load futsals: $e';
    notifyListeners();
  }
}

  // ============================================
  // FETCH SINGLE FUTSAL - Get details by ID
  // ============================================
  Future<Futsal?> fetchFutsalById(int id) async {
    
    try {
      final response = await ApiService.get('futsals/$id');
      
      if (response['futsal'] != null) {
        return Futsal.fromJson(response['futsal']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Provider: Fetch futsal by ID failed - $e');
      return null;
    }
  }

  // ============================================
  // FETCH FUTSAL SLOTS - Get available slots for a date
  // ============================================
  Future<List<Map<String, dynamic>>> fetchFutsalSlots(int futsalId, DateTime date) async {
    debugPrint('📍 Provider: Fetching slots for futsal $futsalId on $date');
    
    try {
      final dateStr = DateFormatter.formatYearMonthDay(date);
      final response = await ApiService.get('futsals/$futsalId/slots?date=$dateStr');
      
      if (response['slots'] != null) {
        final slots = List<Map<String, dynamic>>.from(response['slots']);
        debugPrint('✅ Provider: Loaded ${slots.length} slots');
        return slots;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Provider: Fetch slots failed - $e');
      return [];
    }
  }

  // ============================================
  // FETCH MY FUTSALS - Load owner's futsals
  // ============================================
  Future<void> fetchMyFutsals() async {
    debugPrint('📍 Provider: Fetching my futsals');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getMyFutsals();
      
      _myFutsals = data
          .map((json) => Futsal.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ Provider: Loaded ${_myFutsals.length} futsals');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Provider: Fetch failed - $e');
      _isLoading = false;
      _error = 'Failed to load your futsals: $e';
      notifyListeners();
    }
  }

  // ============================================
  // CREATE FUTSAL - Called when owner submits form
  // ============================================
  Future<Map<String, dynamic>> createFutsal(Map<String, dynamic> futsalData) async {
    debugPrint('📍 Provider: Creating futsal');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Call API
      final response = await ApiService.createFutsal(futsalData);
      
      debugPrint('✅ Provider: Create successful');
      
      // Refresh the list
      await fetchMyFutsals();
      
      _isLoading = false;
      notifyListeners();
      
      return {
        'status': 'success',
        'message': response['message'] ?? 'Futsal created successfully',
      };
      
    } catch (e) {
      debugPrint('❌ Provider: Create failed - $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return {
        'status': 'error',
        'message': 'Failed to create futsal: $e',
      };
    }
  }

  // ============================================
  // UPDATE FUTSAL - Edit existing futsal
  // ============================================
  Future<Map<String, dynamic>> updateFutsal(int id, Map<String, dynamic> futsalData) async {
    debugPrint('📍 Provider: Updating futsal $id');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put('futsals/$id', futsalData);
      
      debugPrint('✅ Provider: Update successful');
      
      // Refresh the list after updating
      await fetchMyFutsals();
      
      _isLoading = false;
      notifyListeners();
      
      return {
        'status': 'success',
        'message': response['message'] ?? 'Futsal updated successfully',
      };
    } catch (e) {
      debugPrint('❌ Provider: Update failed - $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return {
        'status': 'error',
        'message': 'Failed to update futsal: $e',
      };
    }
  }

  // ============================================
  // DELETE FUTSAL - Remove futsal
  // ============================================
  Future<Map<String, dynamic>> deleteFutsal(int id) async {
    debugPrint('📍 Provider: Deleting futsal $id');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('futsals/$id');
      
      debugPrint('✅ Provider: Delete successful');
      
      // Refresh the list
      await fetchMyFutsals();
      
      _isLoading = false;
      notifyListeners();
      
      return {
        'status': 'success',
        'message': response['message'] ?? 'Futsal deleted successfully',
      };
    } catch (e) {
      debugPrint('❌ Provider: Delete failed - $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return {
        'status': 'error',
        'message': 'Failed to delete futsal: $e',
      };
    }
  }

  // ============================================
  // CLEAR ERROR - Reset error state
  // ============================================
  void clearError() {
    _error = null;
    notifyListeners();
  }
}