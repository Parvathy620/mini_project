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
                Color(0xFF0F172A), // Deep Slate Blue
                Color(0xFF1E293B), // Darker Grey/Blue
                Color(0xFF0F172A),
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
                  const Color(0xFF38BDF8).withOpacity(0.2), // Sky Blue
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
                  const Color(0xFF818CF8).withOpacity(0.15), // Soft Indigo
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
