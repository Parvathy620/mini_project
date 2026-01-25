import 'dart:ui';
import 'package:flutter/material.dart';

class LuxuryGlass extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool hasReflection;

  const LuxuryGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.hasReflection = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFF4CA1AF).withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              // Base Tint
              Container(
                padding: padding ?? const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  borderRadius: br,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: child,
              ),

              // Glass Reflection Gradient Overlay
              if (hasReflection)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: br,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Top Highlight Border (Simulating light edge)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
