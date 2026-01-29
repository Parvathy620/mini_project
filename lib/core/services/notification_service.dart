import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  /// Send a notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final notification = AppNotification(
        id: docRef.id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await docRef.set(notification.toMap());
      debugPrint('[NotificationService] Sent to $userId: $title');
    } catch (e) {
      debugPrint('[NotificationService] Error sending: $e');
      // Don't rethrow to avoid blocking main flow
    }
  }

  /// Get stream of notifications for a user
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.data());
      }).toList();
    });
  }

  /// Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('[NotificationService] Error marking read: $e');
    }
  }
}
