import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_common_widgets.dart';

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

  // Gallery + highlights + visibility
  Uint8List? _coverImage;
  final List<String> _highlights = [];
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
                  "Maximum capacity",
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
        title: Text("Add highlight",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: "e.g. Vegan options, Outdoor seating...",
            hintStyle: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) setState(() => _highlights.add(t));
              Navigator.pop(context);
            },
            child:
                Text("Add", style: GoogleFonts.poppins(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _trySave() {
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

    final price = num.tryParse(pricePerPersonCtrl.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Enter a valid price per person.",
                style: GoogleFonts.poppins())),
      );
      return;
    }

    Navigator.pop(context, {
      "category": widget.category,
      "bookingType": widget.bookingType,

      "name": nameCtrl.text.trim(),
      "description": descCtrl.text.trim(),

      "address": addressCtrl.text.trim(),
      "city": _selectedCity,
      "latitude": latitudeCtrl.text.trim(),
      "longitude": longitudeCtrl.text.trim(),

      "days": _selectedDays.toList(),

      // ✅ new capacity pricing model
      "pricingModel": "per_person_capacity",
      "maxCapacity": _maxCapacity,
      "pricePerPerson": price.toDouble(),
      "discount": discountCtrl.text.trim(),

      "coverImage": _coverImage,
      "highlights": _highlights,
      "visibleInSearch": _visibleInSearch,
    });
  }

  @override
  void dispose() {
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
            child: const Icon(Icons.people_alt_rounded, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Capacity Booking",
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
    );
  }

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
                    const SizedBox(height: 12),
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
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: latitudeCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: inputStyle("Latitude"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: longitudeCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: inputStyle("Longitude"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Pricing (Capacity + price per person)
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
                        "Customers will see your max capacity and your price per person."),
                    const SizedBox(height: 12),
                    _capacityCard(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pricePerPersonCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: inputStyle("Price per person (₪)"),
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
                            color: kTextColor,
                          ),
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
                                    borderRadius: BorderRadius.circular(18),
                                  ),
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
