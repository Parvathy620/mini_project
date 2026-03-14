import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/models/review_model.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/review_card.dart';
import '../../../core/widgets/star_rating.dart';
import 'add_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final String targetId;
  final String targetType;
  final String targetName;

  const ReviewsScreen({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _sortBy = 'createdAt';
  int? _filterRating;

  @override
  Widget build(BuildContext context) {
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Reviews & Ratings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          const AppBackground(child: SizedBox.shrink()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Stats Header
                SliverToBoxAdapter(
                  child: FutureBuilder<ReviewStats>(
                    future: reviewService.getReviewStats(widget.targetId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox(height: 150);
                      final stats = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: _buildStatsHeader(stats),
                      );
                    },
                  ),
                ),
                
                // Filters & Sorting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sort Dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sort By:',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _sortBy,
                              dropdownColor: const Color(0xFF1B5E20), // Forest Green
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF69F0AE)),
                              items: const [
                                DropdownMenuItem(value: 'createdAt', child: Text('Most Recent')),
                                DropdownMenuItem(value: 'rating', child: Text('Rating')),
                                DropdownMenuItem(value: 'helpfulVotes', child: Text('Most Helpful')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _sortBy = val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(null, 'All'),
                              _buildFilterChip(5, '5 Stars'),
                              _buildFilterChip(4, '4 Stars'),
                              _buildFilterChip(3, '3 Stars'),
                              _buildFilterChip(2, '2 Stars'),
                              _buildFilterChip(1, '1 Star'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Reviews List
                StreamBuilder<List<ReviewModel>>(
                  stream: reviewService.getReviewsStream(widget.targetId, sortBy: _sortBy),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE))),
                      );
                    }
                    if (snapshot.hasError) {
                      String errorMsg = 'Error loading reviews.';
                      if (snapshot.error.toString().contains('FAILED_PRECONDITION')) {
                        errorMsg = 'Error: Missing Database Index for sorting.\nCheck your console logs for a direct link to create it in Firebase.';
                      }
                      return SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              errorMsg,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          ),
                        ),
                      );
                    }

                    var reviews = snapshot.data ?? [];
                    
                    // Client-side filtering
                    if (_filterRating != null) {
                      reviews = reviews.where((r) => r.rating >= _filterRating! && r.rating < _filterRating! + 1).toList();
                    }

                    // Check if current user has a review
                    ReviewModel? myReview;
                    try {
                      myReview = reviews.firstWhere((r) => r.userId == currentUserId);
                    } catch (_) {}

                    if (reviews.isEmpty) {
                      return SliverFillRemaining(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'No reviews yet. Be the first to share your experience!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                            _buildFloatingActionButton(context, myReview),
                          ],
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == reviews.length) {
                               return _buildFloatingActionButton(context, myReview);
                            }
                            final review = reviews[index];
                            return ReviewCard(
                              review: review,
                              currentUserId: currentUserId,
                              onHelpfulTapped: () {
                                reviewService.incrementHelpfulVotes(review.id);
                              },
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddReviewScreen(
                                      targetId: widget.targetId,
                                      targetType: widget.targetType,
                                      targetName: widget.targetName,
                                      existingReview: review,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              onDelete: () {
                                _showDeleteDialog(context, review, reviewService);
                              },
                            );
                          },
                          childCount: reviews.length + 1, // +1 for the FAB row at the bottom
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, ReviewModel? myReview) {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(24.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddReviewScreen(
                targetId: widget.targetId,
                targetType: widget.targetType,
                targetName: widget.targetName,
                existingReview: myReview,
              ),
            ),
          ).then((_) {
            setState(() {}); 
          });
        },
        backgroundColor: const Color(0xFF69F0AE),
        icon: Icon(myReview != null ? Icons.edit : Icons.add_comment, color: Colors.black),
        label: Text(
          myReview != null ? 'Edit Review' : 'Write a Review',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int? rating, String label) {
    bool isSelected = _filterRating == rating;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        labelStyle: GoogleFonts.inter(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterRating = selected ? rating : null;
          });
        },
        backgroundColor: Colors.white.withOpacity(0.1),
        selectedColor: const Color(0xFF69F0AE),
        checkmarkColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF69F0AE) : Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(ReviewStats stats) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      blur: 20,
      opacity: 0.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Big Average
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                StarRating(rating: stats.averageRating, size: 16),
                const SizedBox(height: 8),
                Text(
                  'Based on ${stats.totalReviews} reviews',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Distribution Bars
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildProgressBar(5, stats.distribution[5] ?? 0, stats.totalReviews),
                const SizedBox(height: 4),
                _buildProgressBar(4, stats.distribution[4] ?? 0, stats.totalReviews),
                const SizedBox(height: 4),
                _buildProgressBar(3, stats.distribution[3] ?? 0, stats.totalReviews),
                const SizedBox(height: 4),
                _buildProgressBar(2, stats.distribution[2] ?? 0, stats.totalReviews),
                const SizedBox(height: 4),
                _buildProgressBar(1, stats.distribution[1] ?? 0, stats.totalReviews),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int stars, int count, int total) {
    double percentage = total > 0 ? count / total : 0;
    return Row(
      children: [
        Text(
          '$stars',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Color(0xFF69F0AE), size: 10),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, ReviewModel review, ReviewService reviewService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Review?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete your review?\nThis action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await reviewService.deleteReview(review.id, review.targetId, review.targetType);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your review has been deleted.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete review.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
