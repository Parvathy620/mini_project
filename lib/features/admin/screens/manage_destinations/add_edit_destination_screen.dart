import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/drive_service.dart'; // Added
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/app_background.dart';

class AddEditDestinationScreen extends StatefulWidget {
  final String? destinationId;
  final String? currentName;
  final String? currentDescription;
  final String? currentDistrict;
  final String? currentDriveLink; 
  final bool? isAvailable; // Added

  const AddEditDestinationScreen({
    super.key, 
    this.destinationId, 
    this.currentName,
    this.currentDescription,
    this.currentDistrict,
    this.currentDriveLink,
    this.isAvailable,
  });

  @override
  State<AddEditDestinationScreen> createState() => _AddEditDestinationScreenState();
}

class _AddEditDestinationScreenState extends State<AddEditDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _driveLinkController = TextEditingController();
  String? _selectedDistrict;
  bool _isLoading = false;
  String? _previewImageUrl;
  bool _isAvailable = true; // State for availability

  final List<String> _keralaDistricts = [
    'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod',
    'Kollam', 'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad',
    'Pathanamthitta', 'Thiruvananthapuram', 'Thrissur', 'Wayanad',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentName != null) {
      _nameController.text = widget.currentName!;
    }
    if (widget.currentDescription != null) {
      _descriptionController.text = widget.currentDescription!;
    }
    if (widget.currentDistrict != null && _keralaDistricts.contains(widget.currentDistrict)) {
      _selectedDistrict = widget.currentDistrict;
    }
    if (widget.currentDriveLink != null) {
      _driveLinkController.text = widget.currentDriveLink!;
      _onDriveLinkChanged(); 
    }
    if (widget.isAvailable != null) {
      _isAvailable = widget.isAvailable!;
    }
    _driveLinkController.addListener(_onDriveLinkChanged);
  }

  void _onDriveLinkChanged() {
    final link = _driveLinkController.text.trim();
    if (link.isEmpty) {
      setState(() => _previewImageUrl = null);
      return;
    }

    final directLink = DriveService.getDirectLinkFromUrl(link);
    if (directLink != null && directLink != _previewImageUrl) {
      setState(() => _previewImageUrl = directLink);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _driveLinkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final adminService = Provider.of<AdminService>(context, listen: false);
        
          if (widget.destinationId == null) {
            await adminService.addDestination(
              _nameController.text.trim(), 
              _descriptionController.text.trim(),
              _selectedDistrict!,
              _previewImageUrl ?? '', 
              isAvailable: _isAvailable,
            );
          } else {
            await adminService.updateDestination(
              widget.destinationId!, 
              _nameController.text.trim(), 
              _descriptionController.text.trim(),
              _selectedDistrict!,
              _previewImageUrl ?? '',
              isAvailable: _isAvailable,
            );
          }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.destinationId == null ? 'Add Destination' : 'Edit Destination',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(24),
              opacity: 0.15,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Destination Name', Icons.place),
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: _buildInputDecoration('District', Icons.map),
                      dropdownColor: const Color(0xFF203A43), // Matches theme
                      style: const TextStyle(color: Colors.white),
                      items: _keralaDistricts.map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value;
                        });
                      },
                      validator: (value) => value == null ? 'Select a district' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _driveLinkController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Public Google Drive Link', Icons.link).copyWith(
                        hintText: 'https://drive.google.com/file/d/...',
                        hintStyle: const TextStyle(color: Colors.white24),
                      ),
                    ),
                    if (_previewImageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _previewImageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => const SizedBox(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Description', Icons.description),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.zero,
                      opacity: 0.1,
                      child: SwitchListTile(
                        value: _isAvailable,
                        onChanged: (val) => setState(() => _isAvailable = val),
                        title: Text('Destination Open', style: GoogleFonts.poppins(color: Colors.white)),
                        subtitle: Text(
                          _isAvailable ? 'Tourists can view & book' : 'Marked as Closed/Unavailable', 
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        activeColor: const Color(0xFF69F0AE),
                        secondary: Icon(
                          _isAvailable ? Icons.check_circle_outline : Icons.highlight_off, 
                          color: _isAvailable ? const Color(0xFF69F0AE) : Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF203A43),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              widget.destinationId == null ? 'Add Destination' : 'Update Destination',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
