import 'package:flutter/material.dart';
import 'package:nearfix/chat_screen/chatscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart'; // ✅ Still used for image URLs
import '../supabase_client.dart';

const Color _primary = Color(0xFF33365D);
const Color _accent = Color(0xFF6366F1);
const Color _bg = Color(0xFFF6F7FB);

class BookingDetailsUI extends StatefulWidget {
  final String bookingId;
  const BookingDetailsUI({super.key, required this.bookingId});

  @override
  State<BookingDetailsUI> createState() => _BookingDetailsUIState();
}

class _BookingDetailsUIState extends State<BookingDetailsUI> {
  Map<String, dynamic>? bookingData;
  bool isLoading = true;

  final String _baseUrl =
      "${AppConfig.baseUrl}/";

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final result = await supabase.rpc('get_booking_details', params: {
        'p_booking_id': int.parse(widget.bookingId),
      });
      final list = result as List<dynamic>;
      final data = list.isNotEmpty ? list.first as Map<String, dynamic> : null;

      if (data != null) {
        setState(() {
          bookingData = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> _handleCancel() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Booking?",
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1C3A))),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("No, Keep it", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => isLoading = true);

    try {
      final data = await supabase.rpc('cancel_booking', params: {
        'p_booking_id': int.parse(widget.bookingId),
      });

      if (data['success'] == true) {
        if (mounted) {
          _showCustomSnackBar(
              context,
              "Booking Cancelled Successfully",
              Icons.check_circle_rounded,
              Colors.redAccent
          );
        }
        _fetchBookingDetails();
      } else {
        setState(() => isLoading = false);
        _showCustomSnackBar(
            context,
            data['message'] ?? "Error cancelling",
            Icons.error_outline_rounded,
            _primary
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showCustomSnackBar(context, "Network error", Icons.wifi_off_rounded, Colors.orange);
    }
  }

  // ✅ New Custom SnackBar UI helper
  void _showCustomSnackBar(BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F3E), // Dark Navy to match your theme
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Function to handle the call logic
  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not available")),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open phone dialer")),
      );
    }
  }

  _StatusCfg _cfg(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return _StatusCfg(
          const Color(0xFF22C55E),
          const Color(0xFFDCFCE7),
          Icons.check_circle_rounded,
          "Booking Confirmed",
        );
      case 'completed':
        return _StatusCfg(
          const Color(0xFF6366F1),
          const Color(0xFFEEEDFD),
          Icons.task_alt_rounded,
          "Service Completed",
        );
      case 'cancelled':
        return _StatusCfg(
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2),
          Icons.cancel_rounded,
          "Booking Cancelled",
        );
      case 'pending':
      default:
        return _StatusCfg(
          const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7),
          Icons.schedule_rounded,
          "Awaiting Confirmation",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final String rawStatus = (bookingData?['status'] ?? "Pending").toString();
    final bool canCancel =
        rawStatus.toLowerCase() == 'confirmed' ||
        rawStatus.toLowerCase() == 'pending';
    final cfg = _cfg(rawStatus);

    // Provider photo logic using the new path from PHP
    String? photoPath = bookingData!['profile_photo_path'];
    String? fullImageUrl;
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith('http')) {
        fullImageUrl = photoPath;
      } else {
        final clean = photoPath.startsWith('/')
            ? photoPath.substring(1)
            : photoPath;
        fullImageUrl = "$_baseUrl$clean";
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHero(context, cfg, rawStatus),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  _serviceSection(),
                  const SizedBox(height: 16),
                  _providerSection(
                    bookingData!['provider_name'] ?? "Not Assigned",
                    fullImageUrl,
                  ),
                  const SizedBox(height: 16),
                  _paymentSection(
                    bookingData!['payment_id'],
                    bookingData!['amount'],
                  ),
                  const SizedBox(height: 16),
                  _locationSection(
                    bookingData!['address'] ?? "No address provided",
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 24),
                    _cancelBtn(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, _StatusCfg cfg, String rawStatus) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        28,
      ),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: cfg.color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cfg.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cfg.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "REF# ${widget.bookingId}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6D88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceSection() {
    final name = bookingData!['service_name'] ?? "Service";
    final date = bookingData!['booking_date'] ?? "TBD";
    return _card(
      "SERVICE",
      Icons.home_repair_service_rounded,
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEBF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getServiceIcon(name), color: _primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1C3A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Color(0xFF6B6D88),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6D88),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerSection(String pName, String? imageUrl) {
    final pId = bookingData!['provider_id'];
    return _card(
      "PROFESSIONAL",
      Icons.person_rounded,
      Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFEAEBF5),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.person, color: _primary, size: 26)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1C3A),
                  ),
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF22C55E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Verified Provider",
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B6D88)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _actionBtn(
            Icons.chat_bubble_rounded,
            const Color(0xFFEEEDFD),
            _accent,
            () async {
              if (pId == null) return;
              final prefs = await SharedPreferences.getInstance();
              final int myId = prefs.getInt('user_id') ?? 1;
              final int? peerId = int.tryParse(pId.toString());
              if (peerId != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderChatMessageScreen(
                      currentUserId: myId,
                      peerId: peerId,
                      peerName: pName,
                      peerImageUrl: imageUrl,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          // ✅ Working Call Button
          _actionBtn(
            Icons.call_rounded,
            const Color(0xFFDCFCE7),
            const Color(0xFF22C55E),
            () => _makePhoneCall(bookingData!['provider_phone']),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color bg,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _paymentSection(String? payId, dynamic amount) {
    return _card(
      "PAYMENT",
      Icons.receipt_long_rounded,
      Column(
        children: [
          _infoRow(
            "Transaction ID",
            (payId == null || payId.isEmpty) ? "Pending" : payId,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEBF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C3A),
                  ),
                ),
                Text(
                  "₹$amount",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationSection(String address) {
    return _card(
      "LOCATION",
      Icons.location_on_rounded,
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1C3A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelBtn(BuildContext context) {
    return GestureDetector(
      onTap: _handleCancel, // ✅ Now connected to the logic
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text(
              "Cancel Booking",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, IconData titleIcon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B6D88),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B6D88)),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C3A),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String service) {
    final s = service.toLowerCase();
    if (s.contains("clean")) return Icons.cleaning_services_rounded;
    if (s.contains("plumb")) return Icons.plumbing_rounded;
    if (s.contains("elect")) return Icons.electrical_services_rounded;
    if (s.contains("ac") || s.contains("air")) return Icons.ac_unit_rounded;
    if (s.contains("paint")) return Icons.format_paint_rounded;
    if (s.contains("laundry")) return Icons.local_laundry_service_rounded;
    return Icons.handyman_rounded;
  }
}

class _StatusCfg {
  final Color color;
  final Color bg;
  final IconData icon;
  final String label;
  const _StatusCfg(this.color, this.bg, this.icon, this.label);
}
