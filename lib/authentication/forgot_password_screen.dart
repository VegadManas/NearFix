import 'package:flutter/material.dart';

import '../supabase_client.dart';
import 'otp_verfication_screen.dart';

const Color _primary = Color(0xFF33365D);
const Color _bg = Color(0xFFF4F5FB);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> sendResetLink() async {
    setState(() => isLoading = true);

    try {
      final data = await supabase.rpc('generate_reset_otp', params: {
        'p_email': emailCtrl.text.trim(),
      });

      if (data['success'] == true) {
        if (!mounted) return;

        // Success: Navigate to OTP Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: emailCtrl.text.trim(),
              // We pass the OTP from the debug response so you can test easily
              serverOtp: data['otp_debug'].toString(),
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "OTP sent successfully!"),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Email not found"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection error. Check your internet."),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.lock_reset_rounded, size: 60, color: _primary),
              const SizedBox(height: 24),
              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1C3A),
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Don't worry! Please enter the email address linked with your account.",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9B9DB8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Email Input
              _buildEmailInput(),

              const SizedBox(height: 40),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEBF5), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "EMAIL ADDRESS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9B9DB8),
                letterSpacing: 1.2,
              ),
            ),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? "Enter a valid email" : null,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C3A)),
              decoration: const InputDecoration(
                hintText: "example@gmail.com",
                hintStyle: TextStyle(color: Color(0xFFCCCDDF), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: isLoading ? null : () {
        if (_formKey.currentState!.validate()) sendResetLink();
      },
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: isLoading ? null : const LinearGradient(
            colors: [Color(0xFF1C1F3E), Color(0xFF4A4D7A)],
          ),
          color: isLoading ? const Color(0xFFCCCDDF) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isLoading ? [] : [
            BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: isLoading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : const Center(
          child: Text(
            "Send Reset Code",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}