import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });
}

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Automatically replace bad words with asterisks
  String _filterProfanity(String text) {
    final badWords = [
      'spam', 'scam', 'fake', 'idiot', 'stupid', 'dumb', 'crap'
    ]; 
    String filteredText = text;
    for (var word in badWords) {
      final RegExp exp = RegExp(word, caseSensitive: false);
      filteredText = filteredText.replaceAllMapped(exp, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    return filteredText;
  }

  // Check spam patterns (e.g., URLs)
  bool _isSpam(String text) {
    if (text.contains('http') || text.contains('www.')) return true;
    return false;
  }

  Future<void> addReview(ReviewModel review) async {
    final filteredText = _filterProfanity(review.text);
    final filteredTitle = _filterProfanity(review.title);
    
    bool isFlagged = _isSpam(filteredText) || _isSpam(filteredTitle);
    
    final finalReview = review.copyWith(
      title: filteredTitle,
      text: filteredText,
      status: isFlagged ? ReviewStatus.pending : ReviewStatus.approved,
    );

    final docRef = _firestore.collection('reviews').doc(finalReview.id);
    await docRef.set(finalReview.toMap());
    
    if (finalReview.status == ReviewStatus.approved) {
      await _updateTargetRating(finalReview.targetId, finalReview.targetType);
    }
  }

  Future<void> updateReview(ReviewModel review) async {
    final filteredText = _filterProfanity(review.text);
    final filteredTitle = _filterProfanity(review.title);
    
    bool isFlagged = _isSpam(filteredText) || _isSpam(filteredTitle);
    
    final finalReview = review.copyWith(
      title: filteredTitle,
      text: filteredText,
      status: isFlagged ? ReviewStatus.pending : ReviewStatus.approved,
    );

    final docRef = _firestore.collection('reviews').doc(finalReview.id);
    await docRef.update(finalReview.toMap());
    
    if (finalReview.status == ReviewStatus.approved) {
      await _updateTargetRating(finalReview.targetId, finalReview.targetType);
    }
  }

  Future<void> deleteReview(String reviewId, String targetId, String targetType) async {
    final docRef = _firestore.collection('reviews').doc(reviewId);
    await docRef.delete();
    
    await _updateTargetRating(targetId, targetType);
  }

  Stream<List<ReviewModel>> getReviewsStream(
    String targetId, {
    ReviewStatus status = ReviewStatus.approved,
    String sortBy = 'createdAt',
    bool descending = true,
  }) {
    Query query = _firestore.collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .where('status', isEqualTo: status.toString().split('.').last);

    return query.snapshots().map((snapshot) {
      final reviews = snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      // Perform local sorting to bypass Firebase Composite Index requirements
      reviews.sort((a, b) {
        int result;
        if (sortBy == 'rating') {
          result = a.rating.compareTo(b.rating);
        } else if (sortBy == 'helpfulVotes') {
          result = a.helpfulVotes.compareTo(b.helpfulVotes);
        } else {
          result = a.createdAt.compareTo(b.createdAt); // Default is createdAt
        }
        return descending ? -result : result; // Reverse if descending
      });
      
      return reviews;
    });
  }

  // Note: Local sorting/filtering might be needed if composite indexes are not created yet.
  // We provide a basic fetch without ordering if needed.
  Future<List<ReviewModel>> fetchReviews(String targetId, {ReviewStatus status = ReviewStatus.approved}) async {
    final snapshot = await _firestore.collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .get();
        
    final reviews = snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    
    // Sort locally by default
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<ReviewStats> getReviewStats(String targetId) async {
    final snapshot = await _firestore.collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .where('status', isEqualTo: ReviewStatus.approved.toString().split('.').last)
        .get();

    if (snapshot.docs.isEmpty) {
      return ReviewStats(averageRating: 0.0, totalReviews: 0, distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0});
    }

    int total = snapshot.docs.length;
    double sum = 0;
    Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in snapshot.docs) {
      final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      sum += rating;
      int star = rating.round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }

    double average = double.parse((sum / total).toStringAsFixed(1));

    return ReviewStats(
      averageRating: average,
      totalReviews: total,
      distribution: dist,
    );
  }

  Future<void> _updateTargetRating(String targetId, String targetType) async {
    final stats = await getReviewStats(targetId);
    
    String collection = targetType == 'destination' ? 'destinations' : 'service_providers';
    
    try {
      await _firestore.collection(collection).doc(targetId).update({
        'rating': stats.averageRating,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating target rating: $e');
      }
    }
  }

  Future<bool> hasUserReviewed(String targetId, String userId) async {
    final snapshot = await _firestore.collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
        
    return snapshot.docs.isNotEmpty;
  }

  Future<void> incrementHelpfulVotes(String reviewId) async {
    final docRef = _firestore.collection('reviews').doc(reviewId);
    await docRef.update({
      'helpfulVotes': FieldValue.increment(1),
    });
  }

  Future<void> replyToReview(String reviewId, String replyText) async {
    final docRef = _firestore.collection('reviews').doc(reviewId);
    await docRef.update({
      'providerReply': replyText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
