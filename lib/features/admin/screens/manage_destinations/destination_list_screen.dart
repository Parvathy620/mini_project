import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/destination_model.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_glass.dart';
import '../../../../core/widgets/app_background.dart';
import 'add_edit_destination_screen.dart';

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({super.key});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Open, Closed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Manage Destinations',
           style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF69F0AE),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditDestinationScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Search & Filter Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Search Bar
                    LuxuryGlass(
                      height: 50,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      opacity: 0.1,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
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
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Open'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Closed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Destination List
            Expanded(
              child: StreamBuilder<List<DestinationModel>>(
                stream: adminService.getDestinations(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                  
                  var destinations = snapshot.data ?? [];

                  // Client-side Filtering
                  if (_searchQuery.isNotEmpty) {
                    destinations = destinations.where((d) => 
                      d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      d.district.toLowerCase().contains(_searchQuery.toLowerCase())
                    ).toList();
                  }

                  if (_statusFilter == 'Open') {
                    destinations = destinations.where((d) => d.isAvailable).toList();
                  } else if (_statusFilter == 'Closed') {
                    destinations = destinations.where((d) => !d.isAvailable).toList();
                  }

                  if (destinations.isEmpty) {
                    return Center(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(16),
                        child: Text(
                          _searchQuery.isEmpty ? 'No destinations found.' : 'No results found.', 
                          style: GoogleFonts.poppins(color: Colors.white)
                        ),
                      )
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final dest = destinations[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: LuxuryGlass(
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.all(12),
                          opacity: 0.15,
                          child: Row(
                            children: [
                              // Image with Status Border
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14), 
                                  border: Border.all(
                                    color: dest.isAvailable ? const Color(0xFF69F0AE) : Colors.redAccent.withOpacity(0.7),
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(2), // Space for border
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: (dest.googleDriveImageUrl.isNotEmpty)
                                        ? Image.network(dest.googleDriveImageUrl, fit: BoxFit.cover)
                                        : (dest.imageUrl.isNotEmpty
                                            ? Image.network(dest.imageUrl, fit: BoxFit.cover)
                                            : Container(color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            dest.name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 16
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      dest.district, 
                                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Glass Action Buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit_rounded,
                                    color: const Color(0xFF69F0AE),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => AddEditDestinationScreen(
                                            destinationId: dest.id, 
                                            currentName: dest.name,
                                            currentDescription: dest.description,
                                            currentDistrict: dest.district,
                                            currentDriveLink: dest.googleDriveImageUrl,
                                            isAvailable: dest.isAvailable,
                                          )
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete_rounded,
                                    color: Colors.redAccent,
                                    onTap: () async {
                                      _confirmDelete(context, dest, adminService);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  Widget _buildFilterChip(String label) {
    bool isSelected = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF69F0AE) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF69F0AE) : Colors.white24),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DestinationModel dest, AdminService service) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: Colors.white.withOpacity(0.1))
        ),
        title: Text('Delete Destination', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${dest.name}"?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await service.deleteDestination(dest.id);
    }
  }
}
