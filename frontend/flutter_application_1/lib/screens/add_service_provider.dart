// lib/screens/add_service_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'help_add_service_provider.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class AddServiceProviderScreen extends StatefulWidget {
  const AddServiceProviderScreen({Key? key}) : super(key: key);

  @override
  State<AddServiceProviderScreen> createState() =>
      _AddServiceProviderScreenState();
}

class _AddServiceProviderScreenState extends State<AddServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController(text: "Your Brand Name");
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _fullDescCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  String _selectedCategory = "Photographers";
  String _selectedCity = "Nablus";
  String _otherCity = "";
  bool _isVisible = true;

  String _priceType = "Per Event"; // chips

  List<String> _images = [];
  List<Map<String, dynamic>> _packages = [];
  List<String> _highlights = [];

  final List<Map<String, dynamic>> _categories = [
    {"name": "Venues", "icon": Icons.apartment},
    {"name": "Photographers", "icon": Icons.photo_camera},
    {"name": "Catering", "icon": Icons.restaurant_menu},
    {"name": "Cake", "icon": Icons.cake},
    {"name": "Flower Shops", "icon": Icons.local_florist},
    {"name": "Decor & Lighting", "icon": Icons.wb_incandescent_outlined},
    {"name": "Music & Entertainment", "icon": Icons.music_note},
    {"name": "Wedding Planners & Coordinators", "icon": Icons.event_note},
    {"name": "Card Printing", "icon": Icons.print},
    {"name": "Jewelry & Accessories", "icon": Icons.diamond},
    {"name": "Car Rental & Transportation", "icon": Icons.directions_car},
    {"name": "Gift & Souvenir", "icon": Icons.redeem},
  ];

  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 10) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _images.add(picked.path));
    }
  }

  void _addPackage() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Add Package",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Package Name"),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: "Short Description"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  setState(() {
                    _packages.add({
                      "name": nameCtrl.text,
                      "price": priceCtrl.text,
                      "desc": descCtrl.text,
                    });
                  });
                  Navigator.pop(context);
                },
                child: Text("Add Package",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  // highlight chips
  void _addHighlight() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Highlight", style: GoogleFonts.poppins()),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "Highlight text"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _highlights.add(ctrl.text));
              Navigator.pop(context);
            },
            child:
                Text("Add", style: GoogleFonts.poppins(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _saveService() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please complete required fields"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    /// simulate success
    Navigator.pop(context, {
      "name": _nameCtrl.text.trim(),
      "brand": _brandCtrl.text.trim(),
      "tagline": _taglineCtrl.text.trim(), // ← مهم
      "address": _addressCtrl.text.trim(), // ← مهم

      "category": _selectedCategory,
      "city": _selectedCity == "Other" ? _otherCity : _selectedCity,

      "price": double.tryParse(_priceCtrl.text) ?? 0,
      "priceType": _priceType,
      "discount": _discountCtrl.text.trim(),

      "shortDescription": _shortDescCtrl.text.trim(),
      "fullDescription": _fullDescCtrl.text.trim(),

      "images": List<String>.from(_images),
      "packages": List<Map<String, dynamic>>.from(_packages),
      "highlights": List<String>.from(_highlights),

      "isActive": _isVisible,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Service",
          style: GoogleFonts.poppins(
              fontSize: 19, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpAddServiceProvider(),
                ),
              );
            },
          ),
        ],
      ),

      // bottom buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {},
                child: Text("Save as Draft",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey.shade700)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text("Save Service",
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------
              // SECTION: BASIC INFO
              // -------------------------
              Text("Basic Info",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              _inputCard(
                Column(
                  children: [
                    _label("Service Name"),
                    TextFormField(
                      controller: _nameCtrl,
                      validator: (v) => v!.trim().isEmpty ? "Required" : null,
                      decoration: _inputDecoration("e.g., Wedding Photography"),
                    ),
                    const SizedBox(height: 14),
                    _label("Brand / Business Name"),
                    TextFormField(
                      controller: _brandCtrl,
                      decoration: _inputDecoration("Your brand name"),
                    ),
                    const SizedBox(height: 14),
                    _label("Short Tagline (optional)"),
                    TextFormField(
                      controller: _taglineCtrl,
                      maxLength: 80,
                      decoration: _inputDecoration(
                          "A short catchy sentence about your service"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // -------------------------
              // SECTION: CATEGORY & LOCATION
              // -------------------------
              Text("Category & Location",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              _inputCard(
                Column(
                  children: [
                    _label("Category"),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(null),
                      items: _categories.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item["name"] as String,
                          child: Row(
                            children: [
                              Icon(
                                item["icon"] as IconData,
                                color: kPrimaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item["name"] as String,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedCategory = v!);
                      },
                    ),
                    const SizedBox(height: 14),
                    _label("City"),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: _inputDecoration(null),
                      items: _cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedCity = v!);
                      },
                    ),
                    if (_selectedCity == "Other") ...[
                      const SizedBox(height: 14),
                      _label("Enter City Name"),
                      TextFormField(
                        onChanged: (v) => _otherCity = v,
                        validator: (v) {
                          if (_selectedCity == "Other" && v!.trim().isEmpty) {
                            return "Required";
                          }
                          return null;
                        },
                        decoration: _inputDecoration("Enter your city name"),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _label("Address (optional)"),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: _inputDecoration("e.g., Downtown Street 12"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // -------------------------
              // SECTION: PRICING
              // -------------------------
              Text("Pricing & Packages",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              _inputCard(
                Column(
                  children: [
                    _label("Starting Price"),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                      decoration: _inputDecoration("e.g., 500")
                          .copyWith(prefixText: "\$ "),
                    ),
                    const SizedBox(height: 16),

                    // price type
                    Row(
                      children: [
                        _priceTypeChip("Per Event"),
                        const SizedBox(width: 6),
                        _priceTypeChip("Per Hour"),
                        const SizedBox(width: 6),
                        _priceTypeChip("Per Person"),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _label("Discount (%)"),
                    TextFormField(
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("0–100"),
                    ),

                    if (_discountCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                    ],

                    const SizedBox(height: 24),
                    _label("Packages (optional)"),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _addPackage,
                        child: const Text("+ Add Package"),
                      ),
                    ),

                    Column(
                      children: _packages
                          .map((p) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${p['name']} — \$${p['price']}\n${p['desc']}",
                                        style:
                                            GoogleFonts.poppins(fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() => _packages.remove(p));
                                      },
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // -------------------------
              // SECTION: DESCRIPTION
              // -------------------------
              Text("Description & Details",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              _inputCard(
                Column(
                  children: [
                    _label("Short Description"),
                    TextFormField(
                      controller: _shortDescCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      validator: (v) => v!.trim().isEmpty ? "Required" : null,
                      decoration:
                          _inputDecoration("Briefly describe your service..."),
                    ),
                    const SizedBox(height: 16),
                    _label("Full Description / Details"),
                    TextFormField(
                      controller: _fullDescCtrl,
                      maxLines: 6,
                      maxLength: 1500,
                      decoration: _inputDecoration(
                          "Tell couples everything they need to know..."),
                    ),
                    const SizedBox(height: 20),
                    _label("Key Highlights (optional)"),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: _addHighlight,
                        child: const Text("+ Add Highlight"),
                      ),
                    ),
                    Column(
                      children: _highlights
                          .map((h) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.circle,
                                    size: 8, color: Colors.black87),
                                title: Text(h,
                                    style: GoogleFonts.poppins(fontSize: 13)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      setState(() => _highlights.remove(h)),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // -------------------------
              // SECTION: MEDIA
              // -------------------------
              Text("Service Photos",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                "Upload high-quality images (up to 10).",
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library_outlined),
                            title: const Text("Choose from Gallery"),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt_outlined),
                            title: const Text("Take a Photo"),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined,
                            color: kPrimaryColor, size: 40),
                        const SizedBox(height: 6),
                        Text("Upload Photos",
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text("Tap to add images",
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _images
                      .map(
                        (path) => Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(File(path),
                                    fit: BoxFit.cover, width: 110, height: 110),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _images.remove(path)),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              if (_images.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "We recommend adding at least 1 photo.",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.orange.shade700),
                  ),
                ),

              const SizedBox(height: 30),

              // -------------------------
              // SETTINGS & VISIBILITY
              // -------------------------
              Text("Settings & Visibility",
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              _inputCard(
                Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: Text("Make this service visible",
                          style: GoogleFonts.poppins(fontSize: 15)),
                      subtitle: Text(
                        "You can hide or show this service anytime.",
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      value: _isVisible,
                      activeColor: kPrimaryColor,
                      onChanged: (v) => setState(() => _isVisible = v),
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

  // HELPER: input decoration
  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _inputCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _priceTypeChip(String label) {
    final isActive = _priceType == label;
    return GestureDetector(
      onTap: () => setState(() => _priceType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.black,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
