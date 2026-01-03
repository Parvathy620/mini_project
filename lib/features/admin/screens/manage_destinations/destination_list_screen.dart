import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/destination_model.dart';
import '../../../../core/services/admin_service.dart';
import 'add_edit_destination_screen.dart';

class DestinationListScreen extends StatelessWidget {
  const DestinationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Destinations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditDestinationScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DestinationModel>>(
        stream: adminService.getDestinations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final destinations = snapshot.data ?? [];
          if (destinations.isEmpty) return const Center(child: Text('No destinations found.'));

          return ListView.builder(
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return ListTile(
                title: Text(dest.name),
                subtitle: Text(dest.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddEditDestinationScreen(
                              destinationId: dest.id, 
                              currentName: dest.name,
                              currentDescription: dest.description,
                            )
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Confirm Dialog
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Destination'),
                            content: const Text('Are you sure?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await adminService.deleteDestination(dest.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
