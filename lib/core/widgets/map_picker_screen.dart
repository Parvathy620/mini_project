import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../widgets/luxury_glass.dart';
import '../widgets/app_background.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key, 
    this.initialLocation = const LatLng(10.8505, 76.2711), // Kerala center
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearching = true);
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'NavikaAdminApp/1.0',
      });
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) => {
            'display_name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Location',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const AppBackground(child: SizedBox.shrink()),
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tourism_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                  ),
                ],
              ),
            ],
          ),
          
          // Search Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10), // Reduced from 20
              child: Column(
                children: [
                  LuxuryGlass(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(16),
                    opacity: 0.8,
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: Colors.black), // Requested black color
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: GoogleFonts.inter(color: Colors.black54),
                        border: InputBorder.none,
                        suffixIcon: _isSearching 
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                          : IconButton(
                              icon: const Icon(Icons.search, color: Colors.black),
                              onPressed: () => _searchPlaces(_searchController.text),
                            ),
                      ),
                      onSubmitted: _searchPlaces,
                    ),
                  ),
                  
                  if (_searchResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                place['display_name'],
                                style: GoogleFonts.inter(color: Colors.black, fontSize: 13), // Requested black color
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                final latLng = LatLng(place['lat'], place['lon']);
                                setState(() {
                                  _selectedLocation = latLng;
                                  _searchResults = [];
                                  _searchController.clear();
                                });
                                _mapController.move(latLng, 15);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Confirm Button
          Positioned(
            bottom: 30,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF203A43),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 10,
              ),
              child: Text(
                'Confirm Selection',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
