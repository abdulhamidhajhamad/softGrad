// lib/screens/add_service_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/service_service.dart';
import 'dart:typed_data'; // 💡 إضافة ضرورية للتعامل مع MemoryImage (لحل مشكلة الويب)

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF111827);

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
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();

  final picker = ImagePicker();

  String? _selectedCategory;
  String? _selectedCity;
  String? _priceType;
  bool _isVisible = true;
  bool _isLoading = false;

// 1. لتخزين الصور الجديدة التي تم اختيارها فقط (قبل رفعها)
  List<Map<String, dynamic>> _images = [];
  // 2. 💡 جديد: لتخزين روابط الصور القديمة التي جُلبت من الـ Backend
  List<String> _existingImageUrls = [];
  List<Map<String, dynamic>> _highlights = [];
  List<Map<String, dynamic>> _packages = [];

  void _showLoadingSnackBar(String message, {bool isError = false}) {
    // نستخدم الألوان الافتراضية للتطبيق (kPrimaryColor و Colors.red)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : kPrimaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final d = widget.existingData!;

      _nameCtrl.text = d["name"] ?? d["serviceName"] ?? "";
      _brandCtrl.text = d["brand"] ?? d["companyName"] ?? "";
      _taglineCtrl.text = d["tagline"] ?? "";
      _addressCtrl.text = d["address"] ?? d["location"]?["address"] ?? "";

      _latitudeCtrl.text =
          (d["latitude"] ?? d["location"]?["latitude"])?.toString() ?? "";
      _longitudeCtrl.text =
          (d["longitude"] ?? d["location"]?["longitude"])?.toString() ?? "";

      _fullDescCtrl.text = d["fullDescription"] ??
          d["additionalInfo"]?["description"] ??
          d["shortDescription"] ??
          "";
      _shortDescCtrl.text = d["fullDescription"] ??
          d["additionalInfo"]?["description"] ??
          d["shortDescription"] ??
          "";

      _priceCtrl.text = d["price"]?.toString() ?? "";
      _discountCtrl.text = d["discount"]?.toString() ?? "";

      _selectedCity = d["city"] ?? d["location"]?["city"];
      _selectedCategory = d["category"];
      _priceType = d["priceType"];
      _isVisible = d["isActive"] ?? true;

      if (d['images'] is List) {
        _existingImageUrls =
            List<String>.from(d["images"]?.cast<String>() ?? []);
      }

      final rawHighlights =
          d["highlights"] ?? d["additionalInfo"]?["highlights"];
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
            return {"title": h.toString(), "url": ""};
          }
        }).toList();
      }

      _packages = List<Map<String, dynamic>>.from(d["packages"] ?? []);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _shortDescCtrl.dispose();
    _fullDescCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  Future<String> _uploadAndSaveImage(String path) async {
    // 💡 مثال افتراضي (يجب استبداله بمنطقك الفعلي):
    if (path.isEmpty) {
      throw Exception("Image path is invalid.");
    }

    // final File imageFile = File(path);
    // final String imageUrl = await SupabaseService.uploadFile(imageFile);
    // return imageUrl;

    // لإزالة خطأ التصريف حاليًا، سنعيد قيمة نصية فارغة.
    // ❌ يجب تعديل هذا السطر بمنطق الرفع الخاص بك
    return Future.value("temp_supabase_url_needs_real_logic");
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || pickedFile.path.isEmpty) {
      return;
    }

    _showLoadingSnackBar('Processing image...');

    try {
      // 💡 الحل لخطأ الـ Namespace: قراءة البايتات مباشرة من XFile
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      setState(() {
        // تخزين البايتات واسم الملف بدلاً من المسار
        _images.add({
          'bytes': bytes,
          'name': fileName,
        });
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showLoadingSnackBar('Image selected successfully.', isError: false);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showLoadingSnackBar('Failed to process image: $e', isError: true);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // 💡 تصحيح 1: إضافة فحص لـ _priceType
    if (_selectedCategory == null ||
        _selectedCity == null ||
        _priceType == null) {
      _showLoadingSnackBar('Please select Category, City, and Price Type.',
          isError: true);
      return;
    }

    // 💡 تعديل: فحص الصور يجب أن يشمل الملفات الجديدة (باستخدام _images)
    if (_images.isEmpty && _existingImageUrls.isEmpty) {
      _showLoadingSnackBar('Please upload at least one image for the service.',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🆕 1. جلب اسم الشركة تلقائياً
      final companyName = await ServiceService.fetchCompanyName();
      if (companyName == null) {
        // يمكنك هنا عرض رسالة خطأ إذا كان اسم الشركة مطلوباً بشكل صارم
        // استخدم الدالة المخصصة لديك لعرض الرسالة
        _showLoadingSnackBar(
            'Could not retrieve company name. Please contact support.',
            isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // 2. استمرار عملية الحفظ
      try {
        final double price = double.tryParse(_priceCtrl.text) ?? 0.0;
        final double? latitude = double.tryParse(_latitudeCtrl.text.trim());
        final double? longitude = double.tryParse(_longitudeCtrl.text.trim());

        final highlightsForApi = _highlights.map((h) {
          return {
            "title": h["title"].toString(),
            "url": h["url"].toString(),
          };
        }).toList();

        // 💡 تصحيح 2: تمرير companyName كمعامل جديد
        final result = await ServiceService.addService(
          title: _nameCtrl.text.trim(),
          description: _fullDescCtrl.text.trim(),
          price: price,
          priceType: _priceType!,
          highlights: highlightsForApi,
          imageFilesData: _images,
          category: _selectedCategory!,
          latitude: latitude,
          longitude: longitude,
          address: _addressCtrl.text.trim(),
          city: _selectedCity!,
          companyName: companyName, // ⬅️ 🆕 تم إضافة اسم الشركة هنا
        );

        _showLoadingSnackBar('Service saved successfully!', isError: false);
        Navigator.of(context).pop(result);
      } catch (e) {
        print('Error adding service: $e');
        _showLoadingSnackBar('Error adding service: ${e.toString()}',
            isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // التعامل مع الخطأ العام (مثل خطأ جلب اسم الشركة)
      print('General error during save process: $e');
      _showLoadingSnackBar('An unexpected error occurred: ${e.toString()}',
          isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
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
                                horizontal: 105, vertical: 12),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              "Service Details",
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInput("Name", _nameCtrl),
                    ],
                  ),
                ),
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeCtrl,
                              decoration: _inputDecoration("Latitude"),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeCtrl,
                              decoration: _inputDecoration("Longitude"),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                            // 1. عرض الصور الجديدة (التي تم اختيارها للتو)
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
                                    // ✅ التصحيح الجوهري هنا: استخدام MemoryImage
                                    // لأن img عبارة عن Map يحتوي على bytes
                                    image: MemoryImage(img['bytes']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            // 2. عرض الصور القديمة (إذا كنت في وضع التعديل)
                            for (final url in _existingImageUrls)
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
                                  child: Image.network(
                                    url, // للصور القادمة من السيرفر نستخدم Network
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                  ),
                                ),
                              ),

                            // زر الإضافة
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
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
