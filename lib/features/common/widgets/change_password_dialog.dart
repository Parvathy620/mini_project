import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/luxury_glass.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController(); // Retype field
  
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(context, listen: false).changePassword(
          currentPassword: _currentPassController.text,
          newPassword: _newPassController.text,
        );
        
        TextInput.finishAutofillContext(); // Signal OS to update password
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password updated successfully!', style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: const Color(0xFF69F0AE),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.inter(color: Colors.white)),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: LuxuryGlass(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(24),
        opacity: 0.15,
        child: SingleChildScrollView( // Keyboard safe
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutofillGroup(
                  child: Column(
                    children: [
                      Row(
                        children: [
                           Container(
                             padding: const EdgeInsets.all(10),
                             decoration: BoxDecoration(color: const Color(0xFF69F0AE).withOpacity(0.2), shape: BoxShape.circle),
                             child: const Icon(Icons.lock_reset, color: Color(0xFF69F0AE)),
                           ),
                           const SizedBox(width: 16),
                           Expanded(child: Text('Change Password', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Hidden Username Field for Password Manager
                      Visibility(
                        visible: false,
                        maintainState: true,
                        child: TextFormField(
                          initialValue: Provider.of<AuthService>(context, listen: false).currentUser?.email,
                          readOnly: true,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                        ),
                      ),
                
                      // Current Password
                      _buildPasswordField(
                        controller: _currentPassController,
                        label: 'Current Password',
                        isObscure: _obscureCurrent,
                        onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        autofillHints: const [AutofillHints.password],
                      ),
                      const SizedBox(height: 16),
                
                      // New Password
                      _buildPasswordField(
                        controller: _newPassController,
                        label: 'New Password',
                        isObscure: _obscureNew,
                        onToggle: () => setState(() => _obscureNew = !_obscureNew),
                        validator: (val) {
                          if (val == null || val.length < 6) return 'Must be at least 6 characters';
                          return null;
                        },
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      const SizedBox(height: 16),
                
                      // Confirm Password (Retype)
                      _buildPasswordField(
                        controller: _confirmPassController,
                        label: 'Retype New Password',
                        isObscure: _obscureConfirm,
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (val) {
                          if (val != _newPassController.text) return 'Passwords do not match';
                          return null;
                        },
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                  ],
                ),
                ),
                const SizedBox(height: 32),
          
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 8),
                    _isLoading 
                      ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF69F0AE))))
                      : ElevatedButton(
                          onPressed: _handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF69F0AE),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Update'),
                        ),
                  ],
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
    required    VoidCallback onToggle,
    String? Function(String?)? validator,
    List<String>? autofillHints,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        autofillHints: autofillHints,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 18),
          suffixIcon: IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
