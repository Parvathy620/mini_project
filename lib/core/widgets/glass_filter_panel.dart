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
    // Glassmorphic Modal Background
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF051F20).withOpacity(0.95), // Deep Jungle Dark
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: const Border(top: BorderSide(color: Colors.white12)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF69F0AE).withOpacity(0.1), blurRadius: 20, spreadRadius: -5), // Subtle Green Glow
        ],
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
                  const SizedBox(height: 32),
                  
                  if (widget.availableDistricts.isNotEmpty) ...[
                    _buildSectionTitle('Districts'),
                    const SizedBox(height: 16),
                    _buildChipGroup(widget.availableDistricts, _selectedDistricts),
                    const SizedBox(height: 32),
                  ],
                  
                  if (widget.availableCategories.isNotEmpty) ...[
                    _buildSectionTitle('Categories'),
                    const SizedBox(height: 16),
                    _buildChipGroup(widget.availableCategories, _selectedCategories),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: const Color(0xFF69F0AE),
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

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Show Available Only'),
                      Switch(
                        value: _onlyAvailable,
                        activeColor: const Color(0xFF69F0AE),
                        activeTrackColor: const Color(0xFF69F0AE).withOpacity(0.3),
                        inactiveThumbColor: Colors.white54,
                        inactiveTrackColor: Colors.white10,
                        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
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
              color: const Color(0xFF021010), // Slightly darker bottom bar
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onReset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white60,
                    ),
                    child: Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF69F0AE).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => widget.onApply(
                        _selectedDistricts,
                        _selectedCategories,
                        _priceRange,
                        _onlyAvailable,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF69F0AE),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply Filters', 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
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
        Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
             color: const Color(0xFF69F0AE).withOpacity(0.1),
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.2)),
           ),
           child: const Icon(Icons.tune_rounded, color: Color(0xFF69F0AE), size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          'Filter Search',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white54,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildChipGroup(List<String> items, List<String> selectedItems) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF69F0AE) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF69F0AE) : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: const Color(0xFF69F0AE).withOpacity(0.3), blurRadius: 8),
              ] : [],
            ),
            child: Text(
              item,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
