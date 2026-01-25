import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/app_background.dart';
import 'add_edit_category_screen.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AppBackground(
        child: StreamBuilder<List<CategoryModel>>(
          stream: adminService.getCategories(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
            
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
               return Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(16),
                  child: Text('No categories found.', style: GoogleFonts.poppins(color: Colors.white)),
                )
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.all(12),
                    opacity: 0.15,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        cat.name,
                         style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 16
                          ),
                      ),
                      subtitle: Text(
                        cat.description, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AddEditCategoryScreen(
                                    categoryId: cat.id, 
                                    currentName: cat.name,
                                    currentDescription: cat.description,
                                  )
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                               bool? confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A2E),
                                  title: const Text('Delete Category', style: TextStyle(color: Colors.white)),
                                  content: const Text('Are you sure?', style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await adminService.deleteCategory(cat.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
