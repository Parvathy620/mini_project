import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/widgets/glass_confirmation_dialog.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/models/verification_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../admin/widgets/glass_dashboard_tile.dart';
import '../../common/screens/notification_list_screen.dart';
import 'verification_submission_screen.dart';
import '../../common/screens/unified_login_screen.dart';
import 'sp_profile_screen.dart';
import '../../common/screens/settings_screen.dart';
import '../widgets/verification_status_card.dart';
import '../../common/screens/booking_list_screen.dart';
import '../../common/screens/enquiry_list_screen.dart';
import 'manage_availability_screen.dart';

class SPDashboardScreen extends StatefulWidget {
  const SPDashboardScreen({super.key});

  @override
  State<SPDashboardScreen> createState() => _SPDashboardScreenState();
}

class _SPDashboardScreenState extends State<SPDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<DocumentSnapshot> _providerStream;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      _providerStream = _firestore.collection('service_providers').doc(user.uid).snapshots();
      // Lazy Trigger: Check my own expiry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<VerificationService>(context, listen: false).checkProviderExpiry(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _providerStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text('Error loading profile')));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Scaffold(body: Center(child: Text('Profile not found')));

        final isApproved = data['isApproved'] ?? false;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context),
          body: AppBackground(
            child: isApproved ? _buildActiveDashboard(data) : _buildPendingView(context),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'PROVIDER',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2.0,
          fontSize: 16,
        ),
      ),
      leading: StreamBuilder<List<AppNotification>>(
        stream: Provider.of<VerificationService>(context, listen: false).getNotifications(Provider.of<AuthService>(context, listen: false).currentUser!.uid),
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
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen()));
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
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
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
                  onTap: () async {
                     final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (c) => GlassConfirmationDialog(
                          title: 'Confirm Logout',
                          content: 'Are you sure you want to log out?',
                          confirmText: 'Logout',
                          confirmColor: Colors.redAccent,
                          onConfirm: () => Navigator.pop(c, true),
                        ),
                     );
                     
                     if (shouldLogout == true && context.mounted) {
                        await Provider.of<AuthService>(context, listen: false).signOut();
                        if (context.mounted) {
                           Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => UnifiedLoginScreen()),
                              (route) => false,
                           );
                        }
                     }
                  },
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDashboard(Map<String, dynamic> data) {
    final verificationService = Provider.of<VerificationService>(context, listen: false);
    final uid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    final isApproved = data['isApproved'] == true;

    return SafeArea(
      top: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const SizedBox(height: 70), // Removed to move widgets top
          GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => SPProfileScreen()));
            },
            child: LuxuryGlass(
              padding: const EdgeInsets.all(20),
              opacity: 0.15,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withOpacity(0.1)),
                    child: ClipOval(
                      child: SafeNetworkImage(
                        imageUrl: (data['googleDriveImageUrl'] != null && data['googleDriveImageUrl'].toString().isNotEmpty)
                            ? data['googleDriveImageUrl']
                            : data['profileImageUrl'],
                        fit: BoxFit.cover,
                        fallback: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Provider', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        // Simple Status Badge (Detailed info in card below)
                        StreamBuilder<ProviderVerification?>(
                          stream: verificationService.getVerificationStream(uid),
                          builder: (context, snapshot) {
                             if (snapshot.connectionState == ConnectionState.waiting) {
                               return const SizedBox(
                                 height: 16, 
                                 width: 16, 
                                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                               );
                             }
                             
                             final status = snapshot.data?.status;
                             final isVerified = status == VerificationStatus.approved;
                             
                             Color badgeColor = Colors.orange;
                             String badgeText = 'ACTION NEEDED';
                             
                             // If isVerified is explicitly true from profile data, trust it even if stream fails or is empty initially
                           if (isApproved) {
                             badgeColor = Colors.green;
                             badgeText = 'VERIFIED';
                           } else if (snapshot.hasData && status == VerificationStatus.pending) {
                              badgeColor = Colors.amber;
                              badgeText = 'PENDING';
                           } else if (!snapshot.hasData && !isApproved) {
                             // No data and not approved -> Action Needed
                             badgeColor = Colors.orange;
                             badgeText = 'ACTION NEEDED';
                           }

                           return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor, 
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Text(
                                badgeText, 
                                style: const TextStyle(color: Colors.white, fontSize: 10)
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Optional Edit Icon to indicate clickability
                  const Icon(Icons.edit, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12), // Reduced from 20
           
           // Verification Status Section
           StreamBuilder<ProviderVerification?>(
             stream: verificationService.getVerificationStream(uid),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
               }
               
               // If no verification data found, but user is approved (Legacy/Manual), show a dummy "Verified" card
               if (!snapshot.hasData || snapshot.data == null) {
                  if (isApproved) {
                    return VerificationStatusCard(
                      verification: ProviderVerification(
                        id: 'manual', 
                        providerId: uid, 
                        documentType: 'manual', 
                        documentUrl: '', 
                        status: VerificationStatus.approved, 
                        submittedAt: DateTime.now()
                      ), 
                      onReverify: () {}
                    );
                  }
                  return const SizedBox();
               }

               return VerificationStatusCard(
                 verification: snapshot.data,
                 onReverify: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VerificationSubmissionScreen()));
                 },
               );
             },
           ),

           const SizedBox(height: 12), // Reduced from 20

           // Use placeholder for other stats for now
           // Actions Grid
           // Actions Grid
           // Actions Grid
           Row(
             children: [
               Expanded(
                 child: GlassDashboardTile(
                   icon: Icons.calendar_month,
                   title: 'Availability',
                   subtitle: 'Manage slots',
                   color: const Color(0xFF69F0AE),
                   onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAvailabilityScreen()));
                   },
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: GlassDashboardTile(
                   icon: Icons.bookmark_border,
                   title: 'Bookings',
                   subtitle: 'View reservations',
                   color: Colors.purpleAccent,
                   onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingListScreen(isProvider: true)));
                   },
                 ),
               ),
             ],
           ),
           const SizedBox(height: 12),
           Row( // Second row for Enquiry or future items
              children: [
                Expanded(
                 child: GlassDashboardTile(
                   icon: Icons.chat_bubble_outline,
                   title: 'Enquiries',
                   subtitle: 'Customer questions',
                   color: Colors.orangeAccent,
                   onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EnquiryListScreen(isProvider: true)));
                   },
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(child: SizedBox()), // Placeholder for balance
              ],
           ),
        ],
      ),
    ),
    );
  }

  Widget _buildPendingView(BuildContext context) {
    final uid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    final verificationService = Provider.of<VerificationService>(context, listen: false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(32),
          opacity: 0.15,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_filled_rounded, size: 64, color: Colors.orangeAccent),
              ),
              const SizedBox(height: 24),
              Text(
                'Account Pending Approval',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You will be able to manage your services once your account is approved by the Admin.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => VerificationSubmissionScreen()));
                },
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF203A43),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: StreamBuilder<ProviderVerification?>(
                  stream: verificationService.getVerificationStream(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF203A43))
                      );
                    }
                    
                    final hasSubmitted = snapshot.hasData && snapshot.data != null;
                    final text = hasSubmitted ? 'Check Status' : 'Submit Verification';
                    
                    return Text(
                      text,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
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
}
