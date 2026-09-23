import 'package:flutter/material.dart';
import 'package:nearfix/booking_screen/scheduling_screen.dart';

import '../app_config.dart';
import '../supabase_client.dart';

const Color _primary = Color(0xFF33365D);
const Color _bg      = Color(0xFFF6F7FB);

class ServiceProviderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final double latitude;
  final double longitude;

  const ServiceProviderDetailScreen({
    super.key,
    required this.provider,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ServiceProviderDetailScreen> createState() =>
      _ServiceProviderDetailScreenState();
}

class _ServiceProviderDetailScreenState
    extends State<ServiceProviderDetailScreen> {
  // Update this URL whenever you restart ngrok
  final String _baseUrl =
      "${AppConfig.baseUrl}/";

  // --- REVIEW STATE ---
  List<dynamic> _reviewData = [];
  String _displayRating = "0.0";
  int _displayCount = 0;
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    // Use the initial values from the provider map as a fallback
    _displayRating = widget.provider['rating']?.toString() ?? "0.0";
    _displayCount = int.tryParse(widget.provider['total_reviews']?.toString() ?? "0") ?? 0;

    _loadAllReviewData();
  }

  Future<void> _loadAllReviewData() async {
    final pId = widget.provider['id'];
    try {
      final data = await supabase
          .rpc('get_provider_reviews', params: {'p_provider_id': pId})
          .timeout(const Duration(seconds: 8));

      if (data['success'] == true) {
        setState(() {
          _reviewData = data['reviews'] ?? [];
          _displayRating = data['avg_rating']?.toString() ?? "0.0";
          _displayCount = int.tryParse(data['total_count']?.toString() ?? "0") ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Review Fetch Error: $e");
    } finally {
      // CRITICAL: This ensures the loading spinner stops no matter what
      if (mounted) {
        setState(() => _loadingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String providerId = widget.provider['id']?.toString() ?? "0";
    final String name = widget.provider['full_name'] ?? widget.provider['name'] ?? "Provider";
    final String title = widget.provider['job_title'] ?? widget.provider['title'] ?? "Professional";
    final String aboutMe = widget.provider['about_me'] ?? "No biography provided.";
    final String experience = widget.provider['experience_years']?.toString() ?? "0";
    final String photoPath = widget.provider['profile_photo_path'] ?? "";
    final String charges = widget.provider['visiting_charges']?.toString() ?? "0";

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, photoPath, name, title),
                  const SizedBox(height: 16),
                  _buildStatsRow(experience),
                  const SizedBox(height: 14),
                  _buildPriceSection(charges),
                  const SizedBox(height: 14),
                  _buildAboutSection(name, aboutMe),
                  const SizedBox(height: 14),
                  _buildReviewCard(), // Integrated Review Section
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomBar(name, title, providerId, charges),
        ],
      ),
    );
  }

  // --- UI COMPONENTS (UNCHANGED DESIGN) ---

  Widget _buildHeader(BuildContext context, String path, String name, String title) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1F3E), Color(0xFF33365D), Color(0xFF282B52)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ArcPainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: _backBtn(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _avatar(path),
                    const SizedBox(width: 16),
                    Expanded(child: _nameAndTitle(name, title)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backBtn() => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0x33FFFFFF)),
    ),
    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
  );

  Widget _avatar(String path) => Stack(
    children: [
      Container(
        width: 78, height: 78,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: ClipOval(
          child: path.isNotEmpty
              ? Image.network(path.startsWith('http') ? path : "$_baseUrl$path", fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback())
              : _avatarFallback(),
        ),
      ),
      Positioned(bottom: 3, right: 3, child: _onlineDot()),
    ],
  );

  Widget _avatarFallback() => Container(color: const Color(0xFFEAEBF5), child: const Icon(Icons.person, size: 40, color: _primary));
  Widget _onlineDot() => Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)));

  Widget _nameAndTitle(String name, String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 7),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20)),
        child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Widget _buildStatsRow(String exp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEFF8)),
        ),
        child: Row(
          children: [
            _statCell(_displayRating, "RATING", Icons.star_rounded, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
            _divider(),
            _statCell("$exp Yrs", "EXPERIENCE", Icons.workspace_premium_rounded, _primary, const Color(0xFFEAEBF5)),
            _divider(),
            _statCell("Verified", "STATUS", Icons.verified_rounded, const Color(0xFF22C55E), const Color(0xFFDCFCE7)),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String val, String lbl, IconData icn, Color clr, Color bg) => Expanded(
    child: Column(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icn, color: clr, size: 18)),
        const SizedBox(height: 7),
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: clr)),
        Text(lbl, style: const TextStyle(fontSize: 10, color: Color(0xFF9B9DB8), fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _divider() => const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEFF5));

  Widget _buildPriceSection(String price) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEFF8))),
      child: Row(
        children: [
          _priceIcon(),
          const SizedBox(width: 16),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Visiting Charges", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B6D88))),
            Text("One-time inspection fee", style: TextStyle(fontSize: 11, color: Color(0xFF9B9DB8))),
          ])),
          _priceBadge(price),
        ],
      ),
    ),
  );

  Widget _priceIcon() => Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFF59E0B)));
  Widget _priceBadge(String price) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A))),
    child: Text("₹$price", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
  );

  Widget _buildAboutSection(String name, String bio) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEFF8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel("ABOUT $name"),
        const SizedBox(height: 14),
        Text(bio, style: const TextStyle(color: Color(0xFF4A4D6A), height: 1.7, fontSize: 14)),
      ]),
    ),
  );

  // --- DYNAMIC REVIEWS ---
  Widget _buildReviewCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEFF8))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel("REVIEWS"),
            const SizedBox(height: 16),
            _ratingSummaryRow(),
            const Divider(color: Color(0xFFF0F0F8), height: 32),
            if (_loadingReviews)
              const Center(child: CircularProgressIndicator(color: _primary))
            else if (_reviewData.isEmpty)
              const Center(child: Text("No reviews available.", style: TextStyle(color: Colors.grey, fontSize: 13)))
            else
              ..._reviewData.map((rev) => _reviewItem(rev)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _ratingSummaryRow() => Row(
    children: [
      Text(_displayRating, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: _primary, letterSpacing: -2)),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 18, color: i < double.parse(_displayRating).floor() ? const Color(0xFFF59E0B) : Colors.grey[200]))),
        Text("Based on $_displayCount reviews", style: const TextStyle(fontSize: 12, color: Color(0xFF9B9DB8))),
      ]),
    ],
  );

  Widget _reviewItem(dynamic rev) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF6F7FB), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(rev['user_name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < (rev['rating'] ?? 0) ? const Color(0xFFF59E0B) : Colors.grey[300]))),
      ]),
      const SizedBox(height: 8),
      Text("\"${rev['review']}\"", style: const TextStyle(fontSize: 13, color: Color(0xFF4A4D6A), fontStyle: FontStyle.italic)),
    ]),
  );

  Widget _sectionLabel(String text) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9B9DB8), letterSpacing: 1.2)),
  ]);

  Widget _buildBottomBar(String name, String job, String providerId, String amount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, -4))]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleServiceScreen(serviceName: job, providerId: providerId, visitingCharge: amount, latitude: widget.latitude, longitude: widget.longitude)));
        },
        child: Ink(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1C1F3E), Color(0xFF33365D)]), borderRadius: BorderRadius.circular(16)),
          child: Container(height: 60, alignment: Alignment.center, child: Text("Book Now  •  ₹$amount", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x0FFFFFFF);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(size.width * .88, size.height * .2), 40.0 + i * 30, p1);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}