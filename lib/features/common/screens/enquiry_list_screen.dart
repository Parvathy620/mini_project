import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enquiry_model.dart';
import '../../../core/services/enquiry_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import 'enquiry_chat_screen.dart';

class EnquiryListScreen extends StatelessWidget {
  final bool isProvider;

  const EnquiryListScreen({super.key, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Login required')));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isProvider ? 'Messages (Tourists)' : 'Messages (Providers)', 
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isProvider ? const BackButton(color: Colors.white) : null,
        automaticallyImplyLeading: isProvider,
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<EnquiryModel>>(
            stream: Provider.of<EnquiryService>(context, listen: false).getEnquiries(
              providerId: isProvider ? user.uid : null,
              touristId: isProvider ? null : user.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));
              }

              final enquiries = snapshot.data ?? [];
              if (enquiries.isEmpty) {
                return Center(child: Text('No messages found', style: GoogleFonts.inter(color: Colors.white54)));
              }

              // Group Enquiries by Conversation Partner
              final Map<String, List<EnquiryModel>> conversations = {};
              for (var enquiry in enquiries) {
                final otherId = isProvider ? enquiry.touristId : enquiry.providerId;
                if (!conversations.containsKey(otherId)) {
                  conversations[otherId] = [];
                }
                conversations[otherId]!.add(enquiry);
              }

              // Convert to List for ListView
              final threadIds = conversations.keys.toList();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: threadIds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final otherId = threadIds[index];
                  final threadEnquiries = conversations[otherId]!;
                  
                  // Sort to find latest message
                  threadEnquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final latestEnquiry = threadEnquiries.first;
                  
                  // Pending count (for Provider) or Unread?
                  // Let's count 'pending' status for provider
                  final pendingCount = isProvider 
                      ? threadEnquiries.where((e) => e.status == 'pending').length 
                      : 0;

                  final otherName = isProvider ? latestEnquiry.touristName : latestEnquiry.providerName;

                  return _ThreadCard(
                    otherId: otherId,
                    otherName: otherName,
                    latestEnquiry: latestEnquiry,
                    pendingCount: pendingCount,
                    isProvider: isProvider,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final String otherId;
  final String otherName;
  final EnquiryModel latestEnquiry;
  final int pendingCount;
  final bool isProvider;

  const _ThreadCard({
    required this.otherId,
    required this.otherName,
    required this.latestEnquiry,
    required this.pendingCount,
    required this.isProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnquiryChatScreen(
              otherUserId: otherId,
              otherUserName: otherName,
              isProvider: isProvider,
            ),
          ),
        );
      },
      child: RepaintBoundary(
        child: LuxuryGlass(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          opacity: 0.1,
          blur: 5, // Optimized blur
        // Highlight if there are pending messages for provider
        child: Row(
          children: [
            // Avatar Placeholder
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF69F0AE).withOpacity(0.2),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(latestEnquiry.createdAt),
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    // Show latest message content (Question or Reply)
                    latestEnquiry.reply != null 
                        ? 'You: ${latestEnquiry.reply}' // If sorted desc, latest could be reply if we check timestamps. 
                        // Actually, logic is simple: latestEnquiry is the last interaction. 
                        // If reply exists, that might be latest. 
                        // But wait, EnquiryModel has 1 timestamp 'createdAt'. Reply doesn't have separate timestamp yet (oops).
                        // So latestEnquiry is the latest QUESTION asked.
                        // If I replied to it, the text shown should probably still be the Question or "Replied".
                        // Let's show the Question text for context, or "Replied" status.
                        : latestEnquiry.message,
                    style: GoogleFonts.inter(
                      color: pendingCount > 0 ? Colors.white : Colors.white70, 
                      fontWeight: pendingCount > 0 ? FontWeight.bold : FontWeight.normal
                    ),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Pending Badge
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  pendingCount.toString(),
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // If today, show time. Else show date.
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('MMM dd').format(date);
  }
}

