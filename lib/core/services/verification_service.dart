import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/verification_model.dart';
import '../models/verification_log_model.dart';
import '../models/notification_model.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _verificationCollection = 'provider_verifications';
  final String _logsCollection = 'verification_logs';
  final String _notificationsCollection = 'notifications';

  /// Submit a new verification request
  Future<void> submitVerification({
    required String providerId,
    required String documentType,
    required String documentUrl,
    String? description, // Optional description update
  }) async {
    try {
      final docRef = _firestore.collection(_verificationCollection).doc();
      final verification = ProviderVerification(
        id: docRef.id,
        providerId: providerId,
        documentType: documentType,
        documentUrl: documentUrl,
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      await docRef.set(verification.toMap());
      
      // Update Provider Description if provided
      if (description != null && description.isNotEmpty) {
        await _firestore.collection('service_providers').doc(providerId).update({
          'description': description,
        });
      }

      await _logAction(
        verificationId: docRef.id,
        action: 'submitted',
        performedBy: providerId,
      );
      
      // Notify Admin
      await _sendNotification(
        userId: 'admin', // Special ID for Admin Notifications
        title: 'New Verification Request',
        body: 'A new service provider has submitted documents for verification.',
        type: 'verification',
      );
    } catch (e) {
      if (kDebugMode) print('Error submitting verification: $e');
      rethrow;
    }
  }

  /// Get verification status for a specific provider
  Future<ProviderVerification?> getVerificationStatus(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection(_verificationCollection)
          .where('providerId', isEqualTo: providerId)
          // .orderBy('submittedAt', descending: true) // Removed to avoid index issues
          // .limit(1) // Can't limit if we want to sort client side
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.map((d) => ProviderVerification.fromMap(d.data())).toList();
        docs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt)); // Sort Descending
        return docs.first;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching status: $e');
      rethrow;
    }
  }

  /// Real-time stream of verification status
  Stream<ProviderVerification?> getVerificationStream(String providerId) {
    return _firestore
        .collection(_verificationCollection)
        .where('providerId', isEqualTo: providerId)
        // .orderBy('submittedAt', descending: true) // Removed to avoid index issues
        // .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final docs = snapshot.docs.map((d) => ProviderVerification.fromMap(d.data())).toList();
            docs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt)); // Sort Descending
            return docs.first;
          }
          return null;
        });
  }

  /// Admin: Fetch all pending requests
  Future<List<ProviderVerification>> getPendingRequests() async {
    try {
      final snapshot = await _firestore
          .collection(_verificationCollection)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => ProviderVerification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching pending requests: $e');
      rethrow;
    }
  }

  /// Admin: Approve a provider
  Future<void> approveProvider(String verificationId, String adminId, String providerId) async {
    try {
      await _firestore.collection(_verificationCollection).doc(verificationId).update({
        'status': VerificationStatus.approved.name,
        'verifiedAt': Timestamp.now(),
        'verifiedBy': adminId,
        // Set expiry for 3 months (90 days)
        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
      });

      // Update Service Provider Collection
      await _firestore.collection('service_providers').doc(providerId).update({
        'isApproved': true,
      });

      await _logAction(
        verificationId: verificationId,
        action: 'approved',
        performedBy: adminId,
      );

      await _sendNotification(
        userId: providerId,
        title: 'Verification Approved',
        body: 'Your account has been verified successfully.',
        type: 'verification',
      );
    } catch (e) {
      if (kDebugMode) print('Error approving provider: $e');
      rethrow;
    }
  }

  /// Admin: Reject a provider
  Future<void> rejectProvider(String verificationId, String adminId, String providerId, String reason) async {
    try {
      await _firestore.collection(_verificationCollection).doc(verificationId).update({
        'status': VerificationStatus.rejected.name,
        'verifiedAt': Timestamp.now(),
        'verifiedBy': adminId,
        'rejectionReason': reason,
      });

      // Update Service Provider Collection (optional: ensure isApproved is false)
      await _firestore.collection('service_providers').doc(providerId).update({
        'isApproved': false,
      });

      await _logAction(
        verificationId: verificationId,
        action: 'rejected',
        performedBy: adminId,
      );

      await _sendNotification(
        userId: providerId,
        title: 'Verification Rejected',
        body: 'Reason: $reason',
        type: 'verification',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// System: Check and process expired verifications & Reminders
  Future<void> checkAndProcessExpirations() async {
    try {
      final now = DateTime.now();
      final warningThreshold = now.add(const Duration(days: 30));
      
      // Fetch all approved verifications
      // Note: In a real app with millions of users, this would be a paginated Cloud Function
      final snapshot = await _firestore
          .collection(_verificationCollection)
          .where('status', isEqualTo: VerificationStatus.approved.name)
          .get();

      for (var doc in snapshot.docs) {
        final verification = ProviderVerification.fromMap(doc.data());
        if (verification.expiryDate == null) continue;

        // 1. Check for Expiration
        if (verification.expiryDate!.isBefore(now)) {
           await _handleExpiredVerification(verification);
        } 
        // 2. Check for Upcoming Expiration (Warning)
        else if (verification.expiryDate!.isBefore(warningThreshold)) {
           await _handleExpiringSoonVerification(verification);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error processing expirations: $e');
    }
  }

  /// Provider: Check own expiry status on login/dashboard load
  Future<void> checkProviderExpiry(String providerId) async {
    try {
      final verification = await getVerificationStatus(providerId);
      if (verification == null || verification.status != VerificationStatus.approved || verification.expiryDate == null) {
        return;
      }

      final now = DateTime.now();
      if (verification.expiryDate!.isBefore(now)) {
        await _handleExpiredVerification(verification);
      } else if (verification.expiryDate!.isBefore(now.add(const Duration(days: 30)))) {
        await _handleExpiringSoonVerification(verification);
      }
    } catch (e) {
      if (kDebugMode) print('Error checking provider expiry: $e');
    }
  }

  Future<void> _handleExpiredVerification(ProviderVerification verification) async {
    // avoid redundant updates if already processed (though status query filters them out usually, double check safety)
    if (verification.status == VerificationStatus.expired) return;

    await _firestore.collection(_verificationCollection).doc(verification.id).update({
      'status': VerificationStatus.expired.name,
    });

    await _firestore.collection('service_providers').doc(verification.providerId).update({
      'isApproved': false,
    });

    await _logAction(
      verificationId: verification.id,
      action: 'expired_auto',
      performedBy: 'SYSTEM',
    );

    await _sendNotification(
      userId: verification.providerId,
      title: 'Verification Expired',
      body: 'Your verification has expired. Please submit new documents to restore your verified status.',
      type: 'verification',
    );
  }

  Future<void> _handleExpiringSoonVerification(ProviderVerification verification) async {
    // Spam Prevention: Only send weekly reminders
    if (verification.lastReminderSentAt != null) {
      final daysSinceLast = DateTime.now().difference(verification.lastReminderSentAt!).inDays;
      if (daysSinceLast < 7) return; 
    }

    await _firestore.collection(_verificationCollection).doc(verification.id).update({
      'lastReminderSentAt': Timestamp.now(),
    });

    final daysLeft = verification.expiryDate!.difference(DateTime.now()).inDays;

    await _sendNotification(
      userId: verification.providerId,
      title: 'Verification Expiring Soon',
      body: 'Your verification will expire in $daysLeft days. Please plan to renew it.',
      type: 'verification',
    );
  }

  /// Fetch notifications for a user
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection(_notificationsCollection).doc(notificationId).update({'isRead': true});
  }

  /// Helper: Log actions
  Future<void> _logAction({
    required String verificationId,
    required String action,
    required String performedBy,
  }) async {
    final docRef = _firestore.collection(_logsCollection).doc();
    final log = VerificationLog(
      id: docRef.id,
      verificationId: verificationId,
      action: action,
      performedBy: performedBy,
      timestamp: DateTime.now(),
    );
    await docRef.set(log.toMap());
  }

  /// Helper: Send in-app notification
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    final docRef = _firestore.collection(_notificationsCollection).doc();
    final notification = AppNotification(
      id: docRef.id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
    );
    await docRef.set(notification.toMap());
  }
}
