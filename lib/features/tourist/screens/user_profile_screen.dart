import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/tourist_model.dart';
import '../../../core/models/destination_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../common/screens/booking_list_screen.dart'; // Reuse booking list logic? Or simple list.
// Actually, re-using _BookingList logic from BookingListScreen would be cleaner if it was public. 
// But let's keep it simple here or copy the fetch logic.
// Better yet: User already has a "Bookings" main tab.
// The profile bookings tab is redundant but requested.
// We'll reimplement a simple stream for it.
import '../../../core/services/booking_service.dart'; // Add this import
import '../../../core/models/booking_model.dart'; // Add this import
import '../widgets/edit_profile_dialog.dart';
import '../../common/screens/settings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const UserProfileScreen({super.key, this.onBackPressed});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) return const Center(child: Text('Login required'));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'PROFILE',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBackPressed ?? () => Navigator.maybePop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('tourists').doc(firebaseUser!.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));

              // Parse TouristModel
              TouristModel tourist;
              try {
                tourist = TouristModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, firebaseUser!.uid);
              } catch (e) {
                 // Fallback if document doesn't exist or is malformed
                 tourist = TouristModel(uid: firebaseUser!.uid, name: firebaseUser!.displayName ?? 'Tourist', email: firebaseUser!.email ?? '');
              }

              return Column(
                children: [
                  const SizedBox(height: 10),
                  // Profile Header
                  RunwayReveal(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF69F0AE).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: SafeNetworkImage(
                                imageUrl: 'https://ui-avatars.com/api/?name=${tourist.name}&background=0D8ABC&color=fff&size=512',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tourist.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            tourist.email,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                          if (tourist.age != null || tourist.mobile != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                if (tourist.age != null && tourist.age!.isNotEmpty)
                                  _buildInfoChip(Icons.cake, '${tourist.age} yrs'),
                                if (tourist.mobile != null && tourist.mobile!.isNotEmpty)
                                  _buildInfoChip(Icons.phone, tourist.mobile!),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditProfileDialog(tourist: tourist),
                              );
                            },
                            child: LuxuryGlass(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              borderRadius: BorderRadius.circular(30),
                              opacity: 0.1,
                              child: Text(
                                'Edit Profile', 
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF69F0AE), 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF69F0AE),
                    labelColor: const Color(0xFF69F0AE),
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                    unselectedLabelStyle: GoogleFonts.outfit(letterSpacing: 1),
                    dividerColor: Colors.white10,
                    tabs: const [
                      Tab(text: 'BOOKINGS'),
                      Tab(text: 'WISHLIST'),
                      Tab(text: 'SETTINGS'),
                    ],
                  ),

                  // Tab View
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRealBookingsTab(tourist.uid),
                        _buildWishlistTab(tourist),
                        const SettingsScreen(), // Embed Settings Screen directly
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF69F0AE)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildRealBookingsTab(String userId) {
    return StreamBuilder<List<BookingModel>>(
      stream: Provider.of<BookingService>(context, listen: false).getBookings(touristId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));
        
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) return Center(child: Text('No bookings yet.', style: GoogleFonts.inter(color: Colors.white54)));

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final isHistory = booking.status == 'completed' || booking.status == 'cancelled';
            
            return RunwayReveal(
              delayMs: index * 50,
              child: LuxuryGlass(
                opacity: 0.05,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.airplane_ticket_outlined,
                        color: isHistory ? Colors.white38 : const Color(0xFF69F0AE),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.providerName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isHistory ? Colors.white60 : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.serviceName.isNotEmpty ? booking.serviceName : 'Service',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.status == 'confirmed' ? Colors.green.withOpacity(0.2)
                        : booking.status == 'pending' ? Colors.orange.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: booking.status == 'confirmed' ? Colors.green
                          : booking.status == 'pending' ? Colors.orange
                          : Colors.red,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWishlistTab(TouristModel tourist) {
    if (tourist.wishlist.isEmpty) {
      return Center(child: Text('Your wishlist is empty.', style: GoogleFonts.inter(color: Colors.white54)));
    }

    return StreamBuilder<List<DestinationModel>>(
      // Ideally we would have a getDestinationsByIds, but streaming all and filtering is easier for now with current DataService
      stream: Provider.of<DataService>(context, listen: false).getDestinations(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));
        
        final allDestinations = snapshot.data ?? [];
        final wishlistDestinations = allDestinations.where((d) => tourist.wishlist.contains(d.id)).toList();

        if (wishlistDestinations.isEmpty) {
           // This could happen if destinations were deleted but IDs remain in wishlist
           return Center(child: Text('No destinations found.', style: GoogleFonts.inter(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          itemCount: wishlistDestinations.length,
          itemBuilder: (context, index) {
            final destination = wishlistDestinations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RunwayReveal(
                delayMs: index * 100,
                child: LuxuryGlass(
                  opacity: 0.05,
                  height: 90,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                       ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: destination.imageUrl.isNotEmpty
                                ? Image.network(destination.imageUrl, fit: BoxFit.cover)
                                : Container(color: Colors.white10),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              destination.district,
                              style: GoogleFonts.inter(color: const Color(0xFF69F0AE), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                           Provider.of<AuthService>(context, listen: false).toggleWishlist(tourist.uid, destination.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

