import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import 'luxury_glass.dart';
import 'star_rating.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String? currentUserId;
  final VoidCallback? onHelpfulTapped;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.currentUserId,
    this.onHelpfulTapped,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LuxuryGlass(
        padding: const EdgeInsets.all(16.0),
        blur: 15,
        opacity: 0.1,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User Info & Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF50C878).withOpacity(0.2), // Emerald tinted
                  backgroundImage: review.userProfilePic.isNotEmpty
                      ? NetworkImage(review.userProfilePic)
                      : null,
                  child: review.userProfilePic.isEmpty
                      ? Text(
                          review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF69F0AE),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      StarRating(rating: review.rating, size: 14),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    dateFormat.format(review.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
                if (currentUserId != null && review.userId == currentUserId)
                  Container(
                    height: 24,
                    width: 24,
                    margin: const EdgeInsets.only(left: 4),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                      color: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) onEdit!();
                        if (value == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text('Edit Review', style: GoogleFonts.inter(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Text('Delete Review', style: GoogleFonts.inter(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title (Optional)
            if (review.title.isNotEmpty) ...[
              Text(
                review.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            // Review Text
            Text(
              review.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Helpful Button
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onHelpfulTapped,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Helpful (${review.helpfulVotes})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
