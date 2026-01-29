import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/runway_reveal.dart';
import 'unified_login_screen.dart';

class CompletePasswordResetScreen extends StatefulWidget {
  final String oobCode;

  const CompletePasswordResetScreen({super.key, required this.oobCode});

  @override
  State<CompletePasswordResetScreen> createState() => _CompletePasswordResetScreenState();
}

class _CompletePasswordResetScreenState extends State<CompletePasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(context, listen: false).confirmPasswordReset(
          code: widget.oobCode,
          newPassword: _passController.text,
        );

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset successfully! Please login.'),
              backgroundColor: const Color(0xFF69F0AE),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )
          );
          // Navigate back to Login (remove all routes)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
            (route) => false
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RunwayReveal(
                  child: Icon(Icons.lock_reset_rounded, size: 80, color: Color(0xFF69F0AE)),
                ),
                const SizedBox(height: 24),
                RunwayReveal(
                  delayMs: 200,
                  child: Text(
                    'Reset Credentials',
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                RunwayReveal(
                  delayMs: 300,
                  child: Text(
                    'Create a new secure passkey for your account.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                RunwayReveal(
                  delayMs: 500,
                  slideUp: true,
                  child: LuxuryGlass(
                    opacity: 0.1,
                    blur: 20,
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPasswordField(
                            controller: _passController,
                            label: 'New Password',
                            isObscure: _obscurePass,
                            onToggle: () => setState(() => _obscurePass = !_obscurePass),
                            validator: (v) => v!.length < 6 ? 'Min 6 chars required' : null,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _confirmPassController,
                            label: 'Retype Password',
                            isObscure: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            validator: (v) => v != _passController.text ? 'Passwords do not match' : null,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: 32),
                          _isLoading 
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)))
                            : ElevatedButton(
                                onPressed: _handleCompleteReset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF69F0AE),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text('RESET PASSWORD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ),
                        ],
                      ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required List<String> autofillHints,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.4)),
          suffixIcon: IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
