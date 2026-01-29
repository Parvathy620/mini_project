import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
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
        await NotificationService().sendNotification(
          userId: booking.providerId,
          title: 'New Booking Request',
          body: '${booking.touristName} requested a booking for ${booking.timeSlot}.',
          type: 'booking',
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
           String title = newStatus == 'confirmed' ? 'Booking Confirmed' : 'Booking Cancelled';
           String body = newStatus == 'confirmed' 
               ? 'Your booking with ${booking.providerName} is confirmed!'
               : 'Booking with ${booking.providerName} was cancelled.';
           
           // If update initiated by provider (usually), notify tourist
           // If by tourist (cancel), notify provider. 
           // For simplicity, we notify both or just the 'other' party.
           // Ideally need to know who initiated. 
           // Let's notify Tourist if Confirmed.
           // Notify Provider if Cancelled by Tourist? Hard to know context here.
           // Lets just notify Tourist for now as they are the ones waiting.
           
           await NotificationService().sendNotification(
              userId: booking.touristId,
              title: title,
              body: body,
              type: 'booking',
           );
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
         
         await NotificationService().sendNotification(
            userId: targetUserId,
            title: title,
            body: body,
            type: 'booking',
         );
      } catch (_) {}

    } catch (e) {
       debugPrint('[BookingService] Cancel failed: $e');
       rethrow;
    }
  }

  String generateId() => _firestore.collection(_collection).doc().id;
}
