import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/models/review_model.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/star_rating.dart';

class AddReviewScreen extends StatefulWidget {
  final String targetId;
  final String targetType;
  final String targetName;
  final ReviewModel? existingReview;

  const AddReviewScreen({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    this.existingReview,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating.toInt();
      _titleController.text = widget.existingReview!.title;
      _textController.text = widget.existingReview!.text;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _errorMessage = null);

    if (_rating == 0) {
      setState(() => _errorMessage = 'Please select a rating before submitting your review.');
      return;
    }
    
    final text = _textController.text.trim();
    if (text.length < 3 || RegExp(r'^(.)\1+$').hasMatch(text.replaceAll(' ', ''))) {
      setState(() => _errorMessage = 'Please write a meaningful review describing your experience.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception('You must be logged in to leave a review.');
      }

      final reviewService = Provider.of<ReviewService>(context, listen: false);
      
      if (widget.existingReview == null) {
        // Check for duplicate review
        bool hasReviewed = await reviewService.hasUserReviewed(widget.targetId, user.uid);
        if (hasReviewed) {
          throw Exception('You already submitted a review. You can edit your existing one.');
        }
      }

      final isEditing = widget.existingReview != null;
      final review = ReviewModel(
        id: isEditing ? widget.existingReview!.id : const Uuid().v4(),
        targetId: widget.targetId,
        targetType: widget.targetType,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous User',
        userProfilePic: user.photoURL ?? '',
        rating: _rating.toDouble(),
        title: _titleController.text.trim(),
        text: text,
        createdAt: isEditing ? widget.existingReview!.createdAt : DateTime.now(),
        helpfulVotes: isEditing ? widget.existingReview!.helpfulVotes : 0,
        status: isEditing ? widget.existingReview!.status : ReviewStatus.pending,
      );

      if (isEditing) {
        await reviewService.updateReview(review);
      } else {
        await reviewService.addReview(review);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Your review has been updated successfully.' : 'Review submitted successfully!'),
            backgroundColor: const Color(0xFF69F0AE),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      if (mounted && e.toString().contains('Failed to submit')) {
        setState(() => _errorMessage = 'Failed to submit review.\nPlease try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasChanges = true;
    if (widget.existingReview != null) {
      hasChanges = _titleController.text.trim() != widget.existingReview!.title ||
                   _textController.text.trim() != widget.existingReview!.text ||
                   _rating.toDouble() != widget.existingReview!.rating;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.existingReview != null ? 'Edit Review' : 'Write a Review',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LuxuryGlass(
                    padding: const EdgeInsets.all(24),
                    blur: 15,
                    opacity: 0.1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How was your experience with ${widget.targetName}?',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Interactive Star Rating
                        Center(
                          child: StarRating(
                            rating: _rating.toDouble(),
                            size: 40,
                            interactable: true,
                            onRatingChanged: (newRating) {
                              setState(() => _rating = newRating);
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Title Input
                        Text(
                          'Review Title (Optional)',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Sum up your experience',
                            hintStyle: const TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 16),
                        
                        // Text Input
                        Text(
                          'Review Description *',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 5,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: 'Share details of your own experience at this place',
                            hintStyle: const TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}), // To trigger active state of button
                        ),
                        // Live character counter
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_textController.text.length} / 500',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !hasChanges) ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF69F0AE),
                        disabledBackgroundColor: Colors.white24,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              widget.existingReview != null ? 'Update Review' : 'Submit Review',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: (_isLoading || !hasChanges) ? Colors.white54 : Colors.black,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
