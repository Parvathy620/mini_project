import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import 'luxury_glass.dart';

class GlassSingleSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String title;
  final String Function(T) itemLabel;
  final String Function(T)? itemSubtitle;
  final Function(T) onConfirm;
  final String cancelText;

  const GlassSingleSelectDialog({
    super.key,
    required this.items,
    this.selectedItem,
    required this.title,
    required this.itemLabel,
    this.itemSubtitle,
    required this.onConfirm,
    this.cancelText = 'Cancel',
  });

  @override
  State<GlassSingleSelectDialog<T>> createState() => _GlassSingleSelectDialogState<T>();
}

class _GlassSingleSelectDialogState<T> extends State<GlassSingleSelectDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) =>
          widget.itemLabel(item).toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: LuxuryGlass(
        borderRadius: BorderRadius.circular(24),
        blur: 30,
        opacity: 0.1,
        color: const Color(0xFF38BDF8).withOpacity(0.08), // Blue gradient tint effect
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Item List
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredItems.length,
                    separatorBuilder: (c, i) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      // Use object equality or some identifier if needed, for simplicity using simple equality
                      // Calling code can pass correct selectedItem instance
                      final isSelected = widget.selectedItem == item;
                      
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        title: Text(
                          widget.itemLabel(item),
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: widget.itemSubtitle != null ? Text(
                          widget.itemSubtitle!(item),
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12
                          )
                        ) : null,
                        trailing: isSelected 
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              )
                            : null,
                        onTap: () {
                          widget.onConfirm(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Cancel Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: GlassContainer(
                height: 48,
                opacity: 0.05,
                borderRadius: BorderRadius.circular(12),
                padding: EdgeInsets.zero,
                child: Center(
                  child: Text(
                    widget.cancelText,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
