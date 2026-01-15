// lib/screens/provider/add_service/add_other_service.dart
// 🆕 صفحة ديناميكية لإضافة خدمات مخصصة (Other Category)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_common_widgets.dart';
import 'package:flutter_application_1/services/service_service.dart';
import '../../map_location_picker.dart' hide kPrimaryColor, kTextColor;

/// ✅ أنواع التسعير المتاحة
enum PricingType {
  perHour('per hour', 'Per Hour', Icons.access_time_rounded),
  perDay('per day', 'Per Day', Icons.calendar_today_rounded),
  perPerson('per person', 'Per Person', Icons.person_rounded);

  final String value;
  final String label;
  final IconData icon;
  const PricingType(this.value, this.label, this.icon);
}

/// ✅ أنواع الحجز المتاحة
enum BookingTypeOption {
  hourly('hourly', 'Hourly', Icons.schedule_rounded),
  daily('daily', 'Daily', Icons.event_rounded),
  capacity('capacity', 'Capacity', Icons.groups_rounded);

  final String value;
  final String label;
  final IconData icon;
  const BookingTypeOption(this.value, this.label, this.icon);
}

class AddOtherService extends StatefulWidget {
  const AddOtherService({super.key});

  @override
  State<AddOtherService> createState() => _AddOtherServiceState();
}

class _AddOtherServiceState extends State<AddOtherService> {
  final _formKey = GlobalKey<FormState>();

  // =====================================================
  // 📋 Basic Info Controllers
  // =====================================================
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();

  // =====================================================
  // 📍 Location Controllers
  // =====================================================
  final addressCtrl = TextEditingController();
  String? _selectedCity;
  double? _selectedLat;
  double? _selectedLng;
  bool _hasLocationSet = false;

  // =====================================================
  // 🎨 Dynamic Options
  // =====================================================
  
  /// نوع التسعير (per hour / per day / per person)
  PricingType _selectedPricingType = PricingType.perHour;
  
  /// نوع الحجز (hourly / daily / capacity)
  BookingTypeOption _selectedBookingType = BookingTypeOption.hourly;
  
  /// هل الخدمة لها موقع ثابت؟
  bool _hasFixedLocation = true;
  
  /// هل مرئية في البحث؟
  bool _visibleInSearch = true;

  // =====================================================
  // 📅 Availability (Days + Time for Hourly)
  // =====================================================
  final List<String> _weekdays = const [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday",
  ];
  final Set<String> _selectedDays = {"Friday", "Saturday", "Sunday"};
  
  TimeOfDay? _from;
  TimeOfDay? _to;

  // =====================================================
  // 👥 Capacity Options (for capacity booking)
  // =====================================================
  int _maxCapacity = 50;
  String _capacityUnit = "person"; // "person" | "piece"

  // =====================================================
  // ⏰ Hourly Options
  // =====================================================
  final minHoursCtrl = TextEditingController(text: "1");
  final maxHoursCtrl = TextEditingController(text: "8");

  // =====================================================
  // 📊 Live Pricing Preview
  // =====================================================
  double? _finalPrice;
  double? _savedAmount;

  // =====================================================
  // 🖼️ Gallery + Highlights
  // =====================================================
  Uint8List? _coverImage;
  final List<Map<String, String>> _highlights = [];

  // =====================================================
  // 🔄 State
  // =====================================================
  bool _saving = false;

  // =====================================================
  // 🎯 Lifecycle
  // =====================================================
  @override
  void initState() {
    super.initState();
    priceCtrl.addListener(_recalcPrice);
    discountCtrl.addListener(_recalcPrice);
    _recalcPrice();
  }

  @override
  void dispose() {
    priceCtrl.removeListener(_recalcPrice);
    discountCtrl.removeListener(_recalcPrice);
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    addressCtrl.dispose();
    minHoursCtrl.dispose();
    maxHoursCtrl.dispose();
    super.dispose();
  }

  // =====================================================
  // 💰 Price Calculation
  // =====================================================
  void _recalcPrice() {
    final price = double.tryParse(priceCtrl.text.trim());
    final disc = double.tryParse(discountCtrl.text.trim());

    if (price == null || price <= 0) {
      if (_finalPrice != null || _savedAmount != null) {
        setState(() {
          _finalPrice = null;
          _savedAmount = null;
        });
      }
      return;
    }

    final d = (disc ?? 0).clamp(0, 100);
    final finalP = price * (1 - d / 100.0);
    final saved = price - finalP;

    if (_finalPrice == finalP && _savedAmount == saved) return;

    setState(() {
      _finalPrice = finalP;
      _savedAmount = saved;
    });
  }

  // =====================================================
  // 🖼️ Image Picker
  // =====================================================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _coverImage = bytes);
  }

  // =====================================================
  // ✨ Highlight Dialog
  // =====================================================
  Future<void> _addHighlight() async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Add Highlight",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: InputDecoration(
                hintText: "Key (e.g. Duration, Style...)",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valCtrl,
              decoration: InputDecoration(
                hintText: "Value (e.g. 2 hours, Modern...)",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () {
              final k = keyCtrl.text.trim();
              final v = valCtrl.text.trim();
              if (k.isNotEmpty && v.isNotEmpty) {
                setState(() => _highlights.add({"key": k, "value": v}));
              }
              Navigator.pop(context);
            },
            child: Text("Add", style: GoogleFonts.poppins(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ⏰ Time Pickers
  // =====================================================
  Future<void> _pickFrom() async {
    final pick = await showTimePicker(context: context, initialTime: _from ?? const TimeOfDay(hour: 9, minute: 0));
    if (pick != null) setState(() => _from = pick);
  }

  Future<void> _pickTo() async {
    final pick = await showTimePicker(context: context, initialTime: _to ?? const TimeOfDay(hour: 22, minute: 0));
    if (pick != null) setState(() => _to = pick);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return "Select";
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $p";
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  // =====================================================
  // 💾 Save Service
  // =====================================================
  Future<void> _trySave() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // Validation
    if (_selectedDays.isEmpty) {
      _showSnack("Select at least one day");
      return;
    }

    // Time validation for hourly
    if (_selectedBookingType == BookingTypeOption.hourly) {
      if (_from == null || _to == null) {
        _showSnack("Set time range for hourly booking");
        return;
      }
      if (_toMinutes(_to!) <= _toMinutes(_from!)) {
        _showSnack("End time must be after start time");
        return;
      }
    }

    // Location validation
    if (_hasFixedLocation && (_selectedCity == null || _selectedCity!.isEmpty)) {
      _showSnack("Select a city");
      return;
    }

    // Build form data
    final form = <String, dynamic>{
      "category": "Other",
      "bookingType": _selectedBookingType.value,
      "name": nameCtrl.text.trim(),
      "description": descCtrl.text.trim(),
      "hasFixedLocation": _hasFixedLocation,
      
      // Location (only if fixed)
      if (_hasFixedLocation) ...{
        "address": addressCtrl.text.trim(),
        "city": _selectedCity,
        "latitude": _selectedLat?.toString() ?? "",
        "longitude": _selectedLng?.toString() ?? "",
      },
      
      "price": priceCtrl.text.trim(),
      "discount": discountCtrl.text.trim(),
      "priceType": _selectedPricingType.value,
      "finalPrice": _finalPrice?.toStringAsFixed(2),
      "savedAmount": _savedAmount?.toStringAsFixed(2),
      
      "coverImage": _coverImage,
      "highlights": _highlights,
      "visibleInSearch": _visibleInSearch,
      
      "days": _selectedDays.toList(),
    };

    // Add booking-type specific fields
    switch (_selectedBookingType) {
      case BookingTypeOption.hourly:
        form["pricingModel"] = "per_hour";
        form["minHours"] = minHoursCtrl.text.trim();
        form["maxHours"] = maxHoursCtrl.text.trim();
        form["timeFrom"] = _fmtTime(_from);
        form["timeTo"] = _fmtTime(_to);
        break;
        
      case BookingTypeOption.daily:
        form["pricingModel"] = "per_day";
        form["allDay"] = true;
        break;
        
      case BookingTypeOption.capacity:
        form["pricingModel"] = _capacityUnit == "piece" ? "per_piece" : "per_person";
        form["maxCapacity"] = _maxCapacity;
        form["capacityUnit"] = _capacityUnit;
        break;
    }

    setState(() => _saving = true);

    try {
      await ServiceService.addServiceFromBookingForm(form);
      if (!mounted) return;

      _showSnack("Service created successfully ✅");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Failed: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins())),
    );
  }

  // =====================================================
  // 🎨 UI Helpers
  // =====================================================
  String _day3(String d) => d.length <= 3 ? d : d.substring(0, 3);

  String _daysSummary() {
    if (_selectedDays.isEmpty) return "No days selected";
    if (_selectedDays.length == _weekdays.length) return "Every day";
    final ordered = _weekdays.where(_selectedDays.contains).toList();
    return ordered.map(_day3).join(", ");
  }

  Widget _miniTitle(String t) => Text(
    t,
    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
  );

  Widget _hint(String t) => Text(
    t,
    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
  );

  // =====================================================
  // 🏗️ Build UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: Text(
          "Add Custom Service",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kTextColor),
        ),
        leading: const BackButton(color: kTextColor),
      ),
      bottomNavigationBar: _buildSaveButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBasicInfoSection(),
              const SizedBox(height: 20),
              _buildBookingTypeSelector(),
              const SizedBox(height: 20),
              _buildPricingTypeSelector(),
              const SizedBox(height: 20),
              _buildLocationSection(),
              const SizedBox(height: 20),
              _buildPricingSection(),
              const SizedBox(height: 20),
              _buildAvailabilitySection(),
              const SizedBox(height: 20),
              // Dynamic sections based on booking type
              if (_selectedBookingType == BookingTypeOption.hourly) ...[
                _buildHourlyOptionsSection(),
                const SizedBox(height: 20),
              ],
              if (_selectedBookingType == BookingTypeOption.capacity) ...[
                _buildCapacitySection(),
                const SizedBox(height: 20),
              ],
              _buildImageSection(),
              const SizedBox(height: 20),
              _buildHighlightsSection(),
              const SizedBox(height: 20),
              _buildVisibilityToggle(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 🎯 Header Widget
  // =====================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: kPrimaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Custom Service",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Create a fully customizable service",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📝 Basic Info Section
  // =====================================================
  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.info_outline_rounded, "Basic Information"),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: nameCtrl,
            decoration: inputStyle("Service Name *"),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
          ),
          const SizedBox(height: 14),
          
          TextFormField(
            controller: descCtrl,
            maxLines: 3,
            decoration: inputStyle("Description *"),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📦 Booking Type Selector
  // =====================================================
  Widget _buildBookingTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.event_note_rounded, "Booking Type"),
          const SizedBox(height: 6),
          _hint("How do customers book this service?"),
          const SizedBox(height: 14),
          
          Row(
            children: BookingTypeOption.values.map((type) {
              final selected = _selectedBookingType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedBookingType = type),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type != BookingTypeOption.values.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? kPrimaryColor.withOpacity(0.12) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? kPrimaryColor : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          color: selected ? kPrimaryColor : Colors.grey.shade500,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? kPrimaryColor : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 💵 Pricing Type Selector
  // =====================================================
  Widget _buildPricingTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.payments_outlined, "Pricing Model"),
          const SizedBox(height: 6),
          _hint("How is the price calculated?"),
          const SizedBox(height: 14),
          
          Row(
            children: PricingType.values.map((type) {
              final selected = _selectedPricingType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPricingType = type),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type != PricingType.values.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? const Color(0xFF10B981) : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          color: selected ? const Color(0xFF10B981) : Colors.grey.shade500,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? const Color(0xFF10B981) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📍 Location Section
  // =====================================================
  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.location_on_outlined, "Service Location"),
          const SizedBox(height: 14),
          
          // Fixed Location Toggle
          _buildLocationTypeToggle(),
          
          // Show location fields only if fixed location
          if (_hasFixedLocation) ...[
            const SizedBox(height: 16),
            
            // City Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: inputStyle("City *"),
              items: kCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCity = v),
              validator: (v) => (_hasFixedLocation && (v == null || v.isEmpty)) ? "Required" : null,
            ),
            const SizedBox(height: 14),
            
            // Address
            TextFormField(
              controller: addressCtrl,
              decoration: inputStyle("Address"),
            ),
            const SizedBox(height: 14),
            
            // Map Picker Button
            _buildMapPickerButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasFixedLocation = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _hasFixedLocation ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _hasFixedLocation ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size: 18,
                      color: _hasFixedLocation ? kPrimaryColor : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Fixed Location",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _hasFixedLocation ? kPrimaryColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasFixedLocation = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_hasFixedLocation ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_hasFixedLocation ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delivery_dining_rounded,
                      size: 18,
                      color: !_hasFixedLocation ? const Color(0xFFF59E0B) : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Go to Client",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_hasFixedLocation ? const Color(0xFFF59E0B) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPickerButton() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MapLocationPicker()),
        );
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _selectedLat = result['latitude'];
            _selectedLng = result['longitude'];
            _hasLocationSet = true;
            if (result['address'] != null) {
              addressCtrl.text = result['address'];
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _hasLocationSet ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasLocationSet ? const Color(0xFF10B981) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _hasLocationSet ? Icons.check_circle_rounded : Icons.map_outlined,
              color: _hasLocationSet ? const Color(0xFF10B981) : kPrimaryColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasLocationSet
                    ? "Location set (${_selectedLat?.toStringAsFixed(4)}, ${_selectedLng?.toStringAsFixed(4)})"
                    : "Pick location on map",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hasLocationSet ? const Color(0xFF10B981) : kTextColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 💰 Pricing Section
  // =====================================================
  Widget _buildPricingSection() {
    final priceLabel = "Price (${_selectedPricingType.label}) *";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.attach_money_rounded, "Pricing"),
          const SizedBox(height: 14),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputStyle(priceLabel),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    final p = double.tryParse(v.trim());
                    if (p == null || p <= 0) return "Invalid";
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputStyle("Discount %"),
                ),
              ),
            ],
          ),
          
          // Live Price Preview
          if (_finalPrice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF10B981).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Final Price",
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          "\$${_finalPrice!.toStringAsFixed(2)} ${_selectedPricingType.label}",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_savedAmount != null && _savedAmount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Save \$${_savedAmount!.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
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

  // =====================================================
  // 📅 Availability Section
  // =====================================================
  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.calendar_month_rounded, "Available Days"),
          const SizedBox(height: 6),
          _hint("Select which days this service is available"),
          const SizedBox(height: 14),
          _buildDaySelector(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 16, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  _daysSummary(),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final row1 = _weekdays.take(4).toList();
    final row2 = _weekdays.skip(4).take(3).toList();

    Widget buildRow(List<String> days, {bool addEmptyLast = false}) {
      return Row(
        children: [
          for (int i = 0; i < days.length; i++) ...[
            Expanded(child: SizedBox(height: 36, child: _buildDayChip(days[i]))),
            if (i != days.length - 1) const SizedBox(width: 8),
          ],
          if (addEmptyLast) ...[
            const SizedBox(width: 8),
            const Expanded(child: SizedBox(height: 36)),
          ],
        ],
      );
    }

    return Column(
      children: [
        buildRow(row1),
        const SizedBox(height: 8),
        buildRow(row2, addEmptyLast: true),
      ],
    );
  }

  Widget _buildDayChip(String d) {
    final selected = _selectedDays.contains(d);

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      selectedColor: kPrimaryColor.withOpacity(0.14),
      backgroundColor: const Color(0xFFF9FAFB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      label: SizedBox(
        height: 20,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _day3(d),
              maxLines: 1,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      onSelected: (_) {
        setState(() {
          if (selected) {
            _selectedDays.remove(d);
          } else {
            _selectedDays.add(d);
          }
        });
      },
    );
  }

  // =====================================================
  // ⏰ Hourly Options Section
  // =====================================================
  Widget _buildHourlyOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.schedule_rounded, "Hourly Options"),
          const SizedBox(height: 14),
          
          // Time Range
          Row(
            children: [
              Expanded(
                child: _buildTimePicker("From", _from, _pickFrom),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePicker("To", _to, _pickTo),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Min/Max Hours
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: minHoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputStyle("Min Hours"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: maxHoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputStyle("Max Hours"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: kPrimaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  Text(
                    _fmtTime(time),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 👥 Capacity Section
  // =====================================================
  Widget _buildCapacitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.groups_rounded, "Capacity Options"),
          const SizedBox(height: 14),
          
          // Unit Type Selector
          _buildCapacityUnitSelector(),
          const SizedBox(height: 14),
          
          // Capacity Stepper
          _buildCapacityStepper(),
        ],
      ),
    );
  }

  Widget _buildCapacityUnitSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _capacityUnit = "person"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _capacityUnit == "person" ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _capacityUnit == "person" ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: _capacityUnit == "person" ? kPrimaryColor : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Per Person",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _capacityUnit == "person" ? kPrimaryColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _capacityUnit = "piece"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _capacityUnit == "piece" ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _capacityUnit == "piece" ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 18,
                      color: _capacityUnit == "piece" ? kPrimaryColor : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Per Piece",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _capacityUnit == "piece" ? kPrimaryColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityStepper() {
    final unitLabel = _capacityUnit == "piece" ? "pieces" : "people";
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_rounded, color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Maximum $unitLabel",
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          _buildStepperButton(Icons.remove_rounded, () {
            if (_maxCapacity > 1) setState(() => _maxCapacity--);
          }),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              "$_maxCapacity",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          _buildStepperButton(Icons.add_rounded, () {
            if (_maxCapacity < 1000) setState(() => _maxCapacity++);
          }),
        ],
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
        ),
        child: Icon(icon, color: kPrimaryColor, size: 20),
      ),
    );
  }

  // =====================================================
  // 🖼️ Image Section
  // =====================================================
  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.image_rounded, "Cover Image"),
          const SizedBox(height: 14),
          
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _coverImage != null ? kPrimaryColor : Colors.grey.shade200,
                  width: _coverImage != null ? 2 : 1,
                ),
              ),
              child: _coverImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_coverImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded, color: kPrimaryColor, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tap to upload image",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ✨ Highlights Section
  // =====================================================
  Widget _buildHighlightsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader(Icons.auto_awesome_rounded, "Highlights"),
              const Spacer(),
              TextButton.icon(
                onPressed: _addHighlight,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text("Add", style: GoogleFonts.poppins(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _hint("Key features of your service"),
          
          if (_highlights.isEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "No highlights added yet",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _highlights.asMap().entries.map((entry) {
                final idx = entry.key;
                final h = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${h['key']}: ${h['value']}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _highlights.removeAt(idx)),
                        child: Icon(Icons.close_rounded, size: 14, color: kPrimaryColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // 👁️ Visibility Toggle
  // =====================================================
  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _visibleInSearch ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: kPrimaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Visible in Search",
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  "Make this service discoverable",
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: _visibleInSearch,
            onChanged: (v) => setState(() => _visibleInSearch = v),
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 💾 Save Button
  // =====================================================
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _saving ? null : _trySave,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "Create Service",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 🔧 Section Header Widget
  // =====================================================
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kTextColor,
          ),
        ),
      ],
    );
  }
}
