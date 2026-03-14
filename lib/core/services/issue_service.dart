import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/issue_model.dart';
import 'notification_service.dart';

class IssueService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'issues';

  /// Report a new issue
  Future<void> reportIssue(IssueModel issue) async {
    try {
      await _firestore.collection(_collection).doc(issue.id).set(issue.toMap());
      
      // Notify Admin about new issue
      await NotificationService().sendNotificationToAdmin(
        title: 'New Issue Reported: ${issue.priority.name.toUpperCase()}',
        body: issue.title,
        data: {
          'type': 'issue',
          'relatedId': issue.id,
        },
      );
    } catch (e) {
      debugPrint('[IssueService] Error reporting issue: $e');
      rethrow;
    }
  }

  /// Get a stream of issues (for admin, with optional filters)
  Stream<List<IssueModel>> getIssues({
    IssueStatus? status,
    IssuePriority? priority,
    String? category,
  }) {
    Query query = _firestore.collection(_collection);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority.name);
    }
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // Sorting by date - will usually require composite index if combined with where
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IssueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Get issues for a specific user
  Stream<List<IssueModel>> getUserIssues(String userId) {
    return _firestore
        .collection(_collection)
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Update issue status (Admin action)
  Future<void> updateIssueStatus(String issueId, IssueStatus status, {String? adminNote}) async {
    try {
      await _firestore.collection(_collection).doc(issueId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (adminNote != null) 'adminNote': adminNote,
      });

      // Fetch issue to notify reporter
      final doc = await _firestore.collection(_collection).doc(issueId).get();
      if (doc.exists) {
        final reporterId = (doc.data() as Map<String, dynamic>)['reporterId'];
        final title = (doc.data() as Map<String, dynamic>)['title'];

        String notifTitle = 'Issue Status Updated';
        String notifBody = 'Your issue "$title" is now ${status.name}.';

        if (status == IssueStatus.resolved) {
          notifTitle = 'Issue Resolved ✅';
          notifBody = 'Your reported issue "$title" has been resolved. Thank you for your patience!';
        }

        await NotificationService().sendPushNotification(
          targetUserId: reporterId,
          title: notifTitle,
          body: notifBody,
          data: {
            'type': 'issue_update',
            'relatedId': issueId,
          },
        );
      }
    } catch (e) {
      debugPrint('[IssueService] Error updating issue status: $e');
      rethrow;
    }
  }

  /// Update issue priority (Admin action)
  Future<void> updateIssuePriority(String issueId, IssuePriority priority) async {
    try {
      await _firestore.collection(_collection).doc(issueId).update({
        'priority': priority.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[IssueService] Error updating issue priority: $e');
      rethrow;
    }
  }

  /// Helper to generate a new ID
  String generateId() {
    return _firestore.collection(_collection).doc().id;
  }
}
