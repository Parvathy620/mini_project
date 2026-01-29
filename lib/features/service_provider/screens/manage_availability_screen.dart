import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/services/availability_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/availability_model.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/luxury_glass.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  AvailabilityModel? _availability;
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final data = await Provider.of<AvailabilityService>(context, listen: false).getAvailability(user.uid);
      setState(() {
        _availability = data ?? AvailabilityModel(providerId: user.uid);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAvailability() async {
    if (_availability == null) return;
    setState(() => _isLoading = true);
    await Provider.of<AvailabilityService>(context, listen: false).setAvailability(_availability!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability Updated')));
      setState(() => _isLoading = false);
    }
  }

  void _toggleDay(int day) {
    if (_availability == null) return;
    final days = List<int>.from(_availability!.workingDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    setState(() {
      _availability = AvailabilityModel(
        providerId: _availability!.providerId,
        workingDays: days,
        startTime: _availability!.startTime,
        endTime: _availability!.endTime,
        blockedDates: _availability!.blockedDates,
        slotDurationMinutes: _availability!.slotDurationMinutes,
      );
    });
  }

  void _toggleDateBlock(DateTime date) {
    if (_availability == null) return;
    final normalized = DateTime(date.year, date.month, date.day);
    final blocks = List<DateTime>.from(_availability!.blockedDates);
    
    // Check if exists (manual check because DateTime equality includes time often, but here we normalized)
    final existingIndex = blocks.indexWhere((d) => d.year == normalized.year && d.month == normalized.month && d.day == normalized.day);
    
    if (existingIndex >= 0) {
      blocks.removeAt(existingIndex);
    } else {
      blocks.add(normalized);
    }

    setState(() {
      _availability = AvailabilityModel(
        providerId: _availability!.providerId,
        workingDays: _availability!.workingDays,
        startTime: _availability!.startTime,
        endTime: _availability!.endTime,
        blockedDates: blocks,
        slotDurationMinutes: _availability!.slotDurationMinutes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: const Color(0xFF69F0AE))));
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Manage Availability', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: const Color(0xFF69F0AE)),
            onPressed: _saveAvailability,
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Working Days
                Text('Working Days', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                  LuxuryGlass(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Days', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 16),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(7, (index) {
                              final dayNum = index + 1;
                              final isSelected = _availability!.workingDays.contains(dayNum);
                              return GestureDetector(
                                onTap: () => _toggleDay(dayNum),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 45, 
                                  height: 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? const Color(0xFF69F0AE) : Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF69F0AE) : Colors.white.withOpacity(0.15), 
                                      width: 1.5
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: const Color(0xFF69F0AE).withOpacity(0.4), blurRadius: 12, spreadRadius: 1)
                                    ] : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    days[index].substring(0, 1), // First letter only (M, T, W...) for cleaner look, or keep 3 letters if preferred. Let's try 3 letters first if space permits, or 1 for circles.
                                    // Actually 3 letters "Mon" fits in 45px? Maybe tight. Let's use 1 letter or increase size. 
                                    // Let's stick to the 3 letters "Mon" but maybe reduce font size slightly or increase circle.
                                    // Or just use "Mon" with 50width.
                                    // Let's try "M", "T" etc for standard clean look.
                                    style: GoogleFonts.outfit(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Block Dates
                Text('Block Specific Dates', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LuxuryGlass(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(20),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    onDaySelected: (selected, focused) {
                      setState(() => _focusedDay = focused);
                      _toggleDateBlock(selected);
                    },
                    selectedDayPredicate: (day) => _availability!.blockedDates.any((d) => isSameDay(d, day)),
                    calendarStyle: CalendarStyle(
                       defaultTextStyle: const TextStyle(color: Colors.white),
                       weekendTextStyle: const TextStyle(color: Colors.white60),
                       selectedDecoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                       todayDecoration: BoxDecoration(color: const Color(0xFF69F0AE).withOpacity(0.3), shape: BoxShape.circle),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(color: Colors.white),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
