import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import 'package:flutter/foundation.dart';

class PdfService {
  Future<void> generateAndDownloadReceipt(BookingModel booking) async {
    final pdf = pw.Document();

    final logoImage = await imageFromAssetBundle('assets/images/travel_app_image.png');
    
    // Load Fonts for Symbols and Emojis
    // NotoSansRegular supports standard text and many symbols like ₹
    // NotoColorEmoji provides fallback for emojis
    final font = await PdfGoogleFonts.notoSansRegular();
    final emoji = await PdfGoogleFonts.notoColorEmoji(); 

    // App Colors
    const PdfColor primaryColor = PdfColor.fromInt(0xFF051F20); // Deep Jungle
    const PdfColor accentColor = PdfColor.fromInt(0xFF69F0AE); // Neon Green
    const PdfColor white = PdfColors.white;
    const PdfColor greyLight = PdfColor.fromInt(0xFFF5F5F5);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Full bleed for header
        theme: pw.ThemeData.withFont(
          base: font,
          fontFallback: [emoji, font],
        ),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // --- Header Section ---
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.only(bottomLeft: pw.Radius.circular(0), bottomRight: pw.Radius.circular(0)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TRAVEL APP', style: pw.TextStyle(color: white, fontSize: 28, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('Booking Confirmation', style: pw.TextStyle(color: accentColor, fontSize: 16, letterSpacing: 1.5)),
                      ],
                    ),
                    if (logoImage != null)
                      pw.Container(
                        height: 70,
                        width: 70,
                        decoration: pw.BoxDecoration(
                          color: white,
                          shape: pw.BoxShape.circle,
                        ),
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.ClipOval(child: pw.Image(logoImage)),
                      ),
                  ],
                ),
              ),

              // --- Body Content ---
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(40),
                  color: white,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Status & ID
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BOOKING ID', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10, letterSpacing: 1)),
                              pw.Text('#${booking.id.toUpperCase().substring(0, 8)}', style: pw.TextStyle(color: primaryColor, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: booking.status == 'approved' ? PdfColors.green50 : PdfColors.orange50,
                              borderRadius: pw.BorderRadius.circular(20),
                              border: pw.Border.all(color: booking.status == 'approved' ? PdfColors.green : PdfColors.orange),
                            ),
                            child: pw.Text(
                              booking.status.toUpperCase(),
                              style: pw.TextStyle(
                                color: booking.status == 'approved' ? PdfColors.green700 : PdfColors.orange700,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 30),
                      pw.Divider(color: PdfColors.grey200),
                      pw.SizedBox(height: 20),

                      // Main Info Grid
                      pw.Text('TRIP DETAILS', style: pw.TextStyle(color: primaryColor, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 15),

                      pw.Container(
                        padding: const pw.EdgeInsets.all(20),
                        decoration: pw.BoxDecoration(
                          color: greyLight,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Column(
                          children: [
                             _buildDetailRow('Service Provider', booking.providerName),
                             pw.SizedBox(height: 10),
                             _buildDetailRow('Service Category', booking.serviceName, isHighlight: true),
                             pw.SizedBox(height: 10),
                             pw.Row(
                               children: [
                                 pw.Expanded(child: _buildInfoBlock('Date', DateFormat('MMM dd, yyyy').format(booking.bookingDate))),
                                 pw.Expanded(child: _buildInfoBlock('Time Slot', booking.timeSlot)),
                               ]
                             ),
                          ],
                        ),
                      ),
                      
                      pw.SizedBox(height: 30),

                      // Tourist Info
                      pw.Text('GUEST INFORMATION', style: pw.TextStyle(color: primaryColor, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        children: [
                           pw.Expanded(child: _buildInfoBlock('Guest Name', booking.touristName)),
                        ]
                      ),

                      pw.Spacer(),

                      // Total Amount Footer
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL PAID', style: pw.TextStyle(color: white, fontSize: 14)),
                            // The Rupee symbol will now render correctly with NotoSans
                            pw.Text(
                              '₹${booking.totalPrice.toStringAsFixed(2)}', 
                              style: pw.TextStyle(color: accentColor, fontSize: 24, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      pw.SizedBox(height: 20),
                      pw.Center(
                         child: pw.Text('Please show this receipt at the venue for entry.', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Color Strip
              pw.Container(height: 10, color: accentColor),
            ],
          );
        },
      ),
    );

    // Save and Open
    try {
      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/receipt_${booking.id}.pdf');
      
      await file.writeAsBytes(bytes);
      
      // Open the file
      await OpenFile.open(file.path);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error saving PDF: $e');
      }
      rethrow;
    }
  }

  pw.Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Using upperCase on the string, not style
        pw.Text(label.toUpperCase(), style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
        pw.Text(
          value, 
          style: pw.TextStyle(
            color: PdfColors.black, 
            fontSize: isHighlight ? 14 : 12, 
            fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal
          )
        ),
      ],
    );
  }

  pw.Widget _buildInfoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(color: PdfColors.black, fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
