import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'luxury_glass.dart';

class GlassFilterPanel extends StatefulWidget {
  final List<String> availableDistricts;
  final List<String> availableCategories;
  final List<String> selectedDistricts;
  final List<String> selectedCategories;
  final RangeValues priceRange;
  final bool onlyAvailable;
  final Function(List<String>, List<String>, RangeValues, bool) onApply;
  final VoidCallback onReset;

  const GlassFilterPanel({
    super.key,
    required this.availableDistricts,
    required this.availableCategories,
    required this.selectedDistricts,
    required this.selectedCategories,
    required this.priceRange,
    required this.onlyAvailable,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<GlassFilterPanel> createState() => _GlassFilterPanelState();
}

class _GlassFilterPanelState extends State<GlassFilterPanel> {
  late List<String> _selectedDistricts;
  late List<String> _selectedCategories;
  late RangeValues _priceRange;
  late bool _onlyAvailable;

  @override
  void initState() {
    super.initState();
    _selectedDistricts = List.from(widget.selectedDistricts);
    _selectedCategories = List.from(widget.selectedCategories);
    _priceRange = widget.priceRange;
    _onlyAvailable = widget.onlyAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  if (widget.availableDistricts.isNotEmpty) ...[
                    _buildSectionTitle('Districts'),
                    const SizedBox(height: 12),
                    _buildChipGroup(widget.availableDistricts, _selectedDistricts),
                    const SizedBox(height: 24),
                  ],
                  
                  if (widget.availableCategories.isNotEmpty) ...[
                    _buildSectionTitle('Categories'),
                    const SizedBox(height: 12),
                    _buildChipGroup(widget.availableCategories, _selectedCategories),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: Colors.cyanAccent,
                    inactiveColor: Colors.white10,
                    labels: RangeLabels(
                      '₹${_priceRange.start.round()}',
                      '₹${_priceRange.end.round()}',
                    ),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹0', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                      Text('₹10,000+', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Only Available'),
                      Switch(
                        value: _onlyAvailable,
                        activeColor: Colors.cyanAccent,
                        trackColor: MaterialStateProperty.all(Colors.white10),
                        onChanged: (val) => setState(() => _onlyAvailable = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onReset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white70,
                    ),
                    child: Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(
                      _selectedDistricts,
                      _selectedCategories,
                      _priceRange,
                      _onlyAvailable,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Apply Filters', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        LuxuryGlass(
          height: 40,
          width: 40,
          padding: EdgeInsets.zero,
          blur: 10,
          borderRadius: BorderRadius.circular(12),
          child: const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Filter Search',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChipGroup(List<String> items, List<String> selectedItems) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedItems.remove(item);
              } else {
                selectedItems.add(item);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              item,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isSelected ? Colors.cyanAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
