import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearfix/booking_screen/booking_screen_details.dart';
import 'package:nearfix/booking_screen/bookings_screen.dart';
import 'package:nearfix/profile_screen/profile_screen.dart';
import 'package:nearfix/service_provider_detail/service_provider_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../address_screen/address_screen.dart';
import '../all_service_providers/all_service_providers.dart';
import '../app_config.dart';
import '../supabase_client.dart';
import '../chat_screen/chat_screen_tile.dart';
import '../map/map_picker_screen.dart';
import '../notifications/notifications.dart';
import '../service_providers/service_providers.dart';

// ════════════════════════════════════════════════════════════
//  COLOR CONFIG
// ════════════════════════════════════════════════════════════

class AppColors {
  static const Color primary = Color(0xFF33365D);
  static const Color scaffold = Color(0xFFF6F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color appBarBg = Color(0xFFFFFFFF);
  static const Color iconBg = Color(0xFFEAEBF5);
  static const Color textDark = Color(0xFF1A1C3A);
  static const Color textMedium = Color(0xFF6B6D88);
  static const Color textLight = Color(0xFFB0B2C8);
  static const Color navActive = Color(0xFF33365D);
  static const Color navInactive = Color(0xFFB0B2C8);
  static const Color navBg = Color(0xFFFFFFFF);
  static const Color bellBg = Color(0xFFEAEBF5);
  static const Color star = Color(0xFFF59E0B);
  static const Color viewAll = Color(0xFF33365D);
  static const Color shadow = Color(0x0D000000);
  static const Color shadowLight = Color(0x08000000);
  static const Color shadowNav = Color(0x0F000000);
}

// ── Distinct color per service icon ────────────────────────
class ServiceStyle {
  final Color bg;
  final Color icon;
  const ServiceStyle({required this.bg, required this.icon});
}

const Map<String, ServiceStyle> serviceColors = {
  "Cleaning": ServiceStyle(bg: Color(0xFFE0F7FA), icon: Color(0xFF0097A7)),
  "Electric": ServiceStyle(bg: Color(0xFFFFF8E1), icon: Color(0xFFF9A825)),
  "Plumbing": ServiceStyle(bg: Color(0xFFE3F2FD), icon: Color(0xFF1565C0)),
  "Repair": ServiceStyle(bg: Color(0xFFFFEBEE), icon: Color(0xFFD32F2F)),
  "AC": ServiceStyle(bg: Color(0xFFE8F5E9), icon: Color(0xFF2E7D32)),
  "Painting": ServiceStyle(bg: Color(0xFFFCE4EC), icon: Color(0xFFC2185B)),
  "Laundry": ServiceStyle(bg: Color(0xFFEDE7F6), icon: Color(0xFF512DA8)),
  "More": ServiceStyle(bg: Color(0xFFF3F3F3), icon: Color(0xFF757575)),
};

// ════════════════════════════════════════════════════════════
//  HOME SCREEN
// ════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List<dynamic> _dbProviders = [];
  Map<String, dynamic>? _upcomingBooking;
  bool _isLoading = true;

  final String _baseUrl = "${AppConfig.baseUrl}/";

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    // New uploads are full Supabase Storage URLs; old rows may still have
    // a relative "uploads/..." path from before the migration.
    return path.startsWith('http') ? path : "$_baseUrl$path";
  }

  List<Map<String, dynamic>> _dynamicServices = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchServices() async {
    final data = await supabase.from('services').select().order('id');
    setState(() {
      _dynamicServices = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _fetchData() async {
    try {
      print("--- Fetching Data Started ---");
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      // Fetch all three simultaneously, same as before — just Supabase calls
      // instead of http.get() to your old PHP endpoints.
      final providersFuture = supabase
          .rpc('get_providers', params: {'p_category': ''})
          .then((v) => v);
      final bookingFuture = supabase
          .rpc('get_upcoming_booking', params: {'p_user_id': userId})
          .then((v) => v);
      final servicesFuture = supabase
          .from('services')
          .select()
          .order('id')
          .then((v) => v);

      final providersData = await providersFuture as List<dynamic>;
      final bookingList = await bookingFuture as List<dynamic>;
      final bookingData = bookingList.isNotEmpty
          ? bookingList.first as Map<String, dynamic>
          : null;
      final servicesData = await servicesFuture;

      if (!mounted) return;

      print("Services found in DB: $servicesData");

      setState(() {
        _dbProviders = List<Map<String, dynamic>>.from(providersData);
        _upcomingBooking = bookingData;
        _dynamicServices = List<Map<String, dynamic>>.from(servicesData);
        _isLoading = false;
      });

      print("--- Fetching Data Completed Successfully ---");
    } catch (e) {
      debugPrint("CRITICAL FETCH ERROR: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Scaffold ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: currentIndex == 0 ? _buildAppBar() : null,
      // NO bottomNavigationBar here — nav is in the Stack below
      body: Stack(
        children: [
          _buildBody(),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (currentIndex) {
      case 0:
        return _buildHomeBody();
      case 1:
        return const BookingsScreen();
      case 2:
        return const ChatScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeBody();
    }
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: 20,
      title: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddressScreen()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LOCATION",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  "Home",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bellBg,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bellBg, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Home Body ─────────────────────────────────────────────

  Widget _buildHomeBody() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // 110px bottom padding so last item clears the floating nav
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 28),
            _buildServicesGrid(),
            const SizedBox(height: 28),
            _buildSectionHeader("Upcoming Booking", showViewAll: false),
            const SizedBox(height: 12),
            _buildUpcomingCard(),
            const SizedBox(height: 28),
            _buildSectionHeader("Recommended for you", showViewAll: false),
            const SizedBox(height: 12),
            _buildRecommendedList(),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => showSearch(
          context: context,
          delegate: ServiceSearchDelegate(_dynamicServices),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textMedium, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search for services...",
                  style: TextStyle(color: AppColors.textMedium, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Services Grid ─────────────────────────────────────────

  Widget _buildServicesGrid() {
    // 1. Determine how many items to show from the database (Max 7)
    int dynamicItemsCount = _dynamicServices.length > 7
        ? 7
        : _dynamicServices.length;

    // 2. Total items in grid will be dynamicItemsCount + 1 (for the "More" button)
    int totalItems = dynamicItemsCount + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalItems,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          // ─── CASE 1: THE "MORE" BUTTON (Always the last item) ───
          if (index == totalItems - 1) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AllServicesScreen(services: _dynamicServices),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3), // Neutral light grey
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.more_horiz, color: Color(0xFF757575), size: 26),
                    SizedBox(height: 6),
                    Text(
                      "More",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ─── CASE 2: DYNAMIC SERVICES FROM DATABASE ───
          final service = _dynamicServices[index];
          final String title = service["title"] ?? "Service";

          // Use our helper functions for colors and icons
          final Color bgColor = getColorFromHex(
            service['bg_color'] ?? "#EAEBF5",
          );
          final Color iconColor = getColorFromHex(
            service['icon_color'] ?? "#33365D",
          );

          return GestureDetector(
            onTap: () => showLocationSelection(context, title),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    getIconFromString(service['icon_name']),
                    color: iconColor,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────

  Widget _buildSectionHeader(String title, {bool showViewAll = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (showViewAll)
            Text(
              "View all",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.viewAll,
              ),
            ),
        ],
      ),
    );
  }

  // ── Upcoming Booking Card ─────────────────────────────────

  Widget _buildUpcomingCard() {
    if (_upcomingBooking == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textLight,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                "No upcoming bookings",
                style: TextStyle(color: AppColors.textMedium, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _upcomingBooking!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          final String actualID = booking['id'].toString();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsUI(bookingId: actualID),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Purple header strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: const Color(0xFF6366F1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "REF# ${booking['id'] ?? '—'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        booking['booking_date'] ?? "Scheduled",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── White body
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider avatar + name + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFFEAEBF5),
                            backgroundImage: NetworkImage(
                              _resolveImageUrl(booking['provider_photo']),
                            ),
                            onBackgroundImageError: (_, __) {},
                            child: booking['provider_photo'] == null
                                ? const Icon(
                                    Icons.person,
                                    size: 13,
                                    color: Color(0xFF6366F1),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking['provider_name'] ?? 'Provider',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B6D88),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDFD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              booking['status'] ?? "Upcoming",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Service name
                      Text(
                        booking['service_name'] ?? "Service",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1C3A),
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 12),

                      // View Details right-aligned
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "View Details",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Color(0xFF6366F1),
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
      ),
    );
  }

  // ── Recommended List ──────────────────────────────────────

  Widget _buildRecommendedList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_dbProviders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            "No recommended providers yet",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 268,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 8),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _dbProviders.length,
        itemBuilder: (context, index) {
          final item = _dbProviders[index];
          final String name = (item['name'] ?? 'Provider').toString();
          final String title = (item['title'] ?? 'Service').toString();
          final String initial = name.trim().isNotEmpty
              ? name.trim()[0].toUpperCase()
              : 'P';
          final String photoUrl = _resolveImageUrl(item['photo']);
          final ratingRaw = item['rating']?.toString() ?? "0";
          final bool hasRating = ratingRaw != "0" && ratingRaw != "0.0";

          return Container(
            width: 182,
            margin: const EdgeInsets.only(right: 16, top: 4, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.primary.withOpacity(0.07)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.13),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
                const BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => showLocationSelection(context, title),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Framed photo + floating action button ──────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: 136,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _monogramBg(initial),
                                  if (photoUrl.isNotEmpty)
                                    Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      gaplessPlayback: true,
                                      errorBuilder: (c, e, s) =>
                                          const SizedBox.shrink(),
                                      loadingBuilder: (c, child, p) => p == null
                                          ? child
                                          : const SizedBox.shrink(),
                                    ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    height: 60,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.42),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // rating — glass pill
                                  Positioned(
                                    top: 9,
                                    left: 9,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.34,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                hasRating
                                                    ? Icons.star_rounded
                                                    : Icons
                                                          .auto_awesome_rounded,
                                                size: 12,
                                                color: AppColors.star,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                hasRating ? ratingRaw : "New",
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // service label on the scrim
                                  Positioned(
                                    left: 11,
                                    right: 52,
                                    bottom: 10,
                                    child: Text(
                                      title.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.9,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // floating arrow straddling the photo edge
                          Positioned(
                            right: 6,
                            bottom: -17,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.78),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Info block ─────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 34),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Available now",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMedium,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Solid gradient fallback used whenever a provider has no photo, or the
  // photo fails to load — always fills the full header area, never a
  // stray sliver on one side.
  Widget _monogramBg(String initial) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.65)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  // ── Floating Bottom Nav ───────────────────────────────────

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: DecoratedBox(
        // shadow lives outside the ClipRRect so it actually shows
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.26),
              blurRadius: 34,
              spreadRadius: -6,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.92),
                    const Color(0xFFEDEEF7).withOpacity(0.86),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.16),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // glossy top edge
                  Positioned(
                    top: 0,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 1.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(
                          0,
                          Icons.home_outlined,
                          Icons.home_rounded,
                          "Home",
                        ),
                        _navItem(
                          1,
                          Icons.calendar_month_outlined,
                          Icons.calendar_month_rounded,
                          "Bookings",
                        ),
                        _navItem(
                          2,
                          Icons.chat_bubble_outline_rounded,
                          Icons.chat_bubble_rounded,
                          "Messages",
                        ),
                        _navItem(
                          3,
                          Icons.person_outline_rounded,
                          Icons.person_rounded,
                          "Profile",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outline, IconData filled, String label) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.82),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.42),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filled : outline,
              color: isActive ? Colors.white : AppColors.navInactive,
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SEARCH DELEGATE
// ════════════════════════════════════════════════════════════

class ServiceSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> services;
  ServiceSearchDelegate(this.services);

  @override
  String get searchFieldLabel => 'Search services...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchBody(context);

  Widget _buildSearchBody(BuildContext context) {
    final results = services
        .where(
          (s) =>
              s["title"].toLowerCase().contains(query.toLowerCase()) &&
              s["title"] != "More",
        )
        .toList();

    if (query.isEmpty) {
      return Container(
        color: AppColors.scaffold,
        child: Center(
          child: Text(
            "Start typing to find services...",
            style: TextStyle(color: AppColors.textMedium),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.scaffold,
      child: results.isEmpty
          ? Center(
              child: Text(
                "No services found",
                style: TextStyle(color: AppColors.textMedium),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildSearchTile(context, results[index]),
            ),
    );
  }

  Widget _buildSearchTile(BuildContext context, Map<String, dynamic> service) {
    final title = service["title"] as String;
    final style =
        serviceColors[title] ??
        const ServiceStyle(bg: Color(0xFFEAEBF5), icon: Color(0xFF33365D));

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        showLocationSelection(context, title);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getIconFromString(service["icon_name"]),
                color: getColorFromHex(service['icon_color'] ?? "#33365D"),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Available in your area",
                    style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// MAKE SURE THESE ARE OUTSIDE OF ANY CLASS
IconData getIconFromString(String? iconName) {
  switch (iconName?.toLowerCase().trim()) {
    case 'cleaning_services':
    case 'cleaning':
      return Icons.cleaning_services;
    case 'electrical_services':
    case 'electric':
    case 'electricity':
      return Icons.electrical_services;
    case 'plumbing':
      return Icons.plumbing;
    case 'handyman':
    case 'repair':
      return Icons.handyman;
    case 'ac_unit':
    case 'ac':
      return Icons.ac_unit;
    case 'format_paint':
    case 'painting':
      return Icons.format_paint;
    case 'local_laundry_service':
    case 'laundry':
      return Icons.local_laundry_service;
    default:
      // This will show a generic icon so you know the helper is working
      // but the name didn't match.
      return Icons.category_outlined;
  }
}

Color getColorFromHex(String hexColor) {
  try {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return const Color(0xFFEAEBF5); // Fallback color
  }
}

class AllServicesScreen extends StatelessWidget {
  // We pass the full list of services to this screen
  final List<Map<String, dynamic>> services;

  const AllServicesScreen({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // Matches your home background
      appBar: AppBar(
        title: const Text(
          "All Services",
          style: TextStyle(
            color: Color(0xFF1A1C3A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: getColorFromHex(s['bg_color']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getIconFromString(s['icon_name']),
                  color: getColorFromHex(s['icon_color']),
                  size: 24,
                ),
              ),
              title: Text(
                s['title'] ?? "Service",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1C3A),
                ),
              ),
              subtitle: const Text("Professional service providers available"),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                showLocationSelection(context, s['title']);
              },
            ),
          );
        },
      ),
    );
  }
}

void showLocationSelection(BuildContext context, String serviceName) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Where do you need the service?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text("Use Current Location"),
              onTap: () async {
                LocationPermission permission =
                    await Geolocator.checkPermission();

                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }

                if (permission == LocationPermission.deniedForever) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Location permission permanently denied"),
                    ),
                  );
                  return;
                }

                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );

                Navigator.pop(context); // close bottom sheet AFTER location

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceProvidersScreen(
                      serviceName: serviceName,
                      latitude: position.latitude,
                      longitude: position.longitude,
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Select Different Location"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapPickerScreen(serviceName: serviceName),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
