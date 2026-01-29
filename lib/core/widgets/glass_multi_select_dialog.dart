import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import 'luxury_glass.dart';

class GlassMultiSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final String title;
  final String Function(T) itemLabel;
  final Function(List<T>) onConfirm;
  final String confirmText;
  final String cancelText;

  const GlassMultiSelectDialog({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.title,
    required this.itemLabel,
    required this.onConfirm,
    this.confirmText = 'Done',
    this.cancelText = 'Cancel',
  });

  @override
  State<GlassMultiSelectDialog<T>> createState() => _GlassMultiSelectDialogState<T>();
}

class _GlassMultiSelectDialogState<T> extends State<GlassMultiSelectDialog<T>> {
  late List<T> _tempSelectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List.from(widget.selectedItems);
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
            
            // Selected Chips (Preview)
            if (_tempSelectedItems.isNotEmpty) ...[
               SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tempSelectedItems.length,
                  itemBuilder: (context, index) {
                    final item = _tempSelectedItems[index];
                    return Container(
                       margin: const EdgeInsets.only(right: 8),
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(
                         color: Colors.blueAccent.withOpacity(0.2),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text(
                             widget.itemLabel(item),
                             style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                           ),
                           const SizedBox(width: 4),
                           GestureDetector(
                             onTap: () {
                               setState(() => _tempSelectedItems.remove(item));
                             },
                             child: const Icon(Icons.close, size: 12, color: Colors.white70),
                           ),
                         ],
                       ),
                    );
                  },
                ),
               ),
               const SizedBox(height: 16),
            ],

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
                      final isSelected = _tempSelectedItems.contains(item);
                      
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        title: Text(
                          widget.itemLabel(item),
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                        trailing: isSelected 
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 10, color: Colors.white),
                              )
                            : Container(
                                width: 18, 
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white30, width: 1.5),
                                ),
                              ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _tempSelectedItems.remove(item);
                            } else {
                              _tempSelectedItems.add(item);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onConfirm(_tempSelectedItems);
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF6366F1)], // Matching app theme
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.confirmText,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
