import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase_client.dart';

const Color _primary = Color(0xFF33365D);
const Color _bg = Color(0xFFF4F5FB);

class AddAddressFormScreen extends StatefulWidget {
  const AddAddressFormScreen({super.key});

  @override
  State<AddAddressFormScreen> createState() => _AddAddressFormScreenState();
}

class _AddAddressFormScreenState extends State<AddAddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String selectedType = "Home";
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddressToDb() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      _showMsg("Error: User not logged in", Colors.red);
      setState(() => isLoading = false);
      return;
    }

    try {
      await supabase.from('addresses').insert({
        "user_id": userId,
        "full_name": _nameController.text.trim(),
        "house": _houseController.text.trim(),
        "area": _areaController.text.trim(),
        "landmark": _landmarkController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "type": selectedType,
      });

      if (!mounted) return;
      _showMsg("Address saved successfully!", Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      _showMsg("Connection Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 28),
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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Address",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Fill in your location details",
                        style: TextStyle(
                          color: Color(0xAAFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Form fields ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInput(
                      label: "FULL NAME",
                      ctrl: _nameController,
                      hint: "Enter your full name",
                      errMsg: "Required",
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF6366F1),
                      iconBg: const Color(0xFFEEEDFD),
                      accentColor: const Color(0xFF6366F1),
                    ),
                    _buildInput(
                      label: "HOUSE NO. / BUILDING",
                      ctrl: _houseController,
                      hint: "e.g. A-102, Sunset Towers",
                      errMsg: "Required",
                      icon: Icons.home_rounded,
                      iconColor: const Color(0xFF22C55E),
                      iconBg: const Color(0xFFDCFCE7),
                      accentColor: const Color(0xFF22C55E),
                    ),
                    _buildInput(
                      label: "AREA / LOCALITY",
                      ctrl: _areaController,
                      hint: "e.g. Satellite, Ahmedabad",
                      errMsg: "Required",
                      icon: Icons.map_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3C7),
                      accentColor: const Color(0xFFF59E0B),
                    ),
                    _buildInput(
                      label: "LANDMARK (OPTIONAL)",
                      ctrl: _landmarkController,
                      hint: "Near a mall, school, etc.",
                      errMsg: null,
                      icon: Icons.place_rounded,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEE2E2),
                      accentColor: const Color(0xFFEF4444),
                    ),
                    _buildInput(
                      label: "PINCODE",
                      ctrl: _pincodeController,
                      hint: "e.g. 380015",
                      errMsg: "Required",
                      icon: Icons.pin_drop_rounded,
                      iconColor: _primary,
                      iconBg: const Color(0xFFEAEBF5),
                      accentColor: _primary,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 6),

                    // Save As label
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          "SAVE AS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9B9DB8),
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _typeSelector(),
                  ],
                ),
              ),
            ),

            // ── Save button ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
              child: GestureDetector(
                onTap: isLoading ? null : _saveAddressToDb,
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: isLoading
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF1C1F3E), Color(0xFF4A4D7A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: isLoading ? const Color(0xFFCCCDDF) : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isLoading
                        ? []
                        : const [
                            BoxShadow(
                              color: Color(0x4433365D),
                              blurRadius: 22,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Color(0x1A33365D),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Save Address",
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Input field ────────────────────────────────────────────────
  Widget _buildInput({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required String? errMsg,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEBF5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row with accent dot
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            // Text field
            TextFormField(
              controller: ctrl,
              keyboardType: keyboardType,
              validator: (v) =>
                  (errMsg != null && (v == null || v.isEmpty)) ? errMsg : null,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C3A),
                letterSpacing: -.2,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFCCCDDF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Type chips ──────────────────────────────────────────────────
  Widget _typeSelector() {
    final types = [
      {
        "label": "Home",
        "icon": Icons.home_rounded,
        "color": const Color(0xFF6366F1),
        "bg": const Color(0xFFEEEDFD),
      },
      {
        "label": "Work",
        "icon": Icons.work_rounded,
        "color": const Color(0xFF22C55E),
        "bg": const Color(0xFFDCFCE7),
      },
      {
        "label": "Other",
        "icon": Icons.location_on_rounded,
        "color": const Color(0xFFF59E0B),
        "bg": const Color(0xFFFEF3C7),
      },
    ];

    return Row(
      children: types.map((t) {
        final selected = selectedType == t["label"];
        final Color color = t["color"] as Color;
        final Color bg = t["bg"] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedType = t["label"] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? color : const Color(0xFFEAEBF5),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: .35),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0x33FFFFFF) : bg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      t["icon"] as IconData,
                      size: 18,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    t["label"] as String,
                    style: TextStyle(
                      color: selected ? Colors.white : _primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
