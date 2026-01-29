import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_confirmation_dialog.dart';

class BookingListScreen extends StatelessWidget {
  final bool isProvider;

  const BookingListScreen({super.key, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Login required')));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(isProvider ? 'My Bookings' : 'My Trips', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: isProvider ? const BackButton(color: Colors.white) : null,
          automaticallyImplyLeading: isProvider,
          bottom: const TabBar(
            indicatorColor: const Color(0xFF69F0AE),
            labelColor: const Color(0xFF69F0AE),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Pending'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: AppBackground(
          child: SafeArea(
            child: TabBarView(
              children: [
                _BookingList(userId: user.uid, isProvider: isProvider, statusFilter: 'confirmed'),
                _BookingList(userId: user.uid, isProvider: isProvider, statusFilter: 'pending'),
                _BookingList(userId: user.uid, isProvider: isProvider, statusFilter: 'completed'), // Or history logic
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String userId;
  final bool isProvider;
  final String statusFilter;

  const _BookingList({
    required this.userId,
    required this.isProvider,
    required this.statusFilter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: Provider.of<BookingService>(context, listen: false).getBookings(
        providerId: isProvider ? userId : null,
        touristId: isProvider ? null : userId,
        status: statusFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(child: Text('No ${statusFilter} bookings', style: GoogleFonts.inter(color: Colors.white54)));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return RepaintBoundary(
              child: LuxuryGlass(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(20),
                opacity: 0.1,
                blur: 5, // Optimized blur
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isProvider ? booking.touristName : booking.providerName,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(booking.status)),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: GoogleFonts.inter(color: _getStatusColor(booking.status), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        booking.timeSlot,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Actions for Provider
                  if (isProvider) ...[
                    // Pending Actions
                    if (booking.status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _confirmAction(context, booking.id, false, isProvider), // Reject
                            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _updateStatus(context, booking.id, 'confirmed'),
                            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    
                    // Confirmed: Option to Cancel
                     if (booking.status == 'confirmed')
                       Align(
                         alignment: Alignment.centerRight,
                         child: GestureDetector(
                           onTap: () => _confirmAction(context, booking.id, true, isProvider), // Cancel
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.redAccent.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                                 const SizedBox(width: 8),
                                 Text(
                                   'Cancel Booking', 
                                   style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ),
                  ],

                  // Actions for Tourist
                   if (!isProvider && (booking.status == 'pending' || booking.status == 'confirmed'))
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _confirmAction(context, booking.id, true, isProvider), // Cancel
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            'Cancel Booking', 
                            style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.greenAccent;
      case 'pending': return Colors.orangeAccent;
      case 'cancelled': return Colors.redAccent;
      case 'completed': return const Color(0xFF66BB6A);
      default: return Colors.grey;
    }
  }

  void _updateStatus(BuildContext context, String bookingId, String status) {
    Provider.of<BookingService>(context, listen: false).updateStatus(bookingId, status);
  }

  void _confirmAction(BuildContext context, String bookingId, bool isCancellation, bool isProvider) {
    showDialog(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: isCancellation ? 'Cancel Booking?' : 'Reject Request?',
        content: isCancellation 
          ? 'Are you sure you want to cancel this booking? This action cannot be undone.'
          : 'Are you sure you want to reject this booking request?',
        confirmText: isCancellation ? 'Yes, Cancel' : 'Reject',
        confirmColor: Colors.redAccent,
        onConfirm: () async {
          Navigator.pop(context);
          // If cancelling (confirmed or pending cancellation), use cancelBooking for full slot cleanup
          // If just rejecting pending, cancelBooking also works as it sets status 'cancelled' and removes slot (even if not added yet logic handles it)
          await Provider.of<BookingService>(context, listen: false).cancelBooking(bookingId, isProvider: isProvider);
        },
      ),
    );
  }
} // End of _BookingList class
