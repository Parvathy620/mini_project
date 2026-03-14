import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/booking_hold_model.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  /// Create a Booking Request
  /// Optionally, we could check for conflict here, but for "Request" status
  /// we might allow overlaps until "Confirmed". 
  /// For "Instant Book", we would need a transaction.
  /// Let's assume Request -> Confirm flow.
  Future<void> createBookingRequest(BookingModel booking) async {
    try {
      await _firestore.collection(_collection).doc(booking.id).set(booking.toMap());
      debugPrint('[BookingService] Booking requested: ${booking.id}');
      
      // Notify Provider
      try {
        await NotificationService().sendPushNotification(
          targetUserId: booking.providerId,
          title: 'New Booking Request',
          body: '${booking.touristName} requested a booking for ${booking.timeSlot}.',
          data: {
            'type': 'booking',
            'relatedId': booking.id,
          },
        );
      } catch (_) {}

      // Notify Admin
      try {
        await NotificationService().sendNotificationToAdmin(
          title: 'New Booking Activity',
          body: 'A new booking has been created in the system by ${booking.touristName}.',
          data: {
            'type': 'booking',
            'relatedId': booking.id,
          },
        );
      } catch (_) {}

      // Notify Customer (Confirmation of request)
      try {
        await NotificationService().sendPushNotification(
          targetUserId: booking.touristId,
          title: 'Booking Confirmed',
          body: 'Your booking request has been successfully created.',
          data: {
            'type': 'booking',
            'relatedId': booking.id,
          },
        );
      } catch (_) {}

    } catch (e) {
      debugPrint('[BookingService] Error creating booking: $e');
      rethrow;
    }
  }

  /// Get Bookings
  Stream<List<BookingModel>> getBookings({String? providerId, String? touristId, String? status}) {
    Query query = _firestore.collection(_collection);

    if (providerId != null) query = query.where('providerId', isEqualTo: providerId);
    if (touristId != null) query = query.where('touristId', isEqualTo: touristId);
    
    // NOTE: Removed 'status' filter and 'orderBy' from Firestore query
    // to avoid needing composite indexes for every combination.
    // Filtering and sorting is done client-side below.

    return query.snapshots().map((snapshot) {
      var bookings = snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Client-side Filter
      if (status != null) {
        bookings = bookings.where((b) => b.status == status).toList();
      }

      // Client-side Sort (Newest first)
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      return bookings;
    });
  }

  /// Update Booking Status
  Future<void> updateStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[BookingService] Status updated -> $newStatus: $bookingId');
      
      // Notify Parties
      try {
        DocumentSnapshot snap = await _firestore.collection(_collection).doc(bookingId).get();
        if (snap.exists) {
           BookingModel booking = BookingModel.fromMap(snap.data() as Map<String, dynamic>, bookingId);
           
           if (newStatus == 'confirmed') {
             // Notify Tourist
             await NotificationService().sendPushNotification(
               targetUserId: booking.touristId,
               title: 'Booking Update',
               body: 'Your booking with ${booking.providerName} has been confirmed.',
               data: {'type': 'booking', 'relatedId': bookingId},
             );
             // Notify Provider
             await NotificationService().sendPushNotification(
               targetUserId: booking.providerId,
               title: 'Booking Accepted',
               body: 'You accepted a booking request from ${booking.touristName}.',
               data: {'type': 'booking', 'relatedId': bookingId},
             );
           } else if (newStatus == 'cancelled') {
             // Notify both
              await NotificationService().sendPushNotification(
               targetUserId: booking.touristId,
               title: 'Booking Update',
               body: 'Your booking with ${booking.providerName} was cancelled.',
               data: {'type': 'booking', 'relatedId': bookingId},
             );
              await NotificationService().sendPushNotification(
               targetUserId: booking.providerId,
               title: 'Booking Update',
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

  /// Confirm Booking (Transaction)
  Future<void> confirmBooking(String bookingId) async {
    // 1. Get availability service (Can't inject easily here without context or locator, 
    // so we assume simple instantiation or we change BookingService to take it in constructor.
    // For simplicity in this structure, we instantiate or use instance if singleton.
    // Given the Provider setup, we cannot easily access other providers here unless passed.
    // Ideally, UI calls a "BookingController" which orchestrates this.
    // However, to keep logic in Service, we will perform the Firestore operations directly 
    // OR we need to fetch the Booking first to know *what* to block.
    
    // We need the booking details (providerId, date, time) to block the slot.
    try {
      DocumentSnapshot snap = await _firestore.collection(_collection).doc(bookingId).get();
      BookingModel booking = BookingModel.fromMap(snap.data() as Map<String, dynamic>, bookingId);
      
      // Block the slot
      // We will perform a manually constructed update to 'availabilities' here 
      // to avoid circular dependency or service instantiation issues if possible,
      // OR better: Just call AvailabilityService() new instance if it's stateless enough.
      // AvailabilityService is stateless except for _firestore.
      
      // Using direct firestore update for atomicity would be best (Batch), 
      // but let's use the service method pattern if we can. 
      // We'll update status first, then block slot.
      
      await updateStatus(bookingId, 'confirmed');
      
      String dateKey = "${booking.bookingDate.year}-${booking.bookingDate.month.toString().padLeft(2,'0')}-${booking.bookingDate.day.toString().padLeft(2,'0')}";
      
      await _firestore.collection('availabilities').doc(booking.providerId).update({
        'manuallyBlockedSlots.$dateKey': FieldValue.arrayUnion([booking.timeSlot])
      });
      
    } catch (e) {
      debugPrint('[BookingService] Confirm failed: $e');
      rethrow;
    }
  }

   /// Cancel Booking
  Future<void> cancelBooking(String bookingId, {required bool isProvider}) async {
    try {
      DocumentSnapshot snap = await _firestore.collection(_collection).doc(bookingId).get();
      if (!snap.exists) throw Exception('Booking not found');
      
      BookingModel booking = BookingModel.fromMap(snap.data() as Map<String, dynamic>, bookingId);
      
      // 1. Update Status
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Remove Blocked Slot (if confirmed)
      // Even if pending, removing it is safe/no-op usually, but confirmed definitely captures slot.
      // We always attempt to remove to be safe.
      String dateKey = "${booking.bookingDate.year}-${booking.bookingDate.month.toString().padLeft(2,'0')}-${booking.bookingDate.day.toString().padLeft(2,'0')}";
      
      await _firestore.collection('availabilities').doc(booking.providerId).update({
        'manuallyBlockedSlots.$dateKey': FieldValue.arrayRemove([booking.timeSlot])
      });

      debugPrint('[BookingService] Cancelled booking: $bookingId');

      // 3. Notify the OTHER party
      try {
         String targetUserId = isProvider ? booking.touristId : booking.providerId;
         String title = 'Booking Cancelled';
         String body = isProvider 
            ? 'Your booking with ${booking.providerName} has been cancelled by the provider.'
            : 'Booking with ${booking.touristName} has been cancelled by the tourist.';
         
         await NotificationService().sendPushNotification(
            targetUserId: targetUserId,
            title: title,
            body: body,
            data: {
              'type': 'booking',
              'relatedId': bookingId,
            },
         );
      } catch (_) {}

    } catch (e) {
       debugPrint('[BookingService] Cancel failed: $e');
       rethrow;
    }
  }

  String generateId() => _firestore.collection(_collection).doc().id;
  String generateHoldId() => _firestore.collection('booking_holds').doc().id;

  /// Get Available Capacity for a Slot
  Future<int> getAvailableCapacity({
    required String providerId,
    required DateTime date,
    required String timeSlot,
    required int defaultCapacity,
  }) async {
    try {
      int bookedCount = 0;
      int heldCount = 0;

      // 1. Get confirmed/pending bookings
      final bookingsSnap = await _firestore.collection(_collection).where('providerId', isEqualTo: providerId).get();
      for (var doc in bookingsSnap.docs) {
        final b = BookingModel.fromMap(doc.data(), doc.id);
        if (b.status != 'cancelled' && b.status != 'rejected') {
          if (b.bookingDate.year == date.year && b.bookingDate.month == date.month && b.bookingDate.day == date.day) {
             if (b.timeSlot == timeSlot) {
               bookedCount += b.numberOfPeople;
             }
          }
        }
      }

      // 2. Get active holds
      final holdsSnap = await _firestore.collection('booking_holds').where('providerId', isEqualTo: providerId).get();
      final now = DateTime.now();
      for (var doc in holdsSnap.docs) {
        final h = BookingHoldModel.fromMap(doc.data(), doc.id);
        if (h.expiresAt.isAfter(now)) {
           if (h.date.year == date.year && h.date.month == date.month && h.date.day == date.day) {
             if (h.timeSlot == timeSlot) {
               heldCount += h.touristCount;
             }
           }
        } else {
           // Clean up expired hold asynchronously
           _firestore.collection('booking_holds').doc(doc.id).delete().catchError((_) {});
        }
      }

      int remaining = defaultCapacity - bookedCount - heldCount;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('[BookingService] Failed to get capacity: $e');
      return 0; // Safe fallback
    }
  }

  /// Create a temporary hold
  Future<bool> createBookingHold(BookingHoldModel hold, int defaultCapacity) async {
    try {
       // Check capacity before holding
       int capacity = await getAvailableCapacity(
         providerId: hold.providerId,
         date: hold.date,
         timeSlot: hold.timeSlot,
         defaultCapacity: defaultCapacity,
       );

       if (capacity >= hold.touristCount) {
          await _firestore.collection('booking_holds').doc(hold.id).set(hold.toMap());
          return true;
       }
       return false;
    } catch(e) {
      debugPrint('Error creating hold: $e');
      return false;
    }
  }

  /// Convert Hold to Booking Request
  Future<void> createBookingFromHold(BookingModel booking, String holdId) async {
     try {
       WriteBatch batch = _firestore.batch();
       batch.delete(_firestore.collection('booking_holds').doc(holdId));
       batch.set(_firestore.collection(_collection).doc(booking.id), booking.toMap());
       await batch.commit();

       debugPrint('[BookingService] Booking requested from hold: ${booking.id}');
       
       // Notifications
       try {
         await NotificationService().sendPushNotification(
           targetUserId: booking.providerId,
           title: 'New Booking Request',
           body: '${booking.touristName} requested a booking for ${booking.timeSlot}.',
           data: {'type': 'booking', 'relatedId': booking.id},
         );
         await NotificationService().sendNotificationToAdmin(
           title: 'New Booking Activity',
           body: 'A new booking has been created in the system by ${booking.touristName}.',
           data: {'type': 'booking', 'relatedId': booking.id},
         );
         await NotificationService().sendPushNotification(
           targetUserId: booking.touristId,
           title: 'Booking Confirmed',
           body: 'Your booking request has been successfully created.',
           data: {'type': 'booking', 'relatedId': booking.id},
         );
       } catch (_) {}

     } catch(e) {
       debugPrint('[BookingService] Failed to create booking from hold: $e');
       rethrow;
     }
  }
}
