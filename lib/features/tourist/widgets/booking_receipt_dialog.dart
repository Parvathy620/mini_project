import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/widgets/luxury_glass.dart';

class BookingReceiptDialog extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onClose;

  const BookingReceiptDialog({
    super.key,
    required this.booking,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
                    
                    // Title
                    Text(
                      'Booking Confirmed!',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here is your booking receipt',
                      style: GoogleFonts.inter(color: Colors.white60),
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
                          _buildRow('Booking ID', '#${booking.id.substring(0, 8)}'),
                          const Divider(color: Colors.white10),
                          _buildRow('Provider', booking.providerName),
                          const Divider(color: Colors.white10),
                          _buildRow('Service', booking.serviceName),
                          const Divider(color: Colors.white10),
                          _buildRow('Date', DateFormat('MMM dd, yyyy').format(booking.bookingDate)),
                          const Divider(color: Colors.white10),
                          _buildRow('Time', booking.timeSlot),
                          const Divider(color: Colors.white10),
                          _buildRow('Total Price', '\₹${booking.totalPrice.toStringAsFixed(2)}', isBold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
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
                            child: Text(
                              'Close',
                              style: GoogleFonts.outfit(color: Colors.white),
                            ),
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
                                await PdfService().generateAndDownloadReceipt(booking);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
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
                            child: Text(
                              'Download',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                color: isBold ? const Color(0xFF69F0AE) : Colors.white,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
