// lib/screens/add_service_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF111827);

// الخدمة + الأيقونة (نفس اللي عندك في Become a Provider)
const List<Map<String, dynamic>> kServiceCategories = [
  {
    'value': 'Venues',
    'label': 'Venues',
    'icon': Icons.apartment_rounded,
  },
  {
    'value': 'Photographers',
    'label': 'Photographers',
    'icon': Icons.photo_camera_outlined,
  },
  {
    'value': 'Catering',
    'label': 'Catering',
    'icon': Icons.restaurant_menu_rounded,
  },
  {
    'value': 'Cake',
    'label': 'Cake',
    'icon': Icons.cake_outlined,
  },
  {
    'value': 'Flower Shops',
    'label': 'Flower Shops',
    'icon': Icons.local_florist_outlined,
  },
  {
    'value': 'Decor & Lighting',
    'label': 'Decor & Lighting',
    'icon': Icons.lightbulb_outline_rounded,
  },
  {
    'value': 'Music & Entertainment',
    'label': 'Music & Entertainment',
    'icon': Icons.music_note_rounded,
  },
  {
    'value': 'Wedding Planners & Coordinators',
    'label': 'Wedding Planners & Coordinators',
    'icon': Icons.event_available_rounded,
  },
  {
    'value': 'Card Printing',
    'label': 'Card Printing',
    'icon': Icons.mail_outline_rounded,
  },
  {
    'value': 'Jewelry & Accessories',
    'label': 'Jewelry & Accessories',
    'icon': Icons.diamond_outlined,
  },
  {
    'value': 'Car Rental & Transportation',
    'label': 'Car Rental & Transportation',
    'icon': Icons.directions_car_filled_outlined,
  },
  {
    'value': 'Gift & Souvenir',
    'label': 'Gift & Souvenir',
    'icon': Icons.card_giftcard_outlined,
  },
];

// المدن (عدليهم لو بدك)
const List<String> kCities = [
  'Nablus',
  'Ramallah',
  'Jenin',
  'Tulkarm',
  'Qalqilya',
  'Hebron',
  'Bethlehem',
  'Jericho',
  'Jerusalem',
  'Other',
];

class AddServiceProviderScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  const AddServiceProviderScreen({Key? key, this.existingData})
      : super(key: key);

  @override
  State<AddServiceProviderScreen> createState() =>
      _AddServiceProviderScreenState();
}

class _AddServiceProviderScreenState extends State<AddServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _fullDescCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  // ⬇⬇ Controllers للـ Longitude / Latitude
  final _longCtrl = TextEditingController();
  final _latCtrl = TextEditingController();

  final picker = ImagePicker();

  String? _selectedCategory; // بدون default
  String? _selectedCity; // بدون default
  String? _priceType; // Per Event / Per Hour / Per Person
  bool _isVisible = true;

  List<String> _images = [];

  // صارت key–value: title + url
  List<Map<String, dynamic>> _highlights = [];

  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final d = widget.existingData!;

      _nameCtrl.text = d["name"] ?? "";
      _brandCtrl.text = d["brand"] ?? "";
      _taglineCtrl.text = d["tagline"] ?? "";
      _addressCtrl.text = d["address"] ?? "";

      // دمج الـ short و full في description واحد
      _fullDescCtrl.text = d["fullDescription"] ?? d["shortDescription"] ?? "";
      _shortDescCtrl.text = d["fullDescription"] ?? d["shortDescription"] ?? "";

      _priceCtrl.text = d["price"]?.toString() ?? "";
      _discountCtrl.text = d["discount"]?.toString() ?? "";

      _selectedCity = d["city"];
      _selectedCategory = d["category"];
      _priceType = d["priceType"];
      _isVisible = d["isActive"] ?? true;

      _images = List<String>.from(d["images"] ?? []);

      // ⬇⬇ تحميل القيم القديمة للـ Lat / Long لو موجودة
      _longCtrl.text =
          d["longitude"]?.toString() ?? d["long"]?.toString() ?? "";
      _latCtrl.text = d["latitude"]?.toString() ?? d["lat"]?.toString() ?? "";

      // دعم القديم (List<String>) والجديد (List<Map<String, dynamic>>)
      final rawHighlights = d["highlights"];
      if (rawHighlights is List) {
        _highlights = rawHighlights.map<Map<String, dynamic>>((h) {
          if (h is Map<String, dynamic>) {
            return {
              "title": (h["title"] ?? "").toString(),
              "url": (h["url"] ?? "").toString(),
            };
          } else if (h is Map) {
            final map = Map<String, dynamic>.from(h);
            return {
              "title": (map["title"] ?? "").toString(),
              "url": (map["url"] ?? "").toString(),
            };
          } else {
            // لو كان String قديم نخليه title فقط
            return {"title": h.toString(), "url": ""};
          }
        }).toList();
      }

      _packages = List<Map<String, dynamic>>.from(d["packages"] ?? []);
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _images.add(picked.path));
    }
  }

  void _addHighlight() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Add Highlight",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                labelText: "Title / Website",
                hintText: "e.g. Official Website",
                hintStyle:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                labelText: "URL",
                hintText: "e.g. https://example.com",
                hintStyle:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (title.isNotEmpty || url.isNotEmpty) {
                setState(() => _highlights.add({
                      "title": title,
                      "url": url,
                    }));
              }
              Navigator.pop(context);
            },
            child: Text(
              "Add",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addPackage() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                "Add Package",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Package Name",
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[700]),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: kPrimaryColor,
                      width: 1.4,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Price (₪)",
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[700]),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: kPrimaryColor,
                      width: 1.4,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _packages.add({
                        "name": nameCtrl.text.trim(),
                        "price": priceCtrl.text.trim(),
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Add Package",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final data = {
      "name": _nameCtrl.text,
      "brand": _brandCtrl.text,
      "tagline": _taglineCtrl.text,
      "address": _addressCtrl.text,

      // Description واحدة تُحفظ في الاثنين
      "shortDescription": _fullDescCtrl.text,
      "fullDescription": _fullDescCtrl.text,

      "category": _selectedCategory ?? "",
      "city": _selectedCity ?? "",
      "priceType": _priceType ?? "",
      "isActive": _isVisible,
      "price": double.tryParse(_priceCtrl.text) ?? 0,

      "discount": _discountCtrl.text,
      "images": _images,

      // ⬇⬇ حفظ الـ Lat / Long
      "longitude": double.tryParse(_longCtrl.text),
      "latitude": double.tryParse(_latCtrl.text),

      // الآن عبارة عن List<Map<String, dynamic>>
      "highlights": _highlights,

      "packages": _packages,
    };

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: kTextColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.existingData == null ? "Add New Service" : "Edit Service",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: kTextColor,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: _save,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Save Service",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Service details (بدون Address)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "Service Details",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _selectedCategory ?? "Select category",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInput("Name", _nameCtrl),
                      // تم حذف حقول Brand و Tagline من الواجهة فقط
                    ],
                  ),
                ),

                // Description card (حقل واحد فقط)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Description",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInput("Description", _fullDescCtrl),
                    ],
                  ),
                ),

                // Pricing & Location (Address + City جنب بعض, price + discount + نوع السعر + الكاتيجوري)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pricing & Location",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Address + City
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput("Address", _addressCtrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCity,
                              decoration: _inputDecoration("City"),
                              icon: const Icon(Icons.expand_more_rounded,
                                  size: 18),
                              items: kCities
                                  .map(
                                    (city) => DropdownMenuItem<String>(
                                      value: city,
                                      child: Text(
                                        city,
                                        style:
                                            GoogleFonts.poppins(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedCity = v);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Longitude + Latitude
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput("Longitude", _longCtrl,
                                isNumber: true),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput("Latitude", _latCtrl,
                                isNumber: true),
                          ),
                        ],
                      ),

                      // Price + Discount
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput("Price (₪)", _priceCtrl,
                                isNumber: true),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput("Discount %", _discountCtrl,
                                isNumber: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Price type chips
                      Text(
                        "Price Type",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceTypeChip("Per Event"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPriceTypeChip("Per Hour"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPriceTypeChip("Per Person"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category with icons
                      Text(
                        "Service Category",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: _inputDecoration("Category"),
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        items: kServiceCategories
                            .map(
                              (cat) => DropdownMenuItem<String>(
                                value: cat['value'] as String,
                                child: Row(
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 18,
                                      color: kPrimaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat['label'] as String,
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedCategory = v);
                        },
                      ),
                    ],
                  ),
                ),

                // Images
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gallery",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Upload a few shots that represent your work.",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final img in _images)
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image(
                                    image: FileImage(File(img)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Color(0xFFD1D5DB),
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined,
                                        size: 22, color: kPrimaryColor),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Add",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: kPrimaryColor,
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
                ),

                // Highlights + visibility (تم حذف قسم Packages فقط)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Highlights",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: kTextColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _addHighlight,
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 20, color: kPrimaryColor),
                          ),
                        ],
                      ),
                      if (_highlights.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Add key points that make your service special.",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      if (_highlights.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 4),
                            for (final h in _highlights)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 16, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (h["title"] ?? "").toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: kTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if ((h["url"] ?? "")
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              (h["url"] ?? "").toString(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      const Divider(height: 24),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Visible in search",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: kTextColor,
                          ),
                        ),
                        subtitle: Text(
                          "Turn off if you are temporarily unavailable.",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: _isVisible,
                        activeColor: kPrimaryColor,
                        onChanged: (v) => setState(() => _isVisible = v),
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

  // Helpers

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kPrimaryColor,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 14, color: kTextColor),
        maxLines:
            (label == "Full Description" || label == "Description") ? 3 : 1,
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _buildPriceTypeChip(String value) {
    final bool isSelected = _priceType == value;

    return GestureDetector(
      onTap: () {
        setState(() => _priceType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? kPrimaryColor : const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : kTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
