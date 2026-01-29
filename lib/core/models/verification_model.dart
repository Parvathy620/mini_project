import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected,
  expired,
}

class ProviderVerification {
  final String id;
  final String providerId;
  final String documentType;
  final String documentUrl;
  final VerificationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime? expiryDate;
  final DateTime? nextRecheckDate;
  final DateTime? lastReminderSentAt;

  ProviderVerification({
    required this.id,
    required this.providerId,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    this.expiryDate,
    this.nextRecheckDate,
    this.lastReminderSentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'nextRecheckDate': nextRecheckDate != null ? Timestamp.fromDate(nextRecheckDate!) : null,
      'lastReminderSentAt': lastReminderSentAt != null ? Timestamp.fromDate(lastReminderSentAt!) : null,
    };
  }

  factory ProviderVerification.fromMap(Map<String, dynamic> map) {
    return ProviderVerification(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      documentType: map['documentType'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      verifiedAt: map['verifiedAt'] != null ? (map['verifiedAt'] as Timestamp).toDate() : null,
      verifiedBy: map['verifiedBy'],
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null,
      nextRecheckDate: map['nextRecheckDate'] != null ? (map['nextRecheckDate'] as Timestamp).toDate() : null,
      lastReminderSentAt: map['lastReminderSentAt'] != null ? (map['lastReminderSentAt'] as Timestamp).toDate() : null,
    );
  }
}
