import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class GhostPaymentScreen extends StatefulWidget {
  final double amount;
  final String serviceName;
  final String providerId;
  final double latitude;
  final double longitude;

  const GhostPaymentScreen({
    super.key,
    required this.amount,
    required this.serviceName,
    required this.providerId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<GhostPaymentScreen> createState() => _GhostPaymentScreenState();
}

class _GhostPaymentScreenState extends State<GhostPaymentScreen> {
  late Razorpay _razorpay;

  static const Color primaryColor = Color(0xFF33365D);

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    // Razorpay listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Launch payment automatically
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchRazorpay());
  }

  void _launchRazorpay() {
    var options = {
      'key': 'rzp_test_SGMtKOLbD6h9TD',
      'amount': (widget.amount * 100).toInt(),
      'name': 'NearFix',
      'description': widget.serviceName,
      'prefill': {
        'contact': '9876543210',
        'email': 'customer@example.com'
      },
      'retry': {'enabled': false},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
      _handleError(PaymentFailureResponse(0, "Gateway Error", {}));
    }
  }

  // PAYMENT SUCCESS
  void _handleSuccess(PaymentSuccessResponse response) {
    if (mounted) {
      Navigator.pop(context, {
        "payment_id": response.paymentId,
        "provider_id": widget.providerId,
        "latitude": widget.latitude,
        "longitude": widget.longitude
      });
    }
  }

  // PAYMENT FAILED / CANCELLED
  void _handleError(PaymentFailureResponse response) {
    if (mounted) {
      Navigator.pop(context, null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment Cancelled or Failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              "Connecting to Secure Gateway...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}