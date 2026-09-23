import 'package:flutter/material.dart';
import '../app_config.dart';
import '../supabase_client.dart';
import '../service_provider_detail/service_provider_detail.dart';

class ServiceProvidersScreen extends StatefulWidget {
  final String serviceName;
  final double latitude;  // Received from Home (Current) or Map (Selected)
  final double longitude; // Received from Home (Current) or Map (Selected)

  const ServiceProvidersScreen({
    super.key,
    required this.serviceName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  static const Color primaryColor = Color(0xFF33365D);
  final String baseUrl = "${AppConfig.baseUrl}/";

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    // New uploads are full Supabase Storage URLs; old rows may still have
    // a relative "uploads/..." path from before the migration.
    return path.startsWith('http') ? path : "$baseUrl$path";
  }

  List<dynamic> _providers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // We no longer call Geolocator here because coordinates are passed in
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await supabase.rpc('nearby_providers', params: {
        'p_category': widget.serviceName,
        'p_lat': widget.latitude,
        'p_lng': widget.longitude,
        'p_radius_km': 8,
      });

      final list = data as List<dynamic>;
      if (list.isNotEmpty) {
        setState(() {
          _providers = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "No experts found within 8km of this location";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Please check your internet.";
        _isLoading = false;
      });
      print("Error: $e");
    }
  }

  // --- PRICE FORMATTING HELPER ---
  String _formatPrice(dynamic price) {
    if (price == null || price.toString() == "0" || price.toString() == "0.00") {
      return "Free Visit";
    }
    double p = double.tryParse(price.toString()) ?? 0;
    return "₹${p.toInt()}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.serviceName,
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            Text(
                _isLoading ? "Searching..." : "${_providers.length} experts found nearby",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildProviderList(),
    );
  }

  Widget _buildProviderList() {
    if (_errorMessage != null && _providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              TextButton(
                onPressed: _fetchProviders,
                child: const Text("Try Again", style: TextStyle(color: primaryColor)),
              )
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];

        double distanceValue = double.tryParse(provider['distance'].toString()) ?? 0.0;
        String distanceLabel = "${distanceValue.toStringAsFixed(1)} km away";

        return _buildProviderCard(
          context,
          providerData: provider,
          name: provider['full_name'] ?? "Expert",
          subTitle: distanceLabel,
          price: _formatPrice(provider['visiting_charges']),
          rating: "4.9",
          imageUrl: _resolveImageUrl(provider['profile_photo_path']),
          isVerified: true,
        );
      },
    );
  }

  Widget _buildProviderCard(BuildContext context, {
    required Map<String, dynamic> providerData,
    required String name,
    required String subTitle,
    required String price,
    required String rating,
    required String imageUrl,
    required bool isVerified,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceProviderDetailScreen(
              provider: providerData,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              _buildImageStack(imageUrl, rating),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                        Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                      ],
                    ),
                    Text(subTitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTag("Verified Partner"),
                        const SizedBox(width: 6),
                        if (isVerified) const Icon(Icons.verified, color: Colors.blue, size: 16),
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

  Widget _buildImageStack(String url, String rating) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url, height: 75, width: 75, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
                height: 75, width: 75, color: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey)
            ),
          ),
        ),
        Positioned(
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
            ),
            child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
                ]
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}