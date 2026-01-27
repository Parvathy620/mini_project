import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/luxury_glass.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/runway_reveal.dart';

class TouristBookingFlow extends StatefulWidget {
  final String serviceName;
  final double price;

  const TouristBookingFlow({
    super.key,
    required this.serviceName,
    required this.price,
  });

  @override
  State<TouristBookingFlow> createState() => _TouristBookingFlowState();
}

class _TouristBookingFlowState extends State<TouristBookingFlow> {
  int _currentStep = 0;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('SECURE BOOKING', style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Select'),
                  _buildStepLine(0),
                  _buildStepIndicator(1, 'Confirm'),
                  _buildStepLine(1),
                  _buildStepIndicator(2, 'Done'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.white10,
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10)] : [],
          ),
          child: Center(
            child: isActive 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('${step + 1}', style: const TextStyle(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > step ? Colors.blueAccent : Colors.white10,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDateSelectionStep();
      case 1:
        return _buildConfirmationStep();
      case 2:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDateSelectionStep() {
    return RunwayReveal(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LuxuryGlass(
          opacity: 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Mission Date', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 20),
              CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedDate == null ? null : () => setState(() => _currentStep = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('Proceed to Confirmation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return RunwayReveal(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LuxuryGlass(
          opacity: 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Flight Manifest', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 30),
              _buildSummaryRow('Service', widget.serviceName),
              const SizedBox(height: 10),
              _buildSummaryRow('Date', _selectedDate.toString().split(' ')[0]),
              const SizedBox(height: 10),
              _buildSummaryRow('Price', '\$${widget.price.toStringAsFixed(2)}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white24),
              ),
              _buildSummaryRow('Total', '\$${widget.price.toStringAsFixed(2)}', isBold: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('Confirm Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return RunwayReveal(
      slideUp: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 40)],
              ),
              child: const Icon(Icons.check, color: Colors.greenAccent, size: 50),
            ),
            const SizedBox(height: 30),
            Text('Booking Confirmed', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Your receipt has been generated.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Base', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: isBold ? 18 : 14)),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
      ],
    );
  }
}
