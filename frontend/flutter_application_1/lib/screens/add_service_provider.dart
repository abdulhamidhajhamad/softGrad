// lib/screens/add_service_provider.dart

import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⭐️ NEW: لاستخدامه في التحقق من بيئة الويب

// Import the Service Layer for the API call
import 'package:flutter_application_1/services/service_service.dart';

// افتراض وجود هذا الملف للإرشاد/المساعدة، يمكنك تعديله حسب المسار الفعلي
import 'help_add_service_provider.dart'; 

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class AddServiceProviderScreen extends StatefulWidget {
  const AddServiceProviderScreen({Key? key}) : super(key: key);

  @override
  State<AddServiceProviderScreen> createState() =>
      _AddServiceProviderState();
}

class _AddServiceProviderState extends State<AddServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // controllers
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _fullDescCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(); 
  
  // ⭐️ متحكمات (Controllers) لخطوط الطول والعرض
  final _latCtrl = TextEditingController();
  final _longCtrl = TextEditingController();


  String _selectedCategory = "Photographers";
  String _selectedCity = "Nablus";
  String _otherCity = "";
  bool _isVisible = true;
  String _priceType = "Per Event"; 
  
  // ⭐️ تم تغيير النوع إلى XFile لدعم الويب والمحمول
  final List<XFile> _selectedImages = []; 

  // قائمة المدن (اختصارا)
  final List<String> _cities = const [
    "Nablus", "Ramallah", "Hebron", "Jenin", "Tulkarm", "Jerusalem", "Other"
  ];
  
  // قائمة الفئات
  final List<String> _categories = const [
    'Venues', 'Photographers', 'Catering', 'Cake', 'Flower Shops', 
    'Makeup Artists', 'Music Bands', 'Decorations'
  ];


  // دالة اختيار الصور المتعددة
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can select a maximum of 10 images.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1000,
      imageQuality: 90,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var pickedFile in pickedFiles) {
          if (_selectedImages.length < 10) {
            // ⭐️ تخزين XFile مباشرة
            _selectedImages.add(pickedFile); 
          } else {
            break; 
          }
        }
      });
    }
  }

  // دالة إضافة الخدمة المحدثة لإرسال البيانات والملفات
  Future<void> _addService() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one service photo.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // تحويل Lat/Long إلى رقم Double
        final double? lat = double.tryParse(_latCtrl.text);
        final double? long = double.tryParse(_longCtrl.text);

        // التأكد من صحة الإدخال الرقمي
        if (lat == null || long == null) {
          throw Exception('Please enter valid numerical values for Latitude and Longitude.');
        }

        // تجهيز بيانات الخدمة النصية
        final serviceData = {
          'serviceName': _nameCtrl.text,
          'category': _selectedCategory,
          'price': double.tryParse(_priceCtrl.text) ?? 0, 
          'isActive': _isVisible, 
          'additionalInfo': {
            'description': _fullDescCtrl.text.isNotEmpty
                ? _fullDescCtrl.text
                : _shortDescCtrl.text,
          },
          // ⭐️ تم إضافة خطوط الطول والعرض هنا
          'location': {
            'address': _addressCtrl.text,
            'city': _selectedCity == 'Other' ? _otherCity : _selectedCity,
            'latitude': lat, 
            'longitude': long, 
          },
        };

        // استدعاء الدالة التي ترسل البيانات والملفات (تقبل XFile)
        await ServiceService.addService(serviceData, _selectedImages);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Service added successfully!'),
              backgroundColor: Colors.green),
        );
        // يمكنك إضافة Navigator.pop(context) هنا للعودة للخلف
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add service: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Text(
          "Add New Service",
          style:
              GoogleFonts.poppins(color: kTextColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const HelpAddServiceProvider(); 
                  },
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // 1. Basic Info
              _inputCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("1. Service Name"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameCtrl,
                      hintText: "E.g., Event Photography Package",
                      validator: (value) =>
                          value!.isEmpty ? 'Service Name is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 2. Category
              _inputCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("2. Category"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(),
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 3. Location and City (محدثة)
              _inputCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("3. Location Details"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressCtrl,
                      hintText: "Detailed Address (e.g., Street, Building No.)",
                      validator: (value) =>
                          value!.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(),
                      value: _selectedCity,
                      isExpanded: true,
                      items: _cities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCity = newValue!;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a city' : null,
                    ),
                    if (_selectedCity == 'Other') ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: TextEditingController(text: _otherCity),
                        hintText: "Enter Other City Name",
                        onChanged: (value) => _otherCity = value,
                        validator: (value) => value!.isEmpty
                            ? 'Please enter the city name'
                            : null,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    _label("Latitude & Longitude"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _latCtrl,
                            hintText: "Latitude",
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                double.tryParse(value!) == null
                                    ? 'Valid number required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _longCtrl,
                            hintText: "Longitude",
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                double.tryParse(value!) == null
                                    ? 'Valid number required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 4. Pricing
              _inputCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("4. Pricing"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _priceCtrl,
                      hintText: "Price (e.g., 500)",
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text("Pricing Unit:", style: GoogleFonts.poppins(fontSize: 12)),
                    Row(
                      children: [
                        _priceTypeChip("Per Event"),
                        const SizedBox(width: 8),
                        _priceTypeChip("Per Hour"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 5. Description
              _inputCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("5. Description"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _shortDescCtrl,
                      hintText: "Short Description (Visible in lists)",
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _fullDescCtrl,
                      hintText: "Full Description (Visible on service page)",
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // ----------------------------------------------------
              // 6. قسم الصور
              _inputCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("6. Service Photos (Max 10)"),
                    const SizedBox(height: 12),
                    // زر إضافة الصور
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(
                            'Add Photos (${_selectedImages.length}/10)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: kPrimaryColor),
                          foregroundColor: kPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // عرض المصغرات
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 80, 
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final imageFile = _selectedImages[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      // ⭐️ التحقق من المنصة لحل مشكلة الـ Web
                                      image: DecorationImage(
                                        image: kIsWeb
                                            ? NetworkImage(imageFile.path) // للويب (يستخدم Blob URL)
                                            : FileImage(File(imageFile.path)) as ImageProvider<Object>, // للمحمول
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // زر الحذف
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 7. Visibility Toggle
              _inputCard(
                Row(
                  children: [
                    _label("7. Service Visibility"),
                    const Spacer(),
                    Switch.adaptive(
                      value: _isVisible,
                      activeColor: kPrimaryColor,
                      onChanged: (bool newValue) {
                        setState(() {
                          _isVisible = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // 8. Submit Button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addService, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Add Service',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  // ----------------------------------------------------
  // الدوال المساعدة (Helper Methods)
  // ----------------------------------------------------

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
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
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(hintText: hintText),
      style: GoogleFonts.poppins(fontSize: 15),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor)),
    );
  }
  
  // دالة لمربعات اختيار نوع السعر
  Widget _priceTypeChip(String label) {
    final isActive = _priceType == label;
    return GestureDetector(
      onTap: () => setState(() => _priceType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: kPrimaryColor)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : kTextColor,
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _shortDescCtrl.dispose();
    _fullDescCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _latCtrl.dispose();
    _longCtrl.dispose();
    super.dispose();
  }
}