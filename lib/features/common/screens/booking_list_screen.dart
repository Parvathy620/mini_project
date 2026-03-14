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
          title: Text(isProvider ? 'My Bookings' : 'My Trips',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: isProvider ? const BackButton(color: Colors.white) : null,
          automaticallyImplyLeading: isProvider,
          bottom: const TabBar(
            indicatorColor: Color(0xFF69F0AE),
            labelColor: Color(0xFF69F0AE),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: AppBackground(
          child: SafeArea(
            child: TabBarView(
              children: [
                _BookingList(userId: user.uid, isProvider: isProvider, statusFilter: 'confirmed'),
                _BookingList(userId: user.uid, isProvider: isProvider, statusFilter: 'completed'),
                _BookingList(userId: user.uid, isProvider: isProvider, statusFilter: 'cancelled'),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)));
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('No $statusFilter bookings', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingCard(booking: booking, isProvider: isProvider);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;

  const _BookingCard({required this.booking, required this.isProvider});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.greenAccent;
      case 'cancelled': return Colors.redAccent;
      case 'completed': return const Color(0xFF66BB6A);
      default: return Colors.grey;
    }
  }

  String _formatDateRange(List<DateTime> dates) {
    if (dates.isEmpty) return 'N/A';
    if (dates.length == 1) return DateFormat('MMM dd, yyyy').format(dates.first);
    return '${DateFormat('MMM dd').format(dates.first)} → ${DateFormat('MMM dd, yyyy').format(dates.last)}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = booking.id.substring(0, 8).toUpperCase();
    return LuxuryGlass(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.1,
      blur: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProvider ? booking.touristName : booking.providerName,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('#BK$bookingId', style: GoogleFonts.ibmPlexMono(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusColor(booking.status)),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: GoogleFonts.inter(color: _statusColor(booking.status), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info rows
          _infoRow(Icons.calendar_today, _formatDateRange(booking.dates)),
          const SizedBox(height: 6),
          _infoRow(Icons.view_day_outlined, '${booking.dates.length} Day${booking.dates.length > 1 ? 's' : ''}'),
          const SizedBox(height: 6),
          _infoRow(Icons.people_outline, '${booking.numberOfPeople} Tourist${booking.numberOfPeople > 1 ? 's' : ''}'),
          const SizedBox(height: 6),
          _infoRow(Icons.payments_outlined, '₹${booking.totalPrice.toStringAsFixed(0)} Total'),

          // Action buttons
          if (_shouldShowActions(booking)) ...[
            const Divider(color: Colors.white10, height: 24),
            _buildActions(context, booking),
          ],
        ],
      ),
    );
  }

  bool _shouldShowActions(BookingModel booking) {
    if (isProvider && booking.status == 'confirmed') return true;
    if (!isProvider && booking.status == 'confirmed') return true;
    return false;
  }

  Widget _buildActions(BuildContext context, BookingModel booking) {
    if (isProvider) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel
          TextButton(
            onPressed: () => _confirmAction(context, booking.id, 'cancel'),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          // Mark Completed
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF69F0AE),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => _updateStatus(context, booking.id, 'completed'),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text('Mark Completed', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      );
    } else {
      // Tourist cancel
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () => _confirmAction(context, booking.id, 'cancel'),
          icon: const Icon(Icons.cancel_outlined, size: 16),
          label: Text('Cancel Booking', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        ),
      ],
    );
  }

  void _updateStatus(BuildContext context, String bookingId, String status) {
    Provider.of<BookingService>(context, listen: false).updateStatus(bookingId, status);
  }

  void _confirmAction(BuildContext context, String bookingId, String action) {
    showDialog(
      context: context,
      builder: (context) => GlassConfirmationDialog(
        title: 'Cancel Booking?',
        content: 'Are you sure you want to cancel this booking? This action cannot be undone.',
        confirmText: 'Yes, Cancel',
        confirmColor: Colors.redAccent,
        onConfirm: () async {
          Navigator.pop(context);
          await Provider.of<BookingService>(context, listen: false)
              .cancelBooking(bookingId, isProvider: isProvider);
        },
      ),
    );
  }
}
