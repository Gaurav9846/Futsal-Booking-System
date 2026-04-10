import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _todayBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  List<Booking> _cancelledBookings = [];
  Map<DateTime, List<Booking>> _calendarBookings = {};
  List<Booking> _selectedDateBookings = [];

  bool isLoading = false;
  String? error;

  int? _currentFutsalId;

  // Getters
  List<Booking> get todayBookings => _todayBookings;
  List<Booking> get upcomingBookings => _upcomingBookings;
  List<Booking> get pastBookings => _pastBookings;
  List<Booking> get cancelledBookings => _cancelledBookings;
  Map<DateTime, List<Booking>> get calendarBookings => _calendarBookings;
  List<Booking> get selectedDateBookings => _selectedDateBookings;

  int get todayCount => _todayBookings.length;
  int get upcomingCount => _upcomingBookings.length;
  int get totalBookings => _todayBookings.length + _upcomingBookings.length;

  int get todayRevenue {
    return _todayBookings.fold(0, (sum, booking) => sum + booking.totalAmount);
  }

  // ============================================
  // PLAYER BOOKING METHODS
  // ============================================

  // Load current user's bookings (for player)
  Future<void> loadUserBookings() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.getMyBookings();
      debugPrint('📅 BOOKINGS COUNT: ${(response['bookings'] ?? []).length}');

      final bookingsJson = response['bookings'] ?? [];

      final List<Booking> allBookings = [];
      for (var json in bookingsJson) {
        try {
          allBookings.add(Booking.fromJson(json));
        } catch (e) {
          debugPrint('❌ BOOKING PARSE ERROR: $e');
          debugPrint('❌ FAILED JSON: $json');
        }
      }

      debugPrint('📅 PARSED BOOKINGS: ${allBookings.length}');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      _upcomingBookings = allBookings.where((b) {
        final bookingDate = DateTime(b.date.year, b.date.month, b.date.day);
        return (b.bookingStatus.toLowerCase() == 'pending' ||
                b.bookingStatus.toLowerCase() == 'confirmed') &&
            !bookingDate.isBefore(today);
      }).toList();

      _pastBookings = allBookings.where((b) {
        final bookingDate = DateTime(b.date.year, b.date.month, b.date.day);
        return b.bookingStatus.toLowerCase() == 'completed' ||
            ((b.bookingStatus.toLowerCase() == 'confirmed' ||
                    b.bookingStatus.toLowerCase() == 'pending') &&
                bookingDate.isBefore(today));
      }).toList();

      _cancelledBookings = allBookings
          .where((b) => b.bookingStatus.toLowerCase() == 'cancelled')
          .toList();

      debugPrint('📅 UPCOMING: ${_upcomingBookings.length}');
      debugPrint('📅 PAST: ${_pastBookings.length}');
      debugPrint('📅 CANCELLED: ${_cancelledBookings.length}');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ LOAD BOOKINGS ERROR: $e');
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  // Create a new booking (for player)
  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    debugPrint('📅 BookingProvider: Creating booking');
    debugPrint('📅 Booking data: $bookingData');

    try {
      final response = await ApiService.createBooking(bookingData);

      debugPrint('📅 API Response: $response');

      if (response['status'] == 'success') {
        return {
          'status': 'success',
          'message': response['message'] ?? 'Booking created successfully',
          'bookingId': response['booking']?['id'] ?? response['bookingId'],
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to create booking',
        };
      }
    } catch (e) {
      debugPrint('📅 BookingProvider Create Error: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // User cancels their own booking (keeps record)
  Future<Map<String, dynamic>> userCancelBooking(int bookingId) async {
    debugPrint('📅 BookingProvider: User cancelling booking $bookingId');

    try {
      final response = await ApiService.cancelUserBooking(bookingId);

      if (response['status'] == 'success') {
        await loadUserBookings();
        return {
          'status': 'success',
          'message': response['message'] ?? 'Booking cancelled successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to cancel booking',
        };
      }
    } catch (e) {
      debugPrint('📅 BookingProvider User Cancel Error: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // PAYMENT METHODS (NEW)
  // ============================================

  Future<Map<String, dynamic>> initiateCodPayment(
      int bookingId, int futsalId) async {
    try {
      final response = await ApiService.confirmCodPayment(
          bookingId); // ✅ Use correct API method

      if (response['status'] == 'success') {
        _updateBookingStatus(
            bookingId,
            (b) => b.copyWith(
                  paymentStatus: 'COMPLETED', // ✅ Should be COMPLETED
                  bookingStatus: 'COMPLETED', // ✅ Should be COMPLETED
                  paymentMethod: 'COD',
                  checkOutTime: DateTime.now(),
                ));
        await loadTodayBookings(futsalId);
        return response;
      }
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Initiate Khalti Payment
  Future<Map<String, dynamic>> initiateKhaltiPayment(int bookingId) async {
    try {
      final response = await ApiService.initiateKhaltiPayment(bookingId);
      print('🔵 PROVIDER RESPONSE: $response');

      // Add status to response
      if (response['paymentUrl'] != null) {
        response['status'] = 'success';
      }
      return response;
    } catch (e) {
      print('❌ PROVIDER ERROR: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

// Verify Khalti Payment
  Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx) async {
    try {
      final response = await ApiService.verifyKhaltiPayment(pidx);
      print('🔵 VERIFY RESPONSE: $response');

      // If payment failed and converted to COD, reload user bookings to show the updated booking
      if (response['convertedToCOD'] == true || response['success'] == false) {
        await loadUserBookings();
      }

      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // OWNER DASHBOARD METHODS
  // ============================================

  // Set current futsal ID
  void setCurrentFutsalId(int futsalId) {
    _currentFutsalId = futsalId;
  }

  // Load today's bookings (for owner)
  Future<void> loadTodayBookings(int futsalId) async {
    debugPrint(
        '📅 BookingProvider: Loading today\'s bookings for futsal $futsalId');

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _currentFutsalId = futsalId;
      final response = await ApiService.getOwnerTodayBookings(futsalId);

      debugPrint('📅 Today bookings response type: ${response.runtimeType}');

      _todayBookings = [];

      if (response is List) {
        debugPrint('📅 Response is a List with ${response.length} items');
        _todayBookings = response
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      _todayBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      debugPrint(
          '📅 BookingProvider: Loaded ${_todayBookings.length} today\'s bookings');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('📅 BookingProvider Error: $e');
    }
  }

  // Load upcoming bookings (for owner)
  Future<void> loadOwnerUpcomingBookings(int futsalId) async {
    debugPrint(
        '📅 BookingProvider: Loading upcoming bookings for futsal $futsalId');

    try {
      final response = await ApiService.getOwnerUpcomingBookings(futsalId);

      debugPrint('📅 Upcoming bookings response type: ${response.runtimeType}');

      _upcomingBookings = [];

      if (response is List) {
        debugPrint('📅 Response is a List with ${response.length} items');
        _upcomingBookings = response
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      _upcomingBookings.sort((a, b) {
        if (a.date != b.date) return a.date.compareTo(b.date);
        return a.startTime.compareTo(b.startTime);
      });

      debugPrint(
          '📅 BookingProvider: Loaded ${_upcomingBookings.length} upcoming bookings');

      notifyListeners();
    } catch (e) {
      debugPrint('📅 BookingProvider Upcoming Error: $e');
    }
  }

// Load month bookings for calendar (for owner)
  Future<void> loadOwnerMonthBookings(int futsalId, DateTime month) async {
    debugPrint(
        '📅 BookingProvider: Loading bookings for ${month.month}/${month.year}');

    try {
      final year = month.year;
      final monthNum = month.month;

      final bookingsData =
          await ApiService.getOwnerMonthBookings(futsalId, year, monthNum);

      debugPrint('📅 Month bookings response length: ${bookingsData.length}');

      // ✅ Convert JSON to Booking objects FIRST
      final List<Booking> bookings = [];
      for (var json in bookingsData) {
        try {
          final booking = Booking.fromJson(json as Map<String, dynamic>);
          bookings.add(booking);
          debugPrint(
              '✅ Parsed booking: id=${booking.id}, date=${booking.date}');
        } catch (e) {
          debugPrint('❌ Failed to parse booking: $e');
        }
      }

      debugPrint('📅 Successfully parsed ${bookings.length} bookings');

      // ✅ Now group by date using Booking objects
      _calendarBookings = {};
      for (var booking in bookings) {
        final date =
            DateTime(booking.date.year, booking.date.month, booking.date.day);
        if (!_calendarBookings.containsKey(date)) {
          _calendarBookings[date] = [];
        }
        _calendarBookings[date]!.add(booking);
      }

      debugPrint(
          '📅 BookingProvider: Loaded ${bookings.length} bookings for month');
      notifyListeners();
    } catch (e) {
      debugPrint('📅 BookingProvider Month Error: $e');
    }
  }

  // Owner cancels booking (complete deletion)
  Future<Map<String, dynamic>> ownerCancelBooking(int bookingId) async {
    try {
      final response = await ApiService.ownerCancelBooking(bookingId);
      if (response['status'] == 'success') {
        if (_currentFutsalId != null) {
          await loadTodayBookings(_currentFutsalId!);
          await loadOwnerUpcomingBookings(_currentFutsalId!);
        }
        return {'status': 'success', 'message': 'Booking cancelled'};
      }
      return {'status': 'error', 'message': response['message'] ?? 'Failed'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // OWNER BOOKING ACTIONS
  // ============================================

  // Check in a customer
  Future<Map<String, dynamic>> checkInCustomer(
      int bookingId, int futsalId) async {
    try {
      final response = await ApiService.checkInBooking(bookingId);
      if (response['status'] == 'success') {
        _updateBookingStatus(
            bookingId,
            (b) => b.copyWith(
                  bookingStatus: 'CONFIRMED',
                  checkInTime: DateTime.now(),
                ));
        await loadTodayBookings(futsalId);
        return response;
      }
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  void _updateBookingStatus(int bookingId, Function(Booking) update) {
    final todayIndex = _todayBookings.indexWhere((b) => b.id == bookingId);
    if (todayIndex != -1) {
      _todayBookings[todayIndex] = update(_todayBookings[todayIndex]);
    }

    final upcomingIndex =
        _upcomingBookings.indexWhere((b) => b.id == bookingId);
    if (upcomingIndex != -1) {
      _upcomingBookings[upcomingIndex] =
          update(_upcomingBookings[upcomingIndex]);
    }

    final pastIndex = _pastBookings.indexWhere((b) => b.id == bookingId);
    if (pastIndex != -1) {
      _pastBookings[pastIndex] = update(_pastBookings[pastIndex]);
    }

    final cancelledIndex =
        _cancelledBookings.indexWhere((b) => b.id == bookingId);
    if (cancelledIndex != -1) {
      _cancelledBookings[cancelledIndex] =
          update(_cancelledBookings[cancelledIndex]);
    }

    for (var date in _calendarBookings.keys) {
      final calendarIndex =
          _calendarBookings[date]?.indexWhere((b) => b.id == bookingId);
      if (calendarIndex != null && calendarIndex != -1) {
        _calendarBookings[date]![calendarIndex] =
            update(_calendarBookings[date]![calendarIndex]);
      }
    }

    final selectedIndex =
        _selectedDateBookings.indexWhere((b) => b.id == bookingId);
    if (selectedIndex != -1) {
      _selectedDateBookings[selectedIndex] =
          update(_selectedDateBookings[selectedIndex]);
    }

    notifyListeners();
  }

  List<Booking> getBookingsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _calendarBookings[normalizedDate] ?? [];
  }

  void selectDate(DateTime date) {
    _selectedDateBookings = getBookingsForDate(date);
    notifyListeners();
  }

  void clearData() {
    _todayBookings = [];
    _upcomingBookings = [];
    _pastBookings = [];
    _cancelledBookings = [];
    _calendarBookings = {};
    _selectedDateBookings = [];
    _currentFutsalId = null;
    error = null;
    notifyListeners();
  }

  Map<String, dynamic> getStatistics() {
    final totalToday = _todayBookings.length;
    final totalUpcoming = _upcomingBookings.length;

    final checkedIn = _todayBookings.where((b) => b.isCheckedIn).length;
    final pending = _todayBookings.where((b) => b.isPending).length;
    final completed = _todayBookings.where((b) => b.isCompleted).length;

    final paid = _todayBookings.where((b) => b.isPaid).length;
    final unpaid =
        _todayBookings.where((b) => !b.isPaid && !b.isCancelled).length;

    return {
      'totalToday': totalToday,
      'totalUpcoming': totalUpcoming,
      'checkedIn': checkedIn,
      'pending': pending,
      'completed': completed,
      'paid': paid,
      'unpaid': unpaid,
      'revenue': todayRevenue,
    };
  }
}
