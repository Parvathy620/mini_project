import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_confirmation_dialog.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer2<AuthService, NotificationService>(
            builder: (context, auth, notif, _) {
              if (notif.unreadCount > 0 && auth.currentUser != null) {
                return IconButton(
                  icon: const Icon(Icons.done_all, color: Color(0xFF69F0AE)),
                  tooltip: 'Mark all as read',
                  onPressed: () {
                    notif.markAllAsRead(auth.currentUser!.uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read', style: TextStyle(color: Colors.white)),
                        backgroundColor: Color(0xFF2E7D32),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const AppBackground(child: SizedBox.expand()),
          SafeArea(
            child: Consumer2<AuthService, NotificationService>(
              builder: (context, auth, notif, child) {
                final userId = auth.currentUser?.uid;
                if (userId == null) {
                  return const Center(child: Text("Please login first.", style: TextStyle(color: Colors.white)));
                }

                return StreamBuilder<List<AppNotification>>(
                  stream: notif.getNotificationsStream(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading notifications.', style: GoogleFonts.inter(color: Colors.white70)));
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white38),
                            const SizedBox(height: 16),
                            Text(
                              "You have no notifications.",
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(context, notification, notif);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification, NotificationService notif) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final isUnread = !notification.isRead;

    IconData iconType;
    Color iconColor;

    switch (notification.type) {
      case 'booking':
        iconType = Icons.book_online;
        iconColor = const Color(0xFF69F0AE);
        break;
      case 'promotional':
        iconType = Icons.local_offer;
        iconColor = Colors.orangeAccent;
        break;
      case 'system':
      default:
        iconType = Icons.info_outline;
        iconColor = Colors.lightBlueAccent;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[800],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
         notif.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread) notif.markAsRead(notification.id);
          // TODO: Implement deep-linking navigation if notification.relatedId exists
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: LuxuryGlass(
            opacity: isUnread ? 0.15 : 0.05,
            blur: isUnread ? 20 : 10,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlight Bar for Unread
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isUnread ? const Color(0xFF69F0AE) : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconType, color: iconColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.body,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                dateFormat.format(notification.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
