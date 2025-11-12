import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/vendors.dart';

class BecomeProviderScreen extends StatefulWidget {
  final bool isDarkMode;
  const BecomeProviderScreen({Key? key, this.isDarkMode = false})
      : super(key: key);

  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  // Handle form submission
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You're now a provider! Welcome aboard 🎉")),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Dispose controllers
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;

    // Background color
    final Color pageBg =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFBE6);

    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subText = isDarkMode ? Colors.white70 : Colors.black54;

    // Input field color
    final Color inputFill =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    // Main accent color
    const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);

    final categories = VendorsListPage.vendorData;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(
          'Become a Provider',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: pageBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header icon
            const Icon(Icons.storefront_rounded,
                size: 60, color: Color.fromARGB(215, 20, 20, 215)),
            const SizedBox(height: 12),

            // Title text
            Text(
              'Join Our Network of Wedding Service Providers',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 18),

            // Subtitle text
            Text(
              'Grow your business by connecting with couples planning their big day',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: subText),
            ),
            const SizedBox(height: 24),

            // Form card
            Card(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: isDarkMode ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand name field
                      _buildTextField(
                        controller: _brandCtrl,
                        label: 'Brand Name',
                        hint: 'Enter your Business name',
                        validatorMsg: 'Please enter your brand name',
                        textColor: textColor,
                        fillColor: inputFill,
                        isDark: isDarkMode,
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      _buildDropdown(
                        categories,
                        kAccentColor,
                        (val) => setState(() => _selectedCategory = val),
                        isDarkMode,
                        textColor,
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      _buildTextField(
                        controller: _descCtrl,
                        label: 'Business Description',
                        hint: 'Describe your services briefly..',
                        maxLines: 3,
                        textColor: textColor,
                        fillColor: inputFill,
                        isDark: isDarkMode,
                      ),
                      const SizedBox(height: 16),

                      // Contact number field
                      _buildTextField(
                        controller: _contactCtrl,
                        label: 'Contact Number',
                        hint: '+970 59 123 4567',
                        keyboardType: TextInputType.phone,
                        validatorMsg: 'Please enter your contact number',
                        textColor: textColor,
                        fillColor: inputFill,
                        isDark: isDarkMode,
                      ),
                      const SizedBox(height: 16),

                      // City field
                      _buildTextField(
                        controller: _locationCtrl,
                        label: 'City',
                        hint: 'e.g. Nablus, Ramallah',
                        textColor: textColor,
                        fillColor: inputFill,
                        isDark: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Become a Provider',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Note text
            Text(
              'You can edit these details anytime in your profile.',
              style: GoogleFonts.poppins(fontSize: 13, color: subText),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Text field widget ----
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color textColor,
    required Color fillColor,
    required bool isDark,
    String? validatorMsg,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color borderColor = Color.fromARGB(215, 20, 20, 215);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 6),

        // Input field
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          validator: validatorMsg != null
              ? (v) => (v == null || v.isEmpty) ? validatorMsg : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 13,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Dropdown widget ----
  Widget _buildDropdown(
    List<Map<String, dynamic>> categories,
    Color accentColor,
    Function(String?) onChanged,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text('Category',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 6),

        // Dropdown field
        DropdownButtonFormField<String>(
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          value: _selectedCategory,
          items: categories
              .map((cat) => DropdownMenuItem<String>(
                    value: cat['name'],
                    child: Row(
                      children: [
                        Icon(cat['icon'], color: accentColor, size: 18),
                        const SizedBox(width: 8),
                        Text(cat['name'],
                            style: GoogleFonts.poppins(
                                fontSize: 13.5, color: textColor)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Select a Category',
            hintStyle: GoogleFonts.poppins(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 11,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
          validator: (value) =>
              value == null ? 'Please select a category' : null,
        ),
      ],
    );
  }
}
