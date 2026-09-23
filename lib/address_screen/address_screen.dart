import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_client.dart';
import 'add_address_form_screen.dart';

const Color _primary = Color(0xFF33365D);
const Color _bg = Color(0xFFF4F5FB);

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  int selectedAddressIndex = 0;
  List<Map<String, dynamic>> addresses = [];

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final data = await supabase
          .from('addresses')
          .select('id, type, house, area, landmark, pincode')
          .eq('user_id', userId);

      setState(() {
        addresses = List<Map<String, dynamic>>.from(
          (data as List).map(
            (addr) => {
              "id": addr['id'], // ✅ Crucial: Store the DB ID
              "title": addr['type'],
              "address": "${addr['house']}, ${addr['area']}",
              "icon": addr['type'] == "Home"
                  ? Icons.home_rounded
                  : addr['type'] == "Work"
                  ? Icons.work_rounded
                  : Icons.location_on_rounded,
            },
          ),
        );
      });
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    }
  }

  Future<void> _deleteAddress(int index) async {
    final addressId = addresses[index]['id'];
    final removedAddress = addresses[index];

    // 1. Optimistic UI update
    setState(() {
      addresses.removeAt(index);
      if (selectedAddressIndex >= addresses.length) {
        selectedAddressIndex = addresses.isEmpty ? 0 : addresses.length - 1;
      }
    });

    try {
      await supabase.from('addresses').delete().eq('id', addressId);
    } catch (e) {
      debugPrint("Error deleting address: $e");
      setState(() {
        addresses.insert(index, removedAddress);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete")),
        );
      }
    }
  }

  Color _iconColor(String title) {
    if (title == "Home") return const Color(0xFF6366F1);
    if (title == "Work") return const Color(0xFF22C55E);
    return const Color(0xFFF59E0B);
  }

  Color _iconBg(String title) {
    if (title == "Home") return const Color(0xFFEEEDFD);
    if (title == "Work") return const Color(0xFFDCFCE7);
    return const Color(0xFFFEF3C7);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1F3E), Color(0xFF33365D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
                      "Select Address",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Choose your service location",
                      style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEBF5),
                          ),
                          child: const Icon(
                            Icons.location_off_rounded,
                            color: _primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "No addresses found",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1C3A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Add one below to get started",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9B9DB8),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = selectedAddressIndex == index;
                      final String title = addresses[index]["title"];
                      final Color iColor = _iconColor(title);
                      final Color iBg = _iconBg(title);

                      return Dismissible(
                        key: ValueKey(
                          addresses[index]["address"] + index.toString(),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteAddress(index),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => selectedAddressIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? iColor
                                    : const Color(0xFFEAEBF5),
                                width: isSelected ? 2 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: iColor.withValues(alpha: .2),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: iColor.withValues(alpha: .08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : const [
                                      BoxShadow(
                                        color: Color(0x0C000000),
                                        blurRadius: 16,
                                        offset: Offset(0, 5),
                                      ),
                                      BoxShadow(
                                        color: Color(0x05000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                // Colored icon box
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isSelected ? iColor : iBg,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    addresses[index]["icon"],
                                    color: isSelected ? Colors.white : iColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: isSelected
                                              ? iColor
                                              : const Color(0xFF1A1C3A),
                                          letterSpacing: -.2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        addresses[index]["address"],
                                        style: const TextStyle(
                                          color: Color(0xFF9B9DB8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Swipe hint + checkmark
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Checkmark
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? iColor
                                            : const Color(0xFFF0F1F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_rounded
                                            : Icons.circle_outlined,
                                        size: isSelected ? 15 : 12,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFCCCDDF),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Swipe hint
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.chevron_left_rounded,
                                          size: 10,
                                          color: Color(0xFFCCCDDF),
                                        ),
                                        Text(
                                          "del",
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFFCCCDDF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Bottom buttons ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Add address
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddAddressFormScreen(),
                      ),
                    );
                    if (result == true) fetchAddresses();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEAEBF5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEBF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 17,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Add New Address",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                            letterSpacing: -.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm button
                GestureDetector(
                  onTap: () {
                    if (addresses.isNotEmpty) {
                      Navigator.pop(
                        context,
                        addresses[selectedAddressIndex]["address"],
                      );
                    }
                  },
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Confirm Address",
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
                            border: Border.all(color: const Color(0x33FFFFFF)),
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
        ],
      ),
    );
  }
}
