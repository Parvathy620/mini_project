import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import 'package:intl/intl.dart';

class NotificationListScreen extends StatelessWidget {
  final String? userId; // Optional override for Admin
  const NotificationListScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final targetUid = userId ?? currentUser?.uid;

    final notificationService = Provider.of<NotificationService>(context, listen: false);

    if (targetUid == null) return const SizedBox();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: StreamBuilder<List<AppNotification>>(
          stream: notificationService.getNotifications(targetUid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error loading notifications', style: GoogleFonts.inter(color: Colors.redAccent)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!;
            // Logic: IsRead = true -> Earlier. IsRead = false -> New.
            final newNotifications = notifications.where((n) => !n.isRead).toList();
            final earlierNotifications = notifications.where((n) => n.isRead).toList();

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No notifications yet', style: GoogleFonts.inter(color: Colors.white54)),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 40),
              children: [
                if (newNotifications.isNotEmpty) ...[
                  Text('New', style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ...newNotifications.map((n) => _buildNotificationItem(context, n, notificationService)),
                  const SizedBox(height: 24),
                ],
                
                if (earlierNotifications.isNotEmpty) ...[
                  Text('Earlier', style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ...earlierNotifications.map((n) => _buildNotificationItem(context, n, notificationService)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notification, NotificationService service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(notification.id),
        onDismissed: (_) {
           // Implement delete if supported
        },
        child: GestureDetector(
          onTap: () async {
            if (!notification.isRead) {
              await service.markAsRead(notification.id);
            }
          },
          child: LuxuryGlass(
            opacity: notification.isRead ? 0.05 : 0.15,
            blur: 20,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            border: notification.isRead ? null : Border.all(color: const Color(0xFF69F0AE).withOpacity(0.3)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getIconColor(notification.type).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(notification.type), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: const Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'verification': return Colors.orangeAccent;
      case 'booking': return Colors.greenAccent;
      case 'enquiry': return Colors.purpleAccent;
      default: return const Color(0xFF66BB6A);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'verification': return Icons.verified_user;
      case 'booking': return Icons.calendar_month;
      case 'enquiry': return Icons.chat;
      default: return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
