import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';

class KhaltiPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String pidx;

  const KhaltiPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.pidx,
  });

  @override
  State<KhaltiPaymentScreen> createState() => _KhaltiPaymentScreenState();
}

class _KhaltiPaymentScreenState extends State<KhaltiPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            // 🔥 Detect Khalti redirect
            if (request.url.contains('payment-verify')) {
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
    final response = await PaymentService.verifyPayment(widget.pidx);
    if (!mounted) return;

    if (response['status'] == 'success') {
      Navigator.pop(context, true); // success
    } else {
      Navigator.pop(context, false); // failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khalti Payment')),
      body: WebViewWidget(controller: _controller),
    );
  }
}