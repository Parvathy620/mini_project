import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Layer
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF051F20), // Deep Jungle
                Color(0xFF004D40), // Dark Teal
                Color(0xFF051F20),
              ],
            ),
          ),
        ),
        
        // Ambient Glow: Top Left (Sky Tint)
        Positioned(
          top: -200,
          left: -200,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF50C878).withOpacity(0.2), // Emerald Glow
                  Colors.transparent,
                ],
                stops: const [0, 0.7],
              ),
            ),
          ),
        ),

        // Ambient Glow: Bottom Right (Pearl/Glow)
        Positioned(
          bottom: -300,
          right: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF69F0AE).withOpacity(0.15), // Spring Green Glow
                  Colors.transparent,
                ],
                stops: const [0, 0.7],
              ),
            ),
          ),
        ),

        // Subtle Refraction Mesh (Optional, kept simple with noise or texture if needed, but staying clean for now)
        
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
