import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String touristId;
  final String touristName;
  final String providerId;
  final String providerName;
  final String serviceName;
  final DateTime bookingDate;
  final String timeSlot; // Format: "HH:mm"
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed', 'rejected'
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
    required this.bookingDate,
    required this.timeSlot,
    this.status = 'pending',
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'touristName': touristName,
      'providerId': providerId,
      'providerName': providerName,
      'serviceName': serviceName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'timeSlot': timeSlot,
      'status': status,
      'totalPrice': totalPrice,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      touristId: map['touristId'] ?? '',
      touristName: map['touristName'] ?? 'Unknown',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? 'Unknown',
      serviceName: map['serviceName'] ?? 'General Service',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      status: map['status'] ?? 'pending',
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
