import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/runway_reveal.dart';
import 'tourist_dashboard_screen.dart';

class TouristRegistrationScreen extends StatefulWidget {
  const TouristRegistrationScreen({super.key});

  @override
  State<TouristRegistrationScreen> createState() => _TouristRegistrationScreenState();
}

class _TouristRegistrationScreenState extends State<TouristRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await Provider.of<AuthService>(context, listen: false).signUpTourist(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TouristDashboardScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
           _showGlowSnackBar('Registration Failed: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showGlowSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: isError ? Colors.redAccent : Colors.cyanAccent),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? Colors.redAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.3), 
          ),
        ),
      ),
    );
  }

  Widget _buildGlowInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'NEW IDENTITY',
          style: GoogleFonts.outfit(
             fontWeight: FontWeight.bold, 
             color: Colors.white,
             letterSpacing: 2.0,
             fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                RunwayReveal(
                  delayMs: 200,
                  slideUp: true,
                  child: LuxuryGlass(
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(32),
                    opacity: 0.1,
                    blur: 20,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.person_add_outlined, size: 40, color: Color(0xFF38BDF8)),
                          const SizedBox(height: 16),
                          Text(
                            'Tourist Access',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                           Text(
                            'Initialize your personal travel profile.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildGlowInput(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.badge_outlined,
                            validator: (v) => v!.isEmpty ? 'Required field' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildGlowInput(
                            controller: _emailController,
                            label: 'Access Email',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required field';
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) return 'Invalid format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildGlowInput(
                            controller: _passwordController,
                            label: 'Secure Passkey',
                            icon: Icons.fingerprint,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required field';
                              if (value.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                              : GestureDetector(
                                  onTap: _register,
                                  child: Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'CONFIRM IDENTITY',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          fontSize: 14,
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
                const SizedBox(height: 20),
                RunwayReveal(
                  delayMs: 400,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Already authenticated? ',
                        style: GoogleFonts.inter(color: Colors.white54),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF38BDF8),
                              fontWeight: FontWeight.w600,
                            ),
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
}
