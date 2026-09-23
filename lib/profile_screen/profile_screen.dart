import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearfix/address_screen/address_screen.dart';
import 'package:nearfix/profile_screen/edit_profile.dart';
import 'package:nearfix/profile_screen/help_support_screen.dart';
import '../app_config.dart'; // still used for the profile image URL
import '../supabase_client.dart';
import '../authentication/sign_in.dart';

// ── Palette ───────────────────────────────────────────────────────
const Color _primary = Color(0xFF33365D);
const Color _surface = Color(0xFFF4F5FB);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  String _userName = "Guest User";
  int? _userId;
  String? _profilePic;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final String _baseUrl =
      "${AppConfig.baseUrl}/";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, .04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _loadUserData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userName = prefs.getString('userName') ?? "Guest User";
      _userId = prefs.getInt('user_id');
      _profilePic = prefs.getString('profile_pic');
    });
    if (_isLoggedIn && _userId != null) _fetchLatestProfileFromDB();
    _animCtrl.forward(from: 0);
  }

  Future<void> _fetchLatestProfileFromDB() async {
    try {
      final data = await supabase
          .from('users')
          .select('name, email, phone, profile_image')
          .eq('id', _userId as Object)
          .maybeSingle();

      if (data != null) {
        String latestPic = data['profile_image'] ?? "";
        setState(() {
          _profilePic = latestPic;
          _userName = data['name'] ?? _userName;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_pic', latestPic);
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Only remove login/user data — keeps 'onboarding_seen' intact
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userName');
    await prefs.remove('user_id');
    await prefs.remove('profile_pic');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E1F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            // Icon + text row (horizontal — more compact)
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1C3A),
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Are you sure you want to sign out?",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B9DB8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E1F0)),
                      ),
                      child: const Center(
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B6D88),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Yes, Logout",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _sectionLabel("Account Settings"),
                    const SizedBox(height: 10),
                    _tile(
                      icon: Icons.person_rounded,
                      title: "Edit Profile",
                      subtitle: "Update your name, photo & info",
                      iconBg: const Color(0xFFEEEDFD),
                      iconColor: const Color(0xFF6366F1),
                      onTap: () {
                        if (_isLoggedIn && _userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(userId: _userId!),
                            ),
                          ).then((value) {
                            if (value == true) _loadUserData();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please Login First")),
                          );
                        }
                      },
                    ),
                    _tile(
                      icon: Icons.location_on_rounded,
                      title: "Saved Addresses",
                      subtitle: "Manage your delivery locations",
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel("Support"),
                    const SizedBox(height: 10),
                    _tile(
                      icon: Icons.help_center_rounded,
                      title: "Help & Support",
                      subtitle: "FAQs, contact & feedback",
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF22C55E),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoggedIn
                        ? _tile(
                            icon: Icons.logout_rounded,
                            title: "Logout",
                            subtitle: "Sign out of your account",
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFEF4444),
                            isLogout: true,
                            onTap: _showLogoutDialog,
                          )
                        : _tile(
                            icon: Icons.login_rounded,
                            title: "Login / Sign Up",
                            subtitle: "Access your account",
                            iconBg: const Color(0xFFEAEBF5),
                            iconColor: _primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ).then((_) => _loadUserData()),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;

    ImageProvider profileImage;
    if (_profilePic != null && _profilePic!.isNotEmpty) {
      final url = _profilePic!.startsWith('http')
          ? _profilePic!
          : "$_baseUrl$_profilePic";
      profileImage = NetworkImage(
        "$url?v=${DateTime.now().millisecondsSinceEpoch}",
      );
    } else {
      profileImage = const AssetImage('assets/pf.png');
    }

    return Stack(
      children: [
        // Dark gradient banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1C1F3E), Color(0xFF33365D), Color(0xFF282B52)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: Stack(
            children: [
              // Arc decoration
              Positioned.fill(child: CustomPaint(painter: _ArcPainter())),
              // Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x406366F1),
                            width: 3,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF33365D),
                        backgroundImage: profileImage,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Name + badge on the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLoggedIn
                                    ? Icons.workspace_premium_rounded
                                    : Icons.person_outline_rounded,
                                color: _isLoggedIn
                                    ? const Color(0xFFFFBB3B)
                                    : const Color(0xAAFFFFFF),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isLoggedIn ? "Gold Member" : "Guest",
                                style: TextStyle(
                                  color: _isLoggedIn
                                      ? const Color(0xFFFFBB3B)
                                      : const Color(0xAAFFFFFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section label ────────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9B9DB8),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Menu tile ────────────────────────────────────────────────────
  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEBF5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isLogout
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1A1C3A),
                          letterSpacing: -.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFAAABC0),
                          fontWeight: FontWeight.w500,
                          letterSpacing: .1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Styled arrow — gradient circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLogout
                          ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
                          : [const Color(0xFFEAEBF5), const Color(0xFFDDDEF0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLogout
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFD5D6EA),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isLogout ? const Color(0xFFEF4444) : _primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Arc decoration painter ────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0FFFFFFF);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * .88, size.height * .15),
        40.0 + i * 30,
        p1,
      );
    }
    final p2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = const Color(0x1A6366F1);
    final path = Path()
      ..moveTo(0, size.height * .8)
      ..quadraticBezierTo(
        size.width * .4,
        size.height * .5,
        size.width,
        size.height * .7,
      );
    canvas.drawPath(path, p2);
  }

  @override
  bool shouldRepaint(_) => false;
}
