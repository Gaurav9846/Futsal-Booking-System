import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class PaymentService {

  /// Mobile: Create booking + initiate Khalti payment
  static Future<Map<String, dynamic>> initiateKhaltiPayment(
      int slotId, int duration) async {
    try {
      debugPrint('📍 Initiating Khalti payment for slot $slotId');

      // 1️⃣ Create booking
      final bookingResponse = await ApiService.post('bookings', {
        'slotId': slotId,
        'paymentMethod': 'KHALTI',
        'duration': duration,
      });

      if (bookingResponse['status'] == 'success' &&
          bookingResponse['booking']?['id'] != null) {

        final bookingId = bookingResponse['booking']['id'];

        // 2️⃣ Initiate Khalti payment
        final paymentResponse = await ApiService.post(
          'bookings/$bookingId/payment/initiate',
          {'paymentMethod': 'KHALTI'},
        );

        return {
          ...paymentResponse,
          'bookingId': bookingId,
        };
      }

      return {
        'status': 'error',
        'message': 'Failed to create booking',
      };

    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// Web: Verify payment using pidx
  static Future<Map<String, dynamic>> verifyPayment(String pidx) async {
    try {
      final response =
          await ApiService.post('payments/verify', {'pidx': pidx});

      // Normalize response for PaymentVerifyPage
      if (response['status'] == 'success') {
        return {
          'status': 'success',
          'paymentStatus': 'COMPLETED',
        };
      } else {
        return {
          'status': 'failed',
          'message': response['message'] ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      return {
        'status': 'failed',
        'message': 'Error verifying payment: $e',
      };
    }
  }
}