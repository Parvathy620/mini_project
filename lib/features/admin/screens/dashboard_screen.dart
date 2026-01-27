import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../common/screens/unified_login_screen.dart';
import 'manage_categories/category_list_screen.dart';
import 'manage_destinations/destination_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'FLIGHT DECK',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildGlassDrawer(context),
      body: AppBackground(
        child: PopScope(
          canPop: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card with Runway Slide effect
                const RunwayReveal(
                  delayMs: 200,
                  child: LuxuryGlass(
                    opacity: 0.05,
                    blur: 30,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFF38BDF8),
                          child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text('Administrator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                             Text('System Operational', style: TextStyle(color: Colors.lightGreenAccent, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                RunwayReveal(
                  delayMs: 400,
                  child: Text(
                    'DATA CHANNELS',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Management Tiles
                RunwayReveal(
                  delayMs: 600,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassTile(
                          context,
                          title: 'Destinations',
                          subtitle: 'Global Coordinates',
                          icon: Icons.map,
                          color: const Color(0xFF38BDF8),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationListScreen())),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGlassTile(
                          context,
                          title: 'Categories',
                          subtitle: 'Classification',
                          icon: Icons.category,
                          color: const Color(0xFF818CF8), // Indigo
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Analytics Stub
                const RunwayReveal(
                  delayMs: 800,
                  child: LuxuryGlass(
                     opacity: 0.03,
                     height: 200,
                     child: Center(
                       child: Text(
                         'Prepare for Takeoff\nAnalytics Module In-Bound',
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.white24),
                       ),
                     ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AspectRatio(
      aspectRatio: 0.9,
      child: GestureDetector(
        onTap: onTap,
        child: LuxuryGlass(
          opacity: 0.1,
          blur: 10,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent, // Important for glass effect
      width: 280,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
        child: LuxuryGlass(
          opacity: 0.15,
          blur: 50,
          borderRadius: BorderRadius.zero,
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.flight, color: Colors.white, size: 50),
              const SizedBox(height: 20),
              Text('NAVIKA ADMIN', style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 40),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: Colors.white),
                title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white),
                title: const Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Abort Session', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                   final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
                        content: const Text('End current session?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('End')),
                        ],
                      ),
                   );
                   if (shouldLogout == true && context.mounted) {
                     await Provider.of<AuthService>(context, listen: false).signOut();
                     if (context.mounted) {
                       Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                          (route) => false
                       );
                     }
                   }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _unusedMethod() {
     // Placeholder to match previous structure length if needed, but not required
  }
}
