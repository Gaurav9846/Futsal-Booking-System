import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/booking_provider.dart';

class KhaltiPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String pidx;
  final int bookingId; // Add bookingId to update status

  const KhaltiPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.pidx,
    required this.bookingId, // Now required
  });

  @override
  State<KhaltiPaymentScreen> createState() => _KhaltiPaymentScreenState();
}

class _KhaltiPaymentScreenState extends State<KhaltiPaymentScreen> {
  late final WebViewController _controller;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            if (request.url.contains('callback') || 
                request.url.contains('payment-status') ||
                request.url.contains('success')) {
              await _verifyPayment();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _verifyPayment() async {
    if (_isVerifying) return;
    _isVerifying = true;

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final response = await bookingProvider.verifyKhaltiPayment(widget.pidx);
      
      if (!mounted) return;

      if (response['success'] == true || response['status'] == 'success') {
        // Also update the booking status locally
        await bookingProvider.loadUserBookings();
        Navigator.pop(context, true); // success
      } else {
        Navigator.pop(context, false); // failed
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context, false); // failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khalti Payment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}