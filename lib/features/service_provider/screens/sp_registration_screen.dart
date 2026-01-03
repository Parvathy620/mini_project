import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/destination_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/data_service.dart';
import 'sp_dashboard_screen.dart'; // We will create this next

class SPRegistrationScreen extends StatefulWidget {
  const SPRegistrationScreen({super.key});

  @override
  State<SPRegistrationScreen> createState() => _SPRegistrationScreenState();
}

class _SPRegistrationScreenState extends State<SPRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedDestinationId;
  String? _selectedCategoryId;
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
      setState(() {
        _isLoading = true;
      });

      try {
        await Provider.of<AuthService>(context, listen: false).signUpServiceProvider(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          destinationId: _selectedDestinationId!,
          categoryId: _selectedCategoryId!,
        );

        if (mounted) {
          // Success, navigate to dashboard (or pending approval screen)
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SPDashboardScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration Failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                  validator: (v) => v!.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 10),
                
                // Destination Dropdown
                StreamBuilder<List<DestinationModel>>(
                  stream: dataService.getDestinations(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData) return const CircularProgressIndicator();
                     final destinations = snapshot.data!;
                     return DropdownButtonFormField<String>(
                       decoration: const InputDecoration(labelText: 'Select Destination'),
                       value: _selectedDestinationId,
                       items: destinations.map((d) => DropdownMenuItem(
                         value: d.id, 
                         child: Text(d.name)
                       )).toList(),
                       onChanged: (val) => setState(() => _selectedDestinationId = val),
                       validator: (v) => v == null ? 'Select destination' : null,
                     );
                  },
                ),
                const SizedBox(height: 10),

                // Category Dropdown
                StreamBuilder<List<CategoryModel>>(
                  stream: dataService.getCategories(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData) return const CircularProgressIndicator();
                     final categories = snapshot.data!;
                     return DropdownButtonFormField<String>(
                       decoration: const InputDecoration(labelText: 'Select Category'),
                       value: _selectedCategoryId,
                       items: categories.map((c) => DropdownMenuItem(
                         value: c.id, 
                         child: Text(c.name)
                       )).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                        validator: (v) => v == null ? 'Select category' : null,
                     );
                  },
                ),
                const SizedBox(height: 20),
                _isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
