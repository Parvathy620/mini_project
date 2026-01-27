import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/luxury_glass.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/runway_reveal.dart';

class TouristEnquiryScreen extends StatefulWidget {
  final String providerName;
  final String serviceName;

  const TouristEnquiryScreen({
    super.key,
    required this.providerName,
    required this.serviceName,
  });

  @override
  State<TouristEnquiryScreen> createState() => _TouristEnquiryScreenState();
}

class _TouristEnquiryScreenState extends State<TouristEnquiryScreen> {
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Enquiry', style: GoogleFonts.outfit(color: Colors.white)),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          child: Column(
            children: [
              RunwayReveal(
                delayMs: 200,
                child: LuxuryGlass(
                  opacity: 0.1,
                  blur: 20,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'SEND REQUEST',
                        style: GoogleFonts.outfit(
                          color: Colors.lightBlueAccent,
                          letterSpacing: 3,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('To', widget.providerName),
                      const SizedBox(height: 10),
                      _buildInfoRow('Service', widget.serviceName),
                      const SizedBox(height: 30),
                      _buildGlassTextField(
                        controller: _messageController,
                        hint: 'Describe your requirements (e.g., dates, group size)...',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text('Enquiry Sent to ${widget.providerName}!'),
                               backgroundColor: Colors.blueAccent.withOpacity(0.8),
                               behavior: SnackBarBehavior.floating,
                             )
                           );
                           Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent, Colors.purpleAccent],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'LAUNCH ENQUIRY',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}
