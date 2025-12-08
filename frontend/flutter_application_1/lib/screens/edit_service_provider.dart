// lib/screens/edit_service_provider.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class EditServiceProviderScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;

  const EditServiceProviderScreen({
    Key? key,
    required this.existingData,
  }) : super(key: key);

  @override
  State<EditServiceProviderScreen> createState() =>
      _EditServiceProviderScreenState();
}

class _EditServiceProviderScreenState extends State<EditServiceProviderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _shortDescCtrl;
  late TextEditingController _fullDescCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;

  List<String> _images = [];
  List<String> _highlights = [];
  List<Map<String, dynamic>> _packages = [];

  late AnimationController _animController;

  // Category options with icons for the bottom sheet
  final List<_CategoryOption> _categoryOptions = const [
    _CategoryOption('Venues', Icons.apartment_rounded),
    _CategoryOption('Photographers', Icons.photo_camera_outlined),
    _CategoryOption('Catering', Icons.restaurant_menu_rounded),
    _CategoryOption('Cake', Icons.cake_outlined),
    _CategoryOption('Flower Shops', Icons.local_florist_outlined),
    _CategoryOption('Decor & Lighting', Icons.lightbulb_outline),
    _CategoryOption('Music & Entertainment', Icons.music_note_outlined),
    _CategoryOption('Wedding Planners & Coordinators', Icons.event_available),
    _CategoryOption('Card Printing', Icons.mail_outline),
    _CategoryOption('Jewelry & Accessories', Icons.diamond_outlined),
    _CategoryOption(
        'Car Rental & Transportation', Icons.directions_car_filled_outlined),
    _CategoryOption('Gift & Souvenir', Icons.card_giftcard_outlined),
  ];

  @override
  void initState() {
    super.initState();

    final s = widget.existingData;

    _nameCtrl = TextEditingController(text: s['name'] ?? "");
    _brandCtrl = TextEditingController(text: s['brand'] ?? "");
    _taglineCtrl = TextEditingController(text: s['tagline'] ?? "");
    _addressCtrl = TextEditingController(text: s['address'] ?? "");

    // وصف واحد موحّد
    final descText =
        (s['fullDescription'] ?? s['shortDescription'] ?? "").toString();
    _shortDescCtrl = TextEditingController(text: descText);
    _fullDescCtrl = TextEditingController(text: descText);

    _cityCtrl = TextEditingController(text: s['city'] ?? "");
    _categoryCtrl = TextEditingController(text: s['category'] ?? "");
    _priceCtrl = TextEditingController(text: s['price']?.toString() ?? "");
    _discountCtrl =
        TextEditingController(text: s['discount']?.toString() ?? "");

    _images = List<String>.from(s['images'] ?? []);
    _highlights = List<String>.from(s['highlights'] ?? []);
    _packages = List<Map<String, dynamic>>.from(s['packages'] ?? []);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _shortDescCtrl.dispose();
    _fullDescCtrl.dispose();
    _cityCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((e) => e.path));
      });
    }
  }

  void _addHighlight() {
    final keyCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Add Highlight",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: "Key",
                hintText: "e.g. Website",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(
                labelText: "Value",
                hintText: "e.g. https://example.com",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () {
              final key = keyCtrl.text.trim();
              final value = valueCtrl.text.trim();
              if (key.isNotEmpty || value.isNotEmpty) {
                final combined =
                    value.isNotEmpty ? "$key • $value" : key; // نص واحد
                setState(() => _highlights.add(combined));
              }
              Navigator.pop(context);
            },
            child: Text(
              "Add",
              style: GoogleFonts.poppins(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final desc = _fullDescCtrl.text.trim();

    final updatedData = {
      "name": _nameCtrl.text.trim(),
      "brand": _brandCtrl.text.trim(),
      "tagline": _taglineCtrl.text.trim(),
      "address": _addressCtrl.text.trim(),
      // وصف واحد يُخزّن في الاثنين
      "shortDescription": desc,
      "fullDescription": desc,
      "city": _cityCtrl.text.trim(),
      "category": _categoryCtrl.text.trim(),
      "price": double.tryParse(_priceCtrl.text.trim()) ?? 0,
      "discount": _discountCtrl.text.trim(),
      "images": _images,
      "highlights": _highlights,
      "packages": _packages,
    };

    Navigator.pop(context, updatedData);
  }

  // Open bottom sheet with category list + icons
  Future<void> _openCategoryPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select category",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _categoryOptions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final opt = _categoryOptions[index];
                      final isSelected = _categoryCtrl.text.trim() == opt.label;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(
                          opt.icon,
                          color: kPrimaryColor,
                        ),
                        title: Text(
                          opt.label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: kTextColor,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: kPrimaryColor)
                            : null,
                        onTap: () {
                          setState(() {
                            _categoryCtrl.text = opt.label;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // plain white background (no gradients / waves)
          Container(color: kBackgroundColor),
          SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_animController.value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 40),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _buildFormScroll(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildSaveButton(),
          ),
        ],
      ),
    );
  }

  // ===================== APP BAR =====================

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _glassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Service",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Update your service details",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // removed extra white icon button (sparkles)
        ],
      ),
    );
  }

  // ===================== FORM BODY =====================

  Widget _buildFormScroll() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _heroImageCard(),
            const SizedBox(height: 18),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Basic Info"),
                  const SizedBox(height: 12),
                  _label("Service Name"),
                  _textField(_nameCtrl, hint: "e.g., Luxe Wedding Photography"),
                  // تم الإبقاء على الكود، لكن تم إزالة حقول Brand و Tagline من الواجهة فقط
                ],
              ),
            ),
            const SizedBox(height: 16),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Location & Category"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("City"),
                            _textField(_cityCtrl, hint: "Nablus"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Category"),
                            _categoryField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _label("Address"),
                  _textField(
                    _addressCtrl,
                    hint: "e.g., Downtown Street 12",
                    maxLines: 2,
                    required: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Pricing"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Price (₪)"),
                            _textField(
                              _priceCtrl,
                              hint: "500",
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Discount %"),
                            _textField(
                              _discountCtrl,
                              hint: "0 - 100",
                              keyboardType: TextInputType.number,
                              required: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Description"),
                  const SizedBox(height: 12),
                  _label("Description"),
                  _textField(
                    _fullDescCtrl,
                    hint: "Explain everything about your service…",
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Highlights"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._highlights.map(
                        (h) => Chip(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFE0E7FF),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          label: Text(
                            h,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kTextColor,
                            ),
                          ),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          onDeleted: () {
                            setState(() => _highlights.remove(h));
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: _addHighlight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: kPrimaryColor.withOpacity(0.7),
                            ),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: kPrimaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Add highlight",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Images"),
                  const SizedBox(height: 10),
                  _images.isEmpty
                      ? GestureDetector(
                          onTap: _pickImages,
                          child: _emptyImagesState(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _images.length) {
                                    return _addImageTile();
                                  }
                                  final img = _images[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _imageTile(img),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Tip: Use bright, high-quality images to attract more bookings.",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade700,
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
    );
  }

  // ===================== HERO / IMAGE HEADER =====================

  Widget _heroImageCard() {
    final hasImage = _images.isNotEmpty;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: Image.file(
                        File(_images.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor.withOpacity(0.85),
                          const Color(0xFF42A5F5),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.isEmpty
                            ? "Your Service"
                            : _nameCtrl.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _taglineCtrl.text.isEmpty
                            ? "Make a great first impression"
                            : _taglineCtrl.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _miniPill(
                            icon: Icons.location_on_rounded,
                            label: _cityCtrl.text.isEmpty
                                ? "City"
                                : _cityCtrl.text,
                          ),
                          _miniPill(
                            icon: Icons.category_rounded,
                            label: _categoryCtrl.text.isEmpty
                                ? "Category"
                                : _categoryCtrl.text,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== HELPERS: UI PARTS =====================

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [kPrimaryColor, const Color(0xFF42A5F5)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: kTextColor, fontSize: 13),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(
            color: kPrimaryColor,
            width: 1.6,
          ),
        ),
      ),
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return "Required";
        return null;
      },
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget _categoryField() {
    return TextFormField(
      controller: _categoryCtrl,
      readOnly: true,
      style: GoogleFonts.poppins(color: kTextColor, fontSize: 13),
      decoration: InputDecoration(
        hintText: "Select category",
        hintStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(
            color: kPrimaryColor,
            width: 1.6,
          ),
        ),
        suffixIcon: const Icon(
          Icons.arrow_drop_down_rounded,
          color: kPrimaryColor,
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Required";
        return null;
      },
      onTap: _openCategoryPicker,
    );
  }

  Widget _miniPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: kPrimaryColor.withOpacity(0.06),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== IMAGES =====================

  Widget _emptyImagesState() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: kPrimaryColor,
                size: 30,
              ),
              const SizedBox(height: 6),
              Text(
                "Add service photos",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Tap to upload images",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addImageTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: Icon(
          Icons.add_rounded,
          color: kPrimaryColor,
          size: 30,
        ),
      ),
    );
  }

  Widget _imageTile(String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() => _images.remove(path));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== SAVE BUTTON =====================

  Widget _buildSaveButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _animController.reverse(from: 1.0);
        },
        onTapUp: (_) {
          _animController.forward(from: 0.7);
          _save();
        },
        onTapCancel: () {
          _animController.forward(from: 0.7);
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                kPrimaryColor,
                const Color(0xFF1414D7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "Save Changes",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== GLASS ICON BUTTON =====================

  Widget _glassIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: kTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

// Small model for category option
class _CategoryOption {
  final String label;
  final IconData icon;
  const _CategoryOption(this.label, this.icon);
}
