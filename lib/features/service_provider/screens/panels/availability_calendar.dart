import 'package:flutter/material.dart';
import '../../../../core/widgets/luxury_glass.dart';

class AvailabilityCalendarPanel extends StatelessWidget {
  const AvailabilityCalendarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LuxuryGlass(
        margin: const EdgeInsets.all(20),
        width: double.infinity,
        opacity: 0.05,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Schedule Coordinates',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Container(
              height: 300,
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 31,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
