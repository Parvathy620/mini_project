import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/models/service_provider_model.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/models/booking_hold_model.dart';
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
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  String? _selectedService;
  int _numberOfPeople = 1;
  bool _isLoading = false;

  AvailabilityModel? _availability;
  Map<String, int> _slotCapacities = {};
  bool _isLoadingSlots = false;
  List<String> _slots = [];

  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool isOffDay(DateTime day) {
    if (_availability == null) return day.weekday == DateTime.sunday;
    return !_availability!.workingDays.contains(day.weekday);
  }

  void _fetchAvailability() async {
    _availability = await Provider.of<AvailabilityService>(context, listen: false).getAvailability(widget.provider.uid);
    if (mounted) {
      setState(() {});
      _refreshSlots();
    }
  }

  void _refreshSlots() async {
    if (_availability == null) return;
    setState(() => _isLoadingSlots = true);
    
    Map<String, int> capacities = {};
    
    final startHour = _availability!.startTime.hour;
    final endHour = _availability!.endTime.hour;
    final duration = _availability!.slotDurationMinutes;
    
    List<String> generatedSlots = [];
    DateTime currentTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, startHour);
    DateTime endTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, endHour);

    bool isBlocked = _availability!.blockedDates.any((d) => isSameDay(d, _selectedDate));
    
    if (!isBlocked && !isOffDay(_selectedDate)) {
      while (currentTime.isBefore(endTime)) {
        String formatted = DateFormat('HH:mm').format(currentTime);
        generatedSlots.add(formatted);
        currentTime = currentTime.add(Duration(minutes: duration));
      }
    }

    final bookingService = Provider.of<BookingService>(context, listen: false);
    for (String slot in generatedSlots) {
       int cap = await bookingService.getAvailableCapacity(
         providerId: widget.provider.uid,
         date: _selectedDate,
         timeSlot: slot,
         defaultCapacity: _availability!.defaultSlotCapacity,
       );
       capacities[slot] = cap;
    }

    if (mounted) {
       setState(() {
         _slots = generatedSlots;
         _slotCapacities = capacities;
         _isLoadingSlots = false;
         if (_selectedSlot != null && (capacities[_selectedSlot!] ?? 0) < _numberOfPeople) {
           _selectedSlot = null;
         }
       });
    }
  }

  void _onDateChanged(DateTime newDate) {
    if (isSameDay(newDate, _selectedDate)) return;
    setState(() {
       _selectedDate = newDate;
       _selectedSlot = null;
    });
    _refreshSlots();
  }

  void _onTouristsChanged(int newCount) {
    if (newCount == _numberOfPeople) return;
    setState(() {
       _numberOfPeople = newCount;
       if (_selectedSlot != null && (_slotCapacities[_selectedSlot!] ?? 0) < _numberOfPeople) {
         _selectedSlot = null; // deselect if no longer valid
       }
    });
  }

  void _showFullCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Date', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  Navigator.pop(context);
                  _onDateChanged(selectedDay);
                },
                enabledDayPredicate: (day) => !isOffDay(day),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                  weekendTextStyle: GoogleFonts.inter(color: Colors.white60),
                  outsideTextStyle: GoogleFonts.inter(color: Colors.white24),
                  selectedDecoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: const Color(0xFF69F0AE).withOpacity(0.3), shape: BoxShape.circle),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBooking() async {
    if (_selectedSlot == null) return;
    
    final finalServiceName = _selectedService ?? (widget.provider.services.isNotEmpty ? widget.provider.services.first : 'General Entry');
    final bookingService = Provider.of<BookingService>(context, listen: false);

    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('Login required');

      // 1. Create Hold
      String holdId = bookingService.generateHoldId();
      BookingHoldModel hold = BookingHoldModel(
        id: holdId,
        providerId: widget.provider.uid,
        touristId: user.uid,
        date: _selectedDate,
        timeSlot: _selectedSlot!,
        touristCount: _numberOfPeople,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      bool holdSuccess = await bookingService.createBookingHold(hold, _availability!.defaultSlotCapacity);
      if (!holdSuccess) {
         throw Exception('Slot filled up before you could book. Please choose another.');
      }

      // 2. Booking Object
      final booking = BookingModel(
        id: bookingService.generateId(),
        touristId: user.uid,
        touristName: user.displayName ?? user.email?.split('@')[0] ?? 'Tourist',
        providerId: widget.provider.uid,
        providerName: widget.provider.name,
        serviceName: finalServiceName,
        bookingDate: _selectedDate,
        timeSlot: _selectedSlot!,
        numberOfPeople: _numberOfPeople,
        totalPrice: widget.provider.price > 0 ? widget.provider.price * _numberOfPeople : 100.0 * _numberOfPeople,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // 3. Confirm directly from hold
      await bookingService.createBookingFromHold(booking, holdId);

      if (mounted) {
        setState(() => _isLoading = false);
        _selectedSlot = null;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BookingReceiptDialog(
            bookings: [booking],
            onClose: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        _refreshSlots();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Builders ---

  Widget _buildStepHeader(String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStepCard({required Widget child}) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: child,
    );
  }

  Widget _buildDateSelector() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepHeader('1', 'Select Date'),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white70),
                onPressed: _showFullCalendar,
                tooltip: 'View Full Calendar',
              ),
            ],
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 14, // show next 14 days initially
              itemBuilder: (context, index) {
                DateTime day = DateTime.now().add(Duration(days: index));
                bool isSelected = isSameDay(day, _selectedDate);
                bool available = !isOffDay(day);

                return GestureDetector(
                  onTap: available ? () => _onDateChanged(day) : null,
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF69F0AE) : (available ? Colors.white.withOpacity(0.05) : Colors.black12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF69F0AE) : Colors.white12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(day).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black54 : (available ? Colors.white54 : Colors.white24),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : (available ? Colors.white : Colors.white24),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E').format(day),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isSelected ? Colors.black87 : (available ? Colors.white : Colors.white24),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }

  Widget _buildTouristStepper() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('2', 'Number of Tourists'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    if (_numberOfPeople > 1) _onTouristsChanged(_numberOfPeople - 1);
                  },
                ),
                Text(
                  '$_numberOfPeople',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                     // Can cap at max capacity if known, else let them choose and block slot later
                    _onTouristsChanged(_numberOfPeople + 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Service Selection (if any)
          StreamBuilder<List<CategoryModel>>(
             stream: Provider.of<DataService>(context, listen: false).getCategories(),
             builder: (context, snapshot) {
               if (!snapshot.hasData) return const SizedBox.shrink();
               final providerCategories = snapshot.data!
                   .where((c) => widget.provider.categoryIds.contains(c.id))
                   .map((c) => c.name).toList();

               if (providerCategories.isEmpty) providerCategories.add('General Service');
               if (_selectedService == null) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) setState(() => _selectedService = providerCategories.first);
                 });
               }

               return Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<String>(
                     value: _selectedService,
                     isExpanded: true,
                     dropdownColor: const Color(0xFF022C22),
                     icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                     style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                     onChanged: (String? val) { if (val != null) setState(() => _selectedService = val); },
                     items: providerCategories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                   ),
                 ),
               );
             }
          ),
        ],
      )
    );
  }

  Widget _buildTimeSlots() {
    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepHeader('3', 'Select Time Slot'),
              if (_isLoadingSlots) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF69F0AE))),
            ],
          ),
          if (_slots.isEmpty && !_isLoadingSlots)
             Text('No slots available on this day.', style: GoogleFonts.inter(color: Colors.white54))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _slots.map((slot) {
                int capacity = _slotCapacities[slot] ?? 0;
                bool isSelected = _selectedSlot == slot;
                bool isAvailable = capacity >= _numberOfPeople;
                bool isLow = isAvailable && (capacity - _numberOfPeople) <= 3; // Running low

                return GestureDetector(
                  onTap: isAvailable ? () => setState(() => _selectedSlot = slot) : null,
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 80) / 3, // 3 columns approx
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? const Color(0xFF69F0AE) 
                        : (isAvailable ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                           ? const Color(0xFF69F0AE) 
                           : (isAvailable ? Colors.white12 : Colors.transparent),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          slot,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.black : (isAvailable ? Colors.white : Colors.white38),
                          ),
                        ),
                        if (isAvailable && isLow) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Only $capacity left',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.deepOrange : Colors.orangeAccent,
                            ),
                          ),
                        ] else if (!isAvailable) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Full',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      )
    );
  }

  Widget _buildSummary() {
    double basePrice = widget.provider.price > 0 ? widget.provider.price : 100.0;
    double totalPrice = basePrice * _numberOfPeople;

    return _buildStepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('4', 'Price Summary'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Date:', style: GoogleFonts.inter(color: Colors.white70)),
              Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time:', style: GoogleFonts.inter(color: Colors.white70)),
              Text(_selectedSlot ?? 'Not selected', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tourists:', style: GoogleFonts.inter(color: Colors.white70)),
              Text('$_numberOfPeople', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_numberOfPeople × \u{20B9}${basePrice.toStringAsFixed(0)}', style: GoogleFonts.inter(color: Colors.white70)),
              Text('\u{20B9}${totalPrice.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Booking Configuration', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Provider Info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        (widget.provider.googleDriveImageUrl.isNotEmpty)
                            ? widget.provider.googleDriveImageUrl
                            : (widget.provider.profileImageUrl.isNotEmpty 
                                ? widget.provider.profileImageUrl 
                                : 'https://via.placeholder.com/150'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.provider.name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildDateSelector(),
              const SizedBox(height: 16),
              
              _buildTouristStepper(),
              const SizedBox(height: 16),

              _buildTimeSlots(),
              const SizedBox(height: 16),

              if (_selectedSlot != null) _buildSummary(),
              const SizedBox(height: 100), // spacing for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedSlot != null
        ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.95),
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
                      'Proceed to Payment', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
              ),
            ),
          )
        : null,
    );
  }
}
