import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // For Android emulator
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  // For iOS simulator
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );
  // For physical device with your computer's IP
  // static const String baseUrl = 'http://192.168.1.x:5000/api';

  // ============================================
  // AUTH METHODS
  // ============================================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    debugPrint('=' * 50);
    debugPrint('🔵 LOGIN RESPONSE');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Headers: ${response.headers}');
    debugPrint('Raw Body: ${response.body}');
    debugPrint('=' * 50);

    try {
      return json.decode(response.body);
    } catch (e) {
      debugPrint('❌ JSON Parse Error: $e');
      return {
        'status': 'error',
        'message': 'Invalid response from server',
        'raw_response': response.body
      };
    }
  }

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    debugPrint('HTTP Status: ${response.statusCode}');
    debugPrint('HTTP Body: ${response.body}');

    return json.decode(response.body);
  }

  // ============================================
  // BASE HTTP METHODS
  // ============================================
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint('📍 GET: $baseUrl/$endpoint');
    debugPrint(
        '🔑 Token being sent: ${token != null ? 'Present (length: ${token.length})' : 'NULL'}');

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('📥 Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('GET failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint('📍 POST: $baseUrl/$endpoint');
    debugPrint('📤 Data: $data');

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

  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint('📍 PUT: $baseUrl/$endpoint');
    debugPrint('📤 Data: $data');

    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    debugPrint('📥 Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('PUT failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint('📍 PATCH: $baseUrl/$endpoint');
    debugPrint('📤 Data: $data');

    final response = await http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    debugPrint('📥 Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('PATCH failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint('📍 DELETE: $baseUrl/$endpoint');

    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('📥 Response: ${response.statusCode} - ${response.body}');

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

  // ============================================
  // LIST METHODS (for endpoints that return arrays)
  // ============================================
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
      } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
        return jsonResponse['data'] as List;
      } else if (jsonResponse is Map && jsonResponse.containsKey('futsals')) {
        return jsonResponse['futsals'] as List;
      } else if (jsonResponse is Map && jsonResponse.containsKey('bookings')) {
        return jsonResponse['bookings'] as List;
      } else if (jsonResponse is Map && jsonResponse.containsKey('courts')) {
        return jsonResponse['courts'] as List;
      }
      return [];
    } else {
      throw Exception('GET LIST failed: ${response.body}');
    }
  }

  // ============================================
  // FUTSAL SPECIFIC METHODS
  // ============================================
  static Future<List<dynamic>> getMyFutsals() async {
    try {
      debugPrint('=' * 50);
      debugPrint('📍 API: Fetching my futsals');
      debugPrint('📡 URL: $baseUrl/futsals/my');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      debugPrint('🔑 Token exists: ${token != null}');
      if (token == null) {
        debugPrint('❌ No token found! User might not be logged in');
        throw Exception('No authentication token found');
      }

      debugPrint('📤 Making request...');
      final response = await http.get(
        Uri.parse('$baseUrl/futsals/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('✅ Success! Found ${jsonResponse['results']} futsals');
        return jsonResponse['futsals'] ?? [];
      } else {
        debugPrint('❌ Error response: ${response.statusCode}');
        throw Exception('Failed to load futsals: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Network error: $e');
      debugPrint('=' * 50);
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createFutsal(
      Map<String, dynamic> futsalData) async {
    try {
      debugPrint('📍 API: Creating futsal');
      debugPrint('📤 Data: $futsalData');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/futsals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(futsalData),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to create futsal');
      }
    } catch (e) {
      debugPrint('❌ Create futsal error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ============================================
  // COURT SPECIFIC METHODS
  // ============================================
  static Future<List<dynamic>> getCourts(int futsalId) async {
    try {
      final response = await getList('futsals/$futsalId/courts');
      return response;
    } catch (e) {
      debugPrint('❌ Get courts error: $e');
      return [];
    }
  }

  // ============================================
  // BOOKING SPECIFIC METHODS - FOR PLAYERS
  // ============================================

  // GET /api/bookings/my-bookings - Get current user's bookings
  static Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final response = await get('bookings/my-bookings');
      return response;
    } catch (e) {
      debugPrint('❌ Get my bookings error: $e');
      return {'bookings': []};
    }
  }

  // Add to ApiService class
  static Future<Map<String, dynamic>> lockSlot(int slotId) async {
    try {
      debugPrint('📍 API: Locking slot $slotId');
      final response = await post('slots/$slotId/lock', {});
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unlockSlot(int slotId) async {
    try {
      final response = await post('slots/$slotId/unlock', {});
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // POST /api/bookings - Create a new booking
  static Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    try {
      debugPrint('📍 ===== API SERVICE CREATE BOOKING =====');
      debugPrint('📍 Received data: $bookingData');
      debugPrint('📍 Data type: ${bookingData.runtimeType}');
      debugPrint('📍 Slot ID: ${bookingData['slotId']}');
      debugPrint('📍 Slot ID type: ${bookingData['slotId'].runtimeType}');

      final response = await post('bookings', bookingData);

      debugPrint('📍 API Response: $response');
      debugPrint('📍 ===== API SERVICE CREATE BOOKING ENDED =====');
      return response;
    } catch (e) {
      debugPrint('❌ Create booking error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Cancel booking (owner)
  static Future<Map<String, dynamic>> ownerCancelBooking(int bookingId) async {
    return await put('owner/bookings/$bookingId/cancel', {});
  }

  // PUT /api/bookings/:id/cancel - Cancel a booking
// Cancel booking (user)
  static Future<Map<String, dynamic>> cancelUserBooking(int bookingId) async {
    return await put('bookings/$bookingId/cancel', {});
  }

  // ============================================
  // OWNER DASHBOARD METHODS - FOR OWNERS
  // ============================================

  // GET /api/owner/dashboard/stats?futsalId=:id
  static Future<Map<String, dynamic>> getDashboardStats(int futsalId) async {
    try {
      final response = await get('owner/dashboard/stats?futsalId=$futsalId');
      return response;
    } catch (e) {
      debugPrint('❌ Get dashboard stats error: $e');
      return {
        'totalCourts': 0,
        'todayBookings': 0,
        'todayRevenue': 0,
        'pendingApprovals': 0,
      };
    }
  }

  // GET /api/owner/dashboard/today-bookings?futsalId=:id
  static Future<List<dynamic>> getDashboardTodayBookings(int futsalId) async {
    try {
      final response =
          await get('owner/dashboard/today-bookings?futsalId=$futsalId');
      return response['bookings'] ?? [];
    } catch (e) {
      debugPrint('❌ Get dashboard today bookings error: $e');
      return [];
    }
  }

  // GET /api/owner/dashboard/weekly-revenue?futsalId=:id
  static Future<List<dynamic>> getWeeklyRevenue(int futsalId) async {
    try {
      final response =
          await get('owner/dashboard/weekly-revenue?futsalId=$futsalId');
      return response['revenue'] ?? [0, 0, 0, 0, 0, 0, 0];
    } catch (e) {
      debugPrint('❌ Get weekly revenue error: $e');
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  // GET /api/owner/dashboard/peak-hours?futsalId=:id
  static Future<Map<String, dynamic>> getPeakHours(int futsalId) async {
    try {
      final response =
          await get('owner/dashboard/peak-hours?futsalId=$futsalId');
      return response['peakHours'] ?? {};
    } catch (e) {
      debugPrint('❌ Get peak hours error: $e');
      return {};
    }
  }

  // GET /api/owner/bookings/upcoming?futsalId=:id
  static Future<List<dynamic>> getOwnerUpcomingBookings(int futsalId) async {
    try {
      final response = await get('owner/bookings/upcoming?futsalId=$futsalId');
      return response['bookings'] ?? [];
    } catch (e) {
      debugPrint('❌ Get owner upcoming bookings error: $e');
      return [];
    }
  }

  // GET /api/owner/bookings/month?futsalId=:id&year=:year&month=:month
  static Future<List<dynamic>> getOwnerMonthBookings(
      int futsalId, int year, int month) async {
    try {
      final response = await get(
          'owner/bookings/month?futsalId=$futsalId&year=$year&month=$month');
      return response['bookings'] ?? [];
    } catch (e) {
      debugPrint('❌ Get owner month bookings error: $e');
      return [];
    }
  }

  // ============================================
  // OWNER BOOKING ACTIONS
  // ============================================

  // POST /api/owner/bookings/:id/check-in
  static Future<Map<String, dynamic>> checkInBooking(int bookingId) async {
    return await put('owner/bookings/$bookingId/checkin', {});
  }

  // POST /api/owner/bookings/:id/complete
  static Future<Map<String, dynamic>> completeBooking(int bookingId) async {
    return await put('owner/bookings/$bookingId/complete', {});
  }

// Confirm COD payment
  static Future<Map<String, dynamic>> confirmCodPayment(int bookingId) async {
    return await put('owner/bookings/$bookingId/cod-confirm', {});
  }

  // PATCH /api/owner/bookings/:id/payment
  static Future<Map<String, dynamic>> updatePaymentStatus(
      int bookingId, String status) async {
    try {
      final response = await patch('owner/bookings/$bookingId/payment', {
        'paymentStatus': status,
      });
      return response;
    } catch (e) {
      debugPrint('❌ Update payment status error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  //For Admin Dashboard
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await get('/admin/dashboard');
    return response;
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    final response = await get('/admin/users');
    return response;
  }

  Future<Map<String, dynamic>> approveOwner(int userId) async {
    final response = await patch('/admin/users/$userId/approve-owner', {});
    return response;
  }

  Future<Map<String, dynamic>> getPendingFutsals() async {
    final response = await get('/admin/futsals/pending');
    return response;
  }

  Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    final response = await patch('/admin/futsals/$futsalId/approve', {});
    return response;
  }

  Future<Map<String, dynamic>> rejectFutsal(int futsalId) async {
    final response = await patch('/admin/futsals/$futsalId/reject', {});
    return response;
  }

  // Admin bookings
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

// Admin analytics
static Future<Map<String, dynamic>> getAdminAnalytics() async {
  try {
    return await get('admin/analytics');
  } catch (e) {
    return {};
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

    // Add each image file to the request
    for (final imageFile in imageFiles) {
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'images',                          // ← must match backend field name
        bytes,
        filename: imageFile.name,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    debugPrint('📤 Uploading ${imageFiles.length} image(s)...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('📥 Upload response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['urls']);  // ← returns Cloudinary URLs
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  } catch (e) {
    debugPrint('❌ Upload images error: $e');
    return [];
  }
}

static Future<Map<String, dynamic>> verifyEmail(
    String email, String otp) async {
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
// TOURNAMENT METHODS
// ============================================

// POST /api/tournaments
static Future<Map<String, dynamic>> createTournament(Map<String, dynamic> tournamentData) async {
  try {
    debugPrint('📍 API: Creating tournament');
    debugPrint('📤 Data: $tournamentData');
    return await post('tournaments', tournamentData);
  } catch (e) {
    debugPrint('❌ Create tournament error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// GET /api/tournaments
static Future<List<dynamic>> getAllTournaments() async {
  try {
    debugPrint('📍 API: Getting all tournaments');
    final response = await get('tournaments');
    return response['tournaments'] ?? [];
  } catch (e) {
    debugPrint('❌ Get all tournaments error: $e');
    return [];
  }
}

// GET /api/tournaments/my-tournaments
static Future<List<dynamic>> getMyTournaments() async {
  try {
    debugPrint('📍 API: Getting my tournaments');
    final response = await get('tournaments/my-tournaments');
    return response['tournaments'] ?? [];
  } catch (e) {
    debugPrint('❌ Get my tournaments error: $e');
    return [];
  }
}

// GET /api/tournaments/:id
static Future<Map<String, dynamic>> getTournamentById(int tournamentId) async {
  try {
    debugPrint('📍 API: Getting tournament by ID: $tournamentId');
    return await get('tournaments/$tournamentId');
  } catch (e) {
    debugPrint('❌ Get tournament by ID error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// PUT /api/tournaments/:id
static Future<Map<String, dynamic>> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
  try {
    debugPrint('📍 API: Updating tournament $tournamentId');
    debugPrint('📤 Data: $tournamentData');
    return await put('tournaments/$tournamentId', tournamentData);
  } catch (e) {
    debugPrint('❌ Update tournament error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// DELETE /api/tournaments/:id
static Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
  try {
    debugPrint('📍 API: Deleting tournament $tournamentId');
    return await delete('tournaments/$tournamentId');
  } catch (e) {
    debugPrint('❌ Delete tournament error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// PATCH /api/tournaments/:id/status
static Future<Map<String, dynamic>> updateTournamentStatus(int tournamentId, String status) async {
  try {
    debugPrint('📍 API: Updating tournament $tournamentId status to $status');
    return await patch('tournaments/$tournamentId/status', {'status': status});
  } catch (e) {
    debugPrint('❌ Update tournament status error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// ============================================
// TEAM MANAGEMENT METHODS
// ============================================

// POST /api/tournaments/:tournamentId/teams
static Future<Map<String, dynamic>> addTeam(int tournamentId, Map<String, dynamic> teamData) async {
  try {
    debugPrint('📍 API: Adding team to tournament $tournamentId');
    debugPrint('📤 Data: $teamData');
    return await post('tournaments/$tournamentId/teams', teamData);
  } catch (e) {
    debugPrint('❌ Add team error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// GET /api/tournaments/:tournamentId/teams
static Future<List<dynamic>> getTeams(int tournamentId) async {
  try {
    debugPrint('📍 API: Getting teams for tournament $tournamentId');
    final response = await get('tournaments/$tournamentId/teams');
    return response['teams'] ?? [];
  } catch (e) {
    debugPrint('❌ Get teams error: $e');
    return [];
  }
}

// PUT /api/teams/:teamId
static Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> teamData) async {
  try {
    debugPrint('📍 API: Updating team $teamId');
    debugPrint('📤 Data: $teamData');
    return await put('teams/$teamId', teamData);
  } catch (e) {
    debugPrint('❌ Update team error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// DELETE /api/teams/:teamId
static Future<Map<String, dynamic>> deleteTeam(int teamId) async {
  try {
    debugPrint('📍 API: Deleting team $teamId');
    return await delete('teams/$teamId');
  } catch (e) {
    debugPrint('❌ Delete team error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// ============================================
// FIXTURE MANAGEMENT METHODS
// ============================================

// POST /api/tournaments/:tournamentId/generate-fixtures
static Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
  try {
    debugPrint('📍 API: Generating fixtures for tournament $tournamentId');
    return await post('tournaments/$tournamentId/generate-fixtures', {});
  } catch (e) {
    debugPrint('❌ Generate fixtures error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// GET /api/tournaments/:tournamentId/matches
static Future<List<dynamic>> getMatches(int tournamentId) async {
  try {
    debugPrint('📍 API: Getting matches for tournament $tournamentId');
    final response = await get('tournaments/$tournamentId/matches');
    return response['matches'] ?? [];
  } catch (e) {
    debugPrint('❌ Get matches error: $e');
    return [];
  }
}

// PATCH /api/matches/:matchId/score
// In api_service.dart - Update the updateMatchScore method

static Future<Map<String, dynamic>> updateMatchScore(int matchId, Map<String, dynamic> scoreData) async {
  try {
    debugPrint('📍 API: Updating match $matchId score');
    debugPrint('📤 Data: $scoreData');
    
    // Make sure the URL is correct - matches should be plural? Let's try both formats
    final response = await patch('matches/$matchId/score', scoreData);
    
    debugPrint('📍 API Response: $response');
    return response;
  } catch (e) {
    debugPrint('❌ Update match score error: $e');
    
    // Try alternative URL format if the first one fails
    try {
      debugPrint('📍 Trying alternative URL format: tournaments/matches/$matchId/score');
      final response = await patch('tournaments/matches/$matchId/score', scoreData);
      return response;
    } catch (e2) {
      debugPrint('❌ Alternative URL also failed: $e2');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}

// PATCH /api/matches/:matchId/status
static Future<Map<String, dynamic>> updateMatchStatus(int matchId, String status) async {
  try {
    debugPrint('📍 API: Updating match $matchId status to $status');
    return await patch('matches/$matchId/status', {'status': status});
  } catch (e) {
    debugPrint('❌ Update match status error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

// ============================================
// STATISTICS METHODS
// ============================================

// GET /api/tournaments/:tournamentId/standings
static Future<List<dynamic>> getTournamentStandings(int tournamentId) async {
  try {
    debugPrint('📍 API: Getting standings for tournament $tournamentId');
    final response = await get('tournaments/$tournamentId/standings');
    return response['standings'] ?? [];
  } catch (e) {
    debugPrint('❌ Get tournament standings error: $e');
    return [];
  }
}

}
