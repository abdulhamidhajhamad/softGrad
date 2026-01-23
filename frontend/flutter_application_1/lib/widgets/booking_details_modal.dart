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
  
  // 🆕 حالة توسيع/طي قسم Working Service Info

  
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
    final priceOptions = widget.serviceData['priceOptions'] as Map<String, dynamic>?;
    
    // Parse price from string or number
    double fallbackPrice = 0;
    final rawPrice = widget.serviceData['price'];
    if (rawPrice != null) {
      if (rawPrice is num) {
        fallbackPrice = rawPrice.toDouble();
      } else if (rawPrice is String) {
        fallbackPrice = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
    }
    
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

      // Try allPrices['perHour'], priceOptions['perHour'], then fallback to main price
      basePrice = (allPrices?['perHour'] as num?)?.toDouble() 
                ?? (priceOptions?['perHour'] as num?)?.toDouble() 
                ?? fallbackPrice;
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
      basePrice = (allPrices?['perPerson'] as num?)?.toDouble() 
                ?? (priceOptions?['perPerson'] as num?)?.toDouble() 
                ?? fallbackPrice;
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
        basePrice = (allPrices?['perEvent'] as num?)?.toDouble() 
                  ?? (priceOptions?['fullVenue'] as num?)?.toDouble()
                  ?? (priceOptions?['perEvent'] as num?)?.toDouble() 
                  ?? fallbackPrice;
        setState(() {
          _calculatedPrice = basePrice;
          _priceBreakdown = {
            'type': 'Full Venue',
            'total': basePrice,
          };
        });
      } else {
        basePrice = (allPrices?['perPerson'] as num?)?.toDouble() 
                  ?? (priceOptions?['perPerson'] as num?)?.toDouble() 
                  ?? fallbackPrice;
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
      basePrice = (allPrices?['perDay'] as num?)?.toDouble() 
                ?? (priceOptions?['perDay'] as num?)?.toDouble() 
                ?? fallbackPrice;
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
      basePrice = (allPrices?['displayPrice'] as num?)?.toDouble() 
                ?? (priceOptions?['basePrice'] as num?)?.toDouble() 
                ?? fallbackPrice;
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
      // 🆕 Fetch alternatives and show smart popup
      _showSmartConflictPopup(message);
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

  // 🆕 Smart Conflict Popup with Alternatives
  void _showSmartConflictPopup(String errorMessage) async {
    // Show loading first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kBlue),
      ),
    );

    try {
      // Fetch alternative slots from API
      final alternatives = await AddToCartService.getAlternativeSlots(
        serviceId: widget.serviceId,
        date: _selectedDate!.toIso8601String(),
        startHour: _startTime?.hour,
        endHour: _endTime?.hour,
        numberOfPeople: _numberOfPeople,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        _showAlternativesDialog(errorMessage, alternatives);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      // Fallback to simple conflict popup
      _showBookingConflictPopup(errorMessage);
    }
  }

  // 🆕 Beautiful Alternatives Dialog
  void _showAlternativesDialog(String errorMessage, Map<String, dynamic> data) {
    final bookingType = data['bookingType']?.toString() ?? '';
    final alternatives = data['alternatives'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(0),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔴 Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time Slot Unavailable',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This slot is already booked',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 🟢 Alternatives Section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alternatives.isEmpty) ...[
                        // No alternatives found
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No alternatives found in the next 14 days',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // 💡 Suggestion header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Available Alternatives',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Alternative cards
                        ...alternatives.asMap().entries.map((entry) {
                          final index = entry.key;
                          final alt = entry.value as Map<String, dynamic>;
                          return _buildAlternativeCard(
                            ctx,
                            alt,
                            bookingType,
                            isFirst: index == 0,
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              
              // 🔵 Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Change Manually',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: kMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 Alternative Card Widget
  Widget _buildAlternativeCard(
    BuildContext dialogContext,
    Map<String, dynamic> alternative,
    String bookingType,
    {bool isFirst = false}
  ) {
    final dateStr = alternative['date']?.toString() ?? '';
    final dayName = alternative['dayName']?.toString() ?? '';
    final slots = alternative['availableSlots'] as List<dynamic>?;
    final availableCapacity = alternative['availableCapacity'];

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final formattedDate = date != null 
        ? DateFormat('MMM dd, yyyy').format(date)
        : dateStr;

    final isToday = date != null && 
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final isTomorrow = date != null && 
        date.difference(DateTime.now()).inDays == 0 &&
        date.day == DateTime.now().add(const Duration(days: 1)).day;

    String dayLabel = dayName;
    if (isToday) dayLabel = 'Today';
    if (isTomorrow) dayLabel = 'Tomorrow';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFF10B981).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst ? const Color(0xFF10B981).withOpacity(0.3) : Colors.grey.shade200,
          width: isFirst ? 2 : 1,
        ),
        boxShadow: isFirst ? [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Apply this alternative
            _applyAlternative(dialogContext, alternative, bookingType);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date row with badge
                Row(
                  children: [
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (isFirst) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: kBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isFirst ? const Color(0xFF10B981) : kMuted,
                    ),
                  ],
                ),
                
                // Time slots or capacity info
                if (slots != null && slots.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.take(3).map((slot) {
                      final start = slot['startHour'] as int? ?? 0;
                      final end = slot['endHour'] as int? ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: kMuted),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatHour24(start)} - ${_formatHour24(end)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                if (availableCapacity != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded, size: 14, color: kMuted),
                        const SizedBox(width: 6),
                        Text(
                          '$availableCapacity spots available',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 Apply selected alternative
  void _applyAlternative(BuildContext dialogContext, Map<String, dynamic> alternative, String bookingType) {
    Navigator.pop(dialogContext); // Close alternatives dialog

    final dateStr = alternative['date']?.toString() ?? '';
    final slots = alternative['availableSlots'] as List<dynamic>?;

    try {
      final newDate = DateTime.parse(dateStr);
      
      setState(() {
        _selectedDate = newDate;
        
        // Apply first available time slot if hourly
        if (slots != null && slots.isNotEmpty && bookingType.toLowerCase() == 'hourly') {
          final firstSlot = slots.first as Map<String, dynamic>;
          _startTime = TimeOfDay(hour: firstSlot['startHour'] as int? ?? 9, minute: 0);
          _endTime = TimeOfDay(hour: firstSlot['endHour'] as int? ?? 10, minute: 0);
        }
      });

      _calculatePrice();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Updated to ${DateFormat('MMM dd').format(newDate)}${slots != null && slots.isNotEmpty ? ' at ${_formatHour24(slots.first['startHour'] as int? ?? 9)}-${_formatHour24(slots.first['endHour'] as int? ?? 10)}' : ''}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Error applying alternative: $e');
    }
  }

  // 🆕 Format hour to 12-hour format
  String _formatHour24(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = screenWidth > 600; // Check if it's web/tablet

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: isWeb 
            ? _buildWebLayout(screenWidth, screenHeight)
            : _buildMobileLayout(),
      ),
    );
  }

  // 📱 Mobile Layout with DraggableScrollableSheet
  Widget _buildMobileLayout() {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return _buildModalContent(scrollController);
      },
    );
  }

  // 🖥️ Web Layout - Centered Dialog Style
  Widget _buildWebLayout(double screenWidth, double screenHeight) {
    final maxWidth = screenWidth > 800 ? 520.0 : screenWidth * 0.85;
    final maxHeight = screenHeight * 0.85;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: _buildModalContent(null),
      ),
    );
  }

  // 🎨 Shared Modal Content
  Widget _buildModalContent(ScrollController? scrollController) {
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

                // Price Display (in scroll area for reference)
                if (_calculatedPrice != null && _calculatedPrice! > 0) ...[
                  _buildPriceDisplay(),
                  const SizedBox(height: 16),
                ],

                // Info Cards
                _buildInfoCard(),
                
                // Extra padding at bottom for web
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 💰 Live Price Display + Action Button (Always visible at bottom)
          _buildBottomActionBar(),
        ],
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

  // 💰 Bottom Action Bar with Live Price Display
  Widget _buildBottomActionBar() {
    final hasPrice = _calculatedPrice != null && _calculatedPrice! > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: hasPrice ? kBlue.withOpacity(0.15) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💵 Live Price Display (shows when price is calculated)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: hasPrice
                ? Column(
                    children: [
                      // Price breakdown summary
                      _buildLivePriceSummary(),
                      const SizedBox(height: 12),
                      // Divider with gradient
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              kBlue.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          
          // 🛒 Action Row: Total + Add to Cart Button
          Row(
            children: [
              // Total Price Display
              if (hasPrice) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₪',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kBlue,
                            ),
                          ),
                          const SizedBox(width: 2),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: _calculatedPrice ?? 0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: kText,
                                  height: 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              // Add to Cart Button
              Expanded(
                flex: hasPrice ? 2 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kText,
                        kText.withBlue(60),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kText.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _submitBooking,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Add to Cart',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
    );
  }

  // 📊 Live Price Summary Widget
  Widget _buildLivePriceSummary() {
    if (_priceBreakdown == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kBlue.withOpacity(0.06),
            kBlue.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlue.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getPriceIcon(),
              color: kBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          
          // Price Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPriceLabel(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPriceDescription(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ],
            ),
          ),
          
          // Unit Price Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: kBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _getUnitPrice(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: kBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 Helper methods for price display
  IconData _getPriceIcon() {
    switch (widget.bookingType) {
      case BookingType.hourly:
        return Icons.schedule_rounded;
      case BookingType.daily:
        return Icons.calendar_today_rounded;
      case BookingType.capacity:
        return Icons.people_rounded;
      case BookingType.mixed:
        return _isFullVenue ? Icons.domain_rounded : Icons.people_rounded;
      case BookingType.display:
        return Icons.storefront_rounded;
    }
  }

  String _getPriceLabel() {
    switch (widget.bookingType) {
      case BookingType.hourly:
        return 'Hourly Booking';
      case BookingType.daily:
        return 'Daily Rate';
      case BookingType.capacity:
        return 'Per Person';
      case BookingType.mixed:
        return _isFullVenue ? 'Full Venue' : 'Per Person';
      case BookingType.display:
        return 'Display Price';
    }
  }

  String _getPriceDescription() {
    if (_priceBreakdown == null) return '';
    
    switch (widget.bookingType) {
      case BookingType.hourly:
        final hours = _priceBreakdown!['hours'] ?? 0;
        return '${hours.toStringAsFixed(1)} hours selected';
      case BookingType.daily:
        return '1 day selected';
      case BookingType.capacity:
        return '$_numberOfPeople ${_numberOfPeople == 1 ? 'person' : 'people'} selected';
      case BookingType.mixed:
        if (_isFullVenue) {
          return 'Entire venue booked';
        }
        return '$_numberOfPeople ${_numberOfPeople == 1 ? 'person' : 'people'} selected';
      case BookingType.display:
        return 'Fixed price';
    }
  }

  String _getUnitPrice() {
    final allPrices = widget.serviceData['allPrices'] as Map<String, dynamic>?;
    final priceOptions = widget.serviceData['priceOptions'] as Map<String, dynamic>?;
    
    // Parse price from string or number
    double fallbackPrice = 0;
    final rawPrice = widget.serviceData['price'];
    if (rawPrice != null) {
      if (rawPrice is num) {
        fallbackPrice = rawPrice.toDouble();
      } else if (rawPrice is String) {
        fallbackPrice = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
    }
    
    switch (widget.bookingType) {
      case BookingType.hourly:
        final perHour = (allPrices?['perHour'] as num?)?.toDouble() 
                      ?? (priceOptions?['perHour'] as num?)?.toDouble() 
                      ?? fallbackPrice;
        return '₪${perHour.toStringAsFixed(0)}/hr';
      case BookingType.daily:
        final perDay = (allPrices?['perDay'] as num?)?.toDouble() 
                     ?? (priceOptions?['perDay'] as num?)?.toDouble() 
                     ?? fallbackPrice;
        return '₪${perDay.toStringAsFixed(0)}/day';
      case BookingType.capacity:
        final perPerson = (allPrices?['perPerson'] as num?)?.toDouble() 
                        ?? (priceOptions?['perPerson'] as num?)?.toDouble() 
                        ?? fallbackPrice;
        return '₪${perPerson.toStringAsFixed(0)}/person';
      case BookingType.mixed:
        if (_isFullVenue) {
          final perEvent = (allPrices?['perEvent'] as num?)?.toDouble() 
                         ?? (priceOptions?['fullVenue'] as num?)?.toDouble() 
                         ?? fallbackPrice;
          return '₪${perEvent.toStringAsFixed(0)}';
        }
        final perPerson = (allPrices?['perPerson'] as num?)?.toDouble() 
                        ?? (priceOptions?['perPerson'] as num?)?.toDouble() 
                        ?? fallbackPrice;
        return '₪${perPerson.toStringAsFixed(0)}/person';
      case BookingType.display:
        final displayPrice = (allPrices?['displayPrice'] as num?)?.toDouble() 
                           ?? (priceOptions?['basePrice'] as num?)?.toDouble() 
                           ?? fallbackPrice;
        return '₪${displayPrice.toStringAsFixed(0)}';
    }
  }

  // 🆕 حقل موقع العميل للخدمات التي تذهب للعميل
  Widget _buildClientLocationField() {
    // قائمة المدن
    const cities = [
      'Nablus', 'Ramallah', 'Jerusalem', 'Hebron', 'Bethlehem',
      'Jenin', 'Tulkarm', 'Qalqilya', 'Jericho', 'Salfit',
      'Tubas', 'Gaza', 'Khan Yunis', 'Rafah', 'Deir al-Balah',
      'Al-Bireh', 'Other',
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

  // ✅ NEW: جلب timeSlots من الـ API
  List<Map<String, String>>? get _timeSlots {
    final slots = widget.serviceData['timeSlots'] as List<dynamic>?;
    if (slots == null || slots.isEmpty) return null;
    return slots.map((slot) {
      return {
        'startTime': slot['startTime']?.toString() ?? '',
        'endTime': slot['endTime']?.toString() ?? '',
      };
    }).where((slot) => slot['startTime']!.isNotEmpty && slot['endTime']!.isNotEmpty).toList();
  }

  Widget _buildInfoCard() {
    // Check if there's any info to show
    final hasBookingInfo = (_minBookingHours != null || _maxBookingHours != null || _maxCapacity != null);
    final hasWorkingDays = _workingDays != null && _workingDays!.isNotEmpty;
    final hasTimeSlots = _timeSlots != null && _timeSlots!.isNotEmpty;
    final hasAvailableHours = _availableHours != null && _availableHours!.isNotEmpty;
    
    if (!hasBookingInfo && !hasWorkingDays && !hasTimeSlots && !hasAvailableHours) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Light gray background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWorkingInfoDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: kBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Working Service Info',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      Text(
                        'Tap to view availability & rules',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kText.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Popup Window for Working Info
  void _showWorkingInfoDialog(BuildContext context) {
    final hasBookingInfo = (_minBookingHours != null || _maxBookingHours != null || _maxCapacity != null);
    final hasWorkingDays = _workingDays != null && _workingDays!.isNotEmpty;
    final hasTimeSlots = _timeSlots != null && _timeSlots!.isNotEmpty;
    final hasAvailableHours = _availableHours != null && _availableHours!.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Working Days Section
                      if (hasWorkingDays) ...[
                        _buildSectionHeader('Working Days', Icons.calendar_month_rounded),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _workingDays!.map((day) => _buildDayChip(day)).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Time Slots Section
                      if (hasTimeSlots) ...[
                        _buildSectionHeader('Available Time Slots', Icons.schedule_rounded),
                        const SizedBox(height: 12),
                        ..._timeSlots!.map((slot) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildTimeSlotCard(slot['startTime']!, slot['endTime']!),
                        )).toList(),
                        const SizedBox(height: 24),
                      ],

                      // Available Hours Section (if no time slots)
                      if (!hasTimeSlots && hasAvailableHours) ...[
                        _buildSectionHeader('Available Hours', Icons.access_time_filled_rounded),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableHours!.map((hour) => _buildHourChip(hour)).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Booking Details Section
                      if (hasBookingInfo) ...[
                        _buildSectionHeader('Booking Rules', Icons.rule_rounded),
                        const SizedBox(height: 12),
                        
                        if (_minBookingHours != null)
                          _buildInfoDetailCard(
                            icon: Icons.timer_outlined,
                            title: 'Minimum Duration',
                            value: '$_minBookingHours hours',
                            color: const Color(0xFF2196F3),
                          ),
                        
                        if (_maxBookingHours != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildInfoDetailCard(
                              icon: Icons.timer_off_outlined,
                              title: 'Maximum Duration',
                              value: '$_maxBookingHours hours',
                              color: const Color(0xFF9C27B0),
                            ),
                          ),
                        
                        if (_maxCapacity != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildInfoDetailCard(
                              icon: Icons.people_outline_rounded,
                              title: 'Maximum Capacity',
                              value: '$_maxCapacity people',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Helper Widgets for Info Card
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kText,
          ),
        ),
      ],
    );
  }

  Widget _buildDayChip(String day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kBlue.withOpacity(0.12),
            kBlue.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: kBlue),
          const SizedBox(width: 4),
          Text(
            _capitalize(day),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourChip(int hour) {
    final timeStr = hour < 12 
        ? '${hour == 0 ? 12 : hour}:00 AM'
        : '${hour == 12 ? 12 : hour - 12}:00 PM';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBlue.withOpacity(0.15)),
      ),
      child: Text(
        timeStr,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kBlue,
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(String startTime, String endTime) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kBlue.withOpacity(0.06),
            kBlue.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlue.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 16,
              color: kBlue,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            startTime,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: kBlue.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            endTime,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ],
            ),
          ),
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
