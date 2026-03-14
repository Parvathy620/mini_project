import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/glass_confirmation_dialog.dart';
import '../widgets/change_password_dialog.dart';
import '../../notifications/screens/notification_settings_screen.dart';
import '../screens/report_issue_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('General'),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  icon: Icons.notifications_active,
                  title: 'Notification Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.lock_reset,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                  color: const Color(0xFF69F0AE),
                ),
                const SizedBox(height: 20),
                
                _buildSectionHeader('Support & Legal'),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  onTap: () => _showPrivacyDialog(context),
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About App',
                  onTap: () => _showAboutDialog(context),
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Issue',
                  onTap: () => _showBugReportDialog(context),
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: LuxuryGlass(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: BorderRadius.circular(20),
        opacity: 0.1,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color == Colors.white ? Colors.white : color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color == Colors.white ? Colors.white70 : color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LuxuryGlass(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy & Security', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'We value your privacy. Your data is encrypted and stored securely.\n\n'
                '• All payments are processed securely.\n'
                '• Location data is only used when necessary.\n'
                '• You can request account deletion at any time.',
                style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: const Color(0xFF69F0AE))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LuxuryGlass(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore, size: 48, color: const Color(0xFF69F0AE)),
              const SizedBox(height: 16),
              Text('Tourism App', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Version 1.0.0', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              Text(
                'The ultimate guide to exploring the world. Book tours, find guides, and manage your trips all in one place.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: const Color(0xFF69F0AE))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
    );
  }
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }
}
