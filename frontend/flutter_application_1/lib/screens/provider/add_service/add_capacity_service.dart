// lib/screens/booking type/add_full_day_service.dart
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

class AddCapacityService extends StatefulWidget {
  final String category;
  final String bookingType;

  const AddCapacityService({
    super.key,
    required this.category,
    required this.bookingType,
  });

  @override
  State<AddCapacityService> createState() => _AddCapacityServiceState();
}

class _AddCapacityServiceState extends State<AddCapacityService> {
  final _formKey = GlobalKey<FormState>();

  // -----------------------------
  // Common
  // -----------------------------
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // Location
  final addressCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  String? _selectedCity;

  // Pricing
  int _maxCapacity = 50; // ✅ default
  final pricePerPersonCtrl = TextEditingController();
  final discountCtrl = TextEditingController();

  // ✅ NEW: unit type before price (person vs piece)
  String _capacityUnit = "person"; // "person" | "piece"

  // ✅ live pricing preview
  double? _finalPricePerPerson;
  double? _savedPerPerson;

  // Gallery + highlights + visibility
  // ✅ Multi-media gallery (up to 10 images/videos)
  final List<MediaItem> _mediaItems = [];
  static const int _maxMediaItems = 10;

  // ✅ Additional info items (key/value pairs)
  final List<Map<String, String>> _additionalInfo = [];
 double? _selectedLat;
  double? _selectedLng;
  bool _hasLocationSet = false;
  // 🆕 هل الخدمة لها موقع ثابت أم تذهب للعميل
  bool _hasFixedLocation = true;
  bool _visibleInSearch = true;

  // -----------------------------
  // ✅ Availability = Days ONLY
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

  Widget _miniTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
      );

  Widget _hint(String t) => Text(
        t,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
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

  // -----------------------------
  // ✅ Capacity Stepper UI
  // -----------------------------
  void _decCapacity() {
    setState(() {
      if (_maxCapacity > 1) _maxCapacity--;
    });
  }

  void _incCapacity() {
    setState(() {
      if (_maxCapacity < 1000) _maxCapacity++; // ✅ safety upper bound
    });
  }

  Widget _roundIconBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimaryColor.withOpacity(0.16)),
        ),
        child: Icon(icon, color: kPrimaryColor, size: 20),
      ),
    );
  }

  Widget _capacityCard() {
    // ✅ label adapts
    final unitLabel = _capacityUnit == "piece" ? "pieces" : "people";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_rounded,
                color: kPrimaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Maximum $unitLabel",
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          _roundIconBtn(icon: Icons.remove_rounded, onTap: _decCapacity),
          const SizedBox(width: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$_maxCapacity",
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _roundIconBtn(icon: Icons.add_rounded, onTap: _incCapacity),
        ],
      ),
    );
  }

  // -----------------------------
  // ✅ Live final price calc (per unit)
  // -----------------------------
  void _recalcPrice() {
    final price = double.tryParse(pricePerPersonCtrl.text.trim());
    final disc = double.tryParse(discountCtrl.text.trim());

    if (price == null || price <= 0) {
      if (_finalPricePerPerson != null || _savedPerPerson != null) {
        setState(() {
          _finalPricePerPerson = null;
          _savedPerPerson = null;
        });
      }
      return;
    }

    final d = (disc ?? 0).clamp(0, 100);
    final finalP = price * (1 - d / 100.0);
    final saved = price - finalP;

    if (_finalPricePerPerson == finalP && _savedPerPerson == saved) return;

    setState(() {
      _finalPricePerPerson = finalP;
      _savedPerPerson = saved;
    });
  }

  // -----------------------------
  // Actions
  // -----------------------------
  Future<void> _pickImages() async {
    if (_mediaItems.length >= _maxMediaItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You can't upload more than $_maxMediaItems items",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You can't upload more than $_maxMediaItems items",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _addAdditionalInfo() async {
    final result = await showAddInfoDialog(context);
    if (result != null) {
      setState(() => _additionalInfo.add(result));
    }
  }

  void _removeAdditionalInfo(int index) {
    setState(() => _additionalInfo.removeAt(index));
  }

bool _saving = false;

Future<void> _trySave() async {
  final ok = _formKey.currentState?.validate() ?? false;
  if (!ok) return;

  if (_selectedDays.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Select at least one day", style: GoogleFonts.poppins())),
    );
    return;
  }

  if (_hasFixedLocation && (_selectedCity == null || _selectedCity!.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Select a city", style: GoogleFonts.poppins())),
    );
    return;
  }

  final price = num.tryParse(pricePerPersonCtrl.text.trim());
  if (price == null || price <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Enter a valid price.", style: GoogleFonts.poppins())),
    );
    return;
  }

  final form = {
    "category": widget.category,
    "bookingType": "capacity",

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

    // capacity
    "pricingModel": "capacity",
    "capacityUnit": _capacityUnit, // "person" | "piece"
    "maxCapacity": _maxCapacity,

    "pricePerUnit": price.toDouble(),
    "discount": discountCtrl.text.trim(),

    "finalPricePerUnit": _finalPricePerPerson?.toStringAsFixed(2),
    "savedPerUnit": _savedPerPerson?.toStringAsFixed(2),

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
  };

  setState(() => _saving = true);

  try {
    await ServiceService.addServiceFromBookingForm(form);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Service created successfully ✅", style: GoogleFonts.poppins())),
    );

    // ✅ هذا اللي AddServiceProviderScreen مستنيه
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
  void initState() {
    super.initState();
    // ✅ live calc listeners
    pricePerPersonCtrl.addListener(_recalcPrice);
    discountCtrl.addListener(_recalcPrice);
    _recalcPrice();
  }

  @override
  void dispose() {
    pricePerPersonCtrl.removeListener(_recalcPrice);
    discountCtrl.removeListener(_recalcPrice);

    nameCtrl.dispose();
    descCtrl.dispose();

    addressCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();

    pricePerPersonCtrl.dispose();
    discountCtrl.dispose();

    super.dispose();
  }

  // -----------------------------
  // UI
  // -----------------------------
  Widget _prettyHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 100),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 44,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.people_alt_rounded, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Capacity Booking!",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
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

  // ✅ NEW: unit picker UI
  Widget _unitPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_rounded, color: kPrimaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Charge per",
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          ChoiceChip(
            selected: _capacityUnit == "person",
            showCheckmark: false,
            selectedColor: kPrimaryColor.withOpacity(0.14),
            backgroundColor: Colors.white,
            label: Text("Person",
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            onSelected: (_) => setState(() => _capacityUnit = "person"),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            selected: _capacityUnit == "piece",
            showCheckmark: false,
            selectedColor: kPrimaryColor.withOpacity(0.14),
            backgroundColor: Colors.white,
            label: Text("Piece",
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            onSelected: (_) => setState(() => _capacityUnit = "piece"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _capacityUnit == "piece" ? "piece" : "person";

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;
        
        if (isDesktop || isTablet) {
          return _buildWebLayout(context, isDesktop, unitLabel);
        }
        return _buildMobileLayout(context, unitLabel);
      },
    );
  }

  Widget _buildWebLayout(BuildContext context, bool isDesktop, String unitLabel) {
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
                  child: const Icon(LucideIcons.users, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Capacity Service",
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
                    child: Row(
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
                                    label: "Service Name",
                                    hint: "Enter your service name",
                                    icon: LucideIcons.tag,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildWebTextField(
                                    controller: descCtrl,
                                    label: "Description",
                                    hint: "Describe your service in detail",
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
                              // Capacity & Pricing Card
                              _buildWebSectionCard(
                                title: "Capacity & Pricing",
                                icon: LucideIcons.dollarSign,
                                children: [
                                  // Unit type selector
                                  Text(
                                    "Charge Per",
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(() => _capacityUnit = "person"),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            decoration: BoxDecoration(
                                              color: _capacityUnit == "person" ? _kPrimaryColor : const Color(0xFFF8F9FC),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _capacityUnit == "person" ? _kPrimaryColor : Colors.grey.shade300),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Person",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: _capacityUnit == "person" ? Colors.white : _kTextPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(() => _capacityUnit = "piece"),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            decoration: BoxDecoration(
                                              color: _capacityUnit == "piece" ? _kPrimaryColor : const Color(0xFFF8F9FC),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _capacityUnit == "piece" ? _kPrimaryColor : Colors.grey.shade300),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Piece",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: _capacityUnit == "piece" ? Colors.white : _kTextPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Max capacity stepper
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FC),
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
                                          child: const Icon(LucideIcons.users, color: _kPrimaryColor, size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            "Max ${_capacityUnit == "piece" ? "pieces" : "people"}",
                                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: _decCapacity,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _kPrimaryLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(LucideIcons.minus, color: _kPrimaryColor, size: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "$_maxCapacity",
                                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: _kPrimaryColor),
                                        ),
                                        const SizedBox(width: 16),
                                        InkWell(
                                          onTap: _incCapacity,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _kPrimaryLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(LucideIcons.plus, color: _kPrimaryColor, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  _buildWebTextField(
                                    controller: pricePerPersonCtrl,
                                    label: "Price per $unitLabel",
                                    hint: "0.00",
                                    icon: LucideIcons.coins,
                                    keyboardType: TextInputType.number,
                                    suffix: "₪",
                                    validator: (v) {
                                      final n = num.tryParse(v?.trim() ?? "");
                                      if (n == null || n <= 0) return "Required";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildWebTextField(
                                    controller: discountCtrl,
                                    label: "Discount (Optional)",
                                    hint: "0",
                                    icon: LucideIcons.percent,
                                    keyboardType: TextInputType.number,
                                    suffix: "%",
                                  ),
                                  if (_finalPricePerPerson != null) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_kPrimaryColor.withOpacity(0.1), _kPrimaryLight],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.calculator, color: _kPrimaryColor, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "Final Price/$unitLabel",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _kTextPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "${_finalPricePerPerson!.toStringAsFixed(2)} ₪",
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: _kPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Gallery Card
                              _buildWebSectionCard(
                                title: "Gallery",
                                icon: LucideIcons.image,
                                children: [
                                  MultiMediaGalleryBox(
                                    mediaItems: _mediaItems,
                                    onPickImages: _pickImages,
                                    onPickVideo: _pickVideo,
                                    onRemove: _removeMediaItem,
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
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapLocationPicker()),
        );
        if (result != null && result is Map) {
          setState(() {
            _selectedLat = result['lat'];
            _selectedLng = result['lng'];
            _hasLocationSet = true;
          });
        }
      },
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

  Widget _buildMobileLayout(BuildContext context, String unitLabel) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: Text("Add Service",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: const BackButton(color: kTextColor),
      ),
      bottomNavigationBar: saveButton(_trySave),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _prettyHeader(),

              // Service Details
              sectionLabel("Service Details"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: inputStyle("Service Name"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),

              // Description
              sectionLabel("Description"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: inputStyle("Describe your service"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),

              // Availability (Days)
              sectionLabel("Availability"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniTitle("Choose days"),
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
                        title: "Days",
                        value: _daysSummary(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 🆕 سؤال: هل الخدمة لها موقع ثابت؟
              sectionLabel("Service Location Type"),
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
                          _hasFixedLocation ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Does this service have a fixed location?",
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
                          ? "Clients will come to your location"
                          : "You will go to the client's location",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _hasFixedLocation = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _hasFixedLocation
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasFixedLocation
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                  width: _hasFixedLocation ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    color: _hasFixedLocation
                                        ? kPrimaryColor
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Yes",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _hasFixedLocation
                                          ? kPrimaryColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    "Fixed Location",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _hasFixedLocation = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_hasFixedLocation
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_hasFixedLocation
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                  width: !_hasFixedLocation ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.delivery_dining_rounded,
                                    color: !_hasFixedLocation
                                        ? kPrimaryColor
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "No",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: !_hasFixedLocation
                                          ? kPrimaryColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    "I Go to Client",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 🆕 قسم الموقع يظهر فقط إذا كانت الخدمة لها موقع ثابت
              if (_hasFixedLocation) ...[
              // Location
              sectionLabel("Location"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: addressCtrl,
                            decoration: inputStyle("Address"),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? "Required"
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: inputStyle("City"),
                            icon:
                                const Icon(Icons.expand_more_rounded, size: 18),
                            items: kCities
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCity = v),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ✅ Map Location Button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Map coordinates (optional)",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapLocationPicker(
                                      initialLat: _selectedLat,
                                      initialLng: _selectedLng,
                                    ),
                                  ),
                                );

                                if (result != null && result is Map) {
                                  setState(() {
                                    _selectedLat = result['latitude'];
                                    _selectedLng = result['longitude'];
                                    _hasLocationSet = true;
                                  });
                                }
                              },
                              icon: Icon(
                                _hasLocationSet
                                    ? Icons.check_circle_rounded
                                    : Icons.map_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                _hasLocationSet
                                    ? "Location Set ✅"
                                    : "Add Map Location",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (_hasLocationSet && _selectedLat != null && _selectedLng != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_pin,
                                        color: kPrimaryColor, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Lat: ${_selectedLat!.toStringAsFixed(5)}, Lng: ${_selectedLng!.toStringAsFixed(5)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18, color: kPrimaryColor),
                                      onPressed: () {
                                        setState(() {
                                          _selectedLat = null;
                                          _selectedLng = null;
                                          _hasLocationSet = false;
                                        });
                                      },
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
              ),
              ],
              // ✅ Pricing (Unit + Capacity + price per unit)
              sectionLabel("Pricing"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: kPrimaryColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Set capacity & price",
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _hint(
                        "Choose if you charge per person (catering) or per piece (cake)."),
                    const SizedBox(height: 12),

                    // ✅ NEW FIELD (before price)
                    _unitPicker(),

                    const SizedBox(height: 12),
                    _capacityCard(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pricePerPersonCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: inputStyle("Price per $unitLabel (₪)"),
                      validator: (v) {
                        final n = num.tryParse(v?.trim() ?? "");
                        if (n == null || n <= 0) return "Enter valid price";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: inputStyle("Discount % (optional)"),
                    ),

                    // ✅ live result
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: kPrimaryColor.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calculate_rounded,
                              color: kPrimaryColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Final price / $unitLabel",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            _finalPricePerPerson == null
                                ? "--"
                                : "${_finalPricePerPerson!.toStringAsFixed(2)} ₪",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          if (_savedPerPerson != null &&
                              _savedPerPerson! > 0) ...[
                            const SizedBox(width: 10),
                            Text(
                              "(-${_savedPerPerson!.toStringAsFixed(2)} ₪)",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Gallery
              sectionLabel("Gallery"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: MultiMediaGalleryBox(
                  mediaItems: _mediaItems,
                  onPickImages: _pickImages,
                  onPickVideo: _pickVideo,
                  onRemove: _removeMediaItem,
                  maxItems: _maxMediaItems,
                ),
              ),

              // Additional Info + Visibility
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
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: cardDecoration(),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _visibleInSearch,
                  activeColor: kPrimaryColor,
                  onChanged: (v) => setState(() => _visibleInSearch = v),
                  title: Text(
                    "Visible in search",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Turn off if temporarily unavailable.",
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}