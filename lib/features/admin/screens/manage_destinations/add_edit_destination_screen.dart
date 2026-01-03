import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/admin_service.dart';

class AddEditDestinationScreen extends StatefulWidget {
  final String? destinationId;
  final String? currentName;
  final String? currentDescription;

  const AddEditDestinationScreen({
    super.key, 
    this.destinationId, 
    this.currentName,
    this.currentDescription,
  });

  @override
  State<AddEditDestinationScreen> createState() => _AddEditDestinationScreenState();
}

class _AddEditDestinationScreenState extends State<AddEditDestinationScreen> {
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
        
        if (widget.destinationId == null) {
          await adminService.addDestination(_nameController.text.trim(), _descriptionController.text.trim());
        } else {
          await adminService.updateDestination(
            widget.destinationId!, 
            _nameController.text.trim(), 
            _descriptionController.text.trim(),
          );
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
      appBar: AppBar(title: Text(widget.destinationId == null ? 'Add Destination' : 'Edit Destination')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Destination Name'),
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
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(widget.destinationId == null ? 'Add Destination' : 'Update Destination'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
