// lib/screens/provider/add_service/add_display_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'booking_common_widgets.dart';
import 'package:flutter_application_1/services/service_service.dart';
import '../../map_location_picker.dart' hide kPrimaryColor, kTextColor;

// Modern Design Tokens
const Color _kPrimaryColor = Color(0xFF6C63FF);
const Color _kPrimaryLight = Color(0xFFE8E6FF);
const Color _kBackgroundColor = Color(0xFFF8F9FC);
const Color _kCardColor = Colors.white;
const Color _kTextPrimary = Color(0xFF1A1D29);
const Color _kTextSecondary = Color(0xFF6B7280);

/// ✅ Display Service - For Flower Shops, Jewelry & Accessories, Gift & Souvenir
/// No pricing - just showcase products/services
class AddDisplayService extends StatefulWidget {
  final String category;
  final String bookingType;

  const AddDisplayService({
    super.key,
    required this.category,
    required this.bookingType,
  });

  @override
  State<AddDisplayService> createState() => _AddDisplayServiceState();
}

class _AddDisplayServiceState extends State<AddDisplayService> {
  final _formKey = GlobalKey<FormState>();

  // -----------------------------
  // Basic Info
  // -----------------------------
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // Location
  final addressCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  String? _selectedCity;
  double? _selectedLat;
  double? _selectedLng;
  bool _hasLocationSet = false;
  bool _hasFixedLocation = true;

  // Gallery (up to 10 images/videos)
  final List<MediaItem> _mediaItems = [];
  static const int _maxMediaItems = 10;

  // Additional info items (key/value pairs)
  final List<Map<String, String>> _additionalInfo = [];

  // Visibility
  bool _visibleInSearch = true;

  // Saving state
  bool _saving = false;

  // -----------------------------
  // Availability Days
  // -----------------------------
  final List<String> _weekdays = const [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  final Set<String> _selectedDays = {"Friday", "Saturday", "Sunday"};

  String _day3(String d) => d.length <= 3 ? d : d.substring(0, 3);

  String _daysSummary() {
    if (_selectedDays.isEmpty) return "No days selected";
    if (_selectedDays.length == _weekdays.length) return "Every day";
    final ordered = _weekdays.where(_selectedDays.contains).toList();
    return ordered.map(_day3).join(", ");
  }

  // -----------------------------
  // Image/Video Picker
  // -----------------------------
  Future<void> _pickImages() async {
    if (_mediaItems.length >= _maxMediaItems) return;

    final picker = ImagePicker();
    final remaining = _maxMediaItems - _mediaItems.length;

    final picked = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked.isEmpty) return;

    final toAdd = picked.take(remaining);
    for (final xf in toAdd) {
      final bytes = await xf.readAsBytes();
      if (bytes.isNotEmpty) {
        setState(() {
          _mediaItems.add(MediaItem(
            bytes: bytes,
            isVideo: false,
            fileName: xf.name,
          ));
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_mediaItems.length >= _maxMediaItems) return;

    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.isNotEmpty) {
      setState(() {
        _mediaItems.add(MediaItem(
          bytes: bytes,
          isVideo: true,
          fileName: picked.name,
        ));
      });
    }
  }

  void _removeMedia(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  // -----------------------------
  // Additional Info
  // -----------------------------
  Future<void> _addAdditionalInfo() async {
    final result = await showAddInfoDialog(context);
    if (result != null) {
      setState(() => _additionalInfo.add(result));
    }
  }

  void _removeAdditionalInfo(int index) {
    setState(() => _additionalInfo.removeAt(index));
  }

  // -----------------------------
  // Location Picker
  // -----------------------------
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLat: _selectedLat,
          initialLng: _selectedLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
        addressCtrl.text = result['address'] ?? '';
        latitudeCtrl.text = _selectedLat?.toString() ?? '';
        longitudeCtrl.text = _selectedLng?.toString() ?? '';
        _hasLocationSet = true;
      });
    }
  }

  // -----------------------------
  // Save
  // -----------------------------
  Future<void> _trySave() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Select at least one day", style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_hasFixedLocation && (_selectedCity == null || _selectedCity!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Select a city", style: GoogleFonts.poppins())),
      );
      return;
    }

    final form = {
      "category": widget.category,
      "bookingType": "display",
      "pricingModel": "per_item",
      "priceType": "display",
      "price": 0,

      "name": nameCtrl.text.trim(),
      "description": descCtrl.text.trim(),

      "hasFixedLocation": _hasFixedLocation,
      if (_hasFixedLocation) ...{
        "address": addressCtrl.text.trim(),
        "city": _selectedCity,
        "latitude": latitudeCtrl.text.trim(),
        "longitude": longitudeCtrl.text.trim(),
      },

      "days": _selectedDays.toList(),

      // Multi-media: send list of media items
      "mediaItems": _mediaItems
          .map((item) => {
                "bytes": item.bytes,
                "isVideo": item.isVideo,
                "fileName": item.fileName,
              })
          .toList(),
      // Cover image is the first image (for backwards compatibility)
      "coverImage": _mediaItems.isNotEmpty && !_mediaItems.first.isVideo
          ? _mediaItems.first.bytes
          : null,
      "highlights": _additionalInfo,
      "visibleInSearch": _visibleInSearch,
    };

    setState(() => _saving = true);

    try {
      await ServiceService.addServiceFromBookingForm(form);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Service created successfully ✅",
                style: GoogleFonts.poppins())),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e", style: GoogleFonts.poppins())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    addressCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();
    super.dispose();
  }

  // -----------------------------
  // UI Helpers
  // -----------------------------
  Widget _miniTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
      );

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _dayChip(String d) {
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
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _daysTwoRowsNeat() {
    final row1 = _weekdays.take(4).toList();
    final row2 = _weekdays.skip(4).take(3).toList();

    Widget buildRow(List<String> days, {bool addEmptyLast = false}) {
      return Row(
        children: [
          for (int i = 0; i < days.length; i++) ...[
            Expanded(child: SizedBox(height: 36, child: _dayChip(days[i]))),
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

  // Get category icon
  IconData _getCategoryIcon() {
    switch (widget.category) {
      case 'Flower Shops':
        return Icons.local_florist_outlined;
      case 'Jewelry & Accessories':
        return Icons.diamond_outlined;
      case 'Gift & Souvenir':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.storefront_rounded;
    }
  }

  // Header
  Widget _prettyHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.08),
            kPrimaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getCategoryIcon(), color: kPrimaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Showcase Your Products",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.category,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Info banner
  Widget _infoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, 
              color: Colors.amber.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This listing is for display only. Customers will contact you directly for pricing and orders.",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildWebLayout(BuildContext context, bool isDesktop) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: Column(
        children: [
          // Modern Top Bar
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: _kCardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kPrimaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.arrowLeft, color: _kPrimaryColor, size: 20),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kPrimaryColor, _kPrimaryColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.store, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Display Service",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    Text(
                      widget.category,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _trySave,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.check, size: 18),
                  label: Text(_saving ? "Saving..." : "Save Service"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.info, color: Colors.amber.shade700, size: 22),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "This listing is for display only. Customers will contact you directly for pricing and orders.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWebSectionCard(
                                    title: "Service Details",
                                    icon: LucideIcons.info,
                                    children: [
                                      _buildWebTextField(
                                        controller: nameCtrl,
                                        label: "Service / Shop Name",
                                        hint: "Enter your service name",
                                        icon: LucideIcons.tag,
                                        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildWebTextField(
                                        controller: descCtrl,
                                        label: "Description",
                                        hint: "Describe your products/services",
                                        icon: LucideIcons.fileText,
                                        maxLines: 4,
                                        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Availability Section
                                  _buildWebSectionCard(
                                    title: "Availability",
                                    icon: LucideIcons.calendar,
                                    children: [
                                      Text(
                                        "Working Days",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _kTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: _weekdays.map((d) => _buildWebDayChip(d)).toList(),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Location Section
                                  _buildWebSectionCard(
                                    title: "Location",
                                    icon: LucideIcons.mapPin,
                                    children: [
                                      Row(
                                        children: [
                                          _buildWebSelectionCard(
                                            title: "Fixed Location",
                                            subtitle: "Customers come to you",
                                            icon: LucideIcons.building2,
                                            isSelected: _hasFixedLocation,
                                            onTap: () => setState(() => _hasFixedLocation = true),
                                          ),
                                          const SizedBox(width: 16),
                                          _buildWebSelectionCard(
                                            title: "Mobile Service",
                                            subtitle: "You go to customers",
                                            icon: LucideIcons.truck,
                                            isSelected: !_hasFixedLocation,
                                            onTap: () => setState(() => _hasFixedLocation = false),
                                          ),
                                        ].map((e) => Expanded(child: e)).toList(),
                                      ),
                                      if (_hasFixedLocation) ...[
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildWebDropdown(
                                                label: "City",
                                                value: _selectedCity,
                                                items: kCities,
                                                onChanged: (v) => setState(() => _selectedCity = v),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _buildWebTextField(
                                                controller: addressCtrl,
                                                label: "Address",
                                                hint: "Street address",
                                                icon: LucideIcons.home,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildWebMapPicker(),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(width: isDesktop ? 32 : 24),
                            
                            // Right Column
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  // Gallery Card
                                  _buildWebSectionCard(
                                    title: "Gallery",
                                    icon: LucideIcons.image,
                                    children: [
                                      MultiMediaGalleryBox(
                                        mediaItems: _mediaItems,
                                        onPickImages: _pickImages,
                                        onPickVideo: _pickVideo,
                                        onRemove: _removeMedia,
                                        maxItems: _maxMediaItems,
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Additional Info Card
                                  _buildWebSectionCard(
                                    title: "Additional Info",
                                    icon: LucideIcons.listPlus,
                                    children: [
                                      AdditionalInfoSection(
                                        items: _additionalInfo,
                                        onAdd: _addAdditionalInfo,
                                        onRemove: _removeAdditionalInfo,
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Visibility Toggle
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: _kCardColor,
                                      borderRadius: BorderRadius.circular(16),
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
                                          child: Icon(
                                            _visibleInSearch ? LucideIcons.eye : LucideIcons.eyeOff,
                                            color: _kPrimaryColor,
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
                                                "Turn off if temporarily unavailable",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: _kTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: _visibleInSearch,
                                          activeColor: _kPrimaryColor,
                                          onChanged: (v) => setState(() => _visibleInSearch = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  // Web Helper Widgets
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
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
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
                child: Icon(icon, color: _kPrimaryColor, size: 20),
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

  Widget _buildWebTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
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
          style: GoogleFonts.poppins(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: _kTextSecondary),
            prefixIcon: icon != null ? Icon(icon, color: _kPrimaryColor, size: 20) : null,
            suffixText: suffix,
            suffixStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _kTextSecondary),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryLight : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kPrimaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? _kPrimaryColor : _kTextSecondary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _kPrimaryColor : _kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.checkCircle2, color: _kPrimaryColor, size: 22),
          ],
        ),
      ),
    );
  }

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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kPrimaryColor : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kPrimaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          _day3(day),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildWebDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text("Select $label", style: GoogleFonts.poppins(fontSize: 13, color: _kTextSecondary)),
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 18),
              items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebMapPicker() {
    return InkWell(
      onTap: _openMapPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hasLocationSet ? _kPrimaryLight.withOpacity(0.5) : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hasLocationSet ? _kPrimaryColor : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              _hasLocationSet ? LucideIcons.mapPin : LucideIcons.map,
              color: _kPrimaryColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasLocationSet
                    ? "Lat: ${_selectedLat?.toStringAsFixed(4)}, Lng: ${_selectedLng?.toStringAsFixed(4)}"
                    : "Pick location on map",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hasLocationSet ? _kPrimaryColor : _kTextSecondary,
                ),
              ),
            ),
            if (_hasLocationSet)
              InkWell(
                onTap: () => setState(() {
                  _selectedLat = null;
                  _selectedLng = null;
                  _hasLocationSet = false;
                }),
                child: const Icon(LucideIcons.x, color: _kPrimaryColor, size: 18),
              )
            else
              const Icon(LucideIcons.chevronRight, color: _kTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: Text("Add Service",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: const BackButton(color: kTextColor),
      ),
      bottomNavigationBar: _saving
          ? Container(
              padding: const EdgeInsets.all(16),
              child: const LinearProgressIndicator(),
            )
          : saveButton(_trySave),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _prettyHeader(),
              _infoBanner(),

              // ─────────────────────────────
              // 1. Service Details
              // ─────────────────────────────
              sectionLabel("Service Details"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: inputStyle("Service / Shop Name"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: inputStyle("Description"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                  ],
                ),
              ),

              // ─────────────────────────────
              // 2. Gallery
              // ─────────────────────────────
              sectionLabel("Gallery"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: MultiMediaGalleryBox(
                  mediaItems: _mediaItems,
                  onPickImages: _pickImages,
                  onPickVideo: _pickVideo,
                  onRemove: _removeMedia,
                  maxItems: _maxMediaItems,
                ),
              ),

              // ─────────────────────────────
              // 3. Availability (Days)
              // ─────────────────────────────
              sectionLabel("Availability"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniTitle("Open Days"),
                    const SizedBox(height: 10),
                    _daysTwoRowsNeat(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: kPrimaryColor.withOpacity(0.12)),
                      ),
                      child: _summaryRow(
                        icon: Icons.event_available_rounded,
                        title: "Open Days",
                        value: _daysSummary(),
                      ),
                    ),
                  ],
                ),
              ),

              // ─────────────────────────────
              // 4. Location Type
              // ─────────────────────────────
              sectionLabel("Location Type"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasFixedLocation
                              ? Icons.storefront_rounded
                              : Icons.delivery_dining_rounded,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Do you have a physical store?",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasFixedLocation
                          ? "Customers can visit your location"
                          : "You deliver to customers",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _locationTypeOption(
                            icon: Icons.storefront_rounded,
                            label: "Yes",
                            subtitle: "Physical Store",
                            isSelected: _hasFixedLocation,
                            onTap: () =>
                                setState(() => _hasFixedLocation = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _locationTypeOption(
                            icon: Icons.delivery_dining_rounded,
                            label: "No",
                            subtitle: "Delivery Only",
                            isSelected: !_hasFixedLocation,
                            onTap: () =>
                                setState(() => _hasFixedLocation = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─────────────────────────────
              // 5. Location (if fixed)
              // ─────────────────────────────
              if (_hasFixedLocation) ...[
                sectionLabel("Store Location"),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: inputStyle("City"),
                        items: kCities
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCity = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Required" : null,
                      ),
                      const SizedBox(height: 14),

                      // Address
                      TextFormField(
                        controller: addressCtrl,
                        decoration: inputStyle("Full Address"),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),
                      const SizedBox(height: 14),

                      // Map picker
                      InkWell(
                        onTap: _openMapPicker,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: kPrimaryColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _hasLocationSet
                                    ? Icons.check_circle_rounded
                                    : Icons.map_rounded,
                                color: _hasLocationSet
                                    ? Colors.green
                                    : kPrimaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _hasLocationSet
                                      ? "Location Set ✓"
                                      : "Pick Location on Map",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _hasLocationSet
                                        ? Colors.green.shade700
                                        : kPrimaryColor,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ─────────────────────────────
              // 6. Additional Info
              // ─────────────────────────────
              sectionLabel("Extra Details"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: AdditionalInfoSection(
                  items: _additionalInfo,
                  onAdd: _addAdditionalInfo,
                  onRemove: _removeAdditionalInfo,
                ),
              ),

              // ─────────────────────────────
              // 7. Visibility
              // ─────────────────────────────
              sectionLabel("Visibility"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: cardDecoration(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _visibleInSearch
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _visibleInSearch
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color:
                            _visibleInSearch ? Colors.green : Colors.grey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Show in Search",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _visibleInSearch
                                ? "Customers can find your service"
                                : "Hidden from search results",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _visibleInSearch,
                      onChanged: (v) => setState(() => _visibleInSearch = v),
                      activeColor: kPrimaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationTypeOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withOpacity(0.1)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryColor : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? kPrimaryColor : Colors.grey.shade600,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
