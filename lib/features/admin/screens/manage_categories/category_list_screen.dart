import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_glass.dart';
import '../../../../core/widgets/app_background.dart';
import 'add_edit_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        backgroundColor: const Color(0xFF69F0AE),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Search Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LuxuryGlass(
                  height: 50,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(16),
                  opacity: 0.1,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    ),
                  ),
                ),
              ),
            ),

            // Category List
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: adminService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                  
                  var categories = snapshot.data ?? [];

                  // Search Filter
                  if (_searchQuery.isNotEmpty) {
                    categories = categories.where((c) => 
                      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                      c.description.toLowerCase().contains(_searchQuery.toLowerCase())
                    ).toList();
                  }

                  if (categories.isEmpty) {
                     return Center(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(16),
                        child: Text(
                          _searchQuery.isEmpty ? 'No categories found.' : 'No results found.', 
                          style: GoogleFonts.poppins(color: Colors.white)
                        ),
                      )
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: LuxuryGlass(
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
                                _buildActionButton(
                                  icon: Icons.edit_rounded,
                                  color: const Color(0xFF69F0AE),
                                  onTap: () {
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
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.delete_rounded,
                                  color: Colors.redAccent,
                                  onTap: () async {
                                     _confirmDelete(context, cat, adminService);
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel cat, AdminService service) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
            side: BorderSide(color: Colors.white.withOpacity(0.1))
          ),
        title: Text('Delete Category', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${cat.name}"?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await service.deleteCategory(cat.id);
    }
  }
}
