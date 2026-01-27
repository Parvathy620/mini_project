import 'package:flutter/material.dart';
import '../../../../core/widgets/luxury_glass.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingsPanel extends StatelessWidget {
  const BookingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return LuxuryGlass(
          opacity: 0.1,
          blur: 10,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.flight_takeoff, color: Colors.blueAccent),
            ),
            title: Text(
              'Booking #8439${index}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Confirmed • Mar ${12 + index}, 2026',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ),
        );
      },
    );
  }
}
