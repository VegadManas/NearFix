import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearfix/booking_screen/booking_screen_details.dart';

import '../supabase_client.dart';

const Color _primary = Color(0xFF33365D);
const Color _accent = Color(0xFF6366F1);
const Color _bg = Color(0xFFF6F7FB);

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  bool isUpcoming = true;
  bool isLoading = true;
  List<dynamic> allBookings = [];
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetchBookings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');
      final data = await supabase
          .rpc('get_all_bookings', params: {'p_user_id': userId});
      setState(() {
        allBookings = data ?? [];
        isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<dynamic> get _filteredBookings {
    return allBookings.where((b) {
      final String s = (b['status'] ?? '').toString().toLowerCase().trim();
      if (isUpcoming) {
        return s == 'pending' || s == 'confirmed' || s == '';
      } else {
        return s == 'completed' || s == 'cancelled';
      }
    }).toList()..sort(
      (a, b) => (int.tryParse(b['id'].toString()) ?? 0).compareTo(
        int.tryParse(a['id'].toString()) ?? 0,
      ),
    );
  }

  _StatusConfig _statusConfig(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return _StatusConfig(
          color: const Color(0xFF22C55E),
          bg: const Color(0xFFDCFCE7),
          icon: Icons.check_circle_rounded,
        );
      case 'completed':
        return _StatusConfig(
          color: const Color(0xFF6366F1),
          bg: const Color(0xFFEEEDFD),
          icon: Icons.task_alt_rounded,
        );
      case 'cancelled':
        return _StatusConfig(
          color: const Color(0xFFEF4444),
          bg: const Color(0xFFFEE2E2),
          icon: Icons.cancel_rounded,
        );
      case 'pending':
      default:
        return _StatusConfig(
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFEF3C7),
          icon: Icons.schedule_rounded,
        );
    }
  }

  // ── Rate bottom sheet ──────────────────────────────────────
  void _showRatingSheet(Map booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RatingSheet(booking: booking),
    ).then((value) {
      if (value == true) {
        _fetchBookings(); // ✅ refresh list
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Bookings",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${allBookings.length} total bookings",
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B6D88)),
              ),
            ],
          ),
          GestureDetector(
            onTap: _fetchBookings,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D33365D),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: isUpcoming
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D33365D),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _tabBtn("Upcoming", isUpcoming, Icons.auto_awesome_rounded, () {
                  if (!isUpcoming) {
                    setState(() => isUpcoming = true);
                    _animController.forward(from: 0);
                  }
                }),
                _tabBtn("History", !isUpcoming, Icons.history_rounded, () {
                  if (isUpcoming) {
                    setState(() => isUpcoming = false);
                    _animController.forward(from: 0);
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    final bookings = _filteredBookings;

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEBF5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: _primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No bookings here",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Your bookings will appear here",
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6D88)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];
          final String status = (b['status'] ?? 'Pending').toString();
          final config = _statusConfig(status);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 60)),
            curve: Curves.easeOut,
            builder: (context, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - val)),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _bookingCard(b, status, config),
            ),
          );
        },
      ),
    );
  }

  // ... (previous imports and constants remain the same)

  Widget _bookingCard(Map b, String status, _StatusConfig config) {
    // Determine if the booking has already been rated
    // We handle both String and Int types just in case
    final bool alreadyRated = b['is_rated']?.toString() == '1';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailsUI(bookingId: b['id'].toString()),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEFF8), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: config.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(config.icon, color: config.color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: config.color,
                      letterSpacing: .8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "REF# ${b['id']}",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B6D88)),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEBF5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.home_repair_service_rounded, color: _primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['service_name'] ?? 'Service',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1C3A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b['provider_name'] ?? 'Provider',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6D88)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${b['amount'] ?? '—'}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF6B6D88)),
                      const SizedBox(width: 6),
                      Text(
                        b['booking_date'] ?? 'TBD',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B6D88)),
                      ),
                      const Spacer(),

                      // ── Updated Rating Logic ────────────────────────
                      if (status.toLowerCase() == 'completed') ...[
                        if (!alreadyRated) ...[
                          _outlineBtn(
                            "Rate",
                            Icons.star_rounded,
                                () => _showRatingSheet(b),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          // Show "Rated" label instead of button
                          const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.stars_rounded, color: Color(0xFF22C55E), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Rated",
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      // ───────────────────────────────────────────────

                      // Update inside _bookingCard
                      _solidBtn(
                        isUpcoming ? "Details" : "View",
                            () async {
                          // 1. Wait for the user to return
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailsUI(bookingId: b['id'].toString()),
                            ),
                          );
                          // 2. Refresh the list to catch the 'cancelled' status
                          _fetchBookings();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
// ... (rest of the helper buttons and RatingSheet remain the same)

  Widget _solidBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1F3E), Color(0xFF4A4D7A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2633365D),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _outlineBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusConfig {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusConfig({
    required this.color,
    required this.bg,
    required this.icon,
  });
}

// ════════════════════════════════════════════════════════════════
// Rating bottom sheet — proper StatefulWidget so controller
// is disposed correctly and overflow is handled
// ════════════════════════════════════════════════════════════════
class _RatingSheet extends StatefulWidget {
  final Map booking;
  const _RatingSheet({required this.booking});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  bool _submitting = false;
  late final TextEditingController _commentCtrl;

  static const _labels = [
    '',
    '😞 Poor',
    '😐 Fair',
    '🙂 Good',
    '😊 Great',
    '🤩 Excellent!',
  ];

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) return;

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final data = await supabase.rpc('submit_review', params: {
        'p_booking_id': widget.booking['id'],
        'p_provider_id': widget.booking['provider_id'],
        'p_user_id': userId,
        'p_rating': _stars,
        'p_review': _commentCtrl.text.trim(),
      });

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true); // ✅ IMPORTANT (return true)

      if (data['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Rating submitted ⭐"),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 32 + kb),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rate your experience",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1C3A),
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.booking['service_name'] ?? 'Service',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B9DB8),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      key: ValueKey(filled),
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 44,
                      color: filled
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFDDE0F0),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _stars == 0 ? "Tap a star to rate" : _labels[_stars],
              key: ValueKey(_stars),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _stars == 0
                    ? const Color(0xFFCCCDDF)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Comment
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAEBF5), width: 1.2),
            ),
            child: TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C3A)),
              decoration: const InputDecoration(
                hintText: "Share your experience (optional)...",
                hintStyle: TextStyle(color: Color(0xFFCCCDDF), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5FB),
                      borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _stars == 0 || _submitting ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _stars > 0
                          ? const LinearGradient(
                              colors: [Color(0xFF1C1F3E), Color(0xFF4A4D7A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: _stars == 0 ? const Color(0xFFE8E9F5) : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _stars > 0
                          ? const [
                              BoxShadow(
                                color: Color(0x3333365D),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Submit Rating",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _stars == 0
                                    ? const Color(0xFFAAABC0)
                                    : Colors.white,
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
    );
  }
}
