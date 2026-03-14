import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String touristId;
  final String touristName;
  final String providerId;
  final String providerName;
  final String serviceName;

  // Multi-day support: dates is the canonical field.
  // bookingDate is kept for display/legacy compatibility (set to dates.first).
  final List<DateTime> dates;
  final String? timeSlot; // nullable - full-day bookings have no slot
  final int numberOfPeople;
  final String status; // 'confirmed', 'cancelled', 'completed'
  final double pricePerPerson;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.touristId,
    required this.touristName,
    required this.providerId,
    required this.providerName,
    required this.serviceName,
    required this.dates,
    this.timeSlot,
    this.numberOfPeople = 1,
    this.status = 'confirmed',
    this.pricePerPerson = 0.0,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Convenience getter for legacy/receipt compatibility
  DateTime get bookingDate => dates.isNotEmpty ? dates.first : DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'touristName': touristName,
      'providerId': providerId,
      'providerName': providerName,
      'serviceName': serviceName,
      'dates': dates.map((d) => Timestamp.fromDate(d)).toList(),
      'timeSlot': timeSlot,
      'numberOfPeople': numberOfPeople,
      'status': status,
      'pricePerPerson': pricePerPerson,
      'totalPrice': totalPrice,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle legacy bookingDate (single date) and new dates[] array
    List<DateTime> parsedDates = [];
    if (map['dates'] != null) {
      parsedDates = (map['dates'] as List<dynamic>)
          .map((e) => (e as Timestamp).toDate())
          .toList();
    } else if (map['bookingDate'] != null) {
      parsedDates = [(map['bookingDate'] as Timestamp).toDate()];
    }

    return BookingModel(
      id: id,
      touristId: map['touristId'] ?? '',
      touristName: map['touristName'] ?? 'Unknown',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? 'Unknown',
      serviceName: map['serviceName'] ?? 'General Service',
      dates: parsedDates,
      timeSlot: map['timeSlot'],
      numberOfPeople: map['numberOfPeople'] ?? 1,
      status: map['status'] ?? 'confirmed',
      pricePerPerson: (map['pricePerPerson'] ?? map['totalPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
