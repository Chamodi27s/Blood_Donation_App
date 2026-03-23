import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // පාර පෙන්වීමට අවශ්‍යයි
import '../../services/location_service.dart';

class DonorMapScreen extends StatefulWidget {
  const DonorMapScreen({super.key});

  @override
  State<DonorMapScreen> createState() => _DonorMapScreenState();
}

class _DonorMapScreenState extends State<DonorMapScreen> {
  LatLng _center = const LatLng(6.9271, 79.8612); // Default Colombo
  final MapController _mapController = MapController();
  bool _isLoading = true;
  Map<String, dynamic>? _selectedData;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // පරිශීලකයාගේ වර්තමාන ස්ථානය ලබා ගැනීම
  _getUserLocation() async {
    try {
      Position pos = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _center = LatLng(pos.latitude, pos.longitude);
          _isLoading = false;
        });
        _mapController.move(_center, 14.5);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Google Maps හරහා පාර පෙන්වීම
  void _openDirections(double lat, double lng) async {
    final String url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. The Map ---
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.red))
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.0,
              onTap: (_, __) => setState(() => _selectedData = null),
            ),
            children: [
              TileLayer(
                // warning එක ඉවත් කරන ලද නිවැරදි URL එක
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bloodlink.app',
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const MarkerLayer(markers: []);

                  List<Marker> markers = [];

                  // User's Location Marker
                  markers.add(
                    Marker(
                      point: _center,
                      width: 60, height: 60,
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.blue, size: 45),
                    ),
                  );

                  // Campaign Markers (Firebase)
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;

                    if (data['geoPoint'] != null && data['geoPoint'] is GeoPoint) {
                      GeoPoint geo = data['geoPoint'];
                      markers.add(
                        Marker(
                          point: LatLng(geo.latitude, geo.longitude),
                          width: 90, height: 90,
                          child: _buildCampaignMarker(data),
                        ),
                      );
                    }
                  }

                  return MarkerLayer(markers: markers);
                },
              ),
            ],
          ),

          // --- 2. Transparent Floating Top Bar ---
          Positioned(
            top: 50, left: 20, right: 20,
            child: _buildFloatingTopBar(),
          ),

          // --- 3. Campaign Detail Card ---
          if (_selectedData != null) _buildInfoCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        onPressed: _getUserLocation,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }

  // --- UI Markers ---
  Widget _buildCampaignMarker(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => setState(() => _selectedData = data),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]),
            child: const Icon(Icons.bloodtype, color: Colors.red, size: 28),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
            child: Text(
              data['name'] ?? 'Camp',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Floating Top Bar ---
  Widget _buildFloatingTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
          const Expanded(
            child: Text("Nearby Campaigns", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // --- Info Card ---
  Widget _buildInfoCard() {
    GeoPoint geo = _selectedData!['geoPoint'];

    return Positioned(
      bottom: 30, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.local_hospital_rounded, color: Colors.red)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedData!['name'] ?? 'Blood Camp', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(_selectedData!['location'] ?? 'Location', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => setState(() => _selectedData = null), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("VIEW CAMP INFO", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: () => _openDirections(geo.latitude, geo.longitude),
                    icon: const Icon(Icons.directions_rounded, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}