import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/models/service_provider_model.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/availability_model.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/data_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/luxury_glass.dart';
import '../../widgets/booking_receipt_dialog.dart';

class BookingScreen extends StatefulWidget {
  final ServiceProviderModel provider;

  const BookingScreen({super.key, required this.provider});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedSlot;
  String? _selectedService;
  bool _isLoading = false;

  AvailabilityModel? _availability;

  List<String> _slots = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  void _fetchAvailability() async {
    _availability = await Provider.of<AvailabilityService>(context, listen: false).getAvailability(widget.provider.uid);
    setState(() {}); 
  }

  List<String> _generateSlotsForDay(DateTime date) {
    final startHour = _availability?.startTime.hour ?? 9;
    final endHour = _availability?.endTime.hour ?? 17;
    final duration = _availability?.slotDurationMinutes ?? 60;

    List<String> slots = [];
    DateTime currentTime = DateTime(date.year, date.month, date.day, startHour);
    DateTime endTime = DateTime(date.year, date.month, date.day, endHour);

    while (currentTime.isBefore(endTime)) {
      String formatted = DateFormat('HH:mm').format(currentTime);
      bool isBlocked = _availability?.blockedDates.any((d) => isSameDay(d, date)) ?? false;
      if (!isBlocked) {
        slots.add(formatted);
      }
      currentTime = currentTime.add(Duration(minutes: duration));
    }
    return slots;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedSlot = null;
        _slots = _generateSlotsForDay(selectedDay);
      });
    }
  }

  Future<void> _processBooking() async {
    if (_selectedDay == null || _selectedSlot == null) return;
    
    final finalServiceName = _selectedService ?? (widget.provider.services.isNotEmpty ? widget.provider.services.first : 'General Entry');

    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('Login required');

      final booking = BookingModel(
        id: Provider.of<BookingService>(context, listen: false).generateId(),
        touristId: user.uid,
        touristName: user.displayName ?? user.email?.split('@')[0] ?? 'Tourist',
        providerId: widget.provider.uid,
        providerName: widget.provider.name,
        serviceName: finalServiceName,
        bookingDate: _selectedDay!,
        timeSlot: _selectedSlot!,
        totalPrice: widget.provider.price > 0 ? widget.provider.price : 100.0,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await Provider.of<BookingService>(context, listen: false).createBookingRequest(booking);

      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BookingReceiptDialog(
            booking: booking,
            onClose: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOffDay(DateTime day) {
      if (_availability == null) return day.weekday == DateTime.sunday;
      return !_availability!.workingDays.contains(day.weekday);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Book Appointment', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView( // Refactored to CustomScrollView
            slivers: [
              // 1. Provider Info Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: LuxuryGlass(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            (widget.provider.googleDriveImageUrl.isNotEmpty)
                                ? widget.provider.googleDriveImageUrl
                                : (widget.provider.profileImageUrl.isNotEmpty 
                                    ? widget.provider.profileImageUrl 
                                    : 'https://via.placeholder.com/150'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.provider.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Select service, date & time', style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Category Selection (Sliver Adapter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<List<CategoryModel>>(
                    stream: Provider.of<DataService>(context, listen: false).getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      
                      final allCategories = snapshot.data!;
                      final providerCategories = allCategories
                          .where((c) => widget.provider.categoryIds.contains(c.id))
                          .map((c) => c.name)
                          .toList();

                      if (providerCategories.isEmpty) {
                         providerCategories.add('General Service');
                      }

                      if (_selectedService == null) {
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (mounted) setState(() => _selectedService = providerCategories.first);
                         });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Select Category', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 12),
                          LuxuryGlass(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF69F0AE).withOpacity(0.1), // Green Glass Tint
                            border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.3)), // Green Border
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedService,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF022C22), // Deep Green Menu
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF69F0AE)),
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedService = newValue);
                                  }
                                },
                                items: providerCategories.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                  ),
                ),
              ),

              // 3. Table Calendar
              SliverToBoxAdapter(
                child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   child: LuxuryGlass(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(20),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      availableGestures: AvailableGestures.horizontalSwipe, // Allow vertical scrolling on page
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                        weekendTextStyle: GoogleFonts.inter(color: Colors.white60),
                        outsideTextStyle: GoogleFonts.inter(color: Colors.white24),
                        selectedDecoration: const BoxDecoration(color: const Color(0xFF69F0AE), shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: const Color(0xFF69F0AE).withOpacity(0.3), shape: BoxShape.circle),
                      ),
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                      ),
                      enabledDayPredicate: (day) => !isOffDay(day),
                    ),
                  ),
                ),
              ),

              // 4. Slots Grid (Wrapped in SliverPadding + SliverGrid)
              if (_selectedDay != null) ...[
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                     child: Text('Available Slots', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                
                if (_slots.isEmpty)
                   SliverToBoxAdapter(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 20),
                       child: Text('No slots available on this day.', style: GoogleFonts.inter(color: Colors.white54)),
                     ),
                   )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final slot = _slots[index];
                          final isSelected = _selectedSlot == slot;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSlot = slot),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF69F0AE) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF69F0AE) : Colors.white12),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _slots.length,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom Spacing
              ] else 
                 SliverToBoxAdapter(
                   child: Padding(
                     padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                     child: Center(child: Text('Select a date to view slots', style: GoogleFonts.inter(color: Colors.white24))),
                   ),
                 ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedDay != null && _selectedSlot != null
        ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.9),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF69F0AE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _processBooking,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      'Confirm Booking', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
              ),
            ),
          )
        : null,
    );
  }
}
