import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/issue_model.dart';
import '../../../core/services/issue_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/drive_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import 'package:uuid/uuid.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _driveLinkController = TextEditingController();
  final _locationController = TextEditingController(); // Added for manual input
  
  String _selectedCategory = 'Infrastructure';
  IssuePriority _selectedPriority = IssuePriority.medium;
  
  final List<String> _categories = [
    'Infrastructure',
    'Safety',
    'Technical Problem',
    'Service Complaint',
    'Other'
  ];

  final List<String> _mediaUrls = [];
  bool _isSubmitting = false;
  String? _linkPreviewUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _driveLinkController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  void _onLinkChanged(String value) {
    if (value.isEmpty) {
      setState(() => _linkPreviewUrl = null);
      return;
    }
    final direct = DriveService.getDirectLinkFromUrl(value.trim());
    setState(() => _linkPreviewUrl = direct);
  }

  void _addMediaLink() {
    final link = _driveLinkController.text.trim();
    if (link.isEmpty) return;
    
    final direct = DriveService.getDirectLinkFromUrl(link);
    if (direct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Google Drive Link')));
      return;
    }

    if (_mediaUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 3 links allowed')));
      return;
    }

    setState(() {
      _mediaUrls.add(link);
      _driveLinkController.clear();
      _linkPreviewUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final issueService = Provider.of<IssueService>(context, listen: false);
      final driveService = Provider.of<DriveService>(context, listen: false);
      
      final user = auth.currentUser;
      if (user == null) throw 'User not logged in';

      final issue = IssueModel(
        id: 'ISSUE${const Uuid().v4().substring(0, 5).toUpperCase()}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        reporterId: user.uid,
        reporterName: user.displayName ?? 'Anonymous',
        location: IssueLocation(address: _locationController.text.trim()),
        mediaUrls: _mediaUrls.map((link) => DriveService.getDirectLinkFromUrl(link)!).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await issueService.reportIssue(issue);

      if (mounted) {
        _showSuccessDialog(issue.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(String issueId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LuxuryGlass(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF69F0AE), size: 64),
              const SizedBox(height: 16),
              Text('Reported Successfully', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Issue ID: #$issueId', style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back from report screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF69F0AE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Safety'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Report an Issue', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Details'),
                  const SizedBox(height: 12),
                  _buildInputCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Issue Title',
                          hint: 'e.g. Broken pavement near park',
                          validator: (v) => v!.isEmpty ? 'Required' : (v.length > 100 ? 'Too long' : null),
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Detailed Description',
                          hint: 'Explain what happened...',
                          maxLines: 4,
                          validator: (v) => v!.length < 10 ? 'Minimum 10 chars' : (v.length > 500 ? 'Too long' : null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Priority Level'),
                  const SizedBox(height: 12),
                  _buildPrioritySelector(),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Location & Evidence'),
                  const SizedBox(height: 12),
                  _buildLocationEvidenceCard(),
                  const SizedBox(height: 32),

                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)))
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF69F0AE),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text('SUBMIT REPORT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1.2),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.1,
      child: Row(
        children: IssuePriority.values.map((priority) {
          bool isSelected = _selectedPriority == priority;
          Color color = _getPriorityColor(priority);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPriority = priority),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      priority.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationEvidenceCard() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        children: [
          // Location Section
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter exact location or landmark...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (v) => v!.isEmpty ? 'Location is required' : null,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          
          // Evidence Selection System
          const Divider(color: Colors.white10, height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.link, color: Colors.white70),
                  const SizedBox(width: 12),
                  Text('Evidence (Public Drive Links)', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _driveLinkController,
                      onChanged: _onLinkChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste Drive file link here...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addMediaLink,
                    icon: const Icon(Icons.add_circle, color: Color(0xFF69F0AE)),
                  ),
                ],
              ),
              if (_linkPreviewUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _linkPreviewUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.white10,
                      child: const Center(child: Text('Preview Failed', style: TextStyle(color: Colors.white24))),
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (_mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaUrls.length,
                itemBuilder: (context, index) {
                  final preview = DriveService.getDirectLinkFromUrl(_mediaUrls[index]);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: preview != null 
                            ? Image.network(preview, width: 80, height: 80, fit: BoxFit.cover)
                            : Container(width: 80, height: 80, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _mediaUrls.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(IssuePriority p) {
    switch (p) {
      case IssuePriority.low: return Colors.blue;
      case IssuePriority.medium: return Colors.greenAccent;
      case IssuePriority.high: return Colors.orange;
      case IssuePriority.urgent: return Colors.redAccent;
    }
  }
}
