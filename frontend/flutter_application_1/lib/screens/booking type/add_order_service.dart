// lib/screens/booking type/add_order_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_common_widgets.dart';
import 'package:flutter_application_1/services/service_service.dart';

class AddOrderService extends StatefulWidget {
  final String category;
  final String bookingType;

  const AddOrderService({
    super.key,
    required this.category,
    required this.bookingType,
  });

  @override
  State<AddOrderService> createState() => _AddOrderServiceState();
}

class _AddOrderServiceState extends State<AddOrderService> {
  final _formKey = GlobalKey<FormState>();

  // common
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // location
  final addressCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  String? _selectedCity;

  // pricing
  final priceCtrl = TextEditingController(); // base item price
  final discountCtrl = TextEditingController();

  // live pricing preview (after discount)
  double? _finalPrice;
  double? _savedAmount;

  bool _visibleInSearch = true;

  Uint8List? _coverImage;

  // highlights key/value
  final List<Map<String, String>> _highlights = [];

  // order-specific
  final minOrderQtyCtrl = TextEditingController(text: "1");

  // ✅ inventory + processing days (steppers)
  int _availableQty = 10; // default
  int _processingDays = 3; // default (0 allowed)

  bool _customization = false;
  final customizationFeeCtrl = TextEditingController();

  bool _delivery = false;
  final deliveryFeeCtrl = TextEditingController();

  // -----------------------------
  // Live final price calc
  // -----------------------------
  void _recalcFinalPrice() {
    final base = double.tryParse(priceCtrl.text.trim());
    final disc = double.tryParse(discountCtrl.text.trim());

    if (base == null || base <= 0) {
      if (_finalPrice != null || _savedAmount != null) {
        setState(() {
          _finalPrice = null;
          _savedAmount = null;
        });
      }
      return;
    }

    final d = (disc ?? 0).clamp(0, 100);
    final finalP = base * (1 - d / 100.0);
    final saved = base - finalP;

    if (_finalPrice == finalP && _savedAmount == saved) return;

    setState(() {
      _finalPrice = finalP;
      _savedAmount = saved;
    });
  }

  // -----------------------------
  // Actions
  // -----------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _coverImage = bytes);
  }

  // highlights dialog: Key + Value
  Future<void> _addHighlight() async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Add highlight",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: InputDecoration(
                hintText: "Key (e.g. Color, Material, Size...)",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valCtrl,
              decoration: InputDecoration(
                hintText: "Value (e.g. Gold, Handmade, A4...)",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
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
            child:
                Text("Add", style: GoogleFonts.poppins(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  bool _saving = false;

Future<void> _trySave() async {
  final ok = _formKey.currentState?.validate() ?? false;
  if (!ok) return;

  if (_selectedCity == null || _selectedCity!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Select a city", style: GoogleFonts.poppins())),
    );
    return;
  }

  if (_coverImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please add a cover image.", style: GoogleFonts.poppins())),
    );
    return;
  }

  if (_availableQty < 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Available quantity must be at least 1.", style: GoogleFonts.poppins())),
    );
    return;
  }

  final minQty = int.tryParse(minOrderQtyCtrl.text.trim()) ?? 1;
  if (_availableQty < minQty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Available quantity must be ≥ minimum order quantity.", style: GoogleFonts.poppins())),
    );
    return;
  }

  final form = {
    "category": widget.category,
    "bookingType": widget.bookingType,

    "name": nameCtrl.text.trim(),
    "description": descCtrl.text.trim(),

    "address": addressCtrl.text.trim(),
    "city": _selectedCity,
    "latitude": latitudeCtrl.text.trim(),
    "longitude": longitudeCtrl.text.trim(),

    "price": priceCtrl.text.trim(),
    "discount": discountCtrl.text.trim(),

    "finalPrice": _finalPrice?.toStringAsFixed(2),
    "savedAmount": _savedAmount?.toStringAsFixed(2),

    "coverImage": _coverImage,
    "highlights": _highlights,
    "visibleInSearch": _visibleInSearch,

    "pricingModel": "per_item",
    "minOrderQty": minOrderQtyCtrl.text.trim(),

    "availableQty": _availableQty,
    "processingDays": _processingDays,

    "customizationAvailable": _customization,
    "customizationFee": customizationFeeCtrl.text.trim(),
    "deliveryAvailable": _delivery,
    "deliveryFee": deliveryFeeCtrl.text.trim(),
  };

  setState(() => _saving = true);

  try {
    await ServiceService.addServiceFromBookingForm(form);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Service created successfully ✅", style: GoogleFonts.poppins())),
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
  void initState() {
    super.initState();
    // live calc listeners
    priceCtrl.addListener(_recalcFinalPrice);
    discountCtrl.addListener(_recalcFinalPrice);
    _recalcFinalPrice();

    // ✅ ensure starting values match rules
    if (_availableQty < 1) _availableQty = 1;
    if (_processingDays < 0) _processingDays = 0;
  }

  @override
  void dispose() {
    priceCtrl.removeListener(_recalcFinalPrice);
    discountCtrl.removeListener(_recalcFinalPrice);

    nameCtrl.dispose();
    descCtrl.dispose();

    addressCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();

    priceCtrl.dispose();
    discountCtrl.dispose();

    minOrderQtyCtrl.dispose();
    customizationFeeCtrl.dispose();
    deliveryFeeCtrl.dispose();

    super.dispose();
  }

  // -----------------------------
  // UI helpers
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
            child: const Icon(Icons.shopping_bag_rounded, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Booking!",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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

  Widget _stepperTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    String? badgeSuffix,
  }) {
    final canMinus = value > min;
    final canPlus = value < max;

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
            child: Icon(icon, color: kPrimaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: canMinus ? onMinus : null,
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: canMinus ? kPrimaryColor : Colors.grey.shade400,
                  ),
                  splashRadius: 18,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    badgeSuffix == null ? "$value" : "$value $badgeSuffix",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canPlus ? onPlus : null,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: canPlus ? kPrimaryColor : Colors.grey.shade400,
                  ),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Build
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: Text(
          "Add Service",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
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
                            items: kCities
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style:
                                            GoogleFonts.poppins(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCity = v),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latitudeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: inputStyle("Latitude (optional)"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: longitudeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: inputStyle("Longitude (optional)"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pricing
              sectionLabel("Pricing"),
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
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputStyle("Base item price (₪)"),
                            validator: (v) {
                              final n = num.tryParse(v?.trim() ?? "");
                              if (n == null || n <= 0)
                                return "Enter valid price";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputStyle("Discount % (optional)"),
                          ),
                        ),
                      ],
                    ),
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
                              "Final price",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            _finalPrice == null
                                ? "--"
                                : "${_finalPrice!.toStringAsFixed(2)} ₪",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          if (_savedAmount != null && _savedAmount! > 0) ...[
                            const SizedBox(width: 10),
                            Text(
                              "(-${_savedAmount!.toStringAsFixed(2)} ₪)",
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

              // Order Rules
              sectionLabel("Order Rules"),
              Container(
                padding: const EdgeInsets.all(22),
                margin: const EdgeInsets.only(bottom: 22),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    _stepperTile(
                      icon: Icons.inventory_2_rounded,
                      title: "Available quantity",
                      subtitle: "How many pieces are available right now",
                      value: _availableQty,
                      min: 1, // ✅ at least 1
                      max: 1000,
                      onMinus: () => setState(() => _availableQty--),
                      onPlus: () => setState(() => _availableQty++),
                      badgeSuffix: "pcs",
                    ),
                    const SizedBox(height: 12),
                    _stepperTile(
                      icon: Icons.timelapse_rounded,
                      title: "Processing days",
                      subtitle: "Preparation time before the order is ready",
                      value: _processingDays,
                      min: 0, // ✅ 0 allowed
                      max: 60,
                      onMinus: () => setState(() => _processingDays--),
                      onPlus: () => setState(() => _processingDays++),
                      badgeSuffix: "days",
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
                child: CoverImageBox(bytes: _coverImage, onPick: _pickImage),
              ),

              // Highlights + Visibility
              sectionLabel("Highlights"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Highlights",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _addHighlight,
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (_highlights.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Add points that make your service special.",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _highlights.map((h) {
                            final k = (h["key"] ?? "").trim();
                            final v = (h["value"] ?? "").trim();
                            return Chip(
                              label: Text(
                                "$k: $v",
                                style: GoogleFonts.poppins(fontSize: 11),
                              ),
                              backgroundColor: const Color(0xFFF9FAFB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(height: 24),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _visibleInSearch,
                      activeColor: kPrimaryColor,
                      onChanged: (v) => setState(() => _visibleInSearch = v),
                      title: Text(
                        "Visible in search",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "Turn off if temporarily unavailable.",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
}
