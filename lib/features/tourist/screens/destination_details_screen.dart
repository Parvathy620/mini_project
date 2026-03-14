import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/models/destination_model.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/safe_network_image.dart';
import 'provider_search_screen.dart';
import '../../../core/widgets/star_rating.dart';
import '../../reviews/screens/reviews_screen.dart';

class DestinationDetailsScreen extends StatelessWidget {
  final DestinationModel destination;

  const DestinationDetailsScreen({super.key, required this.destination});

  void _navigateToProviderSearch(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProviderSearchScreen(
          destinationId: destination.id,
          destinationName: destination.name,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LuxuryGlass(
            padding: EdgeInsets.zero,
            blur: 10,
            opacity: 0.2,
            borderRadius: BorderRadius.circular(50),
            child: const BackButton(color: Colors.white),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AppBackground(child: SizedBox.shrink()),
          CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                  minHeight: 100,
                  child: Hero(
                    tag: 'destination_detail_${destination.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SafeNetworkImage(
                          imageUrl: destination.googleDriveImageUrl.isNotEmpty
                              ? destination.googleDriveImageUrl
                              : destination.imageUrl,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: Colors.white10,
                            child: const Icon(Icons.image, size: 80, color: Colors.white24),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.9),
                              ],
                              stops: const [0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pinned: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: destination.isAvailable
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          border: Border.all(
                            color: destination.isAvailable ? Colors.green : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          destination.isAvailable ? 'AVAILABLE' : 'CURRENTLY CLOSED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title & District
                      Text(
                        destination.name,
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF69F0AE), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            destination.district,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF69F0AE),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.category_outlined, color: Colors.white54, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            destination.category,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Reviews Row
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsScreen(
                                targetId: destination.id,
                                targetType: 'destination',
                                targetName: destination.name,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                destination.rating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StarRating(rating: destination.rating, size: 16),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to read or write reviews',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Description Section
                      if (destination.description.isNotEmpty) ...[
                        Text(
                          'About this Destination',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LuxuryGlass(
                          padding: const EdgeInsets.all(20),
                          blur: 15,
                          opacity: 0.1,
                          borderRadius: BorderRadius.circular(16),
                          child: Text(
                            destination.description,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ] else ...[
                         // Empty State Fallback
                         LuxuryGlass(
                          padding: const EdgeInsets.all(24),
                          blur: 10,
                          opacity: 0.05,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.white24, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'No detailed description provided.',
                                  style: GoogleFonts.inter(color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _navigateToProviderSearch(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF69F0AE),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              shadowColor: const Color(0xFF69F0AE).withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_rounded),
                const SizedBox(width: 12),
                Text(
                  'View Service Providers',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
