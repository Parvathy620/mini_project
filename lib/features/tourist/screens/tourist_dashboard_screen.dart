import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/app_background.dart';

class TouristDashboardScreen extends StatelessWidget {
  const TouristDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Tourist Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                    child: const Icon(Icons.beach_access_rounded, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome User!',
                    style: GoogleFonts.poppins(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start exploring amazing destinations and adventures.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Placeholder for future navigation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF203A43),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Explore Now',
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
