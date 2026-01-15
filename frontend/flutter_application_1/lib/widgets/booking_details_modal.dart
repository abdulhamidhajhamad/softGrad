// lib/widgets/booking_details_modal.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/payment_service/add_to_cart_service.dart';
import '../services/payment_service/cart_service.dart';
import '../screens/user/payment/cart.dart' show CartStore, CartItem;
import '../screens/map_location_picker.dart' hide kPrimaryColor, kTextColor;

// =====================
// 🎨 Design Tokens (from services_customer_home.dart)
// =====================
const Color kBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF7F8FC);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);

// =====================
// 🔥 Booking Type Enum
// =====================
enum BookingType {
  hourly,
  daily,
  capacity,
  mixed,
  display,
}

// =====================
// 🎯 Main Modal Function
// =====================
Future<void> showBookingModal({
  required BuildContext context,
  required String serviceId,
  required String serviceName,
  required String bookingTypeString, // 'hourly', 'daily', 'capacity', 'mixed'
  required Map<String, dynamic> serviceData, // Full service data from API
  required VoidCallback onSuccess,
}) async {
  // Parse booking type
  BookingType bookingType = BookingType.daily;
  switch (bookingTypeString.toLowerCase()) {
    case 'hourly':
      bookingType = BookingType.hourly;
      break;
    case 'daily':
      bookingType = BookingType.daily;
      break;
    case 'capacity':
      bookingType = BookingType.capacity;
      break;
    case 'mixed':
      bookingType = BookingType.mixed;
      break;
    case 'display':
      bookingType = BookingType.display;
      break;
  }

  // Show modal
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BookingDetailsModal(
      serviceId: serviceId,
      serviceName: serviceName,
      bookingType: bookingType,
      serviceData: serviceData,
      onSuccess: onSuccess,
    ),
  );
}

// =====================
// 📱 Booking Modal Widget
// =====================
class _BookingDetailsModal extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final BookingType bookingType;
  final Map<String, dynamic> serviceData;
  final VoidCallback onSuccess;

  const _BookingDetailsModal({
    required this.serviceId,
    required this.serviceName,
    required this.bookingType,
    required this.serviceData,
    required this.onSuccess,
  });

  @override
  State<_BookingDetailsModal> createState() => _BookingDetailsModalState();
}

class _BookingDetailsModalState extends State<_BookingDetailsModal> {
  // =====================
  // 🗓️ Form State
  // =====================
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _numberOfPeople = 1;
  bool _isFullVenue = false;
  bool _isLoading = false;
  
  // 🆕 موقع العميل (للخدمات التي تذهب للعميل)
  final _clientAddressController = TextEditingController();
  final _locationDescriptionController = TextEditingController(); // 🆕 وصف الموقع (landmark)
  String? _clientCity;
  double? _clientLat;
  double? _clientLng;
  bool _hasClientLocationSet = false;
  
  // 🆕 وصف الحجز (اختياري)
  final _bookingDescriptionController = TextEditingController();
  
  // =====================
  // 💰 Price State
  // =====================
  double? _calculatedPrice;
  Map<String, dynamic>? _priceBreakdown;

  // =====================
  // 📊 Service Constraints (from API)
  // =====================
  int? get _maxCapacity => widget.serviceData['maxCapacity'];
  int? get _minBookingHours => widget.serviceData['minBookingHours'];
  int? get _maxBookingHours => widget.serviceData['maxBookingHours'];
  List<int>? get _availableHours => (widget.serviceData['availableHours'] as List<dynamic>?)
      ?.map((e) => e as int)
      .toList();
  List<String>? get _workingDays => (widget.serviceData['workingDays'] as List<dynamic>?)
      ?.map((e) => e.toString().toLowerCase())
      .toList();
  
  // 🆕 هل الخدمة لها موقع ثابت
  bool get _hasFixedLocation => widget.serviceData['hasFixedLocation'] ?? true;

  @override
  void initState() {
    super.initState();
    // Set default date to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    // Calculate initial price
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePrice();
    });
  }

  @override
  void dispose() {
    _clientAddressController.dispose();
    _locationDescriptionController.dispose();
    _bookingDescriptionController.dispose();
    super.dispose();
  }

  // =====================
  // 📅 Date Picker
  // =====================
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate working days
      final dayName = _getDayName(picked);
      if (_workingDays != null && !_workingDays!.contains(dayName)) {
        _showErrorDialog('Service is not available on ${_capitalize(dayName)}s');
        return;
      }

      setState(() => _selectedDate = picked);
      _calculatePrice();
    }
  }

  // =====================
  // ⏰ Time Picker
  // =====================
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
            colorScheme: const ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate available hours
      if (_availableHours != null && !_availableHours!.contains(picked.hour)) {
        _showErrorDialog('Service is not operational at ${picked.hour}:00');
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

  // =====================
  // 💰 Calculate Price
  // =====================
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

    if (widget.bookingType == BookingType.hourly) {
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
        _priceBreakdown = {
          'hours': hours,
          'pricePerHour': basePrice,
          'total': total,
        };
      });
      return;
    }

    if (widget.bookingType == BookingType.capacity) {
      basePrice = (allPrices?['perPerson'] ?? 0).toDouble();
      final total = basePrice * _numberOfPeople;

      setState(() {
        _calculatedPrice = total;
        _priceBreakdown = {
          'numberOfPeople': _numberOfPeople,
          'pricePerPerson': basePrice,
          'total': total,
        };
      });
      return;
    }

    if (widget.bookingType == BookingType.mixed) {
      if (_isFullVenue) {
        basePrice = (allPrices?['perEvent'] ?? 0).toDouble();
        setState(() {
          _calculatedPrice = basePrice;
          _priceBreakdown = {
            'type': 'Full Venue',
            'total': basePrice,
          };
        });
      } else {
        basePrice = (allPrices?['perPerson'] ?? 0).toDouble();
        final total = basePrice * _numberOfPeople;
        setState(() {
          _calculatedPrice = total;
          _priceBreakdown = {
            'numberOfPeople': _numberOfPeople,
            'pricePerPerson': basePrice,
            'total': total,
          };
        });
      }
      return;
    }

    if (widget.bookingType == BookingType.daily) {
      basePrice = (allPrices?['perDay'] ?? 0).toDouble();
      setState(() {
        _calculatedPrice = basePrice;
        _priceBreakdown = {
          'type': 'Per Day',
          'total': basePrice,
        };
      });
      return;
    }

    if (widget.bookingType == BookingType.display) {
      basePrice = (allPrices?['displayPrice'] ?? 0).toDouble();
      setState(() {
        _calculatedPrice = basePrice;
        _priceBreakdown = {
          'type': 'Display',
          'total': basePrice,
        };
      });
      return;
    }
  }

  // =====================
  // ✅ Validation
  // =====================
  String? _validate() {
    if (_selectedDate == null) {
      return 'Please select a date';
    }

    // 🆕 التحقق من أيام العمل
    if (_workingDays != null && _workingDays!.isNotEmpty) {
      final dayName = _getDayName(_selectedDate!);
      if (!_workingDays!.contains(dayName)) {
        return 'Service is not available on ${_capitalize(dayName)}s';
      }
    }

    if (widget.bookingType == BookingType.hourly) {
      if (_startTime == null || _endTime == null) {
        return 'Please select start and end times';
      }

      // 🆕 التحقق من ساعات العمل
      if (_availableHours != null && _availableHours!.isNotEmpty) {
        if (!_availableHours!.contains(_startTime!.hour)) {
          return 'Service is not operational at ${_startTime!.hour}:00';
        }
        // التحقق من أن كل ساعات الحجز ضمن ساعات العمل
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

    if (widget.bookingType == BookingType.capacity || 
        (widget.bookingType == BookingType.mixed && !_isFullVenue)) {
      if (_numberOfPeople <= 0) {
        return 'Please enter number of people';
      }

      if (_maxCapacity != null && _numberOfPeople > _maxCapacity!) {
        return 'Maximum capacity is $_maxCapacity people';
      }
    }

    // 🆕 التحقق من موقع العميل إذا الخدمة بدون موقع ثابت
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

  // =====================
  // 🚀 Submit Booking
  // =====================
  Future<void> _submitBooking() async {
    final error = _validate();
    if (error != null) {
      _showErrorDialog(error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare booking details based on type
      final bookingDetails = <String, dynamic>{
        'date': _selectedDate!.toIso8601String(),
      };

      if (widget.bookingType == BookingType.hourly) {
        bookingDetails['startHour'] = _startTime!.hour;
        bookingDetails['endHour'] = _endTime!.hour;
      }

      if (widget.bookingType == BookingType.capacity ||
          (widget.bookingType == BookingType.mixed && !_isFullVenue)) {
        bookingDetails['numberOfPeople'] = _numberOfPeople;
      }

      if (widget.bookingType == BookingType.mixed) {
        bookingDetails['isFullVenue'] = _isFullVenue;
      }

      // 🆕 إضافة موقع العميل إذا الخدمة بدون موقع ثابت
      if (!_hasFixedLocation) {
        bookingDetails['clientLocation'] = {
          'address': _clientAddressController.text.trim(),
          'city': _clientCity,
          'latitude': _clientLat,
          'longitude': _clientLng,
          'locationDescription': _locationDescriptionController.text.trim(), // 🆕 وصف الموقع
        };
      }

      // 🆕 إضافة وصف الحجز (اختياري)
      final description = _bookingDescriptionController.text.trim();
      if (description.isNotEmpty) {
        bookingDetails['bookingDescription'] = description;
      }

      // Call API
      final result = await AddToCartService.addToCart(
        serviceId: widget.serviceId,
        bookingDetails: bookingDetails,
      );

      if (result['success'] == true) {
        // ✅ Update local CartStore with the new item
        final cartData = result['cart'];
        if (cartData != null) {
          try {
            final cartResponse = CartResponse.fromJson(cartData);
            CartStore.instance.updateFromBackend(cartResponse.items);
          } catch (e) {
            // Fallback: add item manually to local store
            CartStore.instance.add(CartItem(
              id: widget.serviceId,
              serviceName: widget.serviceName,
              companyName: widget.serviceData['companyName']?.toString() ?? 'Provider',
              price: (widget.serviceData['price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: widget.serviceData['imageUrl']?.toString(),
            ));
          }
        } else {
          // Fallback: add item manually to local store
          CartStore.instance.add(CartItem(
            id: widget.serviceId,
            serviceName: widget.serviceName,
            companyName: widget.serviceData['companyName']?.toString() ?? 'Provider',
            price: (widget.serviceData['price'] as num?)?.toDouble() ?? 0.0,
            imageUrl: widget.serviceData['imageUrl']?.toString(),
          ));
        }
        
        setState(() => _isLoading = false);
        Navigator.pop(context);
        _showSuccessDialog();
        widget.onSuccess();
      }

    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // =====================
  // 💬 Dialogs
  // =====================
  void _showErrorDialog(String message) {
    // Check if it's a time conflict or capacity issue
    final isConflict = message.toLowerCase().contains('time slot') || 
                       message.toLowerCase().contains('fully booked') ||
                       message.toLowerCase().contains('not available') ||
                       message.toLowerCase().contains('conflict') ||
                       message.toLowerCase().contains('capacity') ||
                       message.toLowerCase().contains('booked');

    if (isConflict) {
      _showBookingConflictPopup(message);
    } else {
      // Regular error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                'Error',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kBlue),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showBookingConflictPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
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
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Booking Conflict',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Hint
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 18, color: kBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try selecting a different date or time',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Change Time',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text(
              'Success',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(
          'Added to cart successfully!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kBlue),
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // 🎨 UI Builders
  // =====================
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Book Service',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ],
                  ),

                  Text(
                    widget.serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Scrollable Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Date Picker
                        _buildDateField(),
                        const SizedBox(height: 16),

                        // Type-specific fields
                        if (widget.bookingType == BookingType.hourly) ...[
                          _buildTimeFields(),
                          const SizedBox(height: 16),
                        ],

                        if (widget.bookingType == BookingType.capacity) ...[
                          _buildCapacityField(),
                          const SizedBox(height: 16),
                        ],

                        if (widget.bookingType == BookingType.mixed) ...[
                          _buildFullVenueToggle(),
                          const SizedBox(height: 16),
                          if (!_isFullVenue) ...[
                            _buildCapacityField(),
                            const SizedBox(height: 16),
                          ],
                        ],

                        // 🆕 موقع العميل (للخدمات التي تذهب للعميل)
                        if (!_hasFixedLocation) ...[
                          _buildClientLocationField(),
                          const SizedBox(height: 16),
                        ],

                        // 🆕 وصف الحجز (اختياري - لجميع الخدمات)
                        _buildBookingDescriptionField(),
                        const SizedBox(height: 16),

                        // Price Display
                        if (_calculatedPrice != null && _calculatedPrice! > 0) ...[
                          _buildPriceDisplay(),
                          const SizedBox(height: 16),
                        ],

                        // Info Cards
                        _buildInfoCard(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kText,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black.withOpacity(0.14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_shopping_cart_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Add to Cart',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: kBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFields() {
    return Column(
      children: [
        InkWell(
          onTap: () => _pickTime(true),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: kBlue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _startTime?.format(context) ?? 'Select time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: kMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickTime(false),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: kBlue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _endTime?.format(context) ?? 'Select time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: kMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_rounded, color: kBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Number of People',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_numberOfPeople > 1) {
                    setState(() {
                      _numberOfPeople--;
                      _calculatePrice();
                    });
                  }
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBlue.withOpacity(0.20)),
                ),
                child: Text(
                  '$_numberOfPeople',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kBlue,
                  ),
                ),
              ),
              _buildCounterButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_maxCapacity == null || _numberOfPeople < _maxCapacity!) {
                    setState(() {
                      _numberOfPeople++;
                      _calculatePrice();
                    });
                  }
                },
              ),
            ],
          ),
          if (_maxCapacity != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Max capacity: $_maxCapacity people',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kBlue.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildFullVenueToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.domain_rounded, color: kBlue, size: 20),
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
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reserve the entire space',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isFullVenue,
            onChanged: (val) {
              setState(() {
                _isFullVenue = val;
                _calculatePrice();
              });
            },
            activeColor: kBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (_calculatedPrice == null || _calculatedPrice! <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBlue.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          if (_priceBreakdown != null) ...[
            if (_priceBreakdown!['hours'] != null) ...[
              _buildPriceRow(
                '${_priceBreakdown!['hours'].toStringAsFixed(1)} hours',
                '₪${_priceBreakdown!['pricePerHour'].toStringAsFixed(0)}/hour',
              ),
            ],
            if (_priceBreakdown!['numberOfPeople'] != null) ...[
              _buildPriceRow(
                '${_priceBreakdown!['numberOfPeople']} people',
                '₪${_priceBreakdown!['pricePerPerson'].toStringAsFixed(0)}/person',
              ),
            ],
            if (_priceBreakdown!['type'] != null) ...[
              _buildPriceRow(
                _priceBreakdown!['type'],
                '',
              ),
            ],
            const Divider(height: 24, thickness: 1),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: kText,
                ),
              ),
              Text(
                '₪${_calculatedPrice!.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),
        ],
      ),
    );
  }

  // 🆕 حقل موقع العميل للخدمات التي تذهب للعميل
  Widget _buildClientLocationField() {
    // قائمة المدن
    const cities = [
      'Jerusalem', 'Ramallah', 'Nablus', 'Hebron', 'Bethlehem',
      'Jenin', 'Tulkarm', 'Qalqilya', 'Jericho', 'Salfit',
      'Tubas', 'Gaza', 'Khan Yunis', 'Rafah', 'Deir al-Balah',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBlue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBlue.withOpacity(0.15), kBlue.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded, color: kBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                    Text(
                      'Where should we come to serve you?',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Required badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Required',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // City Dropdown
          Text(
            'City',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _clientCity != null ? kBlue.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                width: _clientCity != null ? 1.5 : 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _clientCity,
                hint: Text(
                  'Select your city',
                  style: GoogleFonts.poppins(fontSize: 14, color: kMuted),
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: kBlue),
                items: cities.map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(
                    city,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _clientCity = value),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Address TextField
          Text(
            'Address',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _clientAddressController.text.isNotEmpty 
                    ? kBlue.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.08),
                width: _clientAddressController.text.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _clientAddressController,
              style: GoogleFonts.poppins(fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter your full address',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: kMuted),
                prefixIcon: Icon(Icons.home_outlined, color: kBlue, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Map Location (Optional)
          Text(
            'Pin Location (Optional)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapLocationPicker(
                    initialLat: _clientLat,
                    initialLng: _clientLng,
                  ),
                ),
              );

              if (result != null && result is Map) {
                setState(() {
                  _clientLat = result['latitude'];
                  _clientLng = result['longitude'];
                  _hasClientLocationSet = true;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hasClientLocationSet 
                    ? kBlue.withOpacity(0.08) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasClientLocationSet 
                      ? kBlue 
                      : Colors.black.withOpacity(0.08),
                  width: _hasClientLocationSet ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hasClientLocationSet 
                          ? kBlue.withOpacity(0.15) 
                          : kBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _hasClientLocationSet 
                          ? Icons.check_circle_rounded 
                          : Icons.map_outlined,
                      color: _hasClientLocationSet ? kBlue : kMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasClientLocationSet 
                              ? 'Location Pinned ✓' 
                              : 'Add Map Location',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _hasClientLocationSet ? kBlue : kText,
                          ),
                        ),
                        if (_hasClientLocationSet && _clientLat != null)
                          Text(
                            '${_clientLat!.toStringAsFixed(4)}, ${_clientLng!.toStringAsFixed(4)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kMuted,
                            ),
                          )
                        else
                          Text(
                            'Tap to pin your exact location',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _hasClientLocationSet ? kBlue : kMuted,
                  ),
                ],
              ),
            ),
          ),
          
          // Clear location button
          if (_hasClientLocationSet)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _clientLat = null;
                      _clientLng = null;
                      _hasClientLocationSet = false;
                    });
                  },
                  icon: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade400),
                  label: Text(
                    'Clear location',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 14),
          
          // 🆕 Location Description (Landmark)
          Text(
            'Location Description (Optional)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _locationDescriptionController.text.isNotEmpty 
                    ? kBlue.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.08),
                width: _locationDescriptionController.text.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _locationDescriptionController,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g., Next to Halal Market, beside the mosque...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: kMuted),
                prefixIcon: Icon(Icons.place_outlined, color: kBlue, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 حقل وصف الحجز (اختياري)
  Widget _buildBookingDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Special Requests',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                    Text(
                      'Any special instructions for the provider?',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Optional badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Description TextField
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _bookingDescriptionController.text.isNotEmpty 
                    ? const Color(0xFF8B5CF6).withOpacity(0.3) 
                    : Colors.black.withOpacity(0.08),
                width: _bookingDescriptionController.text.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _bookingDescriptionController,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g., Please arrive 10 minutes early, need extra chairs...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: kMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: GoogleFonts.poppins(fontSize: 10, color: kMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final info = <String>[];

    if (widget.bookingType == BookingType.hourly) {
      if (_minBookingHours != null) {
        info.add('Min. booking: $_minBookingHours hours');
      }
      if (_maxBookingHours != null) {
        info.add('Max. booking: $_maxBookingHours hours');
      }
    }

    if (_maxCapacity != null) {
      info.add('Max capacity: $_maxCapacity people');
    }

    if (_workingDays != null && _workingDays!.isNotEmpty) {
      final days = _workingDays!.map((d) => _capitalize(d)).join(', ');
      info.add('Working days: $days');
    }

    if (info.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlue.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Service Info',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final i in info) ...[
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: kBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    i,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
              ],
            ),
            if (i != info.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  // =====================
  // 🛠️ Helper Functions
  // =====================
  String _getDayName(DateTime date) {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[date.weekday % 7];
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}