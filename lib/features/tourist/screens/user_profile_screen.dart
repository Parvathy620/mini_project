import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/runway_reveal.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? user = FirebaseAuth.instance.currentUser;

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
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Header
              RunwayReveal(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        image: const DecorationImage(
                          // Placeholder avatar
                          image: NetworkImage('https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff&size=512'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email?.split('@')[0].toUpperCase() ?? 'EXPLORER', // Fallback name
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      user?.email ?? 'explorer@navika.com',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LuxuryGlass(
                      height: 40,
                      width: 120,
                      padding: EdgeInsets.zero,
                      opacity: 0.1,
                      child: TextButton(
                        onPressed: () {
                           // Edit Profile Logic (Placeholder)
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Edit Profile layout placeholder')),
                           );
                        },
                        child: Text(
                          'Edit Profile', 
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
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
                    _buildBookingsTab(),
                    _buildWishlistTab(),
                    _buildSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    // Mock Data
    final bookings = [
      {'title': 'Munnar Hill Resort', 'date': 'Today', 'status': 'Active', 'type': 'Hotel'},
      {'title': 'Kovalam Guided Tour', 'date': 'Tomorrow', 'status': 'Upcoming', 'type': 'Guide'},
      {'title': 'Houseboat Cruise', 'date': 'Last Month', 'status': 'Completed', 'type': 'Activity'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isHistory = booking['status'] == 'Completed';
        
        return RunwayReveal(
          delayMs: index * 100,
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
                    booking['type'] == 'Hotel' ? Icons.hotel 
                    : booking['type'] == 'Guide' ? Icons.person_pin 
                    : Icons.directions_boat,
                    color: isHistory ? Colors.white38 : Colors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHistory ? Colors.white60 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['date'] as String,
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
                    color: booking['status'] == 'Active' ? Colors.green.withOpacity(0.2)
                    : booking['status'] == 'Upcoming' ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: booking['status'] == 'Active' ? Colors.green
                      : booking['status'] == 'Upcoming' ? Colors.blue
                      : Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    booking['status'] as String,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWishlistTab() {
    // Mock Wishlist
    final wishlist = ['Varkala Beach', 'Athirappilly Waterfalls'];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RunwayReveal(
            delayMs: index * 100,
            child: LuxuryGlass(
              opacity: 0.05,
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    wishlist[index],
                    style: GoogleFonts.outfit(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white38),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
         _buildSettingItem('Notifications', Icons.notifications_outlined),
         _buildSettingItem('Privacy & Security', Icons.security_outlined),
         _buildSettingItem('App Preferences', Icons.tune_outlined),
         _buildSettingItem('Help & Support', Icons.help_outline),
         const SizedBox(height: 24),
         LuxuryGlass(
           padding: const EdgeInsets.all(16),
           opacity: 0.1,
             child: InkWell(
               onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Logout', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: Text('Are you sure you want to logout?', style: GoogleFonts.inter(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.cyanAccent)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Logout', style: GoogleFonts.inter(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    if (!mounted) return;
                    await Provider.of<AuthService>(context, listen: false).signOut();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
               },
               child: Row(
               children: [
                 const Icon(Icons.logout, color: Colors.redAccent),
                 const SizedBox(width: 16),
                 Text(
                   'Logout',
                   style: GoogleFonts.outfit(
                     color: Colors.redAccent,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ],
             ),
           ),
         ),
      ],
    );
  }

  Widget _buildSettingItem(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LuxuryGlass(
        opacity: 0.05,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
             Icon(icon, color: Colors.white70, size: 20),
             const SizedBox(width: 16),
             Text(title, style: GoogleFonts.inter(color: Colors.white)),
             const Spacer(),
             const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
