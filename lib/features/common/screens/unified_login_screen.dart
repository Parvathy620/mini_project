import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/runway_reveal.dart';
import '../../admin/screens/dashboard_screen.dart';
import '../../service_provider/screens/sp_dashboard_screen.dart';
import '../../service_provider/screens/sp_registration_screen.dart';
import '../../tourist/screens/tourist_dashboard_screen.dart';
import '../../tourist/screens/tourist_registration_screen.dart';
import 'password_reset_screen.dart';

enum UserRole { tourist, provider, admin }

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.tourist; // Default

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential? userCredential =
            await Provider.of<AuthService>(context, listen: false).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential != null && userCredential.user != null) {
          final uid = userCredential.user!.uid;
          await _checkRoleAndRedirect(uid);
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';
        if (e.code == 'user-not-found') message = 'User not found.';
        if (e.code == 'wrong-password') message = 'Incorrect password.';
        if (e.code == 'invalid-credential') message = 'Invalid credentials.';
        
        if (mounted) _showGlowSnackBar(message, isError: true);
      } catch (e) {
        if (mounted) _showGlowSnackBar('Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkRoleAndRedirect(String uid) async {
    // 1. Check Admin
    if (_selectedRole == UserRole.admin) {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (adminDoc.exists && (adminDoc.data() as Map<String, dynamic>)['role'] == 'admin') {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
        return;
      }
    }

    // 2. Check Service Provider
    if (_selectedRole == UserRole.provider) {
      DocumentSnapshot spDoc = await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
      if (spDoc.exists) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SPDashboardScreen()),
          );
        }
        return;
      }
    }

    // 3. Check Tourist
    if (_selectedRole == UserRole.tourist) {
      DocumentSnapshot touristDoc = await FirebaseFirestore.instance.collection('tourists').doc(uid).get();
      if (touristDoc.exists) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TouristDashboardScreen()),
          );
        }
        return;
      }
    }

    // Failure
    await Provider.of<AuthService>(context, listen: false).signOut();
    if (mounted) {
       _showGlowSnackBar('Role mismatch. Please login with the correct role.', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Runway-style animated Logo Reveal
                const RunwayReveal(
                  delayMs: 200,
                  child: Icon(Icons.flight_takeoff, size: 64, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(height: 16),
                RunwayReveal(
                  delayMs: 400,
                  child: Text(
                    'NAVIKA',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                RunwayReveal(
                  delayMs: 600,
                  child: Text(
                    'PREMIUM TRAVEL ASSISTANCE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Role Selector with Runway Effect
                RunwayReveal(
                  delayMs: 800,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRoleItem('Tourist', UserRole.tourist),
                        _buildRoleItem('Partner', UserRole.provider),
                        _buildRoleItem('Admin', UserRole.admin),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Main Glass Card Form
                RunwayReveal(
                  delayMs: 1000,
                  slideUp: true,
                  child: LuxuryGlass(
                    opacity: 0.08,
                    blur: 25,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _getWelcomeTitle(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 25),
                          _buildGlowInput(
                            controller: _emailController,
                            label: 'Access ID / Email',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          _buildGlowInput(
                            controller: _passwordController,
                            label: 'Passkey',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => const PasswordResetScreen())
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          _isLoading
                           ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                           : GestureDetector(
                             onTap: _login,
                             child: Container(
                               height: 55,
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(16),
                                 gradient: const LinearGradient(
                                   colors: [Color(0xFF38BDF8), Color(0xFF6366F1)], // Sky to Indigo
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
                                   'INITIATE SESSION',
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

                // Register Link (Morphing)
                if (_selectedRole != UserRole.admin) ...[
                  const SizedBox(height: 30),
                  RunwayReveal(
                    delayMs: 1200,
                    child: TextButton(
                      onPressed: () {
                         if (_selectedRole == UserRole.tourist) {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const TouristRegistrationScreen()));
                         } else {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const SPRegistrationScreen()));
                         }
                      },
                      child: RichText(
                        text: TextSpan(
                          text: _selectedRole == UserRole.tourist ? 'New Explorer? ' : 'New Partner? ',
                          style: GoogleFonts.inter(color: Colors.white54),
                          children: [
                            TextSpan(
                              text: 'Create Identity',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleItem(String label, UserRole role) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10)]
              : [],
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 1.5,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  String _getWelcomeTitle() {
    switch (_selectedRole) {
      case UserRole.admin: return 'Command Center';
      case UserRole.provider: return 'Partner Hub';
      case UserRole.tourist: return 'Explorer Login';
    }
  }
}
