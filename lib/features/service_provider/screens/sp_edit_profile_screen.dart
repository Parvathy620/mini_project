import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart'; // Removed
import '../../../core/models/service_provider_model.dart';
import '../../../core/services/drive_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/destination_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/widgets/glass_multi_select_dialog.dart';
import '../../../core/widgets/glass_single_select_dialog.dart';

class SPEditProfileScreen extends StatefulWidget {
  final ServiceProviderModel profile;

  const SPEditProfileScreen({super.key, required this.profile});

  @override
  State<SPEditProfileScreen> createState() => _SPEditProfileScreenState();
}

class _SPEditProfileScreenState extends State<SPEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // final DriveService _driveService = DriveService();
  final ProfileService _profileService = ProfileService();

  final DataService _dataService = DataService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _experienceController;
  late TextEditingController _priceRangeController;
  late TextEditingController _driveLinkController; // New Controller

  String _locationName = '';
  String _destinationId = '';
  
  List<String> _categoryIds = [];
  List<String> _categoryNames = []; 


  
  bool _showLinkInput = true; // For toggling link input visibility

  // File? _selectedImage; // Removed
  String? _newDriveImageUrl;
  // String? _newDriveImageId; // Not strictly needed if we just use URL, but existing model has it. We can maybe extract ID.

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _descriptionController = TextEditingController(text: widget.profile.description);
    _experienceController = TextEditingController(text: widget.profile.experience);
    _locationName = widget.profile.location;
    _destinationId = widget.profile.destinationId;
    
    _categoryIds = List.from(widget.profile.categoryIds);
    _fetchCategoryNames(); 

    _priceRangeController = TextEditingController(text: widget.profile.priceRange);
    // Check if we already have a drive link image, if so, collapse the input
    if (widget.profile.googleDriveImageUrl.isNotEmpty) {
      _showLinkInput = false;
    }
    
    _driveLinkController = TextEditingController(); // Init, maybe prefill if existing URL is public link?
    
    _driveLinkController.addListener(_onDriveLinkChanged);
  }

  Future<void> _fetchCategoryNames() async {
    if (_categoryIds.isEmpty) return;
    try {
      final allCategories = await _dataService.getCategories().first; // Get first snapshot
      final names = allCategories
          .where((c) => _categoryIds.contains(c.id))
          .map((c) => c.name)
          .toList();
      if (mounted) {
        setState(() {
          _categoryNames = names;
        });
      }
    } catch (e) {
      print("Error fetching category names: $e");
    }
  }

  void _onDriveLinkChanged() {
    final link = _driveLinkController.text.trim();
    if (link.isEmpty) return;

    final directLink = DriveService.getDirectLinkFromUrl(link);
    if (directLink != null && directLink != _newDriveImageUrl) {
      setState(() {
        _newDriveImageUrl = directLink;
        _showLinkInput = false; // Auto-hide on success
      });
      // Clear focus to close keyboard
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    _priceRangeController.dispose();
    _driveLinkController.dispose();
    super.dispose();
  }

  // Removed _pickImage and _uploadToDrive methods



  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    // Removed upload check

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving profile...')));

    final updatedProfile = ServiceProviderModel(
      uid: widget.profile.uid,
      name: _nameController.text.trim(),
      email: widget.profile.email,
      categoryIds: _categoryIds,
      isApproved: widget.profile.isApproved,
      createdAt: widget.profile.createdAt,
      rating: widget.profile.rating,
      priceRange: _priceRangeController.text.trim(),
      services: [], // Cleared services as UI is removed
      profileImageUrl: widget.profile.profileImageUrl, 
      isAvailable: widget.profile.isAvailable,
      description: _descriptionController.text.trim(),
      experience: _experienceController.text.trim(),
      location: _locationName,
      destinationId: _destinationId,
      googleDriveImageUrl: _newDriveImageUrl ?? widget.profile.googleDriveImageUrl,
      googleDriveImageId: '', // ID not extracted strictly, can be empty or we extract it if needed. Keeping simple.
    );

    try {
      await _profileService.updateProviderProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_newDriveImageUrl != null && _newDriveImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_newDriveImageUrl!);
    } else if (widget.profile.googleDriveImageUrl.isNotEmpty) {
      imageProvider = NetworkImage(widget.profile.googleDriveImageUrl);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Image Preview (Read-Only/Visual)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF66BB6A), width: 2),
                    image: imageProvider != null 
                        ? DecorationImage(image: imageProvider, fit: BoxFit.cover) 
                        : null,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: imageProvider == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                const SizedBox(height: 20),

                // Drive Link Input
                // Drive Link Input (Collapsible)
                if (_showLinkInput)
                  _buildTextField(
                    _driveLinkController, 
                    "Paste Public Drive Link Here (Optional)", 
                    icon: Icons.link,
                    hint: "https://drive.google.com/file/d/...",
                    validator: (v) => null, // Optional
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _showLinkInput = true),
                    child: GlassContainer(
                       padding: const EdgeInsets.all(12),
                       borderRadius: BorderRadius.circular(12),
                       opacity: 0.1,
                       child: Row(
                         children: [
                           const Icon(Icons.check_circle, color: Colors.greenAccent),
                           const SizedBox(width: 10),
                           Expanded(child: Text("Image Link Active", style: GoogleFonts.inter(color: Colors.white))),
                           const Icon(Icons.edit, color: Colors.white60, size: 18),
                         ],
                       ),
                    ),
                  ),

                if (_newDriveImageUrl != null && _showLinkInput)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '✓ Image Preview Loaded',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.greenAccent),
                    ),
                  ),

                const SizedBox(height: 30),

                // Form Fields
                _buildTextField(_nameController, "Provider Name", icon: Icons.person),
                const SizedBox(height: 15),
                _buildCategoryAPISelector(),
                const SizedBox(height: 15),
                // Removed duplicate description field here
                _buildTextField(_descriptionController, "Description", icon: Icons.description, maxLines: 3),
                const SizedBox(height: 15),
                _buildLocationAPISelector(),
                const SizedBox(height: 15),
                _buildTextField(_experienceController, "Experience (Years)", icon: Icons.work_history),
                const SizedBox(height: 15),
                _buildTextField(_priceRangeController, "Price Range (₹)", icon: Icons.attach_money),
                
                // Removed Services Section entirely
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAPISelector() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.1,
      child: InkWell(
        onTap: _showLocationPicker,
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white60),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationName.isNotEmpty ? _locationName : 'Select Location',
                style: TextStyle(
                  color: _locationName.isNotEmpty ? Colors.white : Colors.white60,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<DestinationModel>>(
          stream: _dataService.getDestinations(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox(); 
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final destinations = snapshot.data!;
            DestinationModel? selected;
            try {
              if (_destinationId.isNotEmpty) {
                 selected = destinations.firstWhere((d) => d.id == _destinationId);
              }
            } catch (_) {}

            return GlassSingleSelectDialog<DestinationModel>(
              title: 'Select Location',
              items: destinations,
              selectedItem: selected,
              itemLabel: (item) => item.name,
              itemSubtitle: (item) => item.district,
              onConfirm: (item) {
                setState(() {
                  _locationName = item.name;
                  _destinationId = item.id;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryAPISelector() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.1,
      child: InkWell(
        onTap: _showCategoryPicker,
        child: Row(
          children: [
            const Icon(Icons.category, color: Colors.white60),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _categoryIds.isNotEmpty 
                    ? (_categoryNames.isNotEmpty ? _categoryNames.join(', ') : '${_categoryIds.length} Selected') 
                    : 'Select Categories', // Updated placeholder
                style: TextStyle(
                  color: _categoryIds.isNotEmpty ? Colors.white : Colors.white60,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() async {
    // Show loading state if needed, but for now we stream nicely
    // We need to fetch the categories first or wrap the dialog in a stream builder
    // Since GlassMultiSelectDialog expects a List, we'll wrap the call to it in the stream builder logic
    // But showDialog expects a builder. 
    
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<CategoryModel>>(
          stream: _dataService.getCategories(),
          builder: (context, snapshot) {
             if (snapshot.hasError) return const SizedBox(); // Or error dialog
             if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
             
             final categories = snapshot.data!;
             // Map existing IDs to actual objects for the dialog
             final selectedObjects = categories.where((c) => _categoryIds.contains(c.id)).toList();
             
             return GlassMultiSelectDialog<CategoryModel>(
               title: 'Select Categories',
               items: categories,
               selectedItems: selectedObjects,
               itemLabel: (item) => item.name,
               onConfirm: (selected) {
                 setState(() {
                   _categoryIds = selected.map((e) => e.id).toList();
                   _categoryNames = selected.map((e) => e.name).toList();
                 });
               },
             );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? icon, int maxLines = 1, String? hint, String? Function(String?)? validator}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.1,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          labelStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
          prefixIcon: icon != null ? Icon(icon, color: Colors.white60) : null,
        ),
        validator: validator ?? (val) => val == null || val.isEmpty ? "Required" : null,
      ),
    );
  }
}

