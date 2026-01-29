import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enquiry_model.dart';
import '../../../core/services/enquiry_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';

class EnquiryChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isProvider;

  const EnquiryChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.isProvider,
  });

  @override
  State<EnquiryChatScreen> createState() => _EnquiryChatScreenState();
}

class _EnquiryChatScreenState extends State<EnquiryChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<EnquiryModel>>(
                stream: Provider.of<EnquiryService>(context, listen: false).getEnquiries(
                  providerId: widget.isProvider ? user.uid : widget.otherUserId,
                  touristId: widget.isProvider ? widget.otherUserId : user.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)));
                  }

                  final enquiries = snapshot.data ?? [];
                  // Sort by creation time (Recent last for chat feel)
                  enquiries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                  if (enquiries.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.\nStart a conversation!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    );
                  }

                  // Auto-scroll to bottom
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 20), // Top padding for AppBar
                    physics: const BouncingScrollPhysics(),
                    itemCount: enquiries.length,
                    itemBuilder: (context, index) {
                      return _buildChatBubble(enquiries[index], user.uid);
                    },
                  );
                },
              ),
            ),
            
            // Input Area (Only for Tourists to ask NEW questions)
            // Providers reply to specific bubbles, handled inside _buildChatBubble
            if (!widget.isProvider)
              _buildMessageInput(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(EnquiryModel enquiry, String currentUserId) {
    // If I am the provider, then 'my message' is the reply I sent (technically displayed in same bubble or separate? Model structure dependent)
    // Actually, Model has 'message' (from tourist) and 'reply' (from provider).
    // So 'isMyMessage' is tricky. 
    // Let's assume this bubble displays the INITIAL enquiry.
    // If I am the Tourist, I sent this enquiry -> isMyMessage = true.
    // If I am the Provider, I received this enquiry -> isMyMessage = false.
    bool isMyMessage = enquiry.touristId == currentUserId;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. The Question (Enquiry)
        Align(
          alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: LuxuryGlass(
            margin: const EdgeInsets.only(bottom: 8, left: 40, right: 0),
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMyMessage ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: isMyMessage ? const Radius.circular(0) : const Radius.circular(16),
            ),
            opacity: isMyMessage ? 0.2 : 0.1,
            color: isMyMessage ? const Color(0xFF69F0AE).withOpacity(0.15) : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isMyMessage ? const Color(0xFF69F0AE).withOpacity(0.3) : Colors.white.withOpacity(0.1),
              width: 1
            ),
            blur: 10,
            hasReflection: isMyMessage, // Only detailed reflection for my messages to emphasize them
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry.message,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(enquiry.createdAt),
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                ),
                if (enquiry.requestedDate != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 4),
                     child: Text(
                       'Requested: ${DateFormat('MMM dd').format(enquiry.requestedDate!)}',
                       style: GoogleFonts.inter(color: Colors.yellowAccent, fontSize: 11, fontStyle: FontStyle.italic),
                     ),
                   ),
              ],
            ),
          ),
        ),

        // 2. The Reply (if exists) or Reply Button (if Provider)
        if (enquiry.reply != null)
          Align(
            alignment: isMyMessage ? Alignment.centerLeft : Alignment.centerRight,
            child: LuxuryGlass(
              margin: const EdgeInsets.only(bottom: 16, right: 40, left: 0),
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMyMessage ? const Radius.circular(0) : const Radius.circular(16),
                  bottomRight: isMyMessage ? const Radius.circular(16) : const Radius.circular(0),
              ),
              opacity: 0.15,
              color: Colors.greenAccent.withOpacity(0.1),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              blur: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enquiry.reply!,
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 10, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Replied',
                        style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else if (widget.isProvider)
          // Provider needs to reply
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () => _showReplyDialog(enquiry),
                icon: const Icon(Icons.reply, size: 16, color: const Color(0xFF69F0AE)),
                label: const Text('Reply', style: TextStyle(color: const Color(0xFF69F0AE))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: const Color(0xFF69F0AE).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageInput(String currentUserId) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(30),
      opacity: 0.2,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, color: const Color(0xFF69F0AE)),
            onPressed: () => _sendEnquiry(currentUserId),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEnquiry(String currentUserId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<EnquiryService>(context, listen: false);
      final id = service.generateId();
      
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      final senderName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Tourist';

      final enquiry = EnquiryModel(
        id: id,
        touristId: currentUserId,
        providerId: widget.otherUserId,
        touristName: senderName,
        providerName: widget.otherUserName,
        message: text,
        createdAt: DateTime.now(),
        status: 'pending',
      );
      
      await service.sendEnquiry(enquiry);
      _messageController.clear();
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReplyDialog(EnquiryModel enquiry) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LuxuryGlass(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reply to Message', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(enquiry.message, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: replyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Your reply...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (replyController.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        await Provider.of<EnquiryService>(context, listen: false)
                            .replyToEnquiry(enquiry.id, replyController.text.trim());
                      }
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
