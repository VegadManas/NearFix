import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_config.dart'; // kept for legacy (pre-migration) image paths
import '../supabase_client.dart';

const Color _primary = Color(0xFF33365D);
const Color _bg = Color(0xFFF4F5FB);

class EditProfileScreen extends StatefulWidget {
  final int userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageExt;
  String? _networkImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('users')
          .select('name, email, phone, profile_image')
          .eq('id', widget.userId)
          .maybeSingle();
      if (data != null) {
        setState(() {
          nameCtrl.text = data['name'] ?? "";
          emailCtrl.text = data['email'] ?? "";
          phoneCtrl.text = data['phone'] ?? "";
          _networkImageUrl = data['profile_image'];
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageExt =
            'jpg'; // pickedFile.path is a blob: URL on web, not a real extension
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isLoading = true);
    try {
      String? uploadedImageUrl;

      // Upload the new photo to Supabase Storage first, if one was picked
      if (_imageBytes != null) {
        final ext = _imageExt ?? 'jpg';
        final fileName =
            'user_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await supabase.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        uploadedImageUrl = supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);
      }

      await supabase
          .from('users')
          .update({
            'name': nameCtrl.text.trim(),
            'email': emailCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            if (uploadedImageUrl != null) 'profile_image': uploadedImageUrl,
          })
          .eq('id', widget.userId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nameCtrl.text.trim());
      if (uploadedImageUrl != null) {
        await prefs.setString('profile_pic', uploadedImageUrl);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't save changes: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    ImageProvider? img;
    if (_imageBytes != null) {
      img = MemoryImage(_imageBytes!);
    } else if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty) {
      // New uploads are full Supabase Storage URLs; old rows may still have
      // a relative "uploads/..." path from before the migration.
      img = NetworkImage(
        _networkImageUrl!.startsWith('http')
            ? _networkImageUrl!
            : "${AppConfig.baseUrl}/$_networkImageUrl",
      );
    } else {
      img =
          null; // No photo yet — show a fallback icon instead of a broken image
    }

    return Scaffold(
      backgroundColor: _bg,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // ── Header ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1C1F3E), Color(0xFF33365D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Back + title row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0x33FFFFFF),
                                ),
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
                                "Edit Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.3,
                                ),
                              ),
                              Text(
                                "Update your personal info",
                                style: TextStyle(
                                  color: Color(0xAAFFFFFF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Avatar with glow ring + camera badge
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring
                            Container(
                              width: 98,
                              height: 98,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0x406366F1),
                                  width: 3,
                                ),
                              ),
                            ),
                            // Avatar
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFF33365D),
                              backgroundImage: img,
                              child: img == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 40,
                                    )
                                  : null,
                            ),
                            // Camera badge
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF33365D),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 13,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tap hint
                      const Text(
                        "Tap to change photo",
                        style: TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      children: [
                        _buildInput(
                          "FULL NAME",
                          nameCtrl,
                          Icons.person_rounded,
                          const Color(0xFF6366F1),
                          const Color(0xFFEEEDFD),
                        ),
                        _buildInput(
                          "EMAIL",
                          emailCtrl,
                          Icons.email_rounded,
                          const Color(0xFF22C55E),
                          const Color(0xFFDCFCE7),
                        ),
                        _buildInput(
                          "PHONE NUMBER",
                          phoneCtrl,
                          Icons.phone_rounded,
                          const Color(0xFFF59E0B),
                          const Color(0xFFFEF3C7),
                        ),
                        const SizedBox(height: 28),
                        // Save button
                        GestureDetector(
                          onTap: () => _showConfirmSheet(),
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1C1F3E), Color(0xFF4A4D7A)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x4433365D),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Color(0x1A33365D),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0x33FFFFFF),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showConfirmSheet() {
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
            // Handle
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E1F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            // Icon + text row
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEBF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: _primary,
                    size: 20,
                  ),
                ),

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1C3A),
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Are you sure you want to update your profile?",
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
                      _saveChanges();
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1C1F3E), Color(0xFF33365D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Yes, Save",
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

  Widget _buildInput(
    String label,
    TextEditingController ctrl,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEBF5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            TextFormField(
              controller: ctrl,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C3A),
                letterSpacing: -.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
