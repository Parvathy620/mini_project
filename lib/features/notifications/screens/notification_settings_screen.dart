import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const AppBackground(child: SizedBox.expand()),
          SafeArea(
            child: Consumer2<AuthService, NotificationService>(
              builder: (context, auth, notif, child) {
                final userId = auth.currentUser?.uid;

                if (userId == null) {
                  return const Center(child: Text("Please login first."));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  children: [
                    _buildSectionHeader('Booking Notifications'),
                    _buildToggleItem(
                      title: 'New Booking Alerts',
                      description: 'Get notified when you receive a new request',
                      value: notif.settings['newBookingAlerts'] ?? true,
                      onChanged: (val) => _updateSetting(context, notif, userId, 'newBookingAlerts', val),
                    ),
                    _buildToggleItem(
                      title: 'Booking Confirmations',
                      description: 'Alert me when my booking is confirmed',
                      value: notif.settings['bookingConfirmations'] ?? true,
                      onChanged: (val) => _updateSetting(context, notif, userId, 'bookingConfirmations', val),
                    ),
                    _buildToggleItem(
                      title: 'Booking Cancellations',
                      description: 'Get notified of sudden cancellations',
                      value: notif.settings['bookingCancellations'] ?? true,
                      onChanged: (val) => _updateSetting(context, notif, userId, 'bookingCancellations', val),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Reminder Notifications'),
                    _buildToggleItem(
                      title: 'Upcoming Booking Reminders',
                      description: 'Alert me 24 hours before my booking',
                      value: notif.settings['upcomingBookingReminders'] ?? true,
                      onChanged: (val) => _updateSetting(context, notif, userId, 'upcomingBookingReminders', val),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Promotional Notifications'),
                    _buildToggleItem(
                      title: 'Offers and Updates',
                      description: 'Travel deals and seasonal promotions',
                      value: notif.settings['promotionalNotifications'] ?? false,
                      onChanged: (val) => _updateSetting(context, notif, userId, 'promotionalNotifications', val),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('System Notifications'),
                    _buildToggleItem(
                      title: 'App Updates',
                      description: 'Critical alerts and feature updates',
                      value: notif.settings['appUpdates'] ?? true,
                      onChanged: (val) => _updateSetting(context, notif, userId, 'appUpdates', val),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: const Color(0xFF69F0AE),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LuxuryGlass(
        opacity: 0.1,
        blur: 10,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.black,
                activeTrackColor: const Color(0xFF69F0AE),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.white12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateSetting(BuildContext context, NotificationService notif, String userId, String key, bool value) async {
    try {
      await notif.updateSettingToggle(userId, key, value);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification preference updated.',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to update. Check your internet connection.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
