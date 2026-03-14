import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHoldModel {
  final String id;
  final String providerId;
  final String touristId;
  final List<DateTime> dates; // multi-day support
  final int touristCount;
  final DateTime expiresAt;

  BookingHoldModel({
    required this.id,
    required this.providerId,
    required this.touristId,
    required this.dates,
    required this.touristCount,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'touristId': touristId,
      'dates': dates.map((d) => Timestamp.fromDate(d)).toList(),
      'touristCount': touristCount,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory BookingHoldModel.fromMap(Map<String, dynamic> map, String id) {
    List<DateTime> parsedDates = [];
    if (map['dates'] != null) {
      parsedDates = (map['dates'] as List<dynamic>)
          .map((e) => (e as Timestamp).toDate())
          .toList();
    } else if (map['date'] != null) {
      // legacy single date
      parsedDates = [(map['date'] as Timestamp).toDate()];
    }

    return BookingHoldModel(
      id: id,
      providerId: map['providerId'] ?? '',
      touristId: map['touristId'] ?? '',
      dates: parsedDates,
      touristCount: map['touristCount'] ?? 1,
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
    );
  }
}
