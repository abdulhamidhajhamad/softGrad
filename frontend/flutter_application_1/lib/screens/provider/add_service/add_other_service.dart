// lib/screens/provider/add_service/add_other_service.dart
// 🆕 صفحة ديناميكية لإضافة خدمات مخصصة (Other Category)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'booking_common_widgets.dart';
import 'package:flutter_application_1/services/service_service.dart';
import '../../map_location_picker.dart' hide kPrimaryColor, kTextColor;

// ─────────────────────────────────────────────────────────────
// 🎨 Design Tokens (Web Layout)
// ─────────────────────────────────────────────────────────────
const Color _kPrimaryColor = Color(0xFF6C63FF);
const Color _kPrimaryLight = Color(0xFFE8E6FF);
const Color _kBackgroundColor = Color(0xFFF8F9FC);
const Color _kCardColor = Colors.white;
const Color _kTextPrimary = Color(0xFF1A1D29);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kSuccessColor = Color(0xFF10B981);
const Color _kWarningColor = Color(0xFFF59E0B);
const Color _kDangerColor = Color(0xFFEF4444);

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
  // 🖼️ Gallery + Additional Info
  // =====================================================
  // ✅ Multi-media gallery (up to 10 images/videos)
  final List<MediaItem> _mediaItems = [];
  static const int _maxMediaItems = 10;
  final List<Map<String, String>> _additionalInfo = [];

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
  Future<void> _pickImages() async {
    if (_mediaItems.length >= _maxMediaItems) {
      _showSnack("You can't upload more than $_maxMediaItems items");
      return;
    }

    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    final remainingSlots = _maxMediaItems - _mediaItems.length;
    final filesToAdd = files.take(remainingSlots).toList();

    if (files.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Only $remainingSlots more items can be added. Some images were skipped.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    for (final file in filesToAdd) {
      final bytes = await file.readAsBytes();
      setState(() {
        _mediaItems.add(MediaItem(
          bytes: bytes,
          isVideo: false,
          fileName: file.name,
        ));
      });
    }
  }

  Future<void> _pickVideo() async {
    if (_mediaItems.length >= _maxMediaItems) {
      _showSnack("You can't upload more than $_maxMediaItems items");
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _mediaItems.add(MediaItem(
        bytes: bytes,
        isVideo: true,
        fileName: file.name,
      ));
    });
  }

  void _removeMediaItem(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  // =====================================================
  // ✨ Additional Info Methods
  // =====================================================
  Future<void> _addAdditionalInfo() async {
    final result = await showAddInfoDialog(context);
    if (result != null) {
      setState(() => _additionalInfo.add(result));
    }
  }

  void _removeAdditionalInfo(int index) {
    setState(() => _additionalInfo.removeAt(index));
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
      
      // ✅ Multi-media: send list of media items
      "mediaItems": _mediaItems.map((item) => {
        "bytes": item.bytes,
        "isVideo": item.isVideo,
        "fileName": item.fileName,
      }).toList(),
      // ✅ Cover image is the first image (for backwards compatibility)
      "coverImage": _mediaItems.isNotEmpty && !_mediaItems.first.isVideo 
          ? _mediaItems.first.bytes 
          : null,
      "highlights": _additionalInfo,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;
        
        if (isDesktop || isTablet) {
          return _buildWebLayout(context, isDesktop);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  // =====================================================
  // 🌐 Web Layout
  // =====================================================
  Widget _buildWebLayout(BuildContext context, bool isDesktop) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: Column(
        children: [
          // Top Bar
          _buildWebTopBar(context),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: 32,
              ),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Main Form
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          // Service Info Card
                          _buildWebSectionCard(
                            title: "Service Details",
                            icon: LucideIcons.sparkles,
                            children: [
                              _buildWebTextField(
                                controller: nameCtrl,
                                label: "Service Name",
                                hint: "Enter your service name",
                                icon: LucideIcons.tag,
                                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                              ),
                              const SizedBox(height: 20),
                              _buildWebTextField(
                                controller: descCtrl,
                                label: "Description",
                                hint: "Describe your custom service...",
                                icon: LucideIcons.alignLeft,
                                maxLines: 4,
                                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Booking Type Card
                          _buildWebSectionCard(
                            title: "Booking Type",
                            icon: LucideIcons.calendar,
                            children: [
                              Text(
                                "How do customers book this service?",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildWebBookingTypeSelector(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Pricing Type Card
                          _buildWebSectionCard(
                            title: "Pricing Model",
                            icon: LucideIcons.dollarSign,
                            children: [
                              Text(
                                "How is the price calculated?",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildWebPricingTypeSelector(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Location Card
                          _buildWebSectionCard(
                            title: "Service Location",
                            icon: LucideIcons.mapPin,
                            children: [
                              _buildWebLocationTypeToggle(),
                              if (_hasFixedLocation) ...[
                                const SizedBox(height: 20),
                                _buildWebDropdown(
                                  label: "City",
                                  value: _selectedCity,
                                  items: kCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) => setState(() => _selectedCity = v),
                                ),
                                const SizedBox(height: 16),
                                _buildWebTextField(
                                  controller: addressCtrl,
                                  label: "Address",
                                  hint: "Enter street address",
                                  icon: LucideIcons.home,
                                ),
                                const SizedBox(height: 16),
                                _buildWebMapPicker(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Pricing Card
                          _buildWebSectionCard(
                            title: "Pricing",
                            icon: LucideIcons.coins,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildWebTextField(
                                      controller: priceCtrl,
                                      label: "Price (${_selectedPricingType.label})",
                                      hint: "0.00",
                                      icon: LucideIcons.dollarSign,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return "Required";
                                        final p = double.tryParse(v.trim());
                                        if (p == null || p <= 0) return "Invalid";
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildWebTextField(
                                      controller: discountCtrl,
                                      label: "Discount",
                                      hint: "0",
                                      icon: LucideIcons.percent,
                                      keyboardType: TextInputType.number,
                                      suffix: "%",
                                    ),
                                  ),
                                ],
                              ),
                              if (_finalPrice != null) ...[
                                const SizedBox(height: 20),
                                _buildWebPricePreview(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Availability Card
                          _buildWebSectionCard(
                            title: "Available Days",
                            icon: LucideIcons.calendarDays,
                            children: [
                              Text(
                                "Select which days this service is available",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _weekdays.map((day) => _buildWebDayChip(day)).toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildWebDaysSummary(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Dynamic sections based on booking type
                          if (_selectedBookingType == BookingTypeOption.hourly) ...[
                            _buildWebSectionCard(
                              title: "Hourly Options",
                              icon: LucideIcons.clock,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildWebTimePicker("From", _from, _pickFrom),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildWebTimePicker("To", _to, _pickTo),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildWebTextField(
                                        controller: minHoursCtrl,
                                        label: "Min Hours",
                                        hint: "1",
                                        icon: LucideIcons.arrowDown,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildWebTextField(
                                        controller: maxHoursCtrl,
                                        label: "Max Hours",
                                        hint: "8",
                                        icon: LucideIcons.arrowUp,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          if (_selectedBookingType == BookingTypeOption.capacity) ...[
                            _buildWebSectionCard(
                              title: "Capacity Options",
                              icon: LucideIcons.users,
                              children: [
                                _buildWebCapacityUnitSelector(),
                                const SizedBox(height: 20),
                                _buildWebCapacityStepper(),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Gallery Card
                          _buildWebSectionCard(
                            title: "Gallery",
                            icon: LucideIcons.image,
                            children: [
                              Text(
                                "Upload up to $_maxMediaItems images or videos",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              MultiMediaGalleryBox(
                                mediaItems: _mediaItems,
                                onPickImages: _pickImages,
                                onPickVideo: _pickVideo,
                                onRemove: _removeMediaItem,
                                maxItems: _maxMediaItems,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: isDesktop ? 32 : 20),
                    
                    // Right Column - Settings
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          // Quick Preview
                          _buildWebPreviewCard(),
                          const SizedBox(height: 24),
                          
                          // Additional Info
                          _buildWebSectionCard(
                            title: "Additional Info",
                            icon: LucideIcons.listPlus,
                            children: [
                              Text(
                                "Add highlights or extra details",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AdditionalInfoSection(
                                items: _additionalInfo,
                                onAdd: _addAdditionalInfo,
                                onRemove: _removeAdditionalInfo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Visibility Toggle
                          _buildWebSectionCard(
                            title: "Visibility",
                            icon: LucideIcons.eye,
                            children: [
                              _buildWebVisibilityToggle(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Tips Card
                          _buildWebTipsCard(),
                        ],
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

  // ─────────────────────────────────────────────────────────────
  // 🔝 Web Top Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: _kCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.arrowLeft, size: 20, color: _kTextPrimary),
            ),
          ),
          const SizedBox(width: 20),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryColor, _kPrimaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.sparkles, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 16),
          
          // Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Custom Service",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              Text(
                "Create a fully customizable service",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _kTextSecondary,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Save Button
          ElevatedButton.icon(
            onPressed: _saving ? null : _trySave,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.check, size: 18),
            label: Text(_saving ? "Saving..." : "Create Service"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📦 Web Section Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: _kPrimaryColor),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📝 Web Text Field
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: _kTextSecondary.withOpacity(0.6),
            ),
            prefixIcon: Icon(icon, size: 20, color: _kPrimaryColor),
            suffixText: suffix,
            filled: true,
            fillColor: _kBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDangerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📅 Web Booking Type Selector
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebBookingTypeSelector() {
    return Row(
      children: BookingTypeOption.values.map((type) {
        final selected = _selectedBookingType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedBookingType = type),
            child: Container(
              margin: EdgeInsets.only(
                right: type != BookingTypeOption.values.last ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? _kPrimaryLight : _kBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _kPrimaryColor : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type.icon,
                    color: selected ? _kPrimaryColor : _kTextSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    type.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _kPrimaryColor : _kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 💵 Web Pricing Type Selector
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebPricingTypeSelector() {
    return Row(
      children: PricingType.values.map((type) {
        final selected = _selectedPricingType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPricingType = type),
            child: Container(
              margin: EdgeInsets.only(
                right: type != PricingType.values.last ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFD1FAE5) : _kBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _kSuccessColor : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type.icon,
                    color: selected ? _kSuccessColor : _kTextSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    type.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _kSuccessColor : _kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📍 Web Location Type Toggle
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebLocationTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _kBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasFixedLocation = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _hasFixedLocation ? _kCardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _hasFixedLocation ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.store,
                      size: 20,
                      color: _hasFixedLocation ? _kPrimaryColor : _kTextSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Fixed Location",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _hasFixedLocation ? _kPrimaryColor : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasFixedLocation = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_hasFixedLocation ? _kCardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_hasFixedLocation ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.truck,
                      size: 20,
                      color: !_hasFixedLocation ? _kWarningColor : _kTextSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Go to Client",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_hasFixedLocation ? _kWarningColor : _kTextSecondary,
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

  // ─────────────────────────────────────────────────────────────
  // 🗺️ Web Map Picker
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebMapPicker() {
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hasLocationSet ? const Color(0xFFD1FAE5) : _kBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasLocationSet ? _kSuccessColor : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _hasLocationSet ? _kSuccessColor.withOpacity(0.2) : _kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _hasLocationSet ? LucideIcons.checkCircle : LucideIcons.map,
                color: _hasLocationSet ? _kSuccessColor : _kPrimaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasLocationSet ? "Location Set" : "Pick Location on Map",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasLocationSet ? _kSuccessColor : _kTextPrimary,
                    ),
                  ),
                  if (_hasLocationSet)
                    Text(
                      "${_selectedLat?.toStringAsFixed(4)}, ${_selectedLng?.toStringAsFixed(4)}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: _kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🔢 Web Dropdown
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: _kBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📅 Web Day Chip
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebDayChip(String day) {
    final selected = _selectedDays.contains(day);
    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedDays.remove(day);
          } else {
            _selectedDays.add(day);
          }
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kPrimaryColor : _kBackgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? _kPrimaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          _day3(day),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kTextSecondary,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📊 Web Days Summary
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebDaysSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.calendarCheck, size: 18, color: _kPrimaryColor),
          const SizedBox(width: 10),
          Text(
            _daysSummary(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ⏰ Web Time Picker
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.clock, color: _kPrimaryColor, size: 20),
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
                      color: _kTextSecondary,
                    ),
                  ),
                  Text(
                    _fmtTime(time),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 👥 Web Capacity Unit Selector
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebCapacityUnitSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _kBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _capacityUnit = "person"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _capacityUnit == "person" ? _kCardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _capacityUnit == "person" ? [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.user,
                      size: 20,
                      color: _capacityUnit == "person" ? _kPrimaryColor : _kTextSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Per Person",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _capacityUnit == "person" ? _kPrimaryColor : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _capacityUnit = "piece"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _capacityUnit == "piece" ? _kCardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _capacityUnit == "piece" ? [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.package,
                      size: 20,
                      color: _capacityUnit == "piece" ? _kPrimaryColor : _kTextSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Per Piece",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _capacityUnit == "piece" ? _kPrimaryColor : _kTextSecondary,
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

  // ─────────────────────────────────────────────────────────────
  // 🔢 Web Capacity Stepper
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebCapacityStepper() {
    final unitLabel = _capacityUnit == "piece" ? "pieces" : "people";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.users, color: _kPrimaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Maximum $unitLabel",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ),
          _buildWebStepperButton(LucideIcons.minus, () {
            if (_maxCapacity > 1) setState(() => _maxCapacity--);
          }),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _kCardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              "$_maxCapacity",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildWebStepperButton(LucideIcons.plus, () {
            if (_maxCapacity < 1000) setState(() => _maxCapacity++);
          }),
        ],
      ),
    );
  }

  Widget _buildWebStepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kPrimaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimaryColor.withOpacity(0.3)),
        ),
        child: Icon(icon, color: _kPrimaryColor, size: 20),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 💰 Web Price Preview
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebPricePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kSuccessColor.withOpacity(0.1),
            _kSuccessColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSuccessColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kSuccessColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.badgeDollarSign, color: _kSuccessColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Final Price",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _kTextSecondary,
                  ),
                ),
                Text(
                  "\$${_finalPrice!.toStringAsFixed(2)} ${_selectedPricingType.label}",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kSuccessColor,
                  ),
                ),
              ],
            ),
          ),
          if (_savedAmount != null && _savedAmount! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kDangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Save \$${_savedAmount!.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kDangerColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 👁️ Web Visibility Toggle
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _visibleInSearch ? _kPrimaryLight : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _visibleInSearch ? LucideIcons.eye : LucideIcons.eyeOff,
              color: _visibleInSearch ? _kPrimaryColor : _kTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Visible in Search",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                ),
                Text(
                  "Make this service discoverable",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _visibleInSearch,
            onChanged: (v) => setState(() => _visibleInSearch = v),
            activeColor: _kPrimaryColor,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🎯 Web Preview Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPrimaryColor.withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.sparkles, size: 24, color: _kPrimaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Preview",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    Text(
                      "How your service looks",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWebInfoPill(LucideIcons.tag, nameCtrl.text.isEmpty ? "Service Name" : nameCtrl.text),
          const SizedBox(height: 10),
          _buildWebInfoPill(LucideIcons.calendar, _selectedBookingType.label),
          const SizedBox(height: 10),
          _buildWebInfoPill(LucideIcons.dollarSign, _selectedPricingType.label),
          const SizedBox(height: 10),
          _buildWebInfoPill(LucideIcons.mapPin, _hasFixedLocation ? (_selectedCity ?? "City") : "Mobile"),
          const SizedBox(height: 10),
          _buildWebInfoPill(LucideIcons.calendarDays, _daysSummary()),
          if (_finalPrice != null) ...[
            const SizedBox(height: 10),
            _buildWebInfoPill(LucideIcons.coins, "\$${_finalPrice!.toStringAsFixed(2)}"),
          ],
        ],
      ),
    );
  }

  Widget _buildWebInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kPrimaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 💡 Web Tips Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildWebTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWarningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, size: 20, color: _kWarningColor),
              const SizedBox(width: 10),
              Text(
                "Quick Tips",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kWarningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWebTipItem("Use clear, descriptive names"),
          _buildWebTipItem("Add high-quality photos"),
          _buildWebTipItem("Set competitive pricing"),
          _buildWebTipItem("Choose the right booking type"),
        ],
      ),
    );
  }

  Widget _buildWebTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kWarningColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📱 Mobile Layout
  // =====================================================
  Widget _buildMobileLayout(BuildContext context) {
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
              _buildAdditionalInfoSection(),
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
          _sectionHeader(Icons.image_rounded, "Gallery"),
          const SizedBox(height: 14),
          
          MultiMediaGalleryBox(
            mediaItems: _mediaItems,
            onPickImages: _pickImages,
            onPickVideo: _pickVideo,
            onRemove: _removeMediaItem,
            maxItems: _maxMediaItems,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ✨ Additional Info Section
  // =====================================================
  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: AdditionalInfoSection(
        items: _additionalInfo,
        onAdd: _addAdditionalInfo,
        onRemove: _removeAdditionalInfo,
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
