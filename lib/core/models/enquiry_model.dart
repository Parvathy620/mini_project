import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryModel {
  final String id;
  final String touristId;
  final String touristName; // Denormalized for list display
  final String providerId;
  final String providerName; // Denormalized for list display
  final String message;
  final String? reply;
  final String status; // 'pending', 'replied', 'closed'
  final DateTime? requestedDate;
  final String? preferredTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EnquiryModel({
    required this.id,
    required this.touristId,
    required this.touristName,
    required this.providerId,
    required this.providerName,
    required this.message,
    this.reply,
    this.status = 'pending',
    this.requestedDate,
    this.preferredTime,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'touristName': touristName,
      'providerId': providerId,
      'providerName': providerName,
      'message': message,
      'reply': reply,
      'status': status,
      'requestedDate': requestedDate != null ? Timestamp.fromDate(requestedDate!) : null,
      'preferredTime': preferredTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory EnquiryModel.fromMap(Map<String, dynamic> map, String id) {
    return EnquiryModel(
      id: id,
      touristId: map['touristId'] ?? '',
      touristName: map['touristName'] ?? 'Unknown Tourist',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? 'Unknown Provider',
      message: map['message'] ?? '',
      reply: map['reply'],
      status: map['status'] ?? 'pending',
      requestedDate: map['requestedDate'] != null ? (map['requestedDate'] as Timestamp).toDate() : null,
      preferredTime: map['preferredTime'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
