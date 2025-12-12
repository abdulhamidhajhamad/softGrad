// lib/screens/booking type/add_full_day_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_common_widgets.dart';

class AddFullDayService extends StatefulWidget {
  final String category;
  final String bookingType;

  const AddFullDayService({
    super.key,
    required this.category,
    required this.bookingType,
  });

  @override
  State<AddFullDayService> createState() => _AddFullDayServiceState();
}

class _AddFullDayServiceState extends State<AddFullDayService> {
  final _formKey = GlobalKey<FormState>();

  // common
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();

  final priceCtrl = TextEditingController(); // per day
  final discountCtrl = TextEditingController();

  String? _selectedCity;
  bool _visibleInSearch = true;

  Uint8List? _coverImage;
  final List<String> _highlights = [];

  // ✅ Days (same style as hourly) - store full words internally
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

  // ✅ full-day specific (rules)
  // max events per day is FIXED to 1 (non-editable)
  final TextEditingController maxEventsPerDayCtrl =
      TextEditingController(text: "1");

  final extraDayPriceCtrl = TextEditingController();

  // -----------------------------
  // Helpers (days UI like hourly)
  // -----------------------------
  String _day3(String d) => d.length <= 3 ? d : d.substring(0, 3);

  String _daysSummary() {
    if (_selectedDays.isEmpty) return "No days selected";
    if (_selectedDays.length == _weekdays.length) return "Every day";
    final ordered = _weekdays.where(_selectedDays.contains).toList();
    return ordered.map(_day3).join(", "); // ✅ Mon, Tue, Fri...
  }

  Widget _miniTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
      );

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
    bool smallValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: smallValue ? 11 : 12,
            fontWeight: smallValue ? FontWeight.w600 : FontWeight.w700,
            color: smallValue ? Colors.grey.shade800 : Colors.black,
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
              _day3(d), // ✅ 3D letters
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
  // Actions
  // -----------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _coverImage = bytes);
  }

  Future<void> _addHighlight() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Add highlight",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: "e.g. Includes lighting, Free setup...",
            hintStyle: GoogleFonts.poppins(fontSize: 13),
          ),
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
              final t = ctrl.text.trim();
              if (t.isNotEmpty) setState(() => _highlights.add(t));
              Navigator.pop(context);
            },
            child: Text(
              "Add",
              style: GoogleFonts.poppins(color: kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _trySave() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // ✅ require at least one day
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Select at least one day", style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      "category": widget.category,
      "bookingType": widget.bookingType,

      // common
      "name": nameCtrl.text.trim(),
      "description": descCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "city": _selectedCity,
      "latitude": latitudeCtrl.text.trim(),
      "longitude": longitudeCtrl.text.trim(),
      "price": priceCtrl.text.trim(),
      "discount": discountCtrl.text.trim(),
      "coverImage": _coverImage,
      "highlights": _highlights,
      "visibleInSearch": _visibleInSearch,

      // ✅ days (like hourly)
      "days": _selectedDays.toList(),

      // full-day
      "pricingModel": "per_day",
      "allDay": true, // ✅ event وحدة طول اليوم
      "maxEventsPerDay": "1", // ✅ fixed
      "extraDayPrice": extraDayPriceCtrl.text.trim(),
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    addressCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    maxEventsPerDayCtrl.dispose();
    extraDayPriceCtrl.dispose();
    super.dispose();
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
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
              // ✅ from top like hourly (pretty header)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: kPrimaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Full-Day Booking",
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w800),
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
              ),

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

              // ✅ Availability: Days ONLY (no availability dates)
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
                      child: Column(
                        children: [
                          _summaryRow(
                            icon: Icons.event_available_rounded,
                            title: "Days",
                            value: _daysSummary(), // ✅ 3 letters
                            smallValue: true, // ✅ smaller font
                          ),
                          const SizedBox(height: 8),
                          _summaryRow(
                            icon: Icons.access_time_rounded,
                            title: "Time",
                            value: "All day",
                            smallValue: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              sectionLabel("Pricing & Location"),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputStyle("Price per day (₪)"),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latitudeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: inputStyle("Latitude (optional)"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: longitudeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: inputStyle("Longitude (optional)"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              sectionLabel("Full-Day Rules"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ fixed 1 (non-editable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Max events per day",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),

                          // ✅ blue lock icon
                          const Icon(Icons.lock_rounded,
                              size: 18, color: kPrimaryColor),
                          const SizedBox(width: 8),

                          Text(
                            "1",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              sectionLabel("Gallery"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: CoverImageBox(bytes: _coverImage, onPick: _pickImage),
              ),

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
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _addHighlight,
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              color: kPrimaryColor),
                        ),
                      ],
                    ),
                    if (_highlights.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Add points that make your service special.",
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _highlights
                              .map(
                                (h) => Chip(
                                  label: Text(h,
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                  backgroundColor: const Color(0xFFF9FAFB),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                ),
                              )
                              .toList(),
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
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Turn off if temporarily unavailable.",
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade600),
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
