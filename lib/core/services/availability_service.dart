import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/availability_model.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'availabilities';

  /// Initialize or Update Availability for a Provider
  Future<void> setAvailability(AvailabilityModel availability) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(availability.providerId)
          .set(availability.toMap(), SetOptions(merge: true));
      debugPrint('[AvailabilityService] Availability updated for: ${availability.providerId}');
    } catch (e) {
      debugPrint('[AvailabilityService] Error setting availability: $e');
      rethrow;
    }
  }

  /// Fetch Availability settings
  Stream<AvailabilityModel?> getAvailabilityStream(String providerId) {
    return _firestore
        .collection(_collection)
        .doc(providerId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return AvailabilityModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Fetch Snapshot (One-time)
  Future<AvailabilityModel?> getAvailability(String providerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(providerId).get();
      if (doc.exists && doc.data() != null) {
        return AvailabilityModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[AvailabilityService] Error fetching availability: $e');
      return null;
    }
  }

  /// Block a specific date (Whole Day)
  Future<void> blockDate(String providerId, DateTime date) async {
    try {
      // Normalize date to midnight
      final d = DateTime(date.year, date.month, date.day);
      await _firestore.collection(_collection).doc(providerId).update({
        'blockedDates': FieldValue.arrayUnion([Timestamp.fromDate(d)])
      });
    } catch (e) {
      debugPrint('[AvailabilityService] Error blocking date: $e');
      rethrow;
    }
  }

  /// Unblock a specific date
  Future<void> unblockDate(String providerId, DateTime date) async {
    try {
      final d = DateTime(date.year, date.month, date.day);
      await _firestore.collection(_collection).doc(providerId).update({
        'blockedDates': FieldValue.arrayRemove([Timestamp.fromDate(d)])
      });
    } catch (e) {
      debugPrint('[AvailabilityService] Error unblocking date: $e');
      rethrow;
    }
  }

  /// Block a specific time slot
  Future<void> blockSlot(String providerId, DateTime date, String time) async {
    try {
      // Format date key as "yyyy-MM-dd"
      String dateKey = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
      
      // We need to merge into the map. Firestore dot notation works for map updates.
      // "manuallyBlockedSlots.2025-01-20" : FieldValue.arrayUnion(["10:00"])
      
      await _firestore.collection(_collection).doc(providerId).update({
        'manuallyBlockedSlots.$dateKey': FieldValue.arrayUnion([time])
      });
    } catch (e) {
      debugPrint('[AvailabilityService] Error blocking slot: $e');
      rethrow;
    }
  }

  /// Unblock a specific time slot
  Future<void> unblockSlot(String providerId, DateTime date, String time) async {
    try {
      String dateKey = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
      
      await _firestore.collection(_collection).doc(providerId).update({
        'manuallyBlockedSlots.$dateKey': FieldValue.arrayRemove([time])
      });
    } catch (e) {
      debugPrint('[AvailabilityService] Error unblocking slot: $e');
      rethrow;
    }
  }
}
