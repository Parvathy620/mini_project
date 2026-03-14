import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/review_model.dart';
import '../../../core/services/review_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';

class SPReviewDetailsScreen extends StatefulWidget {
  final ReviewModel review;
  final bool autoFocusReply;

  const SPReviewDetailsScreen({
    super.key,
    required this.review,
    this.autoFocusReply = false,
  });

  @override
  State<SPReviewDetailsScreen> createState() => _SPReviewDetailsScreenState();
}

class _SPReviewDetailsScreenState extends State<SPReviewDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    if (widget.review.providerReply != null) {
      _replyController.text = widget.review.providerReply!;
    }
    if (widget.autoFocusReply) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_replyFocusNode);
      });
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply must be at least 5 characters long')));
      return;
    }
    if (text.length > 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply must be under 300 characters')));
      return;
    }

    setState(() => _isReplying = true);

    try {
      await Provider.of<ReviewService>(context, listen: false).replyToReview(widget.review.id, text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply submitted successfully')));
        Navigator.pop(context); // Go back after successful reply
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Review Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewDetailCard(),
                const SizedBox(height: 24),
                _buildReplySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewDetailCard() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: widget.review.userProfilePic.isNotEmpty ? NetworkImage(widget.review.userProfilePic) : null,
                backgroundColor: Colors.white10,
                child: widget.review.userProfilePic.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.review.userName,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date Submitted: ${DateFormat('MMMM d, yyyy').format(widget.review.createdAt)}',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),

          if (widget.review.bookingId != null) ...[
            Text('BOOKING REFERENCE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('#${widget.review.bookingId}', style: GoogleFonts.ibmPlexMono(color: const Color(0xFF69F0AE), fontSize: 14)),
            const SizedBox(height: 16),
          ],

          if (widget.review.serviceType != null) ...[
            Text('SERVICE TYPE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(widget.review.serviceType!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 16),
          ],

          Text('RATING', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => Icon(
              index < widget.review.rating.round() ? Icons.star : Icons.star_border,
              color: Colors.amber, size: 20,
            )),
          ),
          const SizedBox(height: 16),

          Text('REVIEW', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            widget.review.text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildReplySection() {
    return LuxuryGlass(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reply, color: Color(0xFF69F0AE), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.review.providerReply != null ? 'Edit Reply' : 'Reply to Review',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _replyController,
            focusNode: _replyFocusNode,
            maxLines: 4,
            maxLength: 300,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write your response to the customer...',
              hintStyle: const TextStyle(color: Colors.white38),
              counterStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isReplying ? null : _submitReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isReplying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('Submit Reply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
