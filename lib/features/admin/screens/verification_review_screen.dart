import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add import
import 'package:url_launcher/url_launcher.dart'; // Add this import
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/models/verification_model.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/services/auth_service.dart';

class VerificationReviewScreen extends StatefulWidget {
  final ProviderVerification verification;

  const VerificationReviewScreen({super.key, required this.verification});

  @override
  State<VerificationReviewScreen> createState() => _VerificationReviewScreenState();
}

class _VerificationReviewScreenState extends State<VerificationReviewScreen> {
  final VerificationService _service = VerificationService();
  bool _isProcessing = false;
  final TextEditingController _reasonController = TextEditingController();

  Future<void> _approve() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUser?.uid ?? 'ADMIN'; 

    setState(() => _isProcessing = true);
    try {
      await _service.approveProvider(
        widget.verification.id,
        adminId,
        widget.verification.providerId,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider Approved')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a rejection reason')));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUser?.uid ?? 'ADMIN';

    setState(() => _isProcessing = true);
    try {
      await _service.rejectProvider(
        widget.verification.id,
        adminId,
        widget.verification.providerId,
        _reasonController.text,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider Rejected')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showRejectDialog() {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LuxuryGlass(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reject Verification',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reject();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirm Reject'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument() async {
    final url = widget.verification.documentUrl;
    if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No URL provided')));
        return;
    }
    
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  Map<String, dynamic>? _providerProfile;
  bool _isLoadingProfile = true;
  String _categoryNames = '';
  String _destinationName = '';

  @override
  void initState() {
    super.initState();
    _fetchProviderDetails();
  }

  Future<void> _fetchProviderDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.verification.providerId)
          .get();
      
      if (mounted) {
        final data = doc.data();
        String catNames = 'None';
        String destName = '';
        
        if (data != null) {
           // Resolve Categories
           List<dynamic> ids = data['categoryIds'] ?? (data['categoryId'] != null ? [data['categoryId']] : []);
           if (ids.isNotEmpty) {
             final catDocs = await FirebaseFirestore.instance
                 .collection('service_provider_categories')
                 .where(FieldPath.documentId, whereIn: ids)
                 .get();
             
             catNames = catDocs.docs.map((d) => d.data()['categoryName'].toString()).join(', ');
           }

           // Resolve Destination (Operating Region)
           String destId = data['destinationId'] ?? '';
           if (destId.isNotEmpty) {
             final destDoc = await FirebaseFirestore.instance.collection('destinations').doc(destId).get();
             if (destDoc.exists) {
               destName = destDoc.data()?['name'] ?? '';
             }
           }
        }

        setState(() {
          _providerProfile = data;
          _categoryNames = catNames;
          _destinationName = destName;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // ... (existing helper methods keep same)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Review Request', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 60), // Space for transparent AppBar
              
              // Provider Details Section
              if (_isLoadingProfile)
                const CircularProgressIndicator()
              else if (_providerProfile != null)
                LuxuryGlass(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                           CircleAvatar(
                             radius: 30,
                             backgroundImage: NetworkImage(_providerProfile!['profileImageUrl'] ?? ''),
                             onBackgroundImageError: (_,__) {},
                             child: _providerProfile!['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   _providerProfile!['name'] ?? 'Unknown Provider', 
                                   style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                                 ),
                                 Text(
                                   _providerProfile!['location'] ?? 'No Location', 
                                   style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)
                                 ),
                               ],
                             ),
                           )
                         ],
                       ),
                       const Divider(color: Colors.white10, height: 24),
                       
                       // Service Classification (Categories)
                       Text('Service Classification', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(
                         _categoryNames,
                         style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                       ),
                       const SizedBox(height: 12),
                       
                       // Operating Region (Location)
                       Text('Operating Region', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(
                         (_providerProfile!['location'] != null && _providerProfile!['location'].isNotEmpty) 
                             ? _providerProfile!['location'] 
                             : (_destinationName.isNotEmpty ? _destinationName : 'Not Specified'),
                         style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                       ),
                       const SizedBox(height: 12),

                       Text('Description', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(
                         _providerProfile!['description'] ?? 'No description provided.',
                         style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                       ),
                    ],
                  ),
                ),

              LuxuryGlass(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Document Type', widget.verification.documentType),
                    const Divider(color: Colors.white10),
                    _buildInfoRow('Submitted At', widget.verification.submittedAt.toString().split('.')[0]),
                    const SizedBox(height: 24),
                    
                    Text('Document Action', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    
                    // Large Action Button to Open Link
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openDocument,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Document Link'),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blueAccent.withOpacity(0.8),
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 20),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF66BB6A).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: const Color(0xFF66BB6A), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.verification.documentUrl,
                              style: GoogleFonts.inter(color: const Color(0xFF66BB6A), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    if (_isProcessing)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _showRejectDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _approve,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text('Approve', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: GoogleFonts.inter(color: Colors.white54))),
          Expanded(child: Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
