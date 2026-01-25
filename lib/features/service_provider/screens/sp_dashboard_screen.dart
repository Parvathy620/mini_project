import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/app_background.dart';

class SPDashboardScreen extends StatelessWidget {
  const SPDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Service Provider Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(12),
              blur: 5,
              opacity: 0.1,
              child: InkWell(
                onTap: () async {
                   await Provider.of<AuthService>(context, listen: false).signOut();
                   if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                   }
                },
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(32),
              opacity: 0.15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, size: 64, color: Colors.orangeAccent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Account Pending Approval',
                    style: GoogleFonts.poppins(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You will be able to manage your services once your account is approved by the Admin.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                       // Refresh logic or contact admin could go here
                    },
                     style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF203A43),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Check Status',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
