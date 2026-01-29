import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enquiry_model.dart';
import '../../../core/models/service_provider_model.dart';
import '../../../core/services/enquiry_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';

class EnquiryDialog extends StatefulWidget {
  final ServiceProviderModel provider;

  const EnquiryDialog({super.key, required this.provider});

  @override
  State<EnquiryDialog> createState() => _EnquiryDialogState();
}

class _EnquiryDialogState extends State<EnquiryDialog> {
  final _messageController = TextEditingController();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();



  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) {
        throw Exception('Must be logged in to send enquiry');
      }

      // We might need to fetch user details to get name, or pass it in. 
      // For now, assuming email/id is enough or we fetch profile. 
      // Let's use user.email or "Tourist" as placeholder if name not available in Auth user directly 
      // (Auth user object usually has displayName if updated).
      String touristName = user.displayName ?? user.email?.split('@')[0] ?? 'Tourist';

      final enquiry = EnquiryModel(
        id: Provider.of<EnquiryService>(context, listen: false).generateId(),
        touristId: user.uid,
        touristName: touristName,
        providerId: widget.provider.uid,
        providerName: widget.provider.name,
        message: _messageController.text.trim(),
        requestedDate: null,
        preferredTime: null,
        createdAt: DateTime.now(),
      );

      await Provider.of<EnquiryService>(context, listen: false).sendEnquiry(enquiry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enquiry sent to ${widget.provider.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
     if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: LuxuryGlass(
        opacity: 0.15,
        blur: 20,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enquire',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message to ${widget.provider.name}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Message Input
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message here...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter a message' : null,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF69F0AE),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isLoading ? null : _submitEnquiry,
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Send', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
