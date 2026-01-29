import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/service_provider_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'sp_edit_profile_screen.dart';

class SPProfileScreen extends StatefulWidget {
  const SPProfileScreen({super.key});

  @override
  State<SPProfileScreen> createState() => _SPProfileScreenState();
}

class _SPProfileScreenState extends State<SPProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ServiceProviderModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (uid != null) {
      final profile = await _profileService.getProviderProfile(uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              if (_profile != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SPEditProfileScreen(profile: _profile!)),
                );
                _fetchProfile(); // Refresh on return
              }
            },
          ),
        ],
      ),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
                ? const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Image (Drive)
                        Hero(
                          tag: 'profile_image',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                            ),
                            child: ClipOval(
                              child: SafeNetworkImage(
                                imageUrl: _profile!.googleDriveImageUrl.isNotEmpty 
                                  ? _profile!.googleDriveImageUrl 
                                  : _profile!.profileImageUrl,
                                fit: BoxFit.cover,
                                fallback: const Icon(Icons.person, size: 60, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Name & Role
                        Text(
                          _profile!.name,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        // Removed direct categoryId text as we now have multiple IDs and no names loaded here yet.
                        // Ideally fetching names is better, but for now we hide the raw ID or show generic role.
                        Text(
                          'SERVICE PROVIDER', 
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF66BB6A), letterSpacing: 1.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 30),

                        // Stats / Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBadge(
                              _profile!.isApproved ? 'VERIFIED' : 'PENDING',
                              _profile!.isApproved ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 15),
                            _buildBadge(
                              'RATING: ${_profile!.rating}',
                              Colors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Details Section
                        GlassContainer(
                          padding: const EdgeInsets.all(24),
                          borderRadius: BorderRadius.circular(20),
                          opacity: 0.1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('About'),
                              Text(
                                _profile!.description.isEmpty ? 'No description provided.' : _profile!.description,
                                style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              
                              // Removed Services Section

                              _buildSectionTitle('Location & Area'),
                              _buildInfoRow(Icons.location_on, _profile!.location.isEmpty ? 'Not specified' : _profile!.location),
                              const SizedBox(height: 10),
                              
                              _buildSectionTitle('Experience & Pricing'),
                              _buildInfoRow(Icons.work_outline, _profile!.experience.isEmpty ? 'Not specified' : '${_profile!.experience}'),
                              const SizedBox(height: 5),
                              _buildInfoRow(Icons.attach_money, _profile!.priceRange.isEmpty ? 'Not specified' : _profile!.priceRange),
                              
                              const SizedBox(height: 20),
                              _buildSectionTitle('Contact'),
                              _buildInfoRow(Icons.email_outlined, _profile!.email),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF66BB6A), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.inter(color: Colors.white))),
      ],
    );
  }
  
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
