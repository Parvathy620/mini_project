import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/runway_reveal.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(context, listen: false)
            .sendPasswordResetEmail(_emailController.text.trim());
        
        setState(() => _isEmailSent = true);
        if (mounted) _showGlowSnackBar('Link sent! Check your email to reset your password inside the app.', isError: false);
        
        // Delay to let user read, then pop
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.pop(context);

      } catch (e) {
        if (mounted) _showGlowSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showGlowSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: isError ? Colors.redAccent : const Color(0xFF69F0AE)),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF69F0AE).withOpacity(0.3), 
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RunwayReveal(
                   child: Icon(Icons.lock_reset_rounded, size: 80, color: const Color(0xFF69F0AE)),
                ),
                const SizedBox(height: 24),
                RunwayReveal(
                  delayMs: 200,
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RunwayReveal(
                  delayMs: 400,
                  child: Text(
                    'Enter your registered email address.\nWe will send you a secure link to reset your password instantly inside the app.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                RunwayReveal(
                  delayMs: 600,
                  slideUp: true,
                  child: LuxuryGlass(
                    opacity: 0.1,
                    blur: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Email is required';
                                  if (!val.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.4), size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            _isLoading
                             ? const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)))
                             : ElevatedButton(
                               onPressed: _handleReset,
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF69F0AE),
                                 foregroundColor: Colors.black,
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                 elevation: 0,
                               ),
                               child: Text(
                                 'Send Reset Link', 
                                 style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                               ),
                             ),
                          ],
                        ),
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
}
