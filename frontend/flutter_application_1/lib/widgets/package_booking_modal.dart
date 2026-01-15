// lib/widgets/package_booking_modal.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/package_service/package_service.dart';
import 'package:flutter_application_1/services/package_service/add_to_cart_packages.dart';
import 'package:flutter_application_1/screens/map_location_picker.dart' hide kPrimaryColor, kTextColor;

const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kDanger = Color(0xFFEF4444);
const Color kSuccess = Color(0xFF10B981);

// ✅ Cities List
const List<String> kCities = [
  'Nablus',
  'Ramallah',
  'Jenin',
  'Tulkarm',
  'Qalqilya',
  'Hebron',
  'Salfit',
  'Tubas',
  'Bethlehem',
];

/// 📦 Show Package Booking Modal
Future<List<PackageServiceBooking>?> showPackageBookingModal({
  required BuildContext context,
  required PackageModel package,
}) async {
  return await showModalBottomSheet<List<PackageServiceBooking>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PackageBookingModal(package: package),
  );
}

/// 📦 Package Booking Modal Widget
class PackageBookingModal extends StatefulWidget {
  final PackageModel package;

  const PackageBookingModal({super.key, required this.package});

  @override
  State<PackageBookingModal> createState() => _PackageBookingModalState();
}

class _PackageBookingModalState extends State<PackageBookingModal> {
  late final Map<String, _ServiceBookingData> _bookingData;
  final Map<String, String?> _errors = {};
  bool _isValidating = false;
  bool _showPriceBreakdown = false;

  @override
  void initState() {
    super.initState();
    _bookingData = {
      for (var service in widget.package.services)
        service.serviceId: _ServiceBookingData(
          serviceId: service.serviceId,
          serviceName: service.serviceName,
          bookingType: service.bookingType,
          maxHours: service.maxHours,
          maxCapacity: service.maxCapacity,
          newPrice: service.newPrice,
          hasFixedLocation: service.hasFixedLocation,
          workingDays: service.workingDays,
          availableHours: service.availableHours,
          minBookingHours: service.minBookingHours,
          maxBookingHours: service.maxBookingHours,
        ),
    };
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _getDayName(DateTime date) {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[date.weekday % 7];
  }

  String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  void _showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded, color: kDanger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: kText,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: kMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: kBrandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(String serviceId) async {
    final data = _bookingData[serviceId]!;
    
    final initialDate = data.date ?? _dateOnly(DateTime.now());
    final firstDate = _dateOnly(widget.package.startDate);
    final lastDate = _dateOnly(widget.package.endDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : 
                   initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandBlue,
              onPrimary: Colors.white,
              onSurface: kText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // ✅ التحقق من أيام العمل
      if (data.workingDays.isNotEmpty) {
        final dayName = _getDayName(picked);
        if (!data.workingDays.contains(dayName)) {
          final workingDaysFormatted = data.workingDays.map((d) => _capitalize(d)).join(', ');
          _showErrorPopup(
            'Day Not Available',
            '"${data.serviceName}" is not available on ${_capitalize(dayName)}s.\n\nWorking days: $workingDaysFormatted',
          );
          return;
        }
      }
      
      setState(() {
        data.date = _dateOnly(picked);
        _errors[serviceId] = null;
      });
    }
  }

  Future<void> _pickEndDate(String serviceId) async {
    final data = _bookingData[serviceId]!;
    
    if (data.date == null) {
      setState(() {
        _errors[serviceId] = 'Please select start date first';
      });
      return;
    }

    final initialDate = data.endDate ?? data.date!;
    final firstDate = data.date!;
    final lastDate = _dateOnly(widget.package.endDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : 
                   initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandBlue,
              onPrimary: Colors.white,
              onSurface: kText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        data.endDate = _dateOnly(picked);
        _errors[serviceId] = null;
      });
    }
  }

  /// ✅ Calculate dynamic total price
  double _calculateTotalPrice() {
    double total = 0.0;
    
    for (var entry in _bookingData.entries) {
      total += _calculateServicePrice(entry.value);
    }
    
    return total;
  }

  /// ✅ Calculate individual service price
  double _calculateServicePrice(_ServiceBookingData data) {
    if (data.date == null) return data.newPrice;
    
    switch (data.bookingType.toLowerCase()) {
      case 'hourly':
        if (data.startHour != null && data.endHour != null) {
          final hours = data.endHour! - data.startHour!;
          return data.newPrice * hours.clamp(1, 24);
        }
        return data.newPrice;
        
      case 'capacity':
        if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
          return data.newPrice * data.numberOfPeople!;
        }
        return data.newPrice;
        
      case 'daily':
        if (data.endDate != null) {
          final days = data.endDate!.difference(data.date!).inDays + 1;
          return data.newPrice * days.clamp(1, 365);
        }
        return data.newPrice;
        
      case 'mixed':
        if (data.isFullVenue == true) {
          return data.newPrice;
        } else if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
          return data.newPrice * data.numberOfPeople!;
        }
        return data.newPrice;
        
      default:
        return data.newPrice;
    }
  }

  /// ✅ Get price breakdown details
  List<Map<String, dynamic>> _getPriceBreakdown() {
    final breakdown = <Map<String, dynamic>>[];
    
    for (var service in widget.package.services) {
      final data = _bookingData[service.serviceId]!;
      final price = _calculateServicePrice(data);
      
      String details = '';
      switch (data.bookingType.toLowerCase()) {
        case 'hourly':
          if (data.startHour != null && data.endHour != null) {
            final hours = data.endHour! - data.startHour!;
            details = '$hours hours × ₪${data.newPrice.toStringAsFixed(0)}';
          }
          break;
        case 'capacity':
          if (data.numberOfPeople != null) {
            details = '${data.numberOfPeople} people × ₪${data.newPrice.toStringAsFixed(0)}';
          }
          break;
        case 'daily':
          if (data.date != null && data.endDate != null) {
            final days = data.endDate!.difference(data.date!).inDays + 1;
            details = '$days days × ₪${data.newPrice.toStringAsFixed(0)}';
          }
          break;
        case 'mixed':
          if (data.isFullVenue == true) {
            details = 'Full venue';
          } else if (data.numberOfPeople != null) {
            details = '${data.numberOfPeople} people × ₪${data.newPrice.toStringAsFixed(0)}';
          }
          break;
      }
      
      breakdown.add({
        'name': service.serviceName,
        'category': service.category,
        'price': price,
        'details': details,
        'hasDate': data.date != null,
      });
    }
    
    return breakdown;
  }

  void _validateAndSubmit() async {
    setState(() {
      _isValidating = true;
      _errors.clear();
    });

    bool hasErrors = false;
    for (var entry in _bookingData.entries) {
      final serviceId = entry.key;
      final data = entry.value;

      if (data.date == null) {
        _errors[serviceId] = 'Please select a date';
        hasErrors = true;
        continue;
      }

      final error = PackageCartService.validateServiceBooking(
        bookingType: data.bookingType,
        date: data.date!,
        startHour: data.startHour,
        endHour: data.endHour,
        numberOfPeople: data.numberOfPeople,
        isFullVenue: data.isFullVenue,
        maxHours: data.maxHours,
        maxCapacity: data.maxCapacity,
        hasFixedLocation: data.hasFixedLocation,
        clientCity: data.clientCity,
        clientAddress: data.clientAddress,
        locationDescription: data.locationDescription,
      );

      if (error != null) {
        _errors[serviceId] = error;
        hasErrors = true;
      }
    }

    setState(() => _isValidating = false);

    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fix the errors before continuing',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final bookings = _bookingData.values.map((data) {
      Map<String, dynamic>? clientLocation;
      
      // Add client location if service doesn't have fixed location
      if (!data.hasFixedLocation && data.clientCity != null) {
        clientLocation = {
          'address': data.clientAddress ?? '',
          'city': data.clientCity,
          'latitude': data.clientLat,
          'longitude': data.clientLng,
          'locationDescription': data.locationDescription ?? '',
        };
      }
      
      return PackageServiceBooking(
        serviceId: data.serviceId,
        bookingDetails: BookingDetailsForPackage(
          date: data.date!.toIso8601String(),
          startHour: data.startHour,
          endHour: data.endHour,
          numberOfPeople: data.numberOfPeople,
          clientLocation: clientLocation,
          bookingDescription: data.bookingDescription,
        ),
      );
    }).toList();

    Navigator.pop(context, bookings);
  }

  Future<void> _pickLocation(String serviceId) async {
    final data = _bookingData[serviceId]!;
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLat: data.clientLat,
          initialLng: data.clientLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        data.clientLat = result['latitude'];
        data.clientLng = result['longitude'];
        data.clientAddress = result['address'];
        _errors[serviceId] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalPrice = _calculateTotalPrice();
    final breakdown = _getPriceBreakdown();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                  // ===== Header =====
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kBrandBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: kBrandBlue, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Book Package',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: kText,
                                    ),
                                  ),
                                  Text(
                                    widget.package.packageName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.close_rounded, color: kMuted, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ===== Services List =====
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: widget.package.services.length,
                      itemBuilder: (_, i) {
                        final service = widget.package.services[i];
                        final data = _bookingData[service.serviceId]!;
                        final error = _errors[service.serviceId];

                        return _ServiceBookingCard(
                          index: i + 1,
                          total: widget.package.services.length,
                          service: service,
                          data: data,
                          error: error,
                          onDatePick: () => _pickDate(service.serviceId),
                          onEndDatePick: () => _pickEndDate(service.serviceId),
                          onUpdate: () => setState(() {}),
                          onPickLocation: () => _pickLocation(service.serviceId),
                        );
                      },
                    ),
                  ),

                  // ===== Price Summary with Expandable Breakdown =====
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                      border: Border(top: BorderSide(color: kBorder)),
                    ),
                    child: Column(
                      children: [
                        // Price breakdown (expandable)
                        InkWell(
                          onTap: () => setState(() => _showPriceBreakdown = !_showPriceBreakdown),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kBrandBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: kBrandBlue, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Price',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: kMuted,
                                            ),
                                          ),
                                          Text(
                                            '₪${totalPrice.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: kBrandBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: kBrandBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _showPriceBreakdown ? 'Hide' : 'Details',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: kBrandBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _showPriceBreakdown 
                                                ? Icons.keyboard_arrow_up_rounded 
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: kBrandBlue,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Expandable breakdown
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    children: [
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: kBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: breakdown.map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    item['hasDate'] ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                                    size: 14,
                                                    color: item['hasDate'] ? kSuccess : kMuted,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item['name'],
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w700,
                                                            color: kText,
                                                          ),
                                                        ),
                                                        if (item['details'].isNotEmpty)
                                                          Text(
                                                            item['details'],
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: kMuted,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '₪${(item['price'] as double).toStringAsFixed(0)}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: kBrandBlue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  crossFadeState: _showPriceBreakdown 
                                      ? CrossFadeState.showSecond 
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 200),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // Add to Cart button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isValidating ? null : _validateAndSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBrandBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isValidating
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
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
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
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
}

/// 🎴 Service Booking Card
class _ServiceBookingCard extends StatefulWidget {
  final int index;
  final int total;
  final PackageServiceItem service;
  final _ServiceBookingData data;
  final String? error;
  final VoidCallback onDatePick;
  final VoidCallback onEndDatePick;
  final VoidCallback onUpdate;
  final VoidCallback onPickLocation;

  const _ServiceBookingCard({
    required this.index,
    required this.total,
    required this.service,
    required this.data,
    this.error,
    required this.onDatePick,
    required this.onEndDatePick,
    required this.onUpdate,
    required this.onPickLocation,
  });

  @override
  State<_ServiceBookingCard> createState() => _ServiceBookingCardState();
}

class _ServiceBookingCardState extends State<_ServiceBookingCard> {
  bool _isExpanded = true;

  double _calculateServicePrice() {
    final data = widget.data;
    if (data.date == null) return data.newPrice;
    
    switch (data.bookingType.toLowerCase()) {
      case 'hourly':
        if (data.startHour != null && data.endHour != null) {
          final hours = data.endHour! - data.startHour!;
          return data.newPrice * hours.clamp(1, 24);
        }
        return data.newPrice;
        
      case 'capacity':
        if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
          return data.newPrice * data.numberOfPeople!;
        }
        return data.newPrice;
        
      case 'daily':
        if (data.endDate != null) {
          final days = data.endDate!.difference(data.date!).inDays + 1;
          return data.newPrice * days.clamp(1, 365);
        }
        return data.newPrice;
        
      case 'mixed':
        if (data.isFullVenue == true) {
          return data.newPrice;
        } else if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
          return data.newPrice * data.numberOfPeople!;
        }
        return data.newPrice;
        
      default:
        return data.newPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicePrice = _calculateServicePrice();
    final hasError = widget.error != null;
    final isComplete = widget.data.date != null && !hasError;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError ? kDanger.withOpacity(0.5) : 
                 isComplete ? kSuccess.withOpacity(0.3) : kBorder,
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isComplete ? kSuccess.withOpacity(0.05) : 
                       hasError ? kDanger.withOpacity(0.05) : kBg,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(17),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(17),
                ),
              ),
              child: Row(
                children: [
                  // Index badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isComplete ? kSuccess : 
                             hasError ? kDanger : kBrandBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isComplete 
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text(
                              '${widget.index}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Service info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: kText,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kBrandBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.service.category,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  color: kBrandBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getBookingTypeLabel(widget.service.bookingType),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kBrandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₪${servicePrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: kBrandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: kMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // Date picker
          _buildDatePicker(),
          
          const SizedBox(height: 12),
          
          // Type-specific inputs
          _buildDynamicInputs(context),
          
          // Location section (if service doesn't have fixed location)
          if (!widget.data.hasFixedLocation) ...[
            const SizedBox(height: 12),
            _buildLocationSection(),
          ],
          
          // Booking description (optional)
          const SizedBox(height: 12),
          _buildDescriptionField(),
          
          // Error message
          if (widget.error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDanger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: kDanger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kDanger,
                      ),
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: widget.onDatePick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrandBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: kBrandBlue, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Date',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  Text(
                    widget.data.date == null
                        ? 'Select date'
                        : DateFormat('EEEE, MMM d, yyyy').format(widget.data.date!),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: widget.data.date == null ? kMuted : kText,
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

  Widget _buildDynamicInputs(BuildContext context) {
    switch (widget.service.bookingType.toLowerCase()) {
      case 'hourly':
        return _buildHourlyInputs(context);
      case 'capacity':
        return _buildCapacityInputs(context);
      case 'daily':
        return _buildDailyInputs(context);
      case 'mixed':
        return _buildMixedInputs(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHourlyInputs(BuildContext context) {
    return Column(
      children: [
        // Start Time
        InkWell(
          onTap: () => _pickTime(context, true),
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
                    color: kBrandBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: kBrandBlue, size: 20),
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
                        widget.data.startHour != null
                            ? '${widget.data.startHour!.toString().padLeft(2, '0')}:00'
                            : 'Select time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: widget.data.startHour != null ? kText : kMuted,
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
        // End Time
        InkWell(
          onTap: () => _pickTime(context, false),
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
                    color: kBrandBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: kBrandBlue, size: 20),
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
                        widget.data.endHour != null
                            ? '${widget.data.endHour!.toString().padLeft(2, '0')}:00'
                            : 'Select time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: widget.data.endHour != null ? kText : kMuted,
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
        // Duration indicator
        if (widget.data.startHour != null && widget.data.endHour != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: kSuccess),
                  const SizedBox(width: 6),
                  Text(
                    '${(widget.data.endHour! - widget.data.startHour!).clamp(1, 24)} hours selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialHour = isStart 
        ? (widget.data.startHour ?? 9) 
        : (widget.data.endHour ?? 17);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // ✅ التحقق من ساعات العمل
      if (widget.data.availableHours.isNotEmpty) {
        if (!widget.data.availableHours.contains(picked.hour)) {
          final hoursFormatted = widget.data.availableHours.map((h) => '${h.toString().padLeft(2, '0')}:00').join(', ');
          _showTimeErrorPopup(
            'Time Not Available',
            '"${widget.data.serviceName}" is not operational at ${picked.hour.toString().padLeft(2, '0')}:00.\n\nAvailable hours: $hoursFormatted',
          );
          return;
        }
      }
      
      // ✅ التحقق من الحد الأدنى والأقصى للساعات
      if (!isStart && widget.data.startHour != null) {
        final hours = picked.hour - widget.data.startHour!;
        
        if (hours <= 0) {
          _showTimeErrorPopup(
            'Invalid Time',
            'End time must be after start time.',
          );
          return;
        }
        
        if (widget.data.minBookingHours != null && hours < widget.data.minBookingHours!) {
          _showTimeErrorPopup(
            'Minimum Hours Required',
            '"${widget.data.serviceName}" requires a minimum of ${widget.data.minBookingHours} hours booking.',
          );
          return;
        }
        
        if (widget.data.maxBookingHours != null && hours > widget.data.maxBookingHours!) {
          _showTimeErrorPopup(
            'Maximum Hours Exceeded',
            '"${widget.data.serviceName}" allows a maximum of ${widget.data.maxBookingHours} hours booking.',
          );
          return;
        }
        
        // التحقق من أن كل الساعات ضمن ساعات العمل
        if (widget.data.availableHours.isNotEmpty) {
          for (int h = widget.data.startHour!; h < picked.hour; h++) {
            if (!widget.data.availableHours.contains(h)) {
              _showTimeErrorPopup(
                'Time Range Not Available',
                '"${widget.data.serviceName}" is not operational at ${h.toString().padLeft(2, '0')}:00.',
              );
              return;
            }
          }
        }
      }
      
      if (isStart) {
        widget.data.startHour = picked.hour;
      } else {
        widget.data.endHour = picked.hour;
      }
      widget.onUpdate();
    }
  }

  void _showTimeErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.schedule_rounded, color: kDanger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: kText,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: kMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: kBrandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityInputs(BuildContext context) {
    return _NumberInput(
      label: 'Number of People',
      icon: Icons.groups_rounded,
      value: widget.data.numberOfPeople,
      max: widget.service.maxCapacity,
      onChanged: (v) {
        widget.data.numberOfPeople = v;
        widget.onUpdate();
      },
    );
  }

  Widget _buildDailyInputs(BuildContext context) {
    return InkWell(
      onTap: widget.onEndDatePick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrandBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_rounded, color: kBrandBlue, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Date',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  Text(
                    widget.data.endDate == null
                        ? 'Select end date'
                        : DateFormat('MMM d, yyyy').format(widget.data.endDate!),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: widget.data.endDate == null ? kMuted : kText,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.data.date != null && widget.data.endDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.data.endDate!.difference(widget.data.date!).inDays + 1} days',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: kSuccess,
                  ),
                ),
              ),
            ] else
              const Icon(Icons.chevron_right_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMixedInputs(BuildContext context) {
    return Column(
      children: [
        // Full venue toggle
        InkWell(
          onTap: () {
            widget.data.isFullVenue = !(widget.data.isFullVenue ?? false);
            if (widget.data.isFullVenue == true) {
              widget.data.numberOfPeople = null;
            }
            widget.onUpdate();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.data.isFullVenue == true ? kBrandBlue.withOpacity(0.1) : kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.data.isFullVenue == true ? kBrandBlue : kBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.data.isFullVenue == true 
                      ? Icons.check_box_rounded 
                      : Icons.check_box_outline_blank_rounded,
                  color: widget.data.isFullVenue == true ? kBrandBlue : kMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Book Full Venue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: widget.data.isFullVenue == true ? kBrandBlue : kText,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Number of people (if not full venue)
        if (widget.data.isFullVenue != true) ...[
          const SizedBox(height: 10),
          _NumberInput(
            label: 'Number of People',
            icon: Icons.groups_rounded,
            value: widget.data.numberOfPeople,
            max: widget.service.maxCapacity,
            onChanged: (v) {
              widget.data.numberOfPeople = v;
              widget.onUpdate();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = widget.data.clientLat != null && widget.data.clientLng != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrandBlue.withOpacity(0.15)),
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
                    colors: [kBrandBlue.withOpacity(0.15), kBrandBlue.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: kBrandBlue, size: 22),
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
                color: widget.data.clientCity != null 
                    ? kBrandBlue.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.08),
                width: widget.data.clientCity != null ? 1.5 : 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.data.clientCity,
                hint: Text(
                  'Select your city',
                  style: GoogleFonts.poppins(fontSize: 14, color: kMuted),
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: kBrandBlue),
                items: kCities.map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(
                    city,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                )).toList(),
                onChanged: (value) {
                  widget.data.clientCity = value;
                  widget.onUpdate();
                },
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
                color: (widget.data.clientAddress?.isNotEmpty ?? false)
                    ? kBrandBlue.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.08),
                width: (widget.data.clientAddress?.isNotEmpty ?? false) ? 1.5 : 1,
              ),
            ),
            child: TextField(
              onChanged: (v) {
                widget.data.clientAddress = v;
                widget.onUpdate();
              },
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your full address',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: kMuted),
                prefixIcon: Icon(Icons.home_outlined, color: kBrandBlue, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Pin Location (Optional)
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
            onTap: widget.onPickLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasLocation 
                    ? kBrandBlue.withOpacity(0.08) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasLocation 
                      ? kBrandBlue 
                      : Colors.black.withOpacity(0.08),
                  width: hasLocation ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasLocation 
                          ? kBrandBlue.withOpacity(0.15) 
                          : kBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasLocation 
                          ? Icons.check_circle_rounded 
                          : Icons.map_outlined,
                      color: hasLocation ? kBrandBlue : kMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation 
                              ? 'Location Pinned ✓' 
                              : 'Add Map Location',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasLocation ? kBrandBlue : kText,
                          ),
                        ),
                        if (hasLocation && widget.data.clientLat != null)
                          Text(
                            '${widget.data.clientLat!.toStringAsFixed(4)}, ${widget.data.clientLng!.toStringAsFixed(4)}',
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
                    color: hasLocation ? kBrandBlue : kMuted,
                  ),
                ],
              ),
            ),
          ),
          
          // Clear location button
          if (hasLocation)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    widget.data.clientLat = null;
                    widget.data.clientLng = null;
                    widget.onUpdate();
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
          
          // Location Description (Landmark)
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
                color: (widget.data.locationDescription?.isNotEmpty ?? false)
                    ? kBrandBlue.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.08),
                width: (widget.data.locationDescription?.isNotEmpty ?? false) ? 1.5 : 1,
              ),
            ),
            child: TextField(
              onChanged: (v) {
                widget.data.locationDescription = v;
                widget.onUpdate();
              },
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Next to Halal Market, beside the mosque...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: kMuted),
                prefixIcon: Icon(Icons.place_outlined, color: kBrandBlue, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.note_alt_rounded, color: kBrandBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Notes (Optional)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) {
              widget.data.bookingDescription = v;
              widget.onUpdate();
            },
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any special requests or notes for this service...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBrandBlue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBookingTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hourly':
        return '⏰ Per Hour';
      case 'capacity':
        return '👥 Per Person';
      case 'daily':
        return '📅 Per Day';
      case 'mixed':
        return '🏛️ Venue';
      default:
        return '📦 Service';
    }
  }
}

/// Time Dropdown Widget
class _TimeDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kBrandBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              isDense: true,
              value: value,
              hint: Text(
                '--:--',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kMuted,
                ),
              ),
              items: List.generate(24, (i) => i)
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kText,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Number Input Widget
class _NumberInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? value;
  final int? max;
  final ValueChanged<int?> onChanged;

  const _NumberInput({
    required this.label,
    required this.icon,
    required this.value,
    this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBrandBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kBrandBlue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kMuted,
                      ),
                    ),
                    if (max != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(max: $max)',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: TextField(
                    controller: TextEditingController(text: value?.toString() ?? ''),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: kMuted),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      final parsed = int.tryParse(text);
                      onChanged(parsed);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Service Booking Data Model
class _ServiceBookingData {
  final String serviceId;
  final String serviceName;
  final String bookingType;
  final int? maxHours;
  final int? maxCapacity;
  final double newPrice;
  final bool hasFixedLocation;
  final List<String> workingDays;
  final List<int> availableHours;
  final int? minBookingHours;
  final int? maxBookingHours;

  DateTime? date;
  DateTime? endDate;
  int? startHour;
  int? endHour;
  int? numberOfPeople;
  bool? isFullVenue;
  
  // Client location
  String? clientAddress;
  String? clientCity;
  double? clientLat;
  double? clientLng;
  String? locationDescription;
  
  // Booking description
  String? bookingDescription;

  _ServiceBookingData({
    required this.serviceId,
    required this.serviceName,
    required this.bookingType,
    this.maxHours,
    this.maxCapacity,
    required this.newPrice,
    this.hasFixedLocation = true,
    this.workingDays = const [],
    this.availableHours = const [],
    this.minBookingHours,
    this.maxBookingHours,
  });
}