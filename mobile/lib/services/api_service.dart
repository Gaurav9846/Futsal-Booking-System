import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ============================================
  // BASE URL CONFIGURATION
  // ============================================
  // For Android emulator: http://10.0.2.2:5000/api
  // For iOS simulator: http://localhost:5000/api
  // For physical device: http://192.168.x.x:5000/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    return await post('auth/verify-email', {'email': email, 'otp': otp});
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    return await post('auth/resend-otp', {'email': email});
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await post('auth/forgot-password', {'email': email});
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    return await post('auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  // ============================================
  // BASE HTTP METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('GET failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('POST failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('PUT failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('PATCH failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      } else {
        return {'status': 'success', 'message': 'Deleted successfully'};
      }
    } else {
      throw Exception('DELETE failed: ${response.body}');
    }
  }

  static Future<List<dynamic>> getList(String endpoint) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  debugPrint('📍 GET LIST: $baseUrl/$endpoint');

  final response = await http.get(
    Uri.parse('$baseUrl/$endpoint'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  debugPrint('📥 Response: ${response.statusCode} - ${response.body}');

  if (response.statusCode == 200) {
    final dynamic jsonResponse = json.decode(response.body);
    
    // Handle different response formats
    if (jsonResponse is List) {
      return jsonResponse;
    } 
    // Handle { "futsals": [...] } format
    else if (jsonResponse is Map && jsonResponse.containsKey('futsals')) {
      return jsonResponse['futsals'] as List;
    }
    // Handle { "data": [...] } format
    else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
      return jsonResponse['data'] as List;
    }
    // Handle { "bookings": [...] } format
    else if (jsonResponse is Map && jsonResponse.containsKey('bookings')) {
      return jsonResponse['bookings'] as List;
    }
    // Handle { "courts": [...] } format
    else if (jsonResponse is Map && jsonResponse.containsKey('courts')) {
      return jsonResponse['courts'] as List;
    }
    // Handle { "slots": [...] } format
    else if (jsonResponse is Map && jsonResponse.containsKey('slots')) {
      return jsonResponse['slots'] as List;
    }
    return [];
  } else {
    throw Exception('GET LIST failed: ${response.body}');
  }
}

  // ============================================
  // SLOT METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> lockSlot(int slotId) async {
    try {
      return await post('slots/$slotId/lock', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unlockSlot(int slotId) async {
    try {
      return await post('slots/$slotId/unlock', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // FUTSAL METHODS
  // ============================================
  
  static Future<List<dynamic>> getMyFutsals() async {
    try {
      final response = await get('futsals/my');
      return response['futsals'] ?? [];
    } catch (e) {
      debugPrint('❌ Get my futsals error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createFutsal(Map<String, dynamic> futsalData) async {
    return await post('futsals', futsalData);
  }

  static Future<List<dynamic>> getCourts(int futsalId) async {
    try {
      return await getList('futsals/$futsalId/courts');
    } catch (e) {
      debugPrint('❌ Get courts error: $e');
      return [];
    }
  }

  // ============================================
  // PLAYER BOOKING METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getMyBookings() async {
    try {
      return await get('bookings/my-bookings');
    } catch (e) {
      debugPrint('❌ Get my bookings error: $e');
      return {'bookings': []};
    }
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    return await post('bookings', bookingData);
  }

  static Future<Map<String, dynamic>> cancelUserBooking(int bookingId) async {
    return await put('bookings/$bookingId/cancel', {});
  }

  // ============================================
  // PAYMENT METHODS
  // ============================================

  // ============================================
// COD PAYMENT METHOD
// ============================================

// For COD - Owner marks as paid
static Future<Map<String, dynamic>> confirmCodPayment(int bookingId) async {
  try {
    return await put('owner/bookings/$bookingId/cod-confirm', {});
  } catch (e) {
    debugPrint('❌ Confirm COD payment error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

static Future<Map<String, dynamic>> initiateKhaltiPayment(int bookingId) async {
  try {
    final response = await post('bookings/payment/initiate', {
      'bookingId': bookingId,
      'paymentMethod': 'KHALTI',
    });
    print('🔵 API SERVICE RESPONSE: $response'); // ✅ ADD THIS
    return response;
  } catch (e) {
    print('❌ API SERVICE ERROR: $e'); // ✅ ADD THIS
    return {'status': 'error', 'message': e.toString()};
  }
}

  static Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx) async {
    return await post('bookings/payment/verify', {'pidx': pidx});
  }

  // ============================================
  // OWNER BOOKING ACTIONS
  // ============================================
  
  static Future<Map<String, dynamic>> checkInBooking(int bookingId) async {
    return await put('bookings/owner/$bookingId/checkin', {});
  }

  static Future<Map<String, dynamic>> ownerCancelBooking(int bookingId) async {
    return await delete('bookings/owner/$bookingId/cancel');
  }

  // ============================================
  // OWNER DASHBOARD METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getDashboardStats(int futsalId) async {
    try {
      return await get('owner/dashboard/stats?futsalId=$futsalId');
    } catch (e) {
      return {
        'totalCourts': 0,
        'todayBookings': 0,
        'todayRevenue': 0,
        'pendingApprovals': 0,
      };
    }
  }

// GET /api/bookings/owner/today - Get today's bookings
static Future<List<dynamic>> getOwnerTodayBookings(int futsalId) async {
  try {
    final response = await get('bookings/owner/today?futsalId=$futsalId');
    debugPrint('🔵 Today bookings raw response: $response');
    // response is Map<String, dynamic>, extract the bookings list
    if (response is Map && response.containsKey('bookings')) {
      return response['bookings'] as List;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Get owner today bookings error: $e');
    return [];
  }
}

// GET /api/bookings/owner/upcoming - Get upcoming bookings
static Future<List<dynamic>> getOwnerUpcomingBookings(int futsalId) async {
  try {
    final response = await get('bookings/owner/upcoming?futsalId=$futsalId');
    if (response is Map && response.containsKey('bookings')) {
      return response['bookings'] as List;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Get owner upcoming bookings error: $e');
    return [];
  }
}

// GET /api/bookings/owner/month/:year/:month - Get month bookings
static Future<List<dynamic>> getOwnerMonthBookings(int futsalId, int year, int month) async {
  try {
    final response = await get('bookings/owner/month/$year/$month?futsalId=$futsalId');
    debugPrint('🔵 Month bookings raw response: $response');
    
    if (response is Map && response.containsKey('bookings')) {
      final bookings = response['bookings'] as List;
      debugPrint('🔵 Found ${bookings.length} bookings');
      return bookings;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Get owner month bookings error: $e');
    return [];
  }
}

// GET /api/bookings/owner/all - Get all bookings with filters
static Future<List<dynamic>> getOwnerBookings({
  required int futsalId,
  String? status,
  int? courtId,
  String? date,
}) async {
  try {
    String url = 'bookings/owner/all?futsalId=$futsalId';
    if (status != null) url += '&status=$status';
    if (courtId != null) url += '&courtId=$courtId';
    if (date != null) url += '&date=$date';
    
    final response = await get(url);
    if (response is Map && response.containsKey('bookings')) {
      return response['bookings'] as List;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Get owner bookings error: $e');
    return [];
  }
}
  static Future<List<dynamic>> getWeeklyRevenue(int futsalId) async {
    try {
      final response = await get('owner/dashboard/weekly-revenue?futsalId=$futsalId');
      return response['revenue'] ?? [0, 0, 0, 0, 0, 0, 0];
    } catch (e) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  static Future<Map<String, dynamic>> getPeakHours(int futsalId) async {
    try {
      final response = await get('owner/dashboard/peak-hours?futsalId=$futsalId');
      return response['peakHours'] ?? {};
    } catch (e) {
      return {};
    }
  }

  // ============================================
  // BLOCK PLAYER METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getBlockedPlayers({required int futsalId}) async {
    try {
      return await get('owner/blocks?futsalId=$futsalId');
    } catch (e) {
      return {'blocks': []};
    }
  }

  static Future<Map<String, dynamic>> blockPlayer({
    required int playerId,
    required int futsalId,
    String? reason,
  }) async {
    return await post('owner/blocks', {
      'playerId': playerId,
      'futsalId': futsalId,
      'reason': reason,
    });
  }

  static Future<Map<String, dynamic>> unblockPlayer({
    required int playerId,
    required int futsalId,
  }) async {
    return await delete('owner/blocks/$playerId?futsalId=$futsalId');
  }

  static Future<Map<String, dynamic>> checkIsBlocked({
    required int playerId,
    required int futsalId,
  }) async {
    try {
      return await get('owner/blocks/check/$playerId?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'isBlocked': false};
    }
  }

  // ============================================
  // ADMIN METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    return await get('admin/dashboard');
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    return await get('admin/users');
  }

  static Future<Map<String, dynamic>> approveOwner(int userId) async {
    return await patch('admin/users/$userId/approve-owner', {});
  }

  static Future<Map<String, dynamic>> getPendingFutsals() async {
    return await get('admin/futsals/pending');
  }

  static Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    return await patch('admin/futsals/$futsalId/approve', {});
  }

  static Future<Map<String, dynamic>> rejectFutsal(int futsalId) async {
    return await patch('admin/futsals/$futsalId/reject', {});
  }

  static Future<Map<String, dynamic>> getAdminBookings({
    String status = 'ALL',
    String? from,
    String? to,
    int page = 1,
  }) async {
    try {
      String endpoint = 'admin/bookings?status=$status&page=$page';
      if (from != null && to != null) {
        endpoint += '&from=$from&to=$to';
      }
      return await get(endpoint);
    } catch (e) {
      return {'bookings': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      return await get('admin/analytics');
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateAdminProfile(Map<String, dynamic> data) async {
    return await put('admin/profile', data);
  }

  // ============================================
  // SYSTEM SETTINGS METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      return await get('admin/settings');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> data) async {
    return await put('admin/settings', data);
  }

  // ============================================
  // TOURNAMENT METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> createTournament(Map<String, dynamic> tournamentData) async {
    return await post('tournaments', tournamentData);
  }

  static Future<List<dynamic>> getAllTournaments() async {
    try {
      final response = await get('tournaments');
      return response['tournaments'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMyTournaments() async {
    try {
      final response = await get('tournaments/my-tournaments');
      return response['tournaments'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTournamentById(int tournamentId) async {
    return await get('tournaments/$tournamentId');
  }

  static Future<Map<String, dynamic>> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
    return await put('tournaments/$tournamentId', tournamentData);
  }

  static Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
    return await delete('tournaments/$tournamentId');
  }

  static Future<Map<String, dynamic>> updateTournamentStatus(int tournamentId, String status) async {
    return await patch('tournaments/$tournamentId/status', {'status': status});
  }

  // ============================================
  // TEAM METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> addTeam(int tournamentId, Map<String, dynamic> teamData) async {
    return await post('tournaments/$tournamentId/teams', teamData);
  }

  static Future<List<dynamic>> getTeams(int tournamentId) async {
    try {
      final response = await get('tournaments/$tournamentId/teams');
      return response['teams'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    return await put('teams/$teamId', teamData);
  }

  static Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    return await delete('teams/$teamId');
  }

  // ============================================
  // MATCH / FIXTURE METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
    return await post('tournaments/$tournamentId/generate-fixtures', {});
  }

  static Future<List<dynamic>> getMatches(int tournamentId) async {
    try {
      final response = await get('tournaments/$tournamentId/matches');
      return response['matches'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateMatchScore(int matchId, Map<String, dynamic> scoreData) async {
    return await patch('matches/$matchId/score', scoreData);
  }

  static Future<Map<String, dynamic>> updateMatchStatus(int matchId, String status) async {
    return await patch('matches/$matchId/status', {'status': status});
  }

  static Future<List<dynamic>> getTournamentStandings(int tournamentId) async {
    try {
      final response = await get('tournaments/$tournamentId/standings');
      return response['standings'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // IMAGE UPLOAD
  // ============================================
  
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('$baseUrl/upload/images');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['urls']);
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Upload images error: $e');
      return [];
    }
  }
}