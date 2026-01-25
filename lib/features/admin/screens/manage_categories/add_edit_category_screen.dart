import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/app_background.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final String? categoryId;
  final String? currentName;
  final String? currentDescription;

  const AddEditCategoryScreen({super.key, this.categoryId, this.currentName, this.currentDescription});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentName != null) {
      _nameController.text = widget.currentName!;
    }
    if (widget.currentDescription != null) {
      _descriptionController.text = widget.currentDescription!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final adminService = Provider.of<AdminService>(context, listen: false);
        if (widget.categoryId == null) {
          await adminService.addCategory(_nameController.text.trim(), _descriptionController.text.trim());
        } else {
          await adminService.updateCategory(widget.categoryId!, _nameController.text.trim(), _descriptionController.text.trim());
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.categoryId == null ? 'Add Category' : 'Edit Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(24),
              opacity: 0.15,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Category Name', Icons.category),
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Description', Icons.description),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF203A43),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                widget.categoryId == null ? 'Add Category' : 'Update Category',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
