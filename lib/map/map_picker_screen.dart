import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../service_providers/service_providers.dart';

class MapPickerScreen extends StatefulWidget {
  final String serviceName;

  const MapPickerScreen({super.key, required this.serviceName});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {

  LatLng _draggedLocation = LatLng(23.0225, 72.5714); // Ahmedabad

  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Service Location")),
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _draggedLocation,
              initialZoom: 15,
              onPositionChanged: (position, _) {
                if (position.center != null) {
                  _draggedLocation = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.nearfix.app",
              ),
            ],
          ),

          const Center(
            child: Icon(Icons.location_on, size: 50, color: Colors.red),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33365D),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceProvidersScreen(
                      serviceName: widget.serviceName,
                      latitude: _draggedLocation.latitude,
                      longitude: _draggedLocation.longitude,
                    ),
                  ),
                );

              },
              child: const Text(
                "Confirm Location",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}