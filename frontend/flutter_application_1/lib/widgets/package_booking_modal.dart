// lib/widgets/package_booking_modal.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/package_service/package_service.dart';
import 'package:flutter_application_1/services/package_service/add_to_cart_packages.dart';

const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kDanger = Color(0xFFEF4444);

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
        ),
    };
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
      final data = entry.value;
      
      if (data.date == null) continue;
      
      switch (data.bookingType.toLowerCase()) {
        case 'hourly':
          if (data.startHour != null && data.endHour != null) {
            final hours = data.endHour! - data.startHour!;
            total += data.newPrice * hours;
          }
          break;
          
        case 'capacity':
          if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
            total += data.newPrice * data.numberOfPeople!;
          }
          break;
          
        case 'daily':
          if (data.endDate != null) {
            final days = data.endDate!.difference(data.date!).inDays + 1;
            total += data.newPrice * days.clamp(1, double.infinity.toInt());
          }
          break;
          
        case 'mixed':
          if (data.isFullVenue == true) {
            total += data.newPrice;
          } else if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
            total += data.newPrice * data.numberOfPeople!;
          }
          break;
          
        default:
          total += data.newPrice;
      }
    }
    
    return total;
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
      return PackageServiceBooking(
        serviceId: data.serviceId,
        bookingDetails: BookingDetailsForPackage(
          date: data.date!.toIso8601String(),
          startHour: data.startHour,
          endHour: data.endHour,
          numberOfPeople: data.numberOfPeople,
        ),
      );
    }).toList();

    Navigator.pop(context, bookings);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalPrice = _calculateTotalPrice();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                            const SizedBox(height: 2),
                            Text(
                              widget.package.packageName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: kMuted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: widget.package.services.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final service = widget.package.services[i];
                        final data = _bookingData[service.serviceId]!;
                        final error = _errors[service.serviceId];

                        return _ServiceBookingCard(
                          service: service,
                          data: data,
                          error: error,
                          onDatePick: () => _pickDate(service.serviceId),
                          onEndDatePick: () => _pickEndDate(service.serviceId),
                          onUpdate: () => setState(() {}),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: kBrandBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Total Price',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                        ),
                        Text(
                          '₪${totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: kBrandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isValidating ? null : _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isValidating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isValidating ? 'Validating...' : 'Add to Cart',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
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
}

/// 🎴 Service Booking Card
class _ServiceBookingCard extends StatelessWidget {
  final PackageServiceItem service;
  final _ServiceBookingData data;
  final String? error;
  final VoidCallback onDatePick;
  final VoidCallback onEndDatePick;
  final VoidCallback onUpdate;

  const _ServiceBookingCard({
    required this.service,
    required this.data,
    this.error,
    required this.onDatePick,
    required this.onEndDatePick,
    required this.onUpdate,
  });

  double _calculateServicePrice() {
    switch (data.bookingType.toLowerCase()) {
      case 'hourly':
        if (data.startHour != null && data.endHour != null) {
          final hours = data.endHour! - data.startHour!;
          return data.newPrice * hours;
        }
        return data.newPrice;
        
      case 'capacity':
        if (data.numberOfPeople != null && data.numberOfPeople! > 0) {
          return data.newPrice * data.numberOfPeople!;
        }
        return data.newPrice;
        
      case 'daily':
        if (data.date != null && data.endDate != null) {
          final days = data.endDate!.difference(data.date!).inDays + 1;
          return data.newPrice * days.clamp(1, double.infinity.toInt());
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
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error != null ? kDanger : kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: kBrandBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: kText,
                      ),
                    ),
                    Text(
                      service.category,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₪${servicePrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: kBrandBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          InkWell(
            onTap: onDatePick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: kBrandBlue, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.date == null
                          ? 'Select booking date'
                          : DateFormat('MMM d, yyyy').format(data.date!),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: data.date == null ? kMuted : kText,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: kMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          _buildDynamicInputs(context),

          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: kDanger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kDanger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicInputs(BuildContext context) {
    switch (service.bookingType.toLowerCase()) {
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
    return Row(
      children: [
        Expanded(
          child: _TimeDropdown(
            label: 'Start',
            value: data.startHour,
            onChanged: (v) {
              data.startHour = v;
              onUpdate();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TimeDropdown(
            label: 'End',
            value: data.endHour,
            onChanged: (v) {
              data.endHour = v;
              onUpdate();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityInputs(BuildContext context) {
    return _NumberInput(
      label: 'Number of People',
      value: data.numberOfPeople,
      max: service.maxCapacity,
      onChanged: (v) {
        data.numberOfPeople = v;
        onUpdate();
      },
    );
  }

  Widget _buildDailyInputs(BuildContext context) {
    return InkWell(
      onTap: onEndDatePick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: kBrandBlue, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.endDate == null
                    ? 'Select end date'
                    : DateFormat('MMM d, yyyy').format(data.endDate!),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: data.endDate == null ? kMuted : kText,
                ),
              ),
            ),
            if (data.date != null && data.endDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${data.endDate!.difference(data.date!).inDays + 1} days',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: kBrandBlue,
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
        Row(
          children: [
            Checkbox(
              value: data.isFullVenue ?? false,
              onChanged: (v) {
                data.isFullVenue = v;
                if (v == true) data.numberOfPeople = null;
                onUpdate();
              },
              activeColor: kBrandBlue,
            ),
            Expanded(
              child: Text(
                'Book Full Venue',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: kText,
                ),
              ),
            ),
          ],
        ),
        if (data.isFullVenue != true) ...[
          const SizedBox(height: 8),
          _NumberInput(
            label: 'Number of People',
            value: data.numberOfPeople,
            max: service.maxCapacity,
            onChanged: (v) {
              data.numberOfPeople = v;
              onUpdate();
            },
          ),
        ],
      ],
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: value,
              hint: Text(
                '--:--',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
              items: List.generate(24, (i) => i)
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: kText,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  final String label;
  final int? value;
  final int? max;
  final ValueChanged<int?> onChanged;

  const _NumberInput({
    required this.label,
    required this.value,
    this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value?.toString() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kMuted,
              ),
            ),
            if (max != null) ...[
              const SizedBox(width: 6),
              Text(
                '(max: $max)',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: kText,
          ),
          decoration: InputDecoration(
            hintText: 'Enter number',
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: kMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
          ),
          onChanged: (text) {
            final parsed = int.tryParse(text);
            onChanged(parsed);
          },
        ),
      ],
    );
  }
}

class _ServiceBookingData {
  final String serviceId;
  final String serviceName;
  final String bookingType;
  final int? maxHours;
  final int? maxCapacity;
  final double newPrice;

  DateTime? date;
  DateTime? endDate;
  int? startHour;
  int? endHour;
  int? numberOfPeople;
  bool? isFullVenue;

  _ServiceBookingData({
    required this.serviceId,
    required this.serviceName,
    required this.bookingType,
    this.maxHours,
    this.maxCapacity,
    required this.newPrice,
  });
}