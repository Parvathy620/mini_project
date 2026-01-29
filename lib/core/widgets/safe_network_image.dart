import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final Widget? placeholder;
  final Color? backgroundColor;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.placeholder,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Handle Null/Empty URL
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    // 2. Use CachedNetworkImage for better performance & error handling
    // (Ensure cached_network_image is in pubspec, checking next)
    // If not, we fall back to Image.network with error builder.
    // For now, let's stick to standard Image.network with robust error builder 
    // to avoid adding deps unless confirmed.
    
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.withOpacity(0.1),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => placeholder ?? Container(color: Colors.white.withOpacity(0.05)),
        errorWidget: (context, url, error) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.withOpacity(0.2),
      child: fallback ?? const Icon(Icons.image_not_supported, color: Colors.white24),
    );
  }
}

// Helper for DecorationImage (Provider)
// Since DecorationImage isn't a widget, we need a safe provider or just use a widget in the stack.
// But mostly users use Container(decoration: BoxDecoration(image: ...))
// We can forbid that and use SafeNetworkImage inside a ClipRRect/Stack unless necessary.
// Or provides a static method to return a Safe Provider? 
// Providers like NetworkImage throw: "Exception: Invalid Image data"
// Best to wrap UI in a Widget that handles this or use a specific ImageProvider wrapper (complex).
// Simplest fix: Replace all `decoration: BoxDecoration(image: ...)` with `child: SafeNetworkImage(...)` where possible.
