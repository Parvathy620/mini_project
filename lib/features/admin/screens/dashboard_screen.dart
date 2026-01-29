import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_confirmation_dialog.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../common/screens/unified_login_screen.dart';
import 'manage_categories/category_list_screen.dart';
import 'manage_destinations/destination_list_screen.dart';
import 'admin_verification_dashboard.dart';
import 'manage_providers/provider_management_screen.dart';
import '../../../core/services/verification_service.dart';
import '../widgets/glass_dashboard_tile.dart';
import '../../common/screens/settings_screen.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../../common/screens/notification_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazy Trigger: Global Expiration Check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VerificationService>(context, listen: false).checkAndProcessExpirations();
    });

        return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ADMIN',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        leading: StreamBuilder<List<AppNotification>>(
          // Listen to 'admin' notifications
          stream: Provider.of<NotificationService>(context, listen: false).getNotifications('admin'),
          builder: (context, snapshot) {
            final hasUnread = snapshot.data?.any((n) => !n.isRead) ?? false;
            return Center(
              child: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(12),
                blur: 5,
                opacity: 0.1,
                child: InkWell(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen(userId: 'admin')));
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, color: Colors.white, size: 20),
                      if (hasUnread)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(12),
                  blur: 5,
                  opacity: 0.1,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: const Icon(Icons.settings, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(12),
                  blur: 5,
                  opacity: 0.1,
                  child: InkWell(
                    onTap: () => _handleLogout(context),
                    child: const Icon(Icons.logout, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // drawer: _buildGlassDrawer(context), // REMOVED
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
                          backgroundColor: const Color(0xFF50C878),
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
                    'CONTROLS',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Row 1: Destinations & Categories
                RunwayReveal(
                  delayMs: 600,
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassDashboardTile(
                          title: 'Destinations',
                          subtitle: 'Global Coordinates',
                          icon: Icons.map,
                          color: const Color(0xFF50C878),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationListScreen())),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassDashboardTile(
                          title: 'Categories',
                          subtitle: 'Classification',
                          icon: Icons.category,
                          color: const Color(0xFF66BB6A),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Row 2: Verifications & Providers
                RunwayReveal(
                  delayMs: 700,
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassDashboardTile(
                          title: 'Verifications',
                          subtitle: 'Provider Requests',
                          icon: Icons.verified_user,
                          color: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminVerificationDashboard())),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassDashboardTile(
                          title: 'Providers',
                          subtitle: 'Manage Accounts',
                          icon: Icons.business_center,
                          color: Colors.tealAccent,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderManagementScreen())),
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
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Abort Session', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                   final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (c) => GlassConfirmationDialog(
                        title: 'Confirm',
                        content: 'End current session?',
                        confirmText: 'End',
                        cancelText: 'Stay',
                        confirmColor: Colors.redAccent,
                        onConfirm: () => Navigator.pop(c, true),
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: 'Sign Out?',
        content: 'Are you sure you want to log out of the admin console?',
        confirmText: 'Logout',
        confirmColor: Colors.redAccent,
        onConfirm: () async {
           // Close dialog
           Navigator.pop(context); 
           
           try {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                    (route) => false
                 );
              }
           } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
           }
        },
      ),
    );
  }
}
