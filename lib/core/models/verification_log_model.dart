import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationLog {
  final String id;
  final String verificationId;
  final String action; // e.g., 'submitted', 'approved', 'rejected', 'expired'
  final String performedBy; // Admin ID or 'SYSTEM'
  final DateTime timestamp;

  VerificationLog({
    required this.id,
    required this.verificationId,
    required this.action,
    required this.performedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'verificationId': verificationId,
      'action': action,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory VerificationLog.fromMap(Map<String, dynamic> map) {
    return VerificationLog(
      id: map['id'] ?? '',
      verificationId: map['verificationId'] ?? '',
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
