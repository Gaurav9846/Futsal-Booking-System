import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import 'dart:html' as html;

class PaymentVerifyPage extends StatefulWidget {
  const PaymentVerifyPage({super.key});

  @override
  State<PaymentVerifyPage> createState() => _PaymentVerifyPageState();
}

class _PaymentVerifyPageState extends State<PaymentVerifyPage> {
  bool _isVerifying = true;
  bool _success = false;
  String _message = '';

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

    if (pidx == null) {
      setState(() {
        _isVerifying = false;
        _success = false;
        _message = 'No payment reference found.';
      });
      return;
    }

    try {
      final response = await PaymentService.verifyPayment(pidx);

      if (!mounted) return;

      if (response['status'] == 'success' && response['paymentStatus'] == 'COMPLETED') {
        setState(() {
          _isVerifying = false;
          _success = true;
          _message = 'Payment successful! Your booking is confirmed.';
        });

        // Redirect to home after short delay
        Future.delayed(const Duration(seconds: 2), () {
          html.window.location.href = '/player/home'; // or your route
        });
      } else {
        setState(() {
          _isVerifying = false;
          _success = false;
          _message = response['message'] ?? 'Payment verification failed.';
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
        title: const Text('Verifying Payment'),
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
                    _success ? Icons.check_circle_outline : Icons.error_outline,
                    color: _success ? Colors.green : Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      html.window.location.href = '/player/home';
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