import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearfix/authentication/reset_password_screen.dart';

import '../supabase_client.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String serverOtp; // The "Debug" OTP we got from PHP

  const OtpVerificationScreen({super.key, required this.email, required this.serverOtp});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());

  Future<void> _verifyOtp() async {
    String enteredOtp = _controllers.map((c) => c.text).join();

    // 1. Basic validation
    if (enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all 6 digits")),
      );
      return;
    }

    try {
      final data = await supabase.rpc('verify_reset_otp', params: {
        'p_email': widget.email,
        'p_otp': enteredOtp,
      });

      debugPrint("SERVER RESPONSE: $data");

      if (data['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement( // Use pushReplacement so they can't go back to OTP
            context,
            MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: widget.email))
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Verification failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("CONNECTION ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not connect to server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: const Color(0xFF33365D)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.security_rounded, size: 80, color: Color(0xFF33365D)),
            const SizedBox(height: 24),
            const Text("Verification Code", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text("Enter the 6-digit code sent to\n${widget.email}", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9B9DB8))),
            const SizedBox(height: 32),

            // 6-Digit Input Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33365D),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Verify Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      child: TextFormField(
        controller: _controllers[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
          if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
        },
      ),
    );
  }
}