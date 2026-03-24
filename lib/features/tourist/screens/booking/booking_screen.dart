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
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BookingScreen extends StatefulWidget {
  final ServiceProviderModel provider;
  const BookingScreen({super.key, required this.provider});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // State
  List<DateTime> _selectedDates = [];
  int _numberOfPeople = 1;
  String? _selectedService;
  bool _isLoading = false;
  bool _showCalendar = false;

  late Razorpay _razorpay;
  String? _currentHoldId;
  BookingModel? _pendingBooking;

  AvailabilityModel? _availability;
  // date key -> available capacity
  Map<String, int> _capacityMap = {};
  bool _isCheckingCapacity = false;

  static const int _defaultCapacity = 10;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchAvailabilityAndCapacity();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentHoldId == null || _pendingBooking == null) return;
    
    setState(() => _isLoading = true);
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      
      // confirm booking
      await bookingService.createBookingFromHold(_pendingBooking!, _currentHoldId!);

      if (mounted) {
        final confirmedBooking = _pendingBooking!;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BookingReceiptDialog(
            bookings: [confirmedBooking],
            onClose: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error confirming booking: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentHoldId = null;
          _pendingBooking = null;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message ?? "Unknown error"}'), backgroundColor: Colors.redAccent)
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet Selected: ${response.walletName}'), backgroundColor: Colors.orangeAccent)
      );
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isOffDay(DateTime day) {
    if (_availability == null) return day.weekday == DateTime.sunday;
    return !_availability!.workingDays.contains(day.weekday);
  }

  Future<void> _fetchAvailabilityAndCapacity() async {
    _availability = await Provider.of<AvailabilityService>(context, listen: false)
        .getAvailability(widget.provider.uid);
    if (mounted) {
      setState(() {});
      await _refreshCapacityForRange();
    }
  }

  Future<void> _refreshCapacityForRange() async {
    if (!mounted) return;
    setState(() => _isCheckingCapacity = true);

    final bookingService = Provider.of<BookingService>(context, listen: false);
    Map<String, int> updated = {};

    // Check capacity for next 30 days to show on the calendar strip
    for (int i = 0; i < 30; i++) {
      final day = DateTime.now().add(Duration(days: i));
      if (!_isOffDay(day)) {
        int cap = await bookingService.getAvailableCapacity(
          providerId: widget.provider.uid,
          date: day,
          defaultCapacity: _defaultCapacity,
        );
        updated[_dateKey(day)] = cap;
      }
    }

    if (mounted) setState(() { _capacityMap = updated; _isCheckingCapacity = false; });
  }

  void _toggleDate(DateTime day) {
    if (_isOffDay(day)) return;
    if ((_capacityMap[_dateKey(day)] ?? _defaultCapacity) < 1) return;

    setState(() {
      if (_selectedDates.any((d) => _isSameDay(d, day))) {
        _selectedDates.removeWhere((d) => _isSameDay(d, day));
      } else {
        _selectedDates.add(day);
      }
      _selectedDates.sort();

      // Adjust tourist count to not exceed min capacity across selected dates
      int minCap = _minCapacityAcrossSelected();
      if (_numberOfPeople > minCap && minCap > 0) {
        _numberOfPeople = minCap;
      }
    });
  }

  int _minCapacityAcrossSelected() {
    if (_selectedDates.isEmpty) return _defaultCapacity;
    int min = _defaultCapacity;
    for (final d in _selectedDates) {
      int cap = _capacityMap[_dateKey(d)] ?? _defaultCapacity;
      if (cap < min) min = cap;
    }
    return min < 0 ? 0 : min;
  }

  double get _basePrice => widget.provider.price > 0 ? widget.provider.price : 1500.0;
  double get _totalPrice => _basePrice * _numberOfPeople * _selectedDates.length;

  String get _dateRangeLabel {
    if (_selectedDates.isEmpty) return 'No dates selected';
    if (_selectedDates.length == 1) return DateFormat('MMM dd, yyyy').format(_selectedDates.first);
    return '${DateFormat('MMM dd').format(_selectedDates.first)} → ${DateFormat('MMM dd, yyyy').format(_selectedDates.last)}';
  }

  Future<void> _processBooking() async {
    if (_selectedDates.isEmpty) return;

    final finalServiceName = _selectedService ??
        (widget.provider.services.isNotEmpty ? widget.provider.services.first : 'General Entry');
    final bookingService = Provider.of<BookingService>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Create hold across all dates
      String holdId = bookingService.generateHoldId();
      BookingHoldModel hold = BookingHoldModel(
        id: holdId,
        providerId: widget.provider.uid,
        touristId: user.uid,
        dates: _selectedDates,
        touristCount: _numberOfPeople,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      bool holdSuccess = await bookingService.createBookingHold(hold, _defaultCapacity);
      if (!holdSuccess) {
        throw Exception('One or more selected dates no longer have enough capacity. Please adjust your selection.');
      }

      // 2. Prepare pending booking and open Razorpay checkout
      _currentHoldId = holdId;
      _pendingBooking = BookingModel(
        id: bookingService.generateId(),
        touristId: user.uid,
        touristName: user.displayName ?? user.email?.split('@')[0] ?? 'Tourist',
        providerId: widget.provider.uid,
        providerName: widget.provider.name,
        serviceName: finalServiceName,
        dates: _selectedDates,
        numberOfPeople: _numberOfPeople,
        pricePerPerson: _basePrice,
        totalPrice: _totalPrice,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      var options = {
        'key': 'rzp_test_SSxYjAD0L3jbpu', // Using test placeholder
        'amount': (_totalPrice * 100).toInt(), // Amount in paisa
        'name': widget.provider.name,
        'description': 'Payment for $finalServiceName',
        'prefill': {
          'contact': '', // Optional: add user phone if available
          'email': user.email ?? '',
        },
        'theme': {
          'color': '#69F0AE' // Matches the app's accent color
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        throw Exception('Error starting payment: $e');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent));
        _refreshCapacityForRange();
        setState(() => _isLoading = false);
      }
    }
    // We do not set _isLoading = false here in finally, because we wait for Razorpay UI callback
  }

  // ------- UI Builders -------

  Widget _buildSectionHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF69F0AE).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(step, style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return LuxuryGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: child,
    );
  }

  Widget _buildDayChip(DateTime day) {
    bool isSelected = _selectedDates.any((d) => _isSameDay(d, day));
    bool isOff = _isOffDay(day);
    int cap = _capacityMap[_dateKey(day)] ?? _defaultCapacity;
    bool isFull = cap <= 0;

    Color bg = isSelected
        ? const Color(0xFF69F0AE)
        : (isOff || isFull ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.06));
    Color textColor = isSelected ? Colors.black : (isOff || isFull ? Colors.white24 : Colors.white);

    return GestureDetector(
      onTap: (isOff || isFull) ? null : () => _toggleDate(day),
      child: Container(
        width: 62,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF69F0AE) : Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('MMM').format(day), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: isSelected ? Colors.black54 : Colors.white54)),
              const SizedBox(height: 2),
              Text('${day.day}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              Text(DateFormat('E').format(day), style: GoogleFonts.inter(fontSize: 10, color: textColor)),
              if (!isOff) ...[
                const SizedBox(height: 4),
                if (isFull)
                  Text('Full', style: GoogleFonts.inter(fontSize: 8, color: Colors.redAccent))
                else if (cap <= 3)
                  Text('$cap left', style: GoogleFonts.inter(fontSize: 8, color: Colors.orangeAccent, fontWeight: FontWeight.bold))
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('1', 'Select Dates'),
              Row(
                children: [
                  if (_isCheckingCapacity)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF69F0AE))),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showCalendar = !_showCalendar),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(_showCalendar ? 'Hide' : 'Calendar', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal strip
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 30,
              itemBuilder: (context, index) {
                final day = DateTime.now().add(Duration(days: index));
                return _buildDayChip(day);
              },
            ),
          ),

          // Expandable calendar
          if (_showCalendar) ...[
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 180)),
              focusedDay: _selectedDates.isNotEmpty ? _selectedDates.last : DateTime.now(),
              selectedDayPredicate: (day) => _selectedDates.any((d) => _isSameDay(d, day)),
              onDaySelected: (selected, focused) => _toggleDate(selected),
              enabledDayPredicate: (day) {
                if (_isOffDay(day)) return false;
                int cap = _capacityMap[_dateKey(day)] ?? _defaultCapacity;
                return cap > 0;
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                weekendTextStyle: GoogleFonts.inter(color: Colors.white60),
                outsideTextStyle: GoogleFonts.inter(color: Colors.white24),
                disabledTextStyle: GoogleFonts.inter(color: Colors.white24),
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

          if (_selectedDates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF69F0AE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF69F0AE), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedDates.length} Day${_selectedDates.length > 1 ? 's' : ''} Selected  •  $_dateRangeLabel',
                      style: GoogleFonts.inter(color: const Color(0xFF69F0AE), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTouristStep() {
    int maxCap = _minCapacityAcrossSelected();
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('2', 'Number of Tourists'),
          const SizedBox(height: 16),
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
                  onPressed: _numberOfPeople > 1 ? () => setState(() => _numberOfPeople--) : null,
                ),
                Column(
                  children: [
                    Text('$_numberOfPeople', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    if (maxCap > 0)
                      Text('Max: $maxCap', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _numberOfPeople < maxCap ? () => setState(() => _numberOfPeople++) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Service dropdown
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
                    onChanged: (v) { if (v != null) setState(() => _selectedService = v); },
                    items: providerCategories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    if (_selectedDates.isEmpty) return const SizedBox.shrink();
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('3', 'Booking Summary'),
          const SizedBox(height: 16),
          _summaryRow('Dates', _dateRangeLabel),
          _summaryRow('Total Days', '${_selectedDates.length} Day${_selectedDates.length > 1 ? 's' : ''}'),
          _summaryRow('Tourists', '$_numberOfPeople Person${_numberOfPeople > 1 ? 's' : ''}'),
          _summaryRow('Price Per Person / Day', '₹${_basePrice.toStringAsFixed(0)}'),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_numberOfPeople × ₹${_basePrice.toStringAsFixed(0)} × ${_selectedDates.length} Days',
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              ),
              Text(
                '₹${_totalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              // Provider Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(
                        widget.provider.googleDriveImageUrl.isNotEmpty
                            ? widget.provider.googleDriveImageUrl
                            : (widget.provider.profileImageUrl.isNotEmpty
                                ? widget.provider.profileImageUrl
                                : 'https://via.placeholder.com/150'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.provider.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(widget.provider.description.isNotEmpty ? widget.provider.description : 'Full Day Experience', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildDateStep(),
              const SizedBox(height: 16),

              _buildTouristStep(),
              const SizedBox(height: 16),

              _buildSummaryStep(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedDates.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Proceed to Payment  •  ₹${_totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                ),
              ),
            )
          : null,
    );
  }
}
