// lib/screens/edit_profile_company.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/edit_profile_service.dart';

class EditProfileCompany extends StatefulWidget {
  const EditProfileCompany({Key? key}) : super(key: key);

  @override
  State<EditProfileCompany> createState() => _EditProfileCompanyState();
}

class _EditProfileCompanyState extends State<EditProfileCompany> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _descCtrl;

  File? _logo;
  String? _existingLogoUrl;
  
  // حفظ البيانات القديمة
  String _originalCompanyName = '';
  String _originalEmail = '';
  String _originalPhone = '';
  String _originalCity = '';
  String _originalDescription = '';
  
  bool _isLoading = true;
  bool _isSaving = false;

  static const kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      setState(() => _isLoading = true);
      
      final providerData = await EditProfileService.getProviderDetails();
      
      print('📦 Provider data received: $providerData');
      
      if (mounted) {
        setState(() {
          // ✅ قراءة البيانات من الـ Response المباشر
          _originalCompanyName = providerData['companyName']?.toString() ?? '';
          _originalDescription = providerData['description']?.toString() ?? '';
          _originalCity = providerData['city']?.toString() ?? '';
          _originalEmail = providerData['email']?.toString() ?? '';
          _originalPhone = providerData['phone']?.toString() ?? '';
          
          // ✅ تعيين القيم للـ Controllers
          _nameCtrl.text = _originalCompanyName;
          _descCtrl.text = _originalDescription;
          _cityCtrl.text = _originalCity;
          _emailCtrl.text = _originalEmail;
          _phoneCtrl.text = _originalPhone;
          
          // الشعار
          final logo = providerData['image'] ?? providerData['logo'];
          if (logo != null && logo.toString().isNotEmpty) {
            _existingLogoUrl = logo.toString();
          }
          
          _isLoading = false;
        });
        
        print('✅ Data loaded successfully:');
        print('Company: ${_nameCtrl.text}');
        print('Email: ${_emailCtrl.text}');
        print('Phone: ${_phoneCtrl.text}');
        print('City: ${_cityCtrl.text}');
        print('Description: ${_descCtrl.text}');
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load company data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decor(String hint, {IconData? icon}) {
    return InputDecoration(
      labelText: hint,
      labelStyle:
          GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.grey.shade700, size: 20)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _logo = File(picked.path));
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              )),
          const SizedBox(height: 16),
          ...children
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      // ✅ إرسال فقط الحقول التي تغيرت
      final String? companyNameToSend = _nameCtrl.text.trim() != _originalCompanyName 
          ? _nameCtrl.text.trim() 
          : null;
      
      final String? emailToSend = _emailCtrl.text.trim() != _originalEmail 
          ? _emailCtrl.text.trim() 
          : null;
      
      final String? phoneToSend = _phoneCtrl.text.trim() != _originalPhone 
          ? _phoneCtrl.text.trim() 
          : null;
      
      final String? cityToSend = _cityCtrl.text.trim() != _originalCity 
          ? _cityCtrl.text.trim() 
          : null;
      
      final String? descToSend = _descCtrl.text.trim() != _originalDescription 
          ? _descCtrl.text.trim() 
          : null;

      print('📤 Sending update:');
      print('CompanyName: $companyNameToSend');
      print('Email: $emailToSend');
      print('Phone: $phoneToSend');
      print('City: $cityToSend');
      print('Description: $descToSend');
      print('Logo: ${_logo?.path}');

      final result = await EditProfileService.updateProviderDetails(
        companyName: companyNameToSend,
        email: emailToSend,
        phone: phoneToSend,
        city: cityToSend,
        description: descToSend,
        logoPath: _logo?.path,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company information updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, result);
      }
    } catch (e) {
      print('❌ Error saving: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update company information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          title: Text(
            "Company Information",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.black, fontSize: 18),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: kPrimaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Text(
          "Company Information",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, color: Colors.black, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // LOGO CARD
              _card(
                title: "Company Logo",
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                          image: _logo != null
                              ? DecorationImage(
                                  image: FileImage(_logo!),
                                  fit: BoxFit.cover,
                                )
                              : (_existingLogoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_existingLogoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: _logo == null && _existingLogoUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      size: 30, color: Colors.grey.shade600),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Upload Logo",
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              // COMPANY DETAILS CARD
              _card(
                title: "Company Details",
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _decor("Name", icon: Icons.business),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decor("Email", icon: Icons.mail),
                    validator: (v) {
                      if (v!.isEmpty) return "Required";
                      if (!v.contains("@")) return "Invalid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _decor("Phone", icon: Icons.call),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cityCtrl,
                    decoration: _decor("City", icon: Icons.location_on),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _decor("Description", icon: Icons.description),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Save Company Information",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
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
}