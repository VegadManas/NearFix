import 'package:flutter/material.dart';

import '../supabase_client.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool isLoading = false;
  bool _obscure = true;

  Future<void> _updatePassword() async {
    setState(() => isLoading = true);

    try {
      final data = await supabase.rpc('reset_user_password', params: {
        'p_email': widget.email,
        'p_new_password': passCtrl.text.trim(),
      });

      if (data['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated! Please login."), backgroundColor: Colors.green),
        );
        // Go back to Login and clear the stack
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: const Color(0xFF33365D)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Password", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1C3A))),
              const SizedBox(height: 8),
              const Text("Set a strong password to protect your account.", style: TextStyle(color: Color(0xFF9B9DB8))),
              const SizedBox(height: 32),

              _buildInputField("NEW PASSWORD", passCtrl, true),
              const SizedBox(height: 20),
              _buildInputField("CONFIRM PASSWORD", confirmPassCtrl, true, isConfirm: true),

              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, bool isPass, {bool isConfirm = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEBF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9B9DB8))),
          TextFormField(
            controller: ctrl,
            obscureText: _obscure,
            validator: (v) {
              if (v == null || v.length < 6) return "Min 6 characters";
              if (isConfirm && v != passCtrl.text) return "Passwords do not match";
              return null;
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          if (_formKey.currentState!.validate()) _updatePassword();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF33365D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Reset Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}