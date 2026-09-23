import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearfix/home_screen/home_screen.dart';

import '../supabase_client.dart';

const Color _primary = Color(0xFF33365D);
const Color _bg = Color(0xFFF4F5FB);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  bool isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final data = await supabase.rpc('signup_user', params: {
        'p_name': _nameController.text.trim(),
        'p_email': _emailController.text.trim(),
        'p_phone': _phoneController.text.trim(),
        'p_password': _passController.text.trim(),
      });
      if (data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);
        await prefs.setInt("user_id", int.parse(data["user_id"].toString()));
        await prefs.setString("userName", _nameController.text.trim());
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Account Created!"),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        _showError(data["message"] ?? "Registration failed");
      }
    } catch (e) {
      _showError("Connection error. Check your internet.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Compact header ───────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topPad + 10, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1C1F3E), Color(0xFF33365D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Join NearFix today",
                          style: TextStyle(
                            color: Color(0xAAFFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  children: [
                    _buildInput(
                      label: "FULL NAME",
                      hint: "Enter your full name",
                      icon: Icons.person_rounded,
                      controller: _nameController,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Name is required" : null,
                    ),
                    _buildInput(
                      label: "EMAIL",
                      hint: "test123@example.com",
                      icon: Icons.email_rounded,
                      controller: _emailController,
                      validator: (v) => (v != null && v.contains('@'))
                          ? null
                          : "Enter a valid email",
                    ),
                    _buildInput(
                      label: "PHONE",
                      hint: "1234567890",
                      icon: Icons.phone_rounded,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v != null && v.length >= 10)
                          ? null
                          : "Enter a valid phone number",
                    ),
                    _buildInput(
                      label: "PASSWORD",
                      hint: "••••••••",
                      icon: _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      controller: _passController,
                      isPassword: true,
                      onIconTap: () => setState(() => _obscure = !_obscure),
                      validator: (v) => (v != null && v.length >= 6)
                          ? null
                          : "Min 6 characters required",
                    ),
                    const SizedBox(height: 48),
                    // Button
                    GestureDetector(
                      onTap: isLoading ? null : signUpUser,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF1C1F3E),
                                    Color(0xFF4A4D7A),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: isLoading ? const Color(0xFFCCCDDF) : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isLoading
                              ? []
                              : const [
                                  BoxShadow(
                                    color: Color(0x3333365D),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -.2,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Color(0xFF9B9DB8),
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    VoidCallback? onIconTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEBF5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9B9DB8),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: controller,
              obscureText: isPassword && _obscure,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C3A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFCCCDDF),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: GestureDetector(
                  onTap: onIconTap,
                  child: Icon(icon, size: 18, color: const Color(0xFFCCCDDF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
