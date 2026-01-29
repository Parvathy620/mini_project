import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/verification_model.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_container.dart';

class VerificationSubmissionScreen extends StatefulWidget {
  const VerificationSubmissionScreen({super.key});

  @override
  State<VerificationSubmissionScreen> createState() => _VerificationSubmissionScreenState();
}

class _VerificationSubmissionScreenState extends State<VerificationSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDocType = 'Business License';
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController(); // New Controller
  
  bool _isLoading = false;
  ProviderVerification? _currentVerification;
  final VerificationService _verificationService = VerificationService();

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final verification = await _verificationService.getVerificationStatus(user.uid);
      
      // Fetch existing description
      final profileDoc = await FirebaseFirestore.instance.collection('service_providers').doc(user.uid).get();
      if (profileDoc.exists) {
        final data = profileDoc.data();
        if (data != null && data.containsKey('description')) {
          _descriptionController.text = data['description'];
        }
      }

      if (mounted) setState(() => _currentVerification = verification);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
     if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _verificationService.submitVerification(
        providerId: user.uid,
        documentType: _selectedDocType,
        documentUrl: _urlController.text.trim(),
        description: _descriptionController.text.trim(), // Pass description
      );
      await _fetchStatus();
      if (mounted) {
         Navigator.pop(context); // Go back to dashboard after submission
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification Submitted Successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Verification', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: _currentVerification == null || 
                       _currentVerification!.status == VerificationStatus.rejected || 
                       _currentVerification!.status == VerificationStatus.expired
                    ? _buildGlassForm()
                    : _buildStatusView(),
              ),
      ),
    );
  }

  Widget _buildGlassForm() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit Documents',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide a public Google Drive link to your verification documents and add a brief description.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_currentVerification?.status == VerificationStatus.rejected)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reason: ${_currentVerification?.rejectionReason}', 
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Description Field
            Text('Provider Description', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              opacity: 0.1,
              child: TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe your services...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Description is required';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Document Type Dropdown
            Text('Document Type', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              opacity: 0.1,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDocType,
                  dropdownColor: const Color(0xFF1B5E20), // Dark Green for dropdown
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: GoogleFonts.inter(color: Colors.white),
                  items: ['Business License', 'ID Card', 'Tax Certificate']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedDocType = val!),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Drive Link Input
            Text('Public Drive Link', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              opacity: 0.1,
              child: TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'https://drive.google.com/file/...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.link, color: Colors.white60),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Link is required';
                  if (!value.startsWith('http')) return 'Please enter a valid URL';
                  return null;
                },
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE),
                foregroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Submit for Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    // This is essentially fallback, normally dashboard handles status view.
    // But keeping it for robustness.
    return LuxuryGlass(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
          const SizedBox(height: 20),
          Text(
            'Under Review',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
             'Your documents have been submitted and are currently being reviewed by our admin team.',
             textAlign: TextAlign.center,
             style: GoogleFonts.inter(color: Colors.white70),
          ),
          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}
