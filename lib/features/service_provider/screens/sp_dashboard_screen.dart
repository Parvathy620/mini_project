import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
// Will create this shortly

class SPDashboardScreen extends StatelessWidget {
  const SPDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              // For now, back to SP Login or Main
               if (context.mounted) {
                 Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.orange),
             SizedBox(height: 20),
            Text('Account Pending Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             SizedBox(height: 10),
            Text('You will be able to manage your services once approved by Admin.'),
          ],
        ),
      ),
    );
  }
}
