import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/admin_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryId == null ? 'Add Category' : 'Edit Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),
               TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      child: Text(widget.categoryId == null ? 'Add' : 'Update'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
