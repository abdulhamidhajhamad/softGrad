// signup_provider.dart (ملف مصحح)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/auth_service.dart'; // استخدام AuthService
import 'package:flutter_application_1/screens/provider/home_provider.dart'; // استيراد شاشة لوحة التحكم
import 'package:flutter_application_1/services/vendor_auth_service.dart';
import 'package:flutter_application_1/screens/compliance_provider/compliance_provider.dart';
// يجب أن يكون لديك تعريف لـ ProviderModel في ملف HomeProviderScreen أو آخر.

class SignUpProviderScreen extends StatefulWidget {
  const SignUpProviderScreen({Key? key}) : super(key: key);

  @override
  State<SignUpProviderScreen> createState() => _SignUpProviderScreenState();
}

class _SignUpProviderScreenState extends State<SignUpProviderScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _brandCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _otherCityCtrl = TextEditingController();

  // Dropdowns
  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Jerusalem',
    'Hebron',
    'Bethlehem',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Jericho',
    'Salfit',
    'Tubas',
    'Gaza',
    'Khan Yunis',
    'Rafah',
    'Deir al-Balah',
    'Al-Bireh',
    'Other',
  ];
  String? _selectedCity;

  bool _isLoading = false;

  // 🆕 متغيرات الشعار
  File? _logoFile; // للموبايل
  Uint8List? _logoBytes; // للويب
  String? _logoFileName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    print('🔗 Testing vendor connection to server...');
    await AuthService.testConnection();
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _otherCityCtrl.dispose();
    super.dispose();
  }

  // Colors
  static const kPrimaryButtonColor = Color.fromARGB(215, 20, 20, 215);
  static const kTextColor = Colors.black;

  // Decoration (لم يتم تغييرها)
  InputDecoration _decor({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade700),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kPrimaryButtonColor, width: 2),
      ),
    );
  }

  Text _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      );

  // ======================================================
  // 🆕 Logo Picker
  // ======================================================
  Future<void> _pickLogo() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // للويب
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _logoBytes = bytes;
            _logoFileName = pickedFile.name;
          });
        } else {
          // للموبايل
          setState(() {
            _logoFile = File(pickedFile.path);
            _logoFileName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      print('❌ Error picking logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _logoBytes = null;
      _logoFileName = null;
    });
  }

  // ======================================================
  // Submit → API Call
  // ======================================================
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. تسجيل تفاصيل المزود
        final registerResponse = await AuthService.registerProviderDetails(
          companyName: _brandCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          city: _selectedCity == "Other"
              ? _otherCityCtrl.text.trim()
              : _selectedCity!,
          description: _bioCtrl.text.trim(),
        );

        // 2. 🆕 رفع الشعار إذا تم اختياره
        if (_logoFile != null || _logoBytes != null) {
          try {
            await AuthService.uploadCompanyLogo(
              logoFile: kIsWeb ? _logoBytes : _logoFile,
              fileName: _logoFileName,
            );
          } catch (logoError) {
            print('⚠️ Logo upload failed, continuing without logo: $logoError');
            // نستمر حتى لو فشل رفع الشعار
          }
        }

        // 3. النجاح - الانتقال إلى شاشة التحقق
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              isFromSignup: true,
              providerData: {
                'companyName': _brandCtrl.text.trim(),
                'email': _emailCtrl.text.trim(),
                'phone': _phoneCtrl.text.trim(),
                'city': _selectedCity == "Other"
                    ? _otherCityCtrl.text.trim()
                    : _selectedCity!,
                'description': _bioCtrl.text.trim(),
              },
            ),
          ),
        );
      } catch (e) {
        String errorMessage = 'An error occurred during provider registration.';

        if (e.toString().contains('already have a company')) {
          errorMessage =
              'You already have a company registered with this name.';
        } else if (e.toString().contains('Authentication token not found')) {
          errorMessage =
              'Session expired. Please sign in again before completing provider registration.';
        } else if (e.toString().contains('Network error')) {
          errorMessage = 'Network error. Please check your connection.';
        } else {
          // رسالة خطأ عامة أخرى
          errorMessage =
              'Registration failed: ${e.toString().split(':')[1].trim()}';
        }

        _showErrorDialog(errorMessage);
        await AuthService.deleteToken();
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Registration Failed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(215, 20, 20, 215),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🆕 Logo Picker Widget - Modern & Clean Design
  // ======================================================
  Widget _buildLogoPicker() {
    final bool hasLogo = _logoFile != null || _logoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('Company Logo'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Optional',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Logo Container
        Center(
          child: GestureDetector(
            onTap: _isLoading ? null : _pickLogo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: hasLogo ? Colors.transparent : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasLogo ? kPrimaryButtonColor.withOpacity(0.5) : Colors.grey.shade300,
                  width: hasLogo ? 2 : 1.5,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: hasLogo
                    ? [
                        BoxShadow(
                          color: kPrimaryButtonColor.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // الصورة أو الأيقونة الافتراضية
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: hasLogo
                        ? _buildLogoPreview()
                        : _buildDefaultLogoPlaceholder(),
                  ),
                  
                  // زر الحذف
                  if (hasLogo)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: _removeLogo,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  
                  // زر التعديل
                  if (hasLogo)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kPrimaryButtonColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // نص المساعدة
        Center(
          child: Text(
            hasLogo 
                ? 'Tap to change your logo' 
                : 'Add your company logo for better visibility',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPreview() {
    if (kIsWeb && _logoBytes != null) {
      return Image.memory(
        _logoBytes!,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
      );
    } else if (_logoFile != null) {
      return Image.file(
        _logoFile!,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox();
  }

  Widget _buildDefaultLogoPlaceholder() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryButtonColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: kPrimaryButtonColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload Logo',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BUILD UI =====================
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,

      // Back Button
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            media.padding.top > 0 ? 16 : 24,
            24,
            16 + media.viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Complete Provider Registration',
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your business details to complete registration.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // 🆕 COMPANY LOGO PICKER (اختياري)
                _buildLogoPicker(),
                const SizedBox(height: 24),

                // BRAND NAME
                _label('Brand Name'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _brandCtrl,
                  decoration: _decor(
                    hint: 'Enter your brand name',
                    icon: Icons.storefront_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter brand name' : null,
                ),
                const SizedBox(height: 16),

                // EMAIL (للتأكد من الإدخال الصحيح)
                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decor(
                    hint: 'you@business.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(v.trim());
                    return ok ? null : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 16),

                // PHONE
                _label('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _decor(
                    hint: 'Enter your phone number',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter phone number'
                      : null,
                ),
                const SizedBox(height: 16),

                // BIO (وصف الخدمات)
                _label('Bio'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _bioCtrl,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: _decor(
                    hint: 'Provide a brief description of your services',
                    icon: Icons.description_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your bio/description';
                    }
                    final words = v.trim().split(RegExp(r'\s+')).length;
                    if (words > 200) return 'Max 200 words allowed';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CITY
                _label('City'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  value: _selectedCity,
                  items: _cities
                      .map(
                        (city) => DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  decoration: _decor(
                      hint: "Select your city",
                      icon: Icons.location_city_outlined),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Select your city' : null,
                ),

                if (_selectedCity == "Other") ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: _otherCityCtrl,
                    decoration: _decor(
                      hint: 'Enter your city',
                      icon: Icons.edit_location_alt_outlined,
                    ),
                    validator: (v) {
                      if (_selectedCity == "Other" &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryButtonColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Complete Registration',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context, '/signin'),
                      child: Text(
                        ' Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isLoading
                              ? Colors.grey.shade400
                              : kPrimaryButtonColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
