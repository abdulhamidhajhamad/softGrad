// lib/screens/enter_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EnterDetailsScreen extends StatefulWidget {
  final String role; // 'bride' | 'groom'
  const EnterDetailsScreen({super.key, required this.role});

  @override
  State<EnterDetailsScreen> createState() => _EnterDetailsScreenState();
}

class _EnterDetailsScreenState extends State<EnterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _partnerNameController = TextEditingController();
  final _partnerEmailController = TextEditingController();
  final _guestsController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  // City
  String? _selectedCity = 'Nablus';
  final List<String> _cities = const ['Nablus', 'Ramallah (COMING SOON)'];

  // Currency
  String? _selectedCurrency;
  final List<String> _currencies = const ['₪ (ILS)', 'د.أ  (JOD)'];

  static const Color kBrand = Color(0xFFB14E56);
  static const Color kSuccess = Color(0xFF2E7D32);

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  Future<void> _pickImage() async {
    final XFile? x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      setState(() => _pickedImage = File(x.path));
    }
  }

  @override
  void initState() {
    super.initState();
    for (final c in [
      _partnerNameController,
      _partnerEmailController,
      _guestsController,
      _budgetController,
    ]) {
      c.addListener(_onAnyChange);
    }
  }

  @override
  void dispose() {
    _partnerNameController.dispose();
    _partnerEmailController.dispose();
    _guestsController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // Disabled item for Ramallah (COMING SOON)
  List<DropdownMenuItem<String>> get _cityItems => _cities.map((e) {
    final disabled = e.contains('(COMING SOON)');
    return DropdownMenuItem<String>(
      value: e,
      enabled: !disabled,
      child: Row(
        children: [
          if (disabled) ...[
            const Icon(
              Icons.lock_clock,
              size: 16,
              color: Color.fromARGB(255, 141, 138, 138),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            e,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: disabled ? FontWeight.w500 : FontWeight.w600,
              color: disabled
                  ? const Color.fromARGB(255, 181, 179, 179)
                  : const Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }).toList();

  List<DropdownMenuItem<String>> _toMenuItems(List<String> data) => data
      .map(
        (e) => DropdownMenuItem<String>(
          value: e,
          child: Text(e, style: GoogleFonts.montserrat(fontSize: 14)),
        ),
      )
      .toList();

  bool _isFormValid = false;

  void _onAnyChange() {
    _formKey.currentState?.validate();
    _recomputeValidity();
  }

  void _recomputeValidity() {
    final ok =
        (_partnerNameController.text.trim().length >= 3) &&
        RegExp(
          r'^[\w\.\-]+@[\w\.\-]+\.\w+$',
        ).hasMatch(_partnerEmailController.text.trim()) &&
        int.tryParse(_guestsController.text.trim()) != null &&
        _selectedCity != null &&
        _selectedCurrency != null &&
        _budgetController.text.trim().isNotEmpty;

    if (ok != _isFormValid) setState(() => _isFormValid = ok);
  }

  void _onContinue() {
    final valid = _formKey.currentState?.validate() ?? false;
    _recomputeValidity();
    if (!valid || !_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB00020),
          content: Text(
            'Please fill all fields correctly!',
            style: GoogleFonts.montserrat(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kSuccess,
        content: Text(
          'Details saved successfully!',
          style: GoogleFonts.montserrat(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pushNamed(context, '/schedule_wedding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enter more details',
          style: GoogleFonts.cookie(
            fontSize: 35,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 120, 14, 14),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _onAnyChange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Picture picker block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _box(),
                child: Row(
                  children: [
                    // Avatar preview (tappable)
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kBrand.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickedImage == null
                            ? const Icon(Icons.camera_alt, color: kBrand)
                            : Image.file(_pickedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select your picture',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can change it anytime',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _label('Partner Name *'),
              _field(
                controller: _partnerNameController,
                icon: Icons.person_outline,
                hint: "What is your partner's name?",
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Enter a valid name'
                    : null,
              ),

              const SizedBox(height: 20),

              _label('Partner Email *'),
              _field(
                controller: _partnerEmailController,
                icon: Icons.email_outlined,
                hint: "What is your partner's email?",
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    RegExp(
                      r'^[\w\.\-]+@[\w\.\-]+\.\w+$',
                    ).hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Enter a valid email',
              ),

              const SizedBox(height: 20),

              _label('Guests'),
              _field(
                controller: _guestsController,
                icon: Icons.people_outline,
                hint: 'How many guests do you expect?',
                keyboardType: TextInputType.number,
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Enter a number' : null,
              ),

              const SizedBox(height: 20),

              _label('City'),
              _dropdownRow<String>(
                icon: Icons.location_city,
                value: _selectedCity,
                items: _cityItems, // disabled Ramallah
                onChanged: (val) {
                  if (val != null && !val.contains('(COMING SOON)')) {
                    setState(() => _selectedCity = val);
                    _onAnyChange();
                  }
                },
                hint: 'Choose city',
              ),

              const SizedBox(height: 20),

              _label('Budget & Currency'),
              // Row: currency first, then budget
              Container(
                decoration: _box(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Currency dropdown
                    const Icon(
                      Icons.currency_exchange,
                      color: Color(0xFF2C2C2C),
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          items: _toMenuItems(_currencies),
                          onChanged: (val) {
                            setState(() => _selectedCurrency = val);
                            _onAnyChange();
                          },
                          hint: Text(
                            'Select currency',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Budget field
                    Expanded(
                      child: _innerField(
                        controller: _budgetController,
                        hint: 'Approx. budget',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter budget' : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? kSuccess : kBrand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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

  // ----- UI helpers -----
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF757575),
      ),
    ),
  );

  // Field with leading icon outside the TextFormField to align error text.
  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: _box(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C2C2C), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: (_) => _onAnyChange(),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF2C2C2C),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                // Align error with input start, reduce spacing.
                errorStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  height: 1.0,
                  color: const Color(0xFFB00020),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inner field without icon, for composite rows.
  Widget _innerField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => _onAnyChange(),
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: const Color(0xFF2C2C2C),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 14,
          color: const Color(0xFF9E9E9E),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        errorStyle: GoogleFonts.montserrat(
          fontSize: 12,
          height: 1.0,
          color: const Color(0xFFB00020),
        ),
      ),
    );
  }

  Widget _dropdownRow<T>({
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _box(),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C2C2C), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items,
                onChanged: (v) {
                  onChanged(v);
                  _onAnyChange();
                },
                hint: Text(
                  hint,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
