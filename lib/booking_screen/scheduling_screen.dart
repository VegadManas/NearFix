import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearfix/address_screen/address_screen.dart';
import 'package:nearfix/payment_screen/ghost_payment_screen.dart';

import '../supabase_client.dart';

class ScheduleServiceScreen extends StatefulWidget {
  final String serviceName;
  final String providerId;
  final String visitingCharge;
  final double latitude;
  final double longitude;

  const ScheduleServiceScreen({
    super.key,
    required this.serviceName,
    required this.providerId,
    required this.visitingCharge,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ScheduleServiceScreen> createState() => _ScheduleServiceScreenState();
}

class _ScheduleServiceScreenState extends State<ScheduleServiceScreen>
    with TickerProviderStateMixin {
  static const Color _navy = Color(0xFF1A1D3A);
  static const Color _accent = Color.fromARGB(255, 51, 54, 93);
  static const Color _gold = Color(0xFFFFBB3B);
  static const Color _surface = Color(0xFFF4F4FB);

  DateTime? selectedDate;
  // Mock time slot — UI only, no backend wiring yet
  String? selectedSlot;
  final TextEditingController _notesController = TextEditingController();
  bool isLoading = false;

  late final AnimationController _heroCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, .18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), _cardCtrl.forward);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _cardCtrl.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            onPrimary: Colors.white,
            surface: _navy,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _startBookingProcess() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a date")));
      return;
    }

    final String? pickedAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressScreen()),
    );
    if (pickedAddress == null) return;

    double amountToPay = double.tryParse(widget.visitingCharge) ?? 0.0;

    // --- FIX 1: PASS ALL REQUIRED ARGUMENTS ---
    // GhostPaymentScreen returns a Map<String, dynamic>, not a String!
    final Map<String, dynamic>? paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GhostPaymentScreen(
          amount: amountToPay,
          serviceName: widget.serviceName,
          providerId: widget.providerId,
          latitude: widget.latitude,
          longitude: widget.longitude,
        ),
      ),
    );

    // --- FIX 2: EXTRACT DATA FROM THE RETURNED MAP ---
    if (paymentResult != null && paymentResult.containsKey("payment_id")) {
      String payId = paymentResult["payment_id"];
      _saveBookingToDB(payId, pickedAddress, amountToPay.toString());
    }
  }

  Future<void> _saveBookingToDB(
    String payId,
    String address,
    String finalAmount,
  ) async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    try {
      await supabase.from('bookings').insert({
        "user_id": userId,
        "provider_id": int.parse(widget.providerId),
        "service_name": widget.serviceName,
        "booking_date": DateFormat('yyyy-MM-dd').format(selectedDate!),
        "notes": _notesController.text.trim(),
        "address": address,
        "payment_id": payId,
        "amount": double.tryParse(finalAmount) ?? 0,
        // Sending coordinates to DB as well for the provider to see on a map
        "latitude": widget.latitude,
        "longitude": widget.longitude,
        "status": "Pending",
      });
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving booking: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Booking Requested!", textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardCtrl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel("Choose Date"),
                        const SizedBox(height: 10),
                        _DateCard(
                          selectedDate: selectedDate,
                          accentColor: _accent,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 28),
                        _sectionLabel("Preferred Time"),
                        const SizedBox(height: 10),
                        // TODO: wire selectedSlot to backend when ready
                        _TimeSlotPicker(
                          selectedSlot: selectedSlot,
                          accentColor: _accent,
                          onSelected: (slot) =>
                              setState(() => selectedSlot = slot),
                        ),
                        const SizedBox(height: 28),
                        _sectionLabel("Additional Notes"),
                        const SizedBox(height: 10),
                        _NotesField(
                          controller: _notesController,
                          accentColor: _accent,
                        ),
                        const SizedBox(height: 40),
                        _BookButton(
                          visitingCharge: widget.visitingCharge,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _startBookingProcess,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _navy,
      // No title set here — the hero background already renders the title.
      // Leaving title null means nothing appears in the collapsed toolbar either,
      // which removes the duplicate-text bug entirely.
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "₹${widget.visitingCharge}",
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // title intentionally omitted — hero background owns the title rendering
        collapseMode: CollapseMode.parallax,
        background: FadeTransition(
          opacity: _heroFade,
          child: _HeroHeader(serviceName: widget.serviceName),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: Color(0xFF9090B0),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// Hero header — the ONLY place the title renders
// ════════════════════════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  final String serviceName;
  const _HeroHeader({required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1128), Color(0xFF2C2F5B), Color(0xFF1A1D3A)],
            ),
          ),
        ),
        // Decorative arcs
        CustomPaint(painter: _ArcPainter()),
        // Orb glow — 0x59 = ~35% alpha
        const Positioned(
          right: -30,
          top: -30,
          child: SizedBox(
            width: 160,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x5933365D), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Title — single source of truth
        Positioned(
          left: 20,
          bottom: 24,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  // 0x40 = 25% alpha, 0x80 = 50% alpha
                  color: const Color(0x4033365D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x8033365D)),
                ),
                child: const Text(
                  "NEARFIX  ·  BOOKING",
                  style: TextStyle(
                    color: Color(0xFFB8B4FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Schedule $serviceName",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Time slot picker — mock UI only, no backend wiring yet
// Zones: Morning 12am–12pm | Afternoon 12pm–4pm | Evening 4pm–12am
// ════════════════════════════════════════════════════════════════
class _TimeSlotPicker extends StatelessWidget {
  final String? selectedSlot;
  final Color accentColor;
  final ValueChanged<String> onSelected;

  const _TimeSlotPicker({
    required this.selectedSlot,
    required this.accentColor,
    required this.onSelected,
  });

  static const _zones = [
    _TimeZone(
      id: 'morning',
      label: 'Morning',
      range: '12am – 12pm',
      icon: Icons.wb_sunny_outlined,
    ),
    _TimeZone(
      id: 'afternoon',
      label: 'Afternoon',
      range: '12pm – 4pm',
      icon: Icons.wb_cloudy_outlined,
    ),
    _TimeZone(
      id: 'evening',
      label: 'Evening',
      range: '4pm – 12am',
      icon: Icons.nights_stay_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _zones.map((zone) {
        final bool isSelected = selectedSlot == zone.id;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: zone.id != 'evening' ? 10 : 0),
            child: GestureDetector(
              onTap: () => onSelected(zone.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor : const Color(0xFFE0E0F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0x3333365D)
                          : const Color(0x08000000),
                      blurRadius: isSelected ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      zone.icon,
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9090B0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zone.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A1D3A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone.range,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xCCFFFFFF)
                            : const Color(0xFF9090B0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimeZone {
  final String id;
  final String label;
  final String range;
  final IconData icon;
  const _TimeZone({
    required this.id,
    required this.label,
    required this.range,
    required this.icon,
  });
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 0x0F = ~6% white
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0FFFFFFF);

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * .85, size.height * .2),
        60.0 + i * 34,
        paint1,
      );
    }

    // 0x26 = ~15% purple
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = const Color(0x2633365D);

    final path = Path()
      ..moveTo(0, size.height * .65)
      ..quadraticBezierTo(
        size.width * .4,
        size.height * .4,
        size.width,
        size.height * .55,
      );
    canvas.drawPath(path, paint2);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════
// Date selection card
// ════════════════════════════════════════════════════════════════
class _DateCard extends StatelessWidget {
  final DateTime? selectedDate;
  final Color accentColor;
  final VoidCallback onTap;

  const _DateCard({
    required this.selectedDate,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDate = selectedDate != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDate ? const Color(0x8033365D) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // 0x1F = ~12%, 0x0F = ~6%
              color: hasDate
                  ? const Color(0x1F33365D)
                  : const Color(0x0F000000),
              blurRadius: hasDate ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasDate
                      ? const Color(0x1F33365D)
                      : const Color(0xFFF0F0F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: hasDate ? accentColor : const Color(0xFF9090B0),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Date",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9090B0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasDate
                          ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                          : "Select Date",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: hasDate
                            ? const Color(0xFF1A1D3A)
                            : const Color(0xFFBBBBCC),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: hasDate ? accentColor : const Color(0xFFCCCCDD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Notes field
// ════════════════════════════════════════════════════════════════
class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;

  const _NotesField({required this.controller, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // ~5% black
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(
          color: Color(0xFF1A1D3A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Additional Notes (e.g., gate code, specific problem)",
          hintStyle: const TextStyle(color: Color(0xFFB0B0C8), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x8033365D), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CTA button with shimmer stripe
// ════════════════════════════════════════════════════════════════
class _BookButton extends StatefulWidget {
  final String visitingCharge;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _BookButton({
    required this.visitingCharge,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_BookButton> createState() => _BookButtonState();
}

class _BookButtonState extends State<_BookButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.onPressed == null
                  ? [Colors.grey.shade400, Colors.grey.shade300]
                  : const [Color(0xFF4A4D7A), Color(0xFF33365D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6633365D), // ~40% purple glow
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!widget.isLoading)
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _ShimmerPainter(_shimmer.value),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              widget.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pay ₹${widget.visitingCharge} & Book",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF), // ~20% white circle
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (progress * 1.4 - .2);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0x1FFFFFFF), // ~12% white sweep
          Colors.transparent,
        ],
        stops: [0, .5, 1],
      ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height));
    canvas.drawRect(Offset(x - 60, 0) & Size(120, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ════════════════════════════════════════════════════════════════
// Time slot picker — MOCK UI ONLY, no backend wiring yet
// Three zones: Morning (6am–12pm), Afternoon (12pm–4pm), Evening (4pm–12am)
// ════════════════════════════════════════════════════════════════
