import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/review_model.dart';
import '../../../core/services/review_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_container.dart';
import 'sp_review_details_screen.dart';

class SPReviewsScreen extends StatefulWidget {
  const SPReviewsScreen({super.key});

  @override
  State<SPReviewsScreen> createState() => _SPReviewsScreenState();
}

class _SPReviewsScreenState extends State<SPReviewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _ratingFilter;
  String _dateFilter = 'Newest First';

  final List<String> _dateOptions = ['Newest First', 'Oldest First', 'Last 7 Days', 'Last 30 Days'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              padding: const EdgeInsets.all(24),
              opacity: 0.15,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Reviews', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    
                    Text('Rating', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [null, 5, 4, 3, 2, 1].map((rating) {
                        final isSelected = _ratingFilter == rating;
                        return ChoiceChip(
                          label: Text(rating == null ? 'All Ratings' : '$rating Stars', style: GoogleFonts.inter(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _ratingFilter = rating);
                              setState(() => _ratingFilter = rating);
                            }
                          },
                          selectedColor: const Color(0xFF69F0AE),
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Text('Date Range', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dateOptions.map((opt) {
                        final isSelected = _dateFilter == opt;
                        return ChoiceChip(
                          label: Text(opt, style: GoogleFonts.inter(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _dateFilter = opt);
                              setState(() => _dateFilter = opt);
                            }
                          },
                          selectedColor: const Color(0xFF69F0AE),
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF69F0AE),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Reviews Dashboard', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterSheet,
          )
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<ReviewModel>>(
            stream: Provider.of<ReviewService>(context, listen: false).getReviewsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)));
              }
              if (snapshot.hasError) {
                 return Center(child: Text('Error loading reviews', style: GoogleFonts.inter(color: Colors.redAccent)));
              }

              final allReviews = snapshot.data ?? [];
              
              // Compute Sub-stats
              double avgRating = 0;
              final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
              if (allReviews.isNotEmpty) {
                double total = 0;
                for (var r in allReviews) {
                  total += r.rating;
                  int star = r.rating.round().clamp(1, 5);
                  distribution[star] = (distribution[star] ?? 0) + 1;
                }
                avgRating = total / allReviews.length;
              }

              // Apply Filters
              var filteredReviews = allReviews.where((r) {
                if (_ratingFilter != null && r.rating.round() != _ratingFilter) return false;
                if (_searchQuery.isNotEmpty) {
                  final sq = _searchQuery.toLowerCase();
                  if (!r.text.toLowerCase().contains(sq) && 
                      !(r.bookingId?.toLowerCase().contains(sq) ?? false) && 
                      !r.userName.toLowerCase().contains(sq)) {
                    return false;
                  }
                }
                if (_dateFilter == 'Last 7 Days') {
                  if (DateTime.now().difference(r.createdAt).inDays > 7) return false;
                } else if (_dateFilter == 'Last 30 Days') {
                  if (DateTime.now().difference(r.createdAt).inDays > 30) return false;
                }
                return true;
              }).toList();

              // Sort
              if (_dateFilter == 'Oldest First') {
                filteredReviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              } else {
                filteredReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              }

              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: LuxuryGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(16),
                      opacity: 0.1,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by booking ID or keyword...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Colors.white54),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),

                  // Analytics
                  if (allReviews.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildAnalyticsPanel(allReviews.length, avgRating, distribution),
                    ),

                  // List
                  Expanded(
                    child: filteredReviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rate_review_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No reviews found.', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 18)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: filteredReviews.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildReviewCard(filteredReviews[index]);
                          },
                        ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsPanel(int total, double avg, Map<int, int> dist) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.15,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(avg.toStringAsFixed(1), style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => Icon(
                        index < avg.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 16,
                      )),
                    ),
                    const SizedBox(height: 8),
                    Text('$total reviews', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: Colors.white10),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final count = dist[star] ?? 0;
                    final pct = total > 0 ? count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('$star⭐', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: pct,
                                color: Colors.amber,
                                backgroundColor: Colors.white10,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 24, child: Text('$count', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10))),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final hasReplied = review.providerReply != null && review.providerReply!.isNotEmpty;

    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.userProfilePic.isNotEmpty ? NetworkImage(review.userProfilePic) : null,
                backgroundColor: Colors.white10,
                child: review.userProfilePic.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < review.rating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 14,
                      )),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (review.bookingId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
              child: Text('Ref: #${review.bookingId}', style: GoogleFonts.ibmPlexMono(color: const Color(0xFF69F0AE), fontSize: 11)),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            review.text,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (hasReplied) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), border: Border.all(color: Colors.blueAccent.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Reply', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 4),
                  Text(review.providerReply!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                ],
              ),
            ),
          ],

          const Divider(color: Colors.white10, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SPReviewDetailsScreen(review: review)));
                },
                child: Text('View Details', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SPReviewDetailsScreen(review: review, autoFocusReply: true)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasReplied ? Colors.white10 : const Color(0xFF69F0AE),
                  foregroundColor: hasReplied ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(hasReplied ? 'Edit Reply' : 'Reply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
