import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/destination_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../../core/widgets/glass_filter_panel.dart';
import 'provider_search_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool _isGridView = true;

  // Filters State
  List<String> _selectedDistricts = [];
  List<String> _selectedCategories = [];
  RangeValues _priceRange = const RangeValues(0, 10000); // Placeholder relative range if price was available
  bool _onlyAvailable = false;

  // Mock Data for Filters (In a real app, fetch unique values from DB)
  final List<String> _allDistricts = [
    'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha', 
    'Kottayam', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad', 
    'Malappuram', 'Kozhikode', 'Wayanad', 'Kannur', 'Kasargod'
  ];
  final List<String> _allCategories = ['Beach', 'Hill Station', 'Heritage', 'Pilgrim', 'Wildlife', 'Backwater', 'Urban'];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassFilterPanel(
        availableDistricts: _allDistricts,
        availableCategories: _allCategories,
        selectedDistricts: _selectedDistricts,
        selectedCategories: _selectedCategories,
        priceRange: _priceRange,
        onlyAvailable: _onlyAvailable,
        onApply: (districts, categories, price, available) {
          setState(() {
            _selectedDistricts = districts;
            _selectedCategories = categories;
            _priceRange = price;
            _onlyAvailable = available;
          });
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedDistricts = [];
            _selectedCategories = [];
            _priceRange = const RangeValues(0, 10000);
            _onlyAvailable = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'DISCOVER',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: LuxuryGlass(
                        height: 50,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(16),
                        blur: 15,
                        opacity: 0.1,
                        hasReflection: false,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search destinations...',
                            hintStyle: GoogleFonts.inter(color: Colors.white38),
                            prefixIcon: const Icon(Icons.search, color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: _searchQuery.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    LuxuryGlass(
                      height: 50,
                      width: 50,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      blur: 15,
                      opacity: 0.1,
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Colors.white),
                        onPressed: _openFilterPanel,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Filters Indicators
              if (_selectedDistricts.isNotEmpty || _selectedCategories.isNotEmpty || _onlyAvailable)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (_onlyAvailable) 
                        _buildFilterChip('Available Only', () => setState(() => _onlyAvailable = false)),
                      ..._selectedDistricts.map((d) => _buildFilterChip(d, () => setState(() => _selectedDistricts.remove(d)))),
                      ..._selectedCategories.map((c) => _buildFilterChip(c, () => setState(() => _selectedCategories.remove(c)))),
                    ],
                  ),
                ),
                
              const SizedBox(height: 8),

              // Destinations List/Grid
              Expanded(
                child: StreamBuilder<List<DestinationModel>>(
                  stream: dataService.getDestinations(query: _searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.redAccent)));
                    }
                    
                    var destinations = snapshot.data ?? [];

                    // Client-side Filtering
                    if (_selectedDistricts.isNotEmpty) {
                      destinations = destinations.where((d) => _selectedDistricts.contains(d.district)).toList();
                    }
                    if (_selectedCategories.isNotEmpty) {
                      destinations = destinations.where((d) => _selectedCategories.contains(d.category)).toList();
                    }
                    if (_onlyAvailable) {
                      destinations = destinations.where((d) => d.isAvailable).toList();
                    }
                    // Price filtering for destinations isn't directly applicable unless destination has entry fee, 
                    // but we will skip it for now as per model limitations or assume it filters providers later.

                    if (destinations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No destinations found.',
                              style: GoogleFonts.inter(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    return _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75, // Taller cards
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: destinations.length,
                            itemBuilder: (context, index) {
                              return RunwayReveal(
                                delayMs: (index % 8) * 50,
                                key: ValueKey(destinations[index].id),
                                child: _buildDestinationCard(context, destinations[index]),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: destinations.length,
                            itemBuilder: (context, index) {
                              return RunwayReveal(
                                delayMs: (index % 8) * 50,
                                key: ValueKey(destinations[index].id),
                                child: _buildDestinationListItem(context, destinations[index]),
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.cyanAccent)),
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: Colors.cyanAccent),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, DestinationModel destination) {
    return GestureDetector(
      onTap: () => _navigateToProviderSearch(context, destination),
      child: Hero(
        tag: 'destination_card_${destination.id}',
        child: LuxuryGlass(
          padding: EdgeInsets.zero,
          blur: 0, // Performance optimization for grids, rely on image mainly
          opacity: 0.05,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: destination.imageUrl.isNotEmpty
                    ? Image.network(
                        destination.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10),
                      )
                    : Container(
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                      ),
              ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: destination.isAvailable 
                          ? Colors.green.withOpacity(0.8) 
                          : Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        destination.isAvailable ? 'OPEN' : 'CLOSED',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.district,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.cyanAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildDestinationListItem(BuildContext context, DestinationModel destination) {
    return GestureDetector(
      onTap: () => _navigateToProviderSearch(context, destination),
      child: Hero(
        tag: 'destination_list_${destination.id}',
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: LuxuryGlass(
            padding: const EdgeInsets.all(12),
            height: 120,
            blur: 20,
            opacity: 0.1,
            child: Row(
              children: [
                // Image Section
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: destination.imageUrl.isNotEmpty
                        ? Image.network(
                            destination.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10),
                          )
                        : Container(color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
                  ),
                ),
                
                // Text Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                destination.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: destination.isAvailable 
                                  ? Colors.green.withOpacity(0.2) 
                                  : Colors.red.withOpacity(0.2),
                                border: Border.all(color: destination.isAvailable ? Colors.green : Colors.red),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                destination.isAvailable ? 'Open' : 'Closed',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.cyanAccent),
                            const SizedBox(width: 4),
                            Text(
                              destination.district,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProviderSearch(BuildContext context, DestinationModel destination) {
    Navigator.push(
      context, 
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProviderSearchScreen(
          destinationId: destination.id, 
          destinationName: destination.name
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
