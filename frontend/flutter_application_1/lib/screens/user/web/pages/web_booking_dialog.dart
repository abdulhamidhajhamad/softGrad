// lib/screens/user/web/pages/web_booking_dialog.dart
//
// ✅ Modern Web Booking Dialog
// ✅ All validations from app version
// ✅ Beautiful responsive design

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../web_theme.dart';
import '../../../../services/payment_service/add_to_cart_service.dart';
import '../../../../services/payment_service/cart_service.dart';
import '../../payment/cart.dart' show CartStore, CartItem;

// Booking Types
enum WebBookingType { hourly, daily, capacity, mixed, display }

/// Show web booking dialog
Future<void> showWebBookingDialog({
  required BuildContext context,
  required String serviceId,
  required String serviceName,
  required String bookingTypeString,
  required Map<String, dynamic> serviceData,
  required VoidCallback onSuccess,
}) async {
  // Parse booking type
  WebBookingType bookingType = WebBookingType.daily;
  switch (bookingTypeString.toLowerCase()) {
    case 'hourly':
      bookingType = WebBookingType.hourly;
      break;
    case 'daily':
      bookingType = WebBookingType.daily;
      break;
    case 'capacity':
      bookingType = WebBookingType.capacity;
      break;
    case 'mixed':
      bookingType = WebBookingType.mixed;
      break;
    case 'display':
      bookingType = WebBookingType.display;
      break;
  }

  await showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _WebBookingDialog(
      serviceId: serviceId,
      serviceName: serviceName,
      bookingType: bookingType,
      serviceData: serviceData,
      onSuccess: onSuccess,
    ),
  );
}

class _WebBookingDialog extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final WebBookingType bookingType;
  final Map<String, dynamic> serviceData;
  final VoidCallback onSuccess;

  const _WebBookingDialog({
    required this.serviceId,
    required this.serviceName,
    required this.bookingType,
    required this.serviceData,
    required this.onSuccess,
  });

  @override
  State<_WebBookingDialog> createState() => _WebBookingDialogState();
}

class _WebBookingDialogState extends State<_WebBookingDialog>
    with SingleTickerProviderStateMixin {
  // Form State
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _numberOfPeople = 1;
  bool _isFullVenue = false;
  bool _isLoading = false;

  // Client Location (for services that go to client)
  final _clientAddressController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  String? _clientCity;
  double? _clientLat;
  double? _clientLng;

  // Booking Description
  final _bookingDescriptionController = TextEditingController();

  // Price State
  double? _calculatedPrice;
  Map<String, dynamic>? _priceBreakdown;

  // Animation
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Service Constraints
  int? get _maxCapacity => widget.serviceData['maxCapacity'];
  int? get _minBookingHours => widget.serviceData['minBookingHours'];
  int? get _maxBookingHours => widget.serviceData['maxBookingHours'];
  List<int>? get _availableHours =>
      (widget.serviceData['availableHours'] as List<dynamic>?)?.map((e) => e as int).toList();
  List<String>? get _workingDays =>
      (widget.serviceData['workingDays'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList();
  bool get _hasFixedLocation => widget.serviceData['hasFixedLocation'] ?? true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Default date to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculatePrice());
  }

  @override
  void dispose() {
    _animController.dispose();
    _clientAddressController.dispose();
    _locationDescriptionController.dispose();
    _bookingDescriptionController.dispose();
    super.dispose();
  }

  // ============ Date Picker ============
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kWebPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dayName = _getDayName(picked);
      if (_workingDays != null && _workingDays!.isNotEmpty && !_workingDays!.contains(dayName)) {
        _showError('Service is not available on ${_capitalize(dayName)}s.\nWorking days: ${_workingDays!.map(_capitalize).join(", ")}');
        return;
      }
      setState(() => _selectedDate = picked);
      _calculatePrice();
    }
  }

  // ============ Time Picker ============
  Future<void> _pickTime(bool isStart) async {
    final initialTime = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 17, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kWebPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (_availableHours != null && _availableHours!.isNotEmpty && !_availableHours!.contains(picked.hour)) {
        _showError('Service is not operational at ${picked.hour}:00.\nAvailable hours: ${_availableHours!.join(", ")}');
        return;
      }
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _calculatePrice();
    }
  }

  // ============ Calculate Price ============
  void _calculatePrice() {
    if (_selectedDate == null) {
      setState(() {
        _calculatedPrice = null;
        _priceBreakdown = null;
      });
      return;
    }

    final allPrices = widget.serviceData['allPrices'] as Map<String, dynamic>?;
    double basePrice = 0;

    if (widget.bookingType == WebBookingType.hourly) {
      if (_startTime == null || _endTime == null) {
        setState(() {
          _calculatedPrice = null;
          _priceBreakdown = null;
        });
        return;
      }

      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final hours = (endMinutes - startMinutes) / 60;

      if (hours <= 0) {
        setState(() {
          _calculatedPrice = null;
          _priceBreakdown = null;
        });
        return;
      }

      basePrice = (allPrices?['perHour'] ?? 0).toDouble();
      final total = basePrice * hours;

      setState(() {
        _calculatedPrice = total;
        _priceBreakdown = {'hours': hours, 'pricePerHour': basePrice, 'total': total};
      });
      return;
    }

    if (widget.bookingType == WebBookingType.capacity) {
      basePrice = (allPrices?['perPerson'] ?? 0).toDouble();
      final total = basePrice * _numberOfPeople;
      setState(() {
        _calculatedPrice = total;
        _priceBreakdown = {'numberOfPeople': _numberOfPeople, 'pricePerPerson': basePrice, 'total': total};
      });
      return;
    }

    if (widget.bookingType == WebBookingType.mixed) {
      if (_isFullVenue) {
        basePrice = (allPrices?['perEvent'] ?? 0).toDouble();
        setState(() {
          _calculatedPrice = basePrice;
          _priceBreakdown = {'type': 'Full Venue', 'total': basePrice};
        });
      } else {
        basePrice = (allPrices?['perPerson'] ?? 0).toDouble();
        final total = basePrice * _numberOfPeople;
        setState(() {
          _calculatedPrice = total;
          _priceBreakdown = {'numberOfPeople': _numberOfPeople, 'pricePerPerson': basePrice, 'total': total};
        });
      }
      return;
    }

    if (widget.bookingType == WebBookingType.daily) {
      basePrice = (allPrices?['perDay'] ?? 0).toDouble();
      setState(() {
        _calculatedPrice = basePrice;
        _priceBreakdown = {'type': 'Per Day', 'total': basePrice};
      });
      return;
    }

    if (widget.bookingType == WebBookingType.display) {
      basePrice = (allPrices?['displayPrice'] ?? 0).toDouble();
      setState(() {
        _calculatedPrice = basePrice;
        _priceBreakdown = {'type': 'Display', 'total': basePrice};
      });
    }
  }

  // ============ Validation ============
  String? _validate() {
    if (_selectedDate == null) {
      return 'Please select a date';
    }

    // Validate working days
    if (_workingDays != null && _workingDays!.isNotEmpty) {
      final dayName = _getDayName(_selectedDate!);
      if (!_workingDays!.contains(dayName)) {
        return 'Service is not available on ${_capitalize(dayName)}s';
      }
    }

    if (widget.bookingType == WebBookingType.hourly) {
      if (_startTime == null || _endTime == null) {
        return 'Please select start and end times';
      }

      // Validate available hours
      if (_availableHours != null && _availableHours!.isNotEmpty) {
        if (!_availableHours!.contains(_startTime!.hour)) {
          return 'Service is not operational at ${_startTime!.hour}:00';
        }
        for (int h = _startTime!.hour; h < _endTime!.hour; h++) {
          if (!_availableHours!.contains(h)) {
            return 'Service is not operational at $h:00';
          }
        }
      }

      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final hours = (endMinutes - startMinutes) / 60;

      if (hours <= 0) {
        return 'End time must be after start time';
      }

      if (_minBookingHours != null && hours < _minBookingHours!) {
        return 'Minimum booking is $_minBookingHours hours';
      }

      if (_maxBookingHours != null && hours > _maxBookingHours!) {
        return 'Maximum booking is $_maxBookingHours hours';
      }
    }

    if (widget.bookingType == WebBookingType.capacity ||
        (widget.bookingType == WebBookingType.mixed && !_isFullVenue)) {
      if (_numberOfPeople <= 0) {
        return 'Please enter number of people';
      }
      if (_maxCapacity != null && _numberOfPeople > _maxCapacity!) {
        return 'Maximum capacity is $_maxCapacity people';
      }
    }

    // Validate client location for mobile services
    if (!_hasFixedLocation) {
      if (_clientAddressController.text.trim().isEmpty) {
        return 'Please enter your address';
      }
      if (_clientCity == null || _clientCity!.isEmpty) {
        return 'Please select your city';
      }
    }

    return null;
  }

  // ============ Submit Booking ============
  Future<void> _submitBooking() async {
    final error = _validate();
    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bookingDetails = <String, dynamic>{
        'date': _selectedDate!.toIso8601String(),
      };

      if (widget.bookingType == WebBookingType.hourly) {
        bookingDetails['startHour'] = _startTime!.hour;
        bookingDetails['endHour'] = _endTime!.hour;
      }

      if (widget.bookingType == WebBookingType.capacity ||
          (widget.bookingType == WebBookingType.mixed && !_isFullVenue)) {
        bookingDetails['numberOfPeople'] = _numberOfPeople;
      }

      if (widget.bookingType == WebBookingType.mixed) {
        bookingDetails['isFullVenue'] = _isFullVenue;
      }

      // Client location for mobile services
      if (!_hasFixedLocation) {
        bookingDetails['clientLocation'] = {
          'address': _clientAddressController.text.trim(),
          'city': _clientCity,
          'latitude': _clientLat,
          'longitude': _clientLng,
          'locationDescription': _locationDescriptionController.text.trim(),
        };
      }

      // Booking description
      final description = _bookingDescriptionController.text.trim();
      if (description.isNotEmpty) {
        bookingDetails['bookingDescription'] = description;
      }

      final result = await AddToCartService.addToCart(
        serviceId: widget.serviceId,
        bookingDetails: bookingDetails,
      );

      if (result['success'] == true) {
        final cartData = result['cart'];
        if (cartData != null) {
          try {
            final cartResponse = CartResponse.fromJson(cartData);
            CartStore.instance.updateFromBackend(cartResponse.items);
          } catch (e) {
            CartStore.instance.add(CartItem(
              id: widget.serviceId,
              serviceName: widget.serviceName,
              companyName: widget.serviceData['companyName']?.toString() ?? 'Provider',
              price: (widget.serviceData['price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: widget.serviceData['imageUrl']?.toString(),
            ));
          }
        }

        setState(() => _isLoading = false);
        Navigator.pop(context);
        _showSuccess();
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      if (_isBookingConflict(errorMsg)) {
        _showConflictDialog(errorMsg);
      } else {
        _showError(errorMsg);
      }
    }
  }

  bool _isBookingConflict(String message) {
    final lower = message.toLowerCase();
    return lower.contains('time slot') ||
        lower.contains('fully booked') ||
        lower.contains('not available') ||
        lower.contains('conflict') ||
        lower.contains('capacity');
  }

  // ============ Helper Methods ============
  String _getDayName(DateTime date) {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[date.weekday % 7];
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: kWebError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('Added to cart successfully!', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: kWebSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showConflictDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Conflict',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kWebTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWebBgSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: kWebTextBody,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 18, color: kWebPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try selecting a different date or time',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kWebPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWebPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Change Selection',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Build UI ============
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Field
                        _buildDateField(),
                        const SizedBox(height: 20),

                        // Hourly: Time fields
                        if (widget.bookingType == WebBookingType.hourly) ...[
                          _buildTimeFields(),
                          const SizedBox(height: 20),
                        ],

                        // Capacity: Number of people
                        if (widget.bookingType == WebBookingType.capacity) ...[
                          _buildCapacityField(),
                          const SizedBox(height: 20),
                        ],

                        // Mixed: Full venue toggle + capacity
                        if (widget.bookingType == WebBookingType.mixed) ...[
                          _buildFullVenueToggle(),
                          const SizedBox(height: 20),
                          if (!_isFullVenue) ...[
                            _buildCapacityField(),
                            const SizedBox(height: 20),
                          ],
                        ],

                        // Client location for mobile services
                        if (!_hasFixedLocation) ...[
                          _buildClientLocationField(),
                          const SizedBox(height: 20),
                        ],

                        // Special requests
                        _buildSpecialRequestsField(),
                        const SizedBox(height: 20),

                        // Price display
                        if (_calculatedPrice != null && _calculatedPrice! > 0)
                          _buildPriceCard(),
                      ],
                    ),
                  ),
                ),

                // Bottom actions
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: kWebBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kWebPrimary, kWebPrimaryDark],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Service',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kWebTextPrimary,
                  ),
                ),
                Text(
                  widget.serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: kWebTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: kWebBgSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.close_rounded, color: kWebTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return _buildFieldCard(
      icon: Icons.calendar_today_rounded,
      label: 'Date',
      value: _selectedDate == null
          ? 'Select date'
          : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
      onTap: _pickDate,
      hasValue: _selectedDate != null,
    );
  }

  Widget _buildTimeFields() {
    return Row(
      children: [
        Expanded(
          child: _buildFieldCard(
            icon: Icons.access_time_rounded,
            label: 'Start Time',
            value: _startTime?.format(context) ?? 'Select time',
            onTap: () => _pickTime(true),
            hasValue: _startTime != null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFieldCard(
            icon: Icons.access_time_filled_rounded,
            label: 'End Time',
            value: _endTime?.format(context) ?? 'Select time',
            onTap: () => _pickTime(false),
            hasValue: _endTime != null,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool hasValue = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWebBgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hasValue ? kWebPrimary.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWebPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kWebPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kWebTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasValue ? kWebTextPrimary : kWebTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: kWebTextMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWebBgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWebPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_rounded, color: kWebPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'Number of People',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kWebTextPrimary,
                ),
              ),
              if (_maxCapacity != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kWebPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Max: $_maxCapacity',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kWebPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_numberOfPeople > 1) {
                    setState(() => _numberOfPeople--);
                    _calculatePrice();
                  }
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kWebPrimary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '$_numberOfPeople',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: kWebPrimary,
                  ),
                ),
              ),
              _buildCounterButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_maxCapacity == null || _numberOfPeople < _maxCapacity!) {
                    setState(() => _numberOfPeople++);
                    _calculatePrice();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({required IconData icon, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kWebPrimary, kWebPrimaryDark]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: kWebPrimary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildFullVenueToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWebBgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kWebPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.home_work_rounded, color: kWebPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Full Venue',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kWebTextPrimary,
                  ),
                ),
                Text(
                  'Reserve the entire space exclusively',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: kWebTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isFullVenue,
            onChanged: (val) {
              setState(() => _isFullVenue = val);
              _calculatePrice();
            },
            activeColor: kWebPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildClientLocationField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWebBgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWebPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded, color: kWebPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'Your Location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kWebTextPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kWebError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Required',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kWebError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _clientAddressController,
            decoration: InputDecoration(
              hintText: 'Enter your address',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: kWebTextMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          // City dropdown
          DropdownButtonFormField<String>(
            value: _clientCity,
            decoration: InputDecoration(
              hintText: 'Select city',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: kWebTextMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: ['Jerusalem', 'Tel Aviv', 'Haifa', 'Nazareth', 'Bethlehem', 'Ramallah', 'Nablus', 'Hebron', 'Jaffa', 'Acre']
                .map((city) => DropdownMenuItem(value: city, child: Text(city, style: GoogleFonts.poppins(fontSize: 13))))
                .toList(),
            onChanged: (val) => setState(() => _clientCity = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequestsField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWebBgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWebPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.edit_note_rounded, color: kWebPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'Special Requests',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kWebTextPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kWebBgSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kWebBorder),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kWebTextMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bookingDescriptionController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'e.g., Please arrive 10 minutes early, need extra chairs...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: kWebTextMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    String priceLabel = '';
    if (_priceBreakdown != null) {
      if (_priceBreakdown!.containsKey('hours')) {
        priceLabel = '${_priceBreakdown!['hours']} hours × ₪${(_priceBreakdown!['pricePerHour'] as num).toStringAsFixed(0)}';
      } else if (_priceBreakdown!.containsKey('numberOfPeople')) {
        priceLabel = '${_priceBreakdown!['numberOfPeople']} people × ₪${(_priceBreakdown!['pricePerPerson'] as num).toStringAsFixed(0)}';
      } else if (_priceBreakdown!.containsKey('type')) {
        priceLabel = _priceBreakdown!['type'];
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kWebPrimary.withValues(alpha: 0.1), kWebPrimaryDark.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kWebPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kWebPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.receipt_long_rounded, color: kWebPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Total',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kWebTextMuted,
                  ),
                ),
                if (priceLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    priceLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: kWebTextBody,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₪${_calculatedPrice!.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kWebPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(top: BorderSide(color: kWebBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: kWebPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kWebTextMuted.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Icon(Icons.add_shopping_cart_rounded),
          label: Text(
            _isLoading ? 'Adding...' : 'Add to Cart',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
