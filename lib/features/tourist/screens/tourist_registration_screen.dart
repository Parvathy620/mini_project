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
  final _retypePasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _passwordsMatch = true;
  bool _isPasswordVisible = false;
  bool _isRetypePasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswords);
    _retypePasswordController.addListener(_validatePasswords);
  }

  void _validatePasswords() {
    setState(() {
      _passwordsMatch = _passwordController.text == _retypePasswordController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_passwordsMatch) {
        _showGlowSnackBar("Passwords do not match.", isError: true);
        return;
      }

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
           String message = "Registration failed.";
           if (e.toString().contains("email-already-in-use")) {
             message = "Account already exists. Please login.";
           } else if (e.toString().contains("weak-password")) {
             message = "Password is too weak.";
           }
           _showGlowSnackBar(message, isError: true);
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

  Widget _buildGlowInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscured = true,
    VoidCallback? onVisibilityToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool showErrorBorder = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showErrorBorder 
              ? Colors.redAccent.withOpacity(0.5) 
              : Colors.white.withOpacity(0.1),
        ),
        boxShadow: showErrorBorder
            ? [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10)]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: isPassword ? isObscured : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
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
    bool canSubmit = _passwordController.text.isNotEmpty && 
                     _retypePasswordController.text.isNotEmpty && 
                     _passwordsMatch;

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
                          const Icon(Icons.person_add_outlined, size: 40, color: const Color(0xFF50C878)),
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
                            isObscured: !_isPasswordVisible,
                            onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required field';
                              if (value.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildGlowInput(
                            controller: _retypePasswordController,
                            label: 'Retype Passkey',
                            icon: Icons.fingerprint,
                            isPassword: true,
                            isObscured: !_isRetypePasswordVisible,
                            onVisibilityToggle: () => setState(() => _isRetypePasswordVisible = !_isRetypePasswordVisible),
                            showErrorBorder: !_passwordsMatch && _retypePasswordController.text.isNotEmpty,
                            validator: (value) {
                              if (value != _passwordController.text) return 'Passkeys do not match';
                              return null;
                            },
                          ),
                          // Subtle match indicator
                           if (_retypePasswordController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    _passwordsMatch ? Icons.check_circle_outline : Icons.error_outline,
                                    size: 14,
                                    color: _passwordsMatch ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _passwordsMatch ? 'Passkeys match' : 'Passkeys must match',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _passwordsMatch ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 30),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE)))
                              : GestureDetector(
                                  onTap: canSubmit ? _register : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: canSubmit 
                                          ? [const Color(0xFF50C878), const Color(0xFF66BB6A)]
                                          : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.2)],
                                      ),
                                      boxShadow: canSubmit 
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF50C878).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          )
                                        ]
                                      : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'CONFIRM IDENTITY',
                                        style: GoogleFonts.inter(
                                          color: canSubmit ? Colors.white : Colors.white38,
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
                              color: const Color(0xFF50C878),
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
