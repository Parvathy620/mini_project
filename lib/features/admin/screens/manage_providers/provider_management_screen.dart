import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/service_provider_model.dart';
import '../../../../core/services/data_service.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/luxury_glass.dart';
import '../../../../core/widgets/glass_confirmation_dialog.dart';

class ProviderManagementScreen extends StatefulWidget {
  const ProviderManagementScreen({super.key});

  @override
  State<ProviderManagementScreen> createState() => _ProviderManagementScreenState();
}

class _ProviderManagementScreenState extends State<ProviderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, ServiceProviderModel provider) {
    showDialog(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: 'Remove Provider?',
        content: 'Are you sure you want to remove "${provider.name}"? This will hide their profile and prevent access.',
        confirmText: 'Remove',
        confirmColor: Colors.redAccent,
        onConfirm: () async {
          await Provider.of<DataService>(context, listen: false).deleteProvider(provider.uid);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleVisibility(BuildContext context, ServiceProviderModel provider) async {
    final newStatus = !provider.isHidden;
    await Provider.of<DataService>(context, listen: false).updateProviderStatus(
      provider.uid, 
      isHidden: newStatus
    );
  }

  void _confirmRestore(BuildContext context, ServiceProviderModel provider) {
    showDialog(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: 'Restore Provider?',
        content: 'Restore "${provider.name}"? This will make their profile visible and active again.',
        confirmText: 'Restore',
        confirmColor: Colors.greenAccent,
        onConfirm: () async {
          await Provider.of<DataService>(context, listen: false).restoreProvider(provider.uid);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'PROVIDER MANAGEMENT',
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
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: LuxuryGlass(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              opacity: 0.1,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.white38),
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Spacing removed as requested
            // const SizedBox(height: 20), 
            
            // Provider List

            // Provider List
            Expanded(
              child: StreamBuilder<List<ServiceProviderModel>>(
                stream: Provider.of<DataService>(context).getServiceProvidersForAdmin(searchQuery: _searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));
                  }

                  final providers = snapshot.data!;
                  if (providers.isEmpty) {
                    return Center(child: Text('No providers found', style: GoogleFonts.inter(color: Colors.white54)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: providers.length,
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      return _buildProviderCard(provider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ServiceProviderModel provider) {
    Color statusColor = Colors.greenAccent;
    String statusText = 'ACTIVE';

    if (provider.isDeleted) {
      statusColor = Colors.redAccent;
      statusText = 'REMOVED';
    } else if (provider.isHidden) {
      statusColor = Colors.orangeAccent;
      statusText = 'HIDDEN';
    } else if (!provider.isApproved) {
      statusColor = const Color(0xFF66BB6A);
      statusText = 'PENDING';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Compact spacing
      child: LuxuryGlass(
        opacity: provider.isDeleted ? 0.05 : 0.1,
        borderRadius: BorderRadius.circular(16), // Slightly smaller radius
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.all(12), // Compact padding
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20, // Smaller avatar
                backgroundColor: Colors.white10,
                backgroundImage: (provider.googleDriveImageUrl.isNotEmpty)
                    ? NetworkImage(provider.googleDriveImageUrl)
                    : (provider.profileImageUrl.isNotEmpty 
                        ? NetworkImage(provider.profileImageUrl) 
                        : null),
                child: (provider.googleDriveImageUrl.isEmpty && provider.profileImageUrl.isEmpty)
                    ? Text(provider.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14, // Smaller font
                      ),
                    ),
                    const SizedBox(height: 2), // Compact spacing
                    Text(
                      provider.email,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), // Smaller font
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.inter(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              if (!provider.isDeleted) ...[
                // Hide/Unhide Button
                _buildActionBtn(
                  context, 
                  icon: provider.isHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  onTap: () => _toggleVisibility(context, provider),
                ),
                const SizedBox(width: 8),
                // Delete Button
                _buildActionBtn(
                  context,
                  icon: Icons.delete_outline,
                  color: Colors.redAccent,
                  isDestructive: true,
                  onTap: () => _confirmDelete(context, provider),
                ),
              ] else ... [
                 // Restore Button
                 _buildActionBtn(
                  context,
                  icon: Icons.restore,
                  color: Colors.greenAccent,
                  onTap: () => _confirmRestore(context, provider),
                 ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, {
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDestructive ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            width: 1
          ),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
