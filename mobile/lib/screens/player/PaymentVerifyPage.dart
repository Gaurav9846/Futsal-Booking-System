import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'dart:html' as html;

class PaymentVerifyPage extends StatefulWidget {
  const PaymentVerifyPage({super.key});

  @override
  State<PaymentVerifyPage> createState() => _PaymentVerifyPageState();
}

class _PaymentVerifyPageState extends State<PaymentVerifyPage> {
  bool _isVerifying = true;
  bool _success = false;
  bool _convertedToCOD = false;
  String _message = '';
  int? _bookingId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _verifyPaymentFromUrl();
    } else {
      setState(() {
        _isVerifying = false;
        _message = 'This page is for Web verification only.';
      });
    }
  }

  Future<void> _verifyPaymentFromUrl() async {
    final uri = Uri.base;
    final pidx = uri.queryParameters['pidx'];
    final bookingId = uri.queryParameters['booking_id'];
    final convertedToCOD = uri.queryParameters['converted_to_cod'] == 'true';

    if (convertedToCOD) {
      setState(() {
        _isVerifying = false;
        _success = false;
        _convertedToCOD = true;
        _message = 'Payment failed. Your booking has been converted to Cash on Delivery. Please pay at the venue.';
        _bookingId = bookingId != null ? int.tryParse(bookingId) : null;
      });
      return;
    }

    if (pidx == null) {
      setState(() {
        _isVerifying = false;
        _success = false;
        _message = 'No payment reference found.';
      });
      return;
    }

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final response = await bookingProvider.verifyKhaltiPayment(pidx);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _isVerifying = false;
          _success = true;
          _message = 'Payment successful! Your booking is confirmed.';
          _bookingId = response['bookingId'];
        });
      } else if (response['convertedToCOD'] == true) {
        setState(() {
          _isVerifying = false;
          _success = false;
          _convertedToCOD = true;
          _message = response['message'] ?? 'Payment failed. Booking converted to COD. Please pay at venue.';
          _bookingId = response['bookingId'];
        });
      } else {
        setState(() {
          _isVerifying = false;
          _success = false;
          _message = response['message'] ?? 'Payment verification failed.';
          _bookingId = response['bookingId'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _success = false;
        _message = 'Error verifying payment: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: _isVerifying
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Verifying your payment...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _success 
                        ? Icons.check_circle_outline 
                        : (_convertedToCOD ? Icons.payment : Icons.error_outline),
                    color: _success 
                        ? Colors.green 
                        : (_convertedToCOD ? Colors.orange : Colors.red),
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (kIsWeb) {
                        html.window.location.href = '/player/home';
                      } else {
                        Navigator.pushReplacementNamed(context, '/player/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
      ),
    );
  }
}