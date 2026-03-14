import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../../core/models/destination_model.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';

class NavigationMapScreen extends StatefulWidget {
  final DestinationModel destination;

  const NavigationMapScreen({super.key, required this.destination});

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _currentLocation;
  late LatLng _destinationLocation;
  List<LatLng> _routePoints = [];
  
  double _distanceKm = 0.0;
  double _durationMin = 0.0;
  
  bool _isLoading = true;
  bool _isRouting = false;
  bool _isSatelliteView = false;
  
  // Drive Mode State
  bool _isNavigationActive = false;
  StreamSubscription<Position>? _positionStream;
  double _userHeading = 0.0;
  String _nextInstruction = "Head towards destination";
  List<dynamic> _routeSteps = [];
  
  List<Map<String, dynamic>> _recentSearches = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _destinationLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
    _searchController.text = widget.destination.name;
    _initNavigation();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _stopNavigation();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initNavigation() async {
    await _getCurrentLocation();
    if (_currentLocation != null) {
      _getRoute(_currentLocation!, _destinationLocation);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location. Please enable GPS.')),
        );
      }
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    if (start.latitude == 0 || start.longitude == 0 || end.latitude == 0 || end.longitude == 0) {
      debugPrint('Invalid coordinates for routing');
      return;
    }
    setState(() => _isRouting = true);
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline&steps=true';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          _distanceKm = route['distance'] / 1000;
          _durationMin = route['duration'] / 60;
          
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            _routeSteps = route['legs'][0]['steps'] ?? [];
            if (_routeSteps.isNotEmpty) {
              _nextInstruction = _routeSteps[0]['maneuver']['instruction'] ?? "Follow the route";
            }
          }
          
          setState(() {
            _routePoints = _decodePolyline(geometry);
          });
          
          if (!_isNavigationActive) {
            _fitRoute();
          }
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding route: $e')),
        );
      }
    } finally {
      setState(() => _isRouting = false);
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = <double>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift);
        shift += 5;
        index++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }

    var coordinates = <LatLng>[];
    for (var i = 0; i < lList.length; i += 2) {
      coordinates.add(LatLng(lList[i], lList[i + 1]));
    }
    return coordinates;
  }

  void _fitRoute() {
    if (_routePoints.isEmpty) return;
    
    final bounds = LatLngBounds.fromPoints(_routePoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'NavikaTouristApp/1.0',
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
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recentStr = prefs.getString('recent_searches');
    if (recentStr != null) {
      setState(() {
        _recentSearches = List<Map<String, dynamic>>.from(json.decode(recentStr));
      });
    }
  }

  Future<void> _saveRecentSearch(Map<String, dynamic> search) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists (to push to top)
    _recentSearches.removeWhere((item) => item['display_name'] == search['display_name']);
    _recentSearches.insert(0, search);
    
    // Limit to 5
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    
    await prefs.setString('recent_searches', json.encode(_recentSearches));
    setState(() {});
  }

  void _selectDestination(Map<String, dynamic> place) {
    _destinationLocation = LatLng(place['lat'], place['lon']);
    _saveRecentSearch(place);
    _searchController.text = place['display_name'];
    setState(() {
      _searchResults = [];
    });
    
    if (_currentLocation != null) {
      _getRoute(_currentLocation!, _destinationLocation);
    } else {
      _mapController.move(_destinationLocation, 14);
    }
  }

  void _startNavigation() {
    setState(() {
      _isNavigationActive = true;
    });
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      LatLng newPos = LatLng(position.latitude, position.longitude);
      
      // Update heading if speed is significant
      if (position.speed > 0.5) {
        _userHeading = position.heading;
      }
      
      setState(() {
        _currentLocation = newPos;
      });
      
      _mapController.move(newPos, 17);
      _checkDeviation(newPos);
      _updateNextInstruction(newPos);
    });
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _isNavigationActive = false;
      _userHeading = 0.0;
    });
  }

  void _checkDeviation(LatLng current) {
    if (_routePoints.isEmpty) return;
    
    double minDistance = double.infinity;
    for (var point in _routePoints) {
      double dist = Geolocator.distanceBetween(
        current.latitude, current.longitude,
        point.latitude, point.longitude
      );
      if (dist < minDistance) minDistance = dist;
    }
    
    if (minDistance > 50) { // Deviated by > 50 meters
      debugPrint('Deviated by ${minDistance.toInt()}m. Recalculating...');
      _getRoute(current, _destinationLocation);
    }
  }

  void _updateNextInstruction(LatLng current) {
    if (_routeSteps.isEmpty) return;
    
    // Find nearest step not yet reached
    for (var step in _routeSteps) {
      final stepLoc = step['maneuver']['location'];
      double dist = Geolocator.distanceBetween(
        current.latitude, current.longitude,
        stepLoc[1], stepLoc[0]
      );
      
      if (dist < 30) { // Within 30m of a maneuver point
        // In a real app we'd pop the step or check indices, 
        // here we'll just update based on proximity for simplicity
        setState(() {
          _nextInstruction = step['maneuver']['instruction'];
        });
      }
    }
  }

  Future<void> _launchExternalMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_destinationLocation.latitude},${_destinationLocation.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LuxuryGlass(
            padding: EdgeInsets.zero,
            blur: 10,
            opacity: 0.2,
            borderRadius: BorderRadius.circular(50),
            child: const BackButton(color: Colors.white),
          ),
        ),
        title: Text(
          'Navigation',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const AppBackground(child: SizedBox.shrink()),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)))
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _destinationLocation,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatelliteView 
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tourism_app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.4,
                        color: const Color(0xFF69F0AE),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 45,
                        height: 45,
                        child: Transform.rotate(
                          angle: (_userHeading * (3.14159 / 180)),
                          child: const Icon(
                            Icons.navigation, 
                            color: Colors.blueAccent, 
                            size: 35,
                          ),
                        ),
                      ),
                    Marker(
                      point: _destinationLocation,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          
          // Search Bar Overlay (Hidden during navigation)
          if (!_isNavigationActive)
            SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10), // Reduced from 50 to move it higher
                  LuxuryGlass(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(16),
                    opacity: 0.9, // Increased opacity for better readability
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        color: Colors.black, // Changed to black
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search destination...',
                        hintStyle: GoogleFonts.inter(color: Colors.black54), // Changed to black54
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.black45), // Changed to black45
                          onPressed: () => _searchPlaces(_searchController.text),
                        ),
                      ),
                      onSubmitted: _searchPlaces,
                    ),
                  ),
                  
                  if (_searchResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: LuxuryGlass(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(16),
                        opacity: 0.9,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined, color: Colors.blueAccent, size: 18),
                                title: Text(
                                  place['display_name'],
                                  style: GoogleFonts.inter(color: Colors.black, fontSize: 13), // Changed to black
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectDestination(place),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else if (_searchController.text.isEmpty && _recentSearches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: LuxuryGlass(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(16),
                        opacity: 0.8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('RECENT SEARCHES', style: GoogleFonts.inter(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                GestureDetector(
                                  onTap: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.remove('recent_searches');
                                    setState(() => _recentSearches = []);
                                  },
                                  child: Text('CLEAR', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._recentSearches.map((place) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(Icons.history, color: Colors.black26, size: 16),
                              title: Text(
                                place['display_name'],
                                style: GoogleFonts.inter(color: Colors.black87, fontSize: 12), // Changed to black87
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectDestination(place),
                            )).toList(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating Action Buttons
          Positioned(
            right: 16,
            bottom: _routePoints.isNotEmpty ? 140 : 24,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'recenter',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: () {
                    if (_currentLocation != null) {
                      _mapController.move(_currentLocation!, 15);
                    } else {
                      _getCurrentLocation();
                    }
                  },
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'target',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.flag, color: Colors.white),
                  onPressed: () => _mapController.move(_destinationLocation, 15),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'satellite',
                  mini: true,
                  backgroundColor: _isSatelliteView ? const Color(0xFF69F0AE) : Colors.white.withOpacity(0.1),
                  child: Icon(
                    _isSatelliteView ? Icons.map : Icons.satellite_alt, 
                    color: _isSatelliteView ? Colors.black : Colors.white,
                  ),
                  onPressed: () => setState(() => _isSatelliteView = !_isSatelliteView),
                ),
                if (!_isNavigationActive) ...[
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'google_maps',
                    mini: true,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.directions, color: Colors.white),
                    onPressed: _launchExternalMaps,
                  ),
                ],
              ],
            ),
          ),
          
          // Driving Mode UI Panel
          if (_isNavigationActive)
            Positioned(
              top: 50,
              left: 24,
              right: 24,
              child: LuxuryGlass(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                opacity: 0.9,
                child: Row(
                  children: [
                    const Icon(Icons.navigation, color: Colors.blueAccent, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('NEXT INSTRUCTION', style: GoogleFonts.inter(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_nextInstruction, style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Route Details Card / Navigation Panel
          if (_routePoints.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: LuxuryGlass(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                opacity: 0.2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isNavigationActive) ...[
                       Text(widget.destination.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                       const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isNavigationActive ? 'Remaining' : 'Distance', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${_distanceKm.toStringAsFixed(1)} km', style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Est. Time', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${_durationMin.toInt()} mins', style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _isNavigationActive ? _stopNavigation : _startNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isNavigationActive ? Colors.redAccent : Colors.white,
                            foregroundColor: _isNavigationActive ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_isNavigationActive ? 'End' : 'Start'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
          // Loading Overlay for Routing
          if (_isRouting)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF69F0AE)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
