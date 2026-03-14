import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/booking_hold_model.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  /// Get Available Capacity for a single date
  Future<int> getAvailableCapacity({
    required String providerId,
    required DateTime date,
    required int defaultCapacity,
  }) async {
    try {
      int bookedCount = 0;
      int heldCount = 0;

      // 1. Count confirmed bookings that include this date
      final bookingsSnap = await _firestore
          .collection(_collection)
          .where('providerId', isEqualTo: providerId)
          .get();

      for (var doc in bookingsSnap.docs) {
        final b = BookingModel.fromMap(doc.data(), doc.id);
        if (b.status != 'cancelled' && b.status != 'rejected') {
          bool containsDate = b.dates.any((d) =>
              d.year == date.year && d.month == date.month && d.day == date.day);
          if (containsDate) bookedCount += b.numberOfPeople;
        }
      }

      // 2. Count active holds that include this date
      final holdsSnap = await _firestore
          .collection('booking_holds')
          .where('providerId', isEqualTo: providerId)
          .get();
      final now = DateTime.now();
      for (var doc in holdsSnap.docs) {
        final h = BookingHoldModel.fromMap(doc.data(), doc.id);
        if (h.expiresAt.isAfter(now)) {
          bool containsDate = h.dates.any((d) =>
              d.year == date.year && d.month == date.month && d.day == date.day);
          if (containsDate) heldCount += h.touristCount;
        } else {
          _firestore.collection('booking_holds').doc(doc.id).delete().catchError((_) {});
        }
      }

      int remaining = defaultCapacity - bookedCount - heldCount;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('[BookingService] Failed to get capacity: $e');
      return 0;
    }
  }

  /// Get the minimum available capacity across a list of dates (bottleneck)
  Future<int> getAvailableCapacityForDates({
    required String providerId,
    required List<DateTime> dates,
    required int defaultCapacity,
  }) async {
    if (dates.isEmpty) return 0;
    int minCapacity = defaultCapacity;
    for (final date in dates) {
      int cap = await getAvailableCapacity(
        providerId: providerId,
        date: date,
        defaultCapacity: defaultCapacity,
      );
      if (cap < minCapacity) minCapacity = cap;
    }
    return minCapacity;
  }

  /// Create a temporary hold for multiple dates
  Future<bool> createBookingHold(BookingHoldModel hold, int defaultCapacity) async {
    try {
      // Validate capacity across ALL selected dates
      int minCapacity = await getAvailableCapacityForDates(
        providerId: hold.providerId,
        dates: hold.dates,
        defaultCapacity: defaultCapacity,
      );

      if (minCapacity >= hold.touristCount) {
        await _firestore.collection('booking_holds').doc(hold.id).set(hold.toMap());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[BookingService] Error creating hold: $e');
      return false;
    }
  }

  /// Convert Hold to Confirmed Booking (batched atomic operation)
  Future<void> createBookingFromHold(BookingModel booking, String holdId) async {
    try {
      WriteBatch batch = _firestore.batch();
      batch.delete(_firestore.collection('booking_holds').doc(holdId));
      batch.set(_firestore.collection(_collection).doc(booking.id), booking.toMap());
      await batch.commit();

      debugPrint('[BookingService] Booking confirmed from hold: ${booking.id}');

      try {
        await NotificationService().sendPushNotification(
          targetUserId: booking.providerId,
          title: 'New Booking!',
          body: '${booking.touristName} booked ${booking.dates.length} day(s) with you.',
          data: {'type': 'booking', 'relatedId': booking.id},
        );
        await NotificationService().sendNotificationToAdmin(
          title: 'New Booking Activity',
          body: 'A confirmed booking was created by ${booking.touristName}.',
          data: {'type': 'booking', 'relatedId': booking.id},
        );
        await NotificationService().sendPushNotification(
          targetUserId: booking.touristId,
          title: 'Booking Confirmed!',
          body: 'Your booking with ${booking.providerName} is confirmed.',
          data: {'type': 'booking', 'relatedId': booking.id},
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[BookingService] Failed to confirm booking from hold: $e');
      rethrow;
    }
  }

  /// Update Booking Status
  Future<void> updateStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[BookingService] Status updated -> $newStatus: $bookingId');

      try {
        DocumentSnapshot snap = await _firestore.collection(_collection).doc(bookingId).get();
        if (snap.exists) {
          BookingModel booking = BookingModel.fromMap(snap.data() as Map<String, dynamic>, bookingId);

          if (newStatus == 'completed') {
            await NotificationService().sendPushNotification(
              targetUserId: booking.touristId,
              title: 'Booking Completed',
              body: 'Your booking with ${booking.providerName} is marked as completed.',
              data: {'type': 'booking', 'relatedId': bookingId},
            );
          } else if (newStatus == 'cancelled') {
            await NotificationService().sendPushNotification(
              targetUserId: booking.touristId,
              title: 'Booking Cancelled',
              body: 'Your booking with ${booking.providerName} was cancelled.',
              data: {'type': 'booking', 'relatedId': bookingId},
            );
            await NotificationService().sendPushNotification(
              targetUserId: booking.providerId,
              title: 'Booking Cancelled',
              body: 'Booking with ${booking.touristName} was cancelled.',
              data: {'type': 'booking', 'relatedId': bookingId},
            );
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[BookingService] Error updating status: $e');
      rethrow;
    }
  }

  /// Get Bookings Stream
  Stream<List<BookingModel>> getBookings({
    String? providerId,
    String? touristId,
    String? status,
  }) {
    Query query = _firestore.collection(_collection);
    if (providerId != null) query = query.where('providerId', isEqualTo: providerId);
    if (touristId != null) query = query.where('touristId', isEqualTo: touristId);

    return query.snapshots().map((snapshot) {
      var bookings = snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (status != null) {
        bookings = bookings.where((b) => b.status == status).toList();
      }

      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      return bookings;
    });
  }

  /// Cancel Booking
  Future<void> cancelBooking(String bookingId, {required bool isProvider}) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[BookingService] Cancelled booking: $bookingId');

      try {
        DocumentSnapshot snap = await _firestore.collection(_collection).doc(bookingId).get();
        if (snap.exists) {
          BookingModel booking = BookingModel.fromMap(snap.data() as Map<String, dynamic>, bookingId);
          String targetUserId = isProvider ? booking.touristId : booking.providerId;
          String body = isProvider
              ? 'Your booking with ${booking.providerName} has been cancelled by the provider.'
              : 'Booking with ${booking.touristName} has been cancelled.';

          await NotificationService().sendPushNotification(
            targetUserId: targetUserId,
            title: 'Booking Cancelled',
            body: body,
            data: {'type': 'booking', 'relatedId': bookingId},
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[BookingService] Cancel failed: $e');
      rethrow;
    }
  }

  String generateId() => _firestore.collection(_collection).doc().id;
  String generateHoldId() => _firestore.collection('booking_holds').doc().id;
}
