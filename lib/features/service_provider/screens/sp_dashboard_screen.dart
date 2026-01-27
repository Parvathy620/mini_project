import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/runway_reveal.dart';
import 'panels/enquiries_panel.dart';
import 'panels/bookings_panel.dart';
import 'panels/availability_calendar.dart';

class SPDashboardScreen extends StatefulWidget {
  const SPDashboardScreen({super.key});

  @override
  State<SPDashboardScreen> createState() => _SPDashboardScreenState();
}

class _SPDashboardScreenState extends State<SPDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _panels = [
    const EnquiriesPanel(),
    const BookingsPanel(),
    const AvailabilityCalendarPanel(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'FLIGHT DECK',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: LuxuryGlass(
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
        child: Column(
          children: [
            const SizedBox(height: 100),
            
            // Glassmorphic Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: RunwayReveal(
                delayMs: 200,
                child: LuxuryGlass(
                  height: 60,
                  opacity: 0.1,
                  blur: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabItem(0, 'ENQUIRIES', Icons.mail_outline),
                      _buildTabItem(1, 'BOOKINGS', Icons.confirmation_number_outlined),
                      _buildTabItem(2, 'AVAILABILITY', Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Main Content Area with Horizontal Motion
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.2, 0.0), // Runway slide effect
                    end: Offset.zero,
                  ).animate(animation);
                  
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: _panels[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ) 
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 18,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
