import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/widgets/luxury_glass.dart';

class BookingReceiptDialog extends StatelessWidget {
  final List<BookingModel> bookings;
  final VoidCallback onClose;

  const BookingReceiptDialog({
    super.key,
    required this.bookings,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final booking = bookings.first;
    final double totalPrice = bookings.fold<double>(0, (sum, b) => sum + b.totalPrice);
    final List<DateTime> allDates = bookings.expand((b) => b.dates).toList()..sort();

    String dateRangeText;
    if (allDates.isEmpty) {
      dateRangeText = 'N/A';
    } else if (allDates.length == 1) {
      dateRangeText = DateFormat('MMM dd, yyyy').format(allDates.first);
    } else {
      dateRangeText = '${DateFormat('MMM dd').format(allDates.first)} → ${DateFormat('MMM dd, yyyy').format(allDates.last)}';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LuxuryGlass(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 40),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Booking Confirmed!',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Payment successful. Here is your receipt.',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Receipt Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          _buildRow('Booking ID', '#${booking.id.substring(0, 8).toUpperCase()}'),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Provider', booking.providerName),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Service', booking.serviceName),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Dates', dateRangeText),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Total Days', '${allDates.length} Day${allDates.length > 1 ? 's' : ''}'),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Tourists', '${booking.numberOfPeople}'),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Price / Person / Day', '₹${booking.pricePerPerson.toStringAsFixed(0)}'),
                          const Divider(color: Colors.white10, height: 16),
                          _buildRow('Total Paid', '₹${totalPrice.toStringAsFixed(0)}', isBold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: onClose,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                            child: Text('Close', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generating Receipt...')),
                                );
                                await PdfService().generateAndDownloadReceipt(bookings);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF69F0AE),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text('Download', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              color: isBold ? const Color(0xFF69F0AE) : Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
