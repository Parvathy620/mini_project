import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/service_provider_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../../core/widgets/glass_filter_panel.dart';

class ProviderSearchScreen extends StatefulWidget {
  final String destinationId;
  final String destinationName;

  const ProviderSearchScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
  });

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  
  // Filter State
  List<String> _selectedCategories = []; // Using names for UI match, but need IDs for backend potentially
  // Actually, DataService filters by CategoryId. FilterPanel uses generic strings.
  // We need to map category names to IDs.
  Map<String, String> _categoryNameToId = {};
  List<String> _categoryNames = [];

  RangeValues _priceRange = const RangeValues(0, 10000);
  bool _onlyAvailable = false;
  String _sortBy = 'rating_desc'; // rating_desc, price_asc, price_desc, availability

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
        availableDistricts: const [], // No district filter for providers within destination
        availableCategories: _categoryNames,
        selectedDistricts: const [],
        selectedCategories: _selectedCategories,
        priceRange: _priceRange,
        onlyAvailable: _onlyAvailable,
        onApply: (districts, categories, price, available) {
          setState(() {
            _selectedCategories = categories;
            _priceRange = price;
            _onlyAvailable = available;
          });
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedCategories = [];
            _priceRange = const RangeValues(0, 10000);
            _onlyAvailable = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildSortOption('Recommended (Rating)', 'rating_desc'),
            _buildSortOption('Price: Low to High', 'price_asc'),
            _buildSortOption('Price: High to Low', 'price_desc'),
            _buildSortOption('Availability', 'availability'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.inter(color: isSelected ? Colors.cyanAccent : Colors.white70)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.destinationName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search & Controls Layer
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
                            hintText: 'Search services...',
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
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    LuxuryGlass(
                      height: 50,
                      width: 50,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      blur: 15,
                      opacity: 0.1,
                      child: IconButton(
                        icon: const Icon(Icons.sort_rounded, color: Colors.white),
                        onPressed: _showSortOptions,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Filters
              if (_selectedCategories.isNotEmpty || _onlyAvailable)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (_onlyAvailable) 
                        _buildFilterChip('Available Only', () => setState(() => _onlyAvailable = false)),
                      ..._selectedCategories.map((c) => _buildFilterChip(c, () => setState(() => _selectedCategories.remove(c)))),
                    ],
                  ),
                ),

              // Load Categories to populate filter panel implicitly
              StreamBuilder<List<CategoryModel>>(
                stream: dataService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // Update the mapping for filters
                    final categories = snapshot.data!;
                    _categoryNames = categories.map((c) => c.name).toList();
                    for (var c in categories) {
                      _categoryNameToId[c.name] = c.id;
                    }
                  }
                  return const SizedBox.shrink(); // Invisible, just used for side-effect of data loading
                },
              ),

              // Providers List
              Expanded(
                child: StreamBuilder<List<ServiceProviderModel>>(
                  stream: dataService.getServiceProviders(
                    destinationId: widget.destinationId,
                    // We don't filter by category ID in stream because we support multi-select categories client-side
                    // Passing null fetches all for this destination
                    searchQuery: _searchQuery,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading providers', style: GoogleFonts.inter(color: Colors.redAccent)));
                    }

                    var providers = snapshot.data ?? [];

                    // Client-side Filtering & Sorting
                    // 1. Categories
                    if (_selectedCategories.isNotEmpty) {
                      // Filter if provider has ANY of selected category IDs
                      // Convert selected names to IDs
                      final selectedIds = _selectedCategories.map((n) => _categoryNameToId[n]).whereType<String>().toSet();
                      providers = providers.where((p) => selectedIds.contains(p.categoryId)).toList();
                    }

                    // 2. Availability
                    if (_onlyAvailable) {
                      providers = providers.where((p) => p.isAvailable).toList();
                    }

                    // 3. Price (Approximate filter)
                    // Assuming priceRange is string like '$$$' or number? Model says String.
                    // We can't strictly filter string range with numeric controls easily without parsing.
                    // Skipping numeric price filter for now unless parsing logic is added.

                    // 4. Sorting
                    switch (_sortBy) {
                      case 'price_asc':
                        providers.sort((a, b) => a.priceRange.length.compareTo(b.priceRange.length)); // Rough proxy
                        break;
                      case 'price_desc':
                        providers.sort((a, b) => b.priceRange.length.compareTo(a.priceRange.length));
                        break;
                      case 'availability':
                        providers.sort((a, b) => (b.isAvailable ? 1 : 0).compareTo(a.isAvailable ? 1 : 0));
                        break;
                      case 'rating_desc':
                      default:
                        providers.sort((a, b) => b.rating.compareTo(a.rating));
                        break;
                    }

                    if (providers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No service providers found.',
                              style: GoogleFonts.inter(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: providers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return RunwayReveal(
                          delayMs: (index % 8) * 50,
                          slideUp: true,
                          child: _buildProviderCard(providers[index]),
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
      margin: const EdgeInsets.only(right: 8, bottom: 8),
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

  Widget _buildProviderCard(ServiceProviderModel provider) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              image: provider.profileImageUrl.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(provider.profileImageUrl), 
                      fit: BoxFit.cover
                    ) 
                  : null,
            ),
            child: provider.profileImageUrl.isEmpty 
                ? const Icon(Icons.person, color: Colors.white54, size: 30) 
                : null,
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        provider.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Services Tags
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: provider.services.take(3).map((service) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      service,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 14, color: Colors.greenAccent.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text(
                      provider.priceRange.isNotEmpty ? provider.priceRange : 'Ask for price',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.greenAccent.withOpacity(0.8)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                           BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Text(
                        'Book Now',
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
