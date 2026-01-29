import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/enquiry_model.dart';
import 'notification_service.dart';

class EnquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'enquiries';

  /// Send a new enquiry from Tourist -> Provider
  Future<void> sendEnquiry(EnquiryModel enquiry) async {
    try {
      await _firestore.collection(_collection).doc(enquiry.id).set(enquiry.toMap());
      debugPrint('[EnquiryService] Enquiry sent: ${enquiry.id}');
      
      // Trigger Notification for Provider
      // Creating simple instance to avoid DI complexity here
      try {
        await NotificationService().sendNotification(
          userId: enquiry.providerId,
          title: 'New Enquiry',
          body: 'You have a new enquiry from ${enquiry.touristName}',
          type: 'enquiry',
        );
      } catch (_) {}

    } catch (e) {
      debugPrint('[EnquiryService] Error sending enquiry: $e');
      rethrow;
    }
  }

  /// Fetch enquiries for a specific Provider or Tourist
  Stream<List<EnquiryModel>> getEnquiries({String? providerId, String? touristId}) {
    Query query = _firestore.collection(_collection);

    if (providerId != null) {
      query = query.where('providerId', isEqualTo: providerId);
    } else if (touristId != null) {
      query = query.where('touristId', isEqualTo: touristId);
    }
    
    return query.snapshots().map((snapshot) {
      final enquiries = snapshot.docs.map((doc) {
        return EnquiryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Client-side sort to avoid composite index requirement
      enquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return enquiries;
    });
  }

  /// Reply to an enquiry (Provider -> Tourist)
  Future<void> replyToEnquiry(String enquiryId, String replyMessage) async {
    try {
      // Fetch enquiry to get tourist ID? Or pass it in. 
      // Optimized: Just get the doc first.
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(enquiryId).get();
      if (!doc.exists) throw Exception('Enquiry not found');
      
      String touristId = (doc.data() as Map<String, dynamic>)['touristId'];

      await _firestore.collection(_collection).doc(enquiryId).update({
        'reply': replyMessage,
        'status': 'replied',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[EnquiryService] Replied to enquiry: $enquiryId');

      // Trigger Notification for Tourist
      try {
         await NotificationService().sendNotification(
          userId: touristId,
          title: 'Enquiry Reply',
          body: 'A provider has replied to your enquiry.',
          type: 'enquiry',
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[EnquiryService] Error replying: $e');
      rethrow;
    }
  }

  /// Helper to generate a new ID (can use Uuid package or Firestore doc().id)
  String generateId() {
    return _firestore.collection(_collection).doc().id;
  }
}
