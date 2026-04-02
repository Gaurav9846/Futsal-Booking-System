import 'package:flutter/material.dart';
import '../models/court.dart';
import '../services/api_service.dart';

class CourtProvider with ChangeNotifier {
  List<Court> _courts = [];
  bool isLoading = false;
  String? error;

  int? _currentFutsalId;

  List<Court> get courts => _courts;
  List<Court> get activeCourts => _courts.where((c) => c.isActive).toList();
  List<Court> get maintenanceCourts =>
      _courts.where((c) => c.isUnderMaintenance).toList();

  // Load courts for a specific futsal
  Future<void> loadCourts(int futsalId) async {
    debugPrint('🏟️ CourtProvider: Loading courts for futsal $futsalId');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _currentFutsalId = futsalId;
      // RESTful: GET /futsals/:futsalId/courts
      final response = await ApiService.getList('futsals/$futsalId/courts');

      _courts = response.map((json) => Court.fromJson(json)).toList();
      debugPrint('🏟️ CourtProvider: Loaded ${_courts.length} courts');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏟️ CourtProvider Error: $e');
    }
  }

  // Add a new court
  Future<Map<String, dynamic>> addCourt(Map<String, dynamic> courtData) async {
    debugPrint('🏟️ CourtProvider: Adding new court');

    try {
      // RESTful: POST /futsals/:futsalId/courts
      final response = await ApiService.post('futsals/$_currentFutsalId/courts', courtData);

      if (response['status'] == 'success') {
        if (_currentFutsalId != null) {
          await loadCourts(_currentFutsalId!);
        }

        return {
          'status': 'success',
          'message': response['message'] ?? 'Court added successfully'
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to add court'
        };
      }
    } catch (e) {
      debugPrint('🏟️ CourtProvider Add Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Update court details
  Future<Map<String, dynamic>> updateCourt(int courtId, Map<String, dynamic> courtData) async {
    debugPrint('🏟️ CourtProvider: Updating court $courtId');
    debugPrint('📦 Update data: $courtData');

    try {
      // RESTful: PUT /courts/:courtId
      final response = await ApiService.put('courts/$courtId', courtData);

      if (response['status'] == 'success') {
        // Update local court data
        final index = _courts.indexWhere((c) => c.id == courtId);
        if (index != -1) {
          _courts[index] = Court.fromJson({
            ..._courts[index].toJson(),
            ...courtData,
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': response['message'] ?? 'Court updated successfully'
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update court'
        };
      }
    } catch (e) {
      debugPrint('🏟️ CourtProvider Update Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Toggle maintenance mode
  Future<Map<String, dynamic>> toggleMaintenance(
      int courtId, bool isUnderMaintenance) async {
    debugPrint(
        '🏟️ CourtProvider: Toggling maintenance for court $courtId to $isUnderMaintenance');

    try {
      // RESTful: PATCH /courts/:courtId/maintenance
      final response = await ApiService.patch('courts/$courtId/maintenance', {
        'isUnderMaintenance': isUnderMaintenance,
      });

      if (response['status'] == 'success') {
        final index = _courts.indexWhere((c) => c.id == courtId);
        if (index != -1) {
          _courts[index] = Court.fromJson({
            ..._courts[index].toJson(),
            'isUnderMaintenance': isUnderMaintenance,
            'maintenanceUntil': isUnderMaintenance
                ? DateTime.now().add(const Duration(days: 1)).toIso8601String()
                : null,
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': isUnderMaintenance
              ? 'Court marked for maintenance'
              : 'Court is now available'
        };
      } else {
        return {
          'status': 'error',
          'message':
              response['message'] ?? 'Failed to update maintenance status'
        };
      }
    } catch (e) {
      debugPrint('🏟️ CourtProvider Maintenance Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Toggle active status
  Future<Map<String, dynamic>> toggleActive(int courtId, bool isActive) async {
    debugPrint(
        '🏟️ CourtProvider: Toggling active for court $courtId to $isActive');

    try {
      // RESTful: Use update endpoint with isActive field
      final response = await ApiService.put('courts/$courtId', {
        'isActive': isActive,
      });

      if (response['status'] == 'success') {
        final index = _courts.indexWhere((c) => c.id == courtId);
        if (index != -1) {
          _courts[index] = Court.fromJson({
            ..._courts[index].toJson(),
            'isActive': isActive,
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': isActive ? 'Court activated' : 'Court deactivated'
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update court status'
        };
      }
    } catch (e) {
      debugPrint('🏟️ CourtProvider Active Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Set peak hour pricing
  Future<Map<String, dynamic>> setPeakPrice(int courtId, int? peakPrice) async {
    debugPrint(
        '🏟️ CourtProvider: Setting peak price for court $courtId to $peakPrice');

    try {
      // RESTful: PATCH /courts/:courtId/peak-price
      final response = await ApiService.patch('courts/$courtId/peak-price', {
        'peakPrice': peakPrice,
      });

      if (response['status'] == 'success') {
        final index = _courts.indexWhere((c) => c.id == courtId);
        if (index != -1) {
          _courts[index] = Court.fromJson({
            ..._courts[index].toJson(),
            'peakPrice': peakPrice,
          });
          notifyListeners();
        }

        return {
          'status': 'success',
          'message': peakPrice != null
              ? 'Peak price set to रू $peakPrice'
              : 'Peak pricing removed'
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to set peak price'
        };
      }
    } catch (e) {
      debugPrint('🏟️ CourtProvider Peak Price Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Delete court
  Future<Map<String, dynamic>> deleteCourt(int courtId) async {
    debugPrint('🏟️ CourtProvider: Deleting court $courtId');

    try {
      // RESTful: DELETE /courts/:courtId
      final response = await ApiService.delete('courts/$courtId');

      if (response['status'] == 'success') {
        _courts.removeWhere((c) => c.id == courtId);
        notifyListeners();

        return {
          'status': 'success',
          'message': response['message'] ?? 'Court deleted successfully'
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to delete court'
        };
      }
    } catch (e) {
      debugPrint('🏟️ CourtProvider Delete Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Generate slots for a court
  Future<Map<String, dynamic>> generateSlots(int courtId, DateTime startDate, DateTime endDate) async {
    debugPrint('🏟️ CourtProvider: Generating slots for court $courtId');

    try {
      final response = await ApiService.post('courts/$courtId/generate-slots', {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      });

      return {
        'status': response['status'] ?? 'success',
        'message': response['message'] ?? 'Slots generated successfully',
        'count': response['count'] ?? 0
      };
    } catch (e) {
      debugPrint('🏟️ CourtProvider Generate Slots Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Get court by ID
  Court? getCourtById(int courtId) {
    try {
      return _courts.firstWhere((c) => c.id == courtId);
    } catch (e) {
      return null;
    }
  }

  // Clear data
  void clearData() {
    _courts = [];
    _currentFutsalId = null;
    error = null;
    notifyListeners();
  }

  // Get court statistics
  Map<String, dynamic> getStatistics() {
    final total = _courts.length;
    final active = activeCourts.length;
    final maintenance = maintenanceCourts.length;
    final inactive = _courts.where((c) => !c.isActive).length;

    final indoor = _courts.where((c) => c.courtType == 'indoor').length;
    final outdoor = _courts.where((c) => c.courtType == 'outdoor').length;
    final withPeakPricing = _courts.where((c) => c.peakPrice != null).length;

    return {
      'total': total,
      'active': active,
      'maintenance': maintenance,
      'inactive': inactive,
      'indoor': indoor,
      'outdoor': outdoor,
      'withPeakPricing': withPeakPricing,
    };
  }
}