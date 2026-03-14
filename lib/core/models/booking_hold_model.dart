import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHoldModel {
  final String id;
  final String providerId;
  final String touristId;
  final DateTime date;
  final String timeSlot;
  final int touristCount;
  final DateTime expiresAt;

  BookingHoldModel({
    required this.id,
    required this.providerId,
    required this.touristId,
    required this.date,
    required this.timeSlot,
    required this.touristCount,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'touristId': touristId,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'touristCount': touristCount,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory BookingHoldModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingHoldModel(
      id: id,
      providerId: map['providerId'] ?? '',
      touristId: map['touristId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      touristCount: map['touristCount'] ?? 1,
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
    );
  }
}
