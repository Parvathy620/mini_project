import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/destination_model.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/services/data_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../../core/widgets/glass_filter_panel.dart';
import '../../../core/widgets/glass_confirmation_dialog.dart';
import 'provider_search_screen.dart';
import 'user_profile_screen.dart';
import '../../common/screens/unified_login_screen.dart';
import '../../common/screens/booking_list_screen.dart';
import '../../common/screens/enquiry_list_screen.dart';
import '../../common/screens/notification_list_screen.dart';
import '../../common/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/tourist_model.dart';

class TouristDashboardScreen extends StatefulWidget {
  const TouristDashboardScreen({super.key});

  @override
  State<TouristDashboardScreen> createState() => _TouristDashboardScreenState();
}



class _TouristDashboardScreenState extends State<TouristDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  late final List<Widget> _pages;
  bool _isNavBarVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pages = [
      const _ExploreTab(),
      const BookingListScreen(isProvider: false),
      const EnquiryListScreen(isProvider: false),
      UserProfileScreen(onBackPressed: () => _onItemTapped(0)),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isNavBarVisible = true; // Always show nav bar when changing tabs
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: AppBackground(
        child: Stack(
          children: [
            // Content Layer
            Positioned.fill(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.reverse && _isNavBarVisible) {
                    setState(() => _isNavBarVisible = false);
                  } else if (notification.direction == ScrollDirection.forward && !_isNavBarVisible) {
                    setState(() => _isNavBarVisible = true);
                  }
                  return true;
                },
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: _pages,
                ),
              ),
            ),

            // Gradient Background under Nav Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: _isNavBarVisible ? 0 : -150,
              height: 150,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF051F20).withOpacity(0.8), // Faded Deep Jungle
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Navigation Bar Layer
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _isNavBarVisible ? 0 : -100,
              left: 0,
              right: 0, 
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12), // Margin from bottom
                  child: LuxuryGlass(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    borderRadius: BorderRadius.circular(30),
                    blur: 20,
                    opacity: 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.explore_outlined, Icons.explore, 0, 'Explore'),
                      _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_today, 1, 'Bookings'),
                      _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 2, 'Messages'),
                      _buildNavItem(Icons.person_outline, Icons.person, 3, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
      // bottomNavigationBar: Removed to prevent square background
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF69F0AE).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        // ... (rest of _buildNavItem logic remains same but ensuring it exists in replacement)
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? const Color(0xFF69F0AE) : Colors.white70),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExploreTab extends StatefulWidget {
  const _ExploreTab();

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool _isGridView = true;

  // Filters State
  List<String> _selectedDistricts = [];
  List<String> _selectedCategories = [];
  RangeValues _priceRange = const RangeValues(0, 10000); 
  bool _onlyAvailable = false;
  late Stream<List<DestinationModel>> _allDestinationsStream;

  final List<String> _allDistricts = [
    'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha', 
    'Kottayam', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad', 
    'Malappuram', 'Kozhikode', 'Wayanad', 'Kannur', 'Kasargod'
  ];
  final List<String> _allCategories = ['Beach', 'Hill Station', 'Heritage', 'Pilgrim', 'Wildlife', 'Backwater', 'Urban'];

  @override
  void initState() {
    super.initState();
    final dataService = Provider.of<DataService>(context, listen: false);
    _allDestinationsStream = dataService.getDestinations(); // Fetch all once
  }

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

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: 'Logout',
        content: 'Are you sure you want to logout?',
        confirmText: 'Logout',
        confirmColor: Colors.redAccent,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (shouldLogout == true) {
      if (!mounted) return;
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: 'Exit App',
        content: 'Do you want to exit the application?',
        confirmText: 'Exit',
        confirmColor: Colors.redAccent,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    // Note: We use Scaffold here mainly for the AppBar. 
    // The background is provided by the parent.
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'EXPLORE',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationListScreen()),
              );
            }, 
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: Colors.white,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white54),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white54),
              onPressed: _handleLogout,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tourists')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    List<String> wishlist = [];
                    if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                       try {
                         final data = userSnapshot.data!.data() as Map<String, dynamic>;
                         wishlist = List<String>.from(data['wishlist'] ?? []);
                       } catch (e) {
                         // mismatch or error
                       }
                    }

                    return StreamBuilder<List<DestinationModel>>(
                      stream: _allDestinationsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.redAccent)));
                        }
                        
                        var destinations = snapshot.data ?? [];

                        // Client-side Filtering
                        if (_searchQuery.isNotEmpty) {
                          destinations = destinations.where((d) => 
                            d.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            d.district.toLowerCase().contains(_searchQuery.toLowerCase())
                          ).toList();
                        }

                        if (_selectedDistricts.isNotEmpty) {
                          destinations = destinations.where((d) => _selectedDistricts.contains(d.district)).toList();
                        }
                        if (_selectedCategories.isNotEmpty) {
                          destinations = destinations.where((d) => _selectedCategories.contains(d.category)).toList();
                        }
                        if (_onlyAvailable) {
                          destinations = destinations.where((d) => d.isAvailable).toList();
                        }

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
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
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
                                    child: _buildDestinationCard(context, destinations[index], wishlist),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                                itemCount: destinations.length,
                                itemBuilder: (context, index) {
                                  return RunwayReveal(
                                    delayMs: (index % 8) * 50,
                                    key: ValueKey(destinations[index].id),
                                    child: _buildDestinationListItem(context, destinations[index], wishlist),
                                  );
                                },
                              );
                      },
                    );
                  }
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
        color: const Color(0xFF69F0AE).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF69F0AE))),
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: const Color(0xFF69F0AE)),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, DestinationModel destination, List<String> wishlist) {
    final isWishlisted = wishlist.contains(destination.id);
    return GestureDetector(
      onTap: () => _navigateToProviderSearch(context, destination),
      child: Hero(
        tag: 'destination_card_${destination.id}',
        child: LuxuryGlass(
          padding: EdgeInsets.zero,
          blur: 0, 
          opacity: 0.05,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SafeNetworkImage(
                  imageUrl: destination.googleDriveImageUrl.isNotEmpty 
                      ? destination.googleDriveImageUrl 
                      : destination.imageUrl,
                  fit: BoxFit.cover,
                  fallback: Container(
                    color: Colors.white10,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: destination.isAvailable 
                          ? Colors.green.withOpacity(0.8) 
                          : Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        destination.isAvailable ? 'OPEN' : 'CLOSED',
                        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
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
                        color: const Color(0xFF69F0AE),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ],
                ),
              ),

              // Wishlist Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                     final user = FirebaseAuth.instance.currentUser;
                     if (user != null) {
                       Provider.of<AuthService>(context, listen: false).toggleWishlist(user.uid, destination.id);
                     }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.redAccent : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationListItem(BuildContext context, DestinationModel destination, List<String> wishlist) {
    final isWishlisted = wishlist.contains(destination.id);
    return GestureDetector(
      onTap: () => _navigateToProviderSearch(context, destination),
      child: Hero(
        tag: 'destination_list_${destination.id}',
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: RepaintBoundary(
            child: LuxuryGlass(
              padding: const EdgeInsets.all(12),
              height: 130, // Increased to 130 to fit content comfortably with long text options
              blur: 5, // Reduced blur for better scroll performance
              opacity: 0.1,
              child: Row(
                children: [
                // Image Section
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: SafeNetworkImage(
                      imageUrl: destination.googleDriveImageUrl.isNotEmpty 
                          ? destination.googleDriveImageUrl 
                          : destination.imageUrl,
                      fit: BoxFit.cover,
                      fallback: Container(color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
                    ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: destination.isAvailable 
                                  ? Colors.green.withOpacity(0.2) 
                                  : Colors.red.withOpacity(0.2),
                                border: Border.all(color: destination.isAvailable ? Colors.green : Colors.red),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                destination.isAvailable ? 'Open' : 'Closed',
                                style: GoogleFonts.inter(fontSize: 9, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: const Color(0xFF69F0AE)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                destination.district,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF69F0AE),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
                
                // Wishlist Button
                IconButton(
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border, 
                    color: isWishlisted ? Colors.redAccent : Colors.white30
                  ),
                  onPressed: () {
                     final user = FirebaseAuth.instance.currentUser;
                     if (user != null) {
                       Provider.of<AuthService>(context, listen: false).toggleWishlist(user.uid, destination.id);
                     }
                  },
                ),
              ],
            ),
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
