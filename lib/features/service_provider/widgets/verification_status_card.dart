import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/verification_model.dart';
import '../../../core/widgets/luxury_glass.dart';

class VerificationStatusCard extends StatelessWidget {
  final ProviderVerification? verification;
  final VoidCallback onReverify;

  const VerificationStatusCard({
    super.key,
    required this.verification,
    required this.onReverify,
  });

  @override
  Widget build(BuildContext context) {
    if (verification == null) return const SizedBox();

    final status = verification!.status;
    final expiryDate = verification!.expiryDate;
    final daysLeft = expiryDate != null ? expiryDate.difference(DateTime.now()).inDays : 999;
    
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.verified;
    String statusText = 'VERIFIED';
    String message = 'Your account is fully verified.';

    if (status == VerificationStatus.expired) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.gpp_bad;
      statusText = 'EXPIRED';
      message = 'Your verification documents have expired. Please submit new documents immediately.';
    } else if (status == VerificationStatus.approved && daysLeft <= 30) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.access_time_filled;
      statusText = 'EXPIRING SOON';
      message = 'Your verification expires in $daysLeft days. Please renew to avoid service interruption.';
    } else if (status == VerificationStatus.rejected) {
      statusColor = Colors.red;
      statusIcon = Icons.block;
      statusText = 'REJECTED';
      message = 'Your verification was rejected: ${verification!.rejectionReason ?? "Please check requirements."}';
    } else if (status == VerificationStatus.pending) {
      statusColor = Colors.amber;
      statusIcon = Icons.hourglass_empty;
      statusText = 'PENDING';
      message = 'Your documents are under review by the administration.';
    }

    return LuxuryGlass(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 10, spreadRadius: -2)
                  ]
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Status',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: statusColor.withOpacity(0.5), blurRadius: 8)
                        ]
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.05),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.white.withOpacity(0.05))
             ),
             child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
          
          if (expiryDate != null && status == VerificationStatus.approved) ...[
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Expiry Date:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8)
                   ),
                   child: Text(DateFormat('d MMM yyyy').format(expiryDate), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                 ),
               ],
             ),
          ],
          if (status == VerificationStatus.expired || (status == VerificationStatus.approved && daysLeft <= 30) || status == VerificationStatus.rejected) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReverify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: statusColor.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status == VerificationStatus.rejected ? 'Re-Submit Documents' : 'Renew Verification',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
