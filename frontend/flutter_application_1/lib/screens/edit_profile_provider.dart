// lib/screens/edit_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_provider.dart';

class EditProfileProvider extends StatefulWidget {
  final ProviderModel provider;

  const EditProfileProvider({Key? key, required this.provider})
      : super(key: key);

  @override
  State<EditProfileProvider> createState() => _EditProfileProviderState();
}

class _EditProfileProviderState extends State<EditProfileProvider> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _confirmCtrl;

  String? _selectedCategory;
  String? _selectedCity;

  final List<String> _categories = const [
    'Venues',
    'Photographers',
    'Catering',
    'Cake',
    'Flower Shops',
    'Decor & Lighting',
    'Music & Entertainment',
    'Wedding Planners & Coordinators',
    'Card Printing',
    'Jewelry & Accessories',
    'Car Rental & Transportation',
    'Gift & Souvenir',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Venues': Icons.location_city_outlined,
    'Photographers': Icons.camera_alt_outlined,
    'Catering': Icons.restaurant_menu_outlined,
    'Cake': Icons.cake_outlined,
    'Flower Shops': Icons.local_florist_outlined,
    'Decor & Lighting': Icons.light_mode_outlined,
    'Music & Entertainment': Icons.music_note_outlined,
    'Wedding Planners & Coordinators': Icons.event_available_outlined,
    'Card Printing': Icons.print_outlined,
    'Jewelry & Accessories': Icons.diamond_outlined,
    'Car Rental & Transportation': Icons.directions_car_filled_outlined,
    'Gift & Souvenir': Icons.card_giftcard_outlined,
  };

  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

  String _passwordStrengthLabel = "";
  Color _passwordStrengthColor = Colors.transparent;
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();

    _brandCtrl = TextEditingController(text: widget.provider.brandName);
    _emailCtrl = TextEditingController(text: widget.provider.email);
    _phoneCtrl = TextEditingController(text: widget.provider.phone);
    _descCtrl = TextEditingController(text: widget.provider.description);

    _passCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();

    _selectedCategory = widget.provider.category;
    _selectedCity = widget.provider.city;
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  static const kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

  InputDecoration _decor({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: Colors.grey.shade700)
          : null,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Text _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      );

  void _evaluatePasswordStrength(String password) {
    String label;
    Color color;

    if (password.isEmpty) {
      label = '';
      color = Colors.transparent;
    } else if (password.length < 6) {
      label = 'Weak';
      color = Colors.red;
    } else if (password.length < 16) {
      label = 'Medium';
      color = Colors.orange;
    } else {
      label = 'Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  double _strengthValue() {
    switch (_passwordStrengthLabel) {
      case 'Weak':
        return 0.33;
      case 'Medium':
        return 0.66;
      case 'Strong':
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final updatedProvider = ProviderModel(
      brandName: _brandCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      category: _selectedCategory ?? widget.provider.category,
      description: _descCtrl.text.trim(),
      city: _selectedCity ?? widget.provider.city,
      bookings: widget.provider.bookings,
      views: widget.provider.views,
      messages: widget.provider.messages,
      reviews: widget.provider.reviews,
    );

    Navigator.pop(context, updatedProvider);
  }

  Widget _modernCard({required Widget child}) {
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _modernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Profile Information"),

                    _label("Brand Name"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _brandCtrl,
                      decoration:
                          _decor(hint: "Brand name", icon: Icons.storefront_outlined),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 18),

                    _label("Email"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          _decor(hint: "Email address", icon: Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v.trim());
                        return ok ? null : "Invalid email";
                      },
                    ),

                    const SizedBox(height: 18),

                    _label("Phone"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _decor(hint: "Phone", icon: Icons.phone_outlined),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 18),

                    _label("City"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      decoration:
                          _decor(hint: "City", icon: Icons.location_city_outlined),
                      items: _cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city, style: GoogleFonts.poppins(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCity = v),
                    ),
                  ],
                ),
              ),

              _modernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Business Details"),

                    _label("Category"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: _decor(
                          hint: "Select Category", icon: Icons.category_outlined),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(_categoryIcons[cat],
                                  size: 18, color: kPrimaryColor),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(cat,
                                    style: GoogleFonts.poppins(),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v),
                    ),

                    const SizedBox(height: 18),

                    _label("Description"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: _decor(
                          hint: "Describe your business",
                          icon: Icons.description_outlined),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ],
                ),
              ),

              _modernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Security"),

                    _label("New Password"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_showPass,
                      onChanged: _evaluatePasswordStrength,
                      decoration: _decor(
                        hint: "••••••••",
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_showPass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _showPass = !_showPass),
                        ),
                      ),
                    ),

                    if (_passwordStrengthLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _strengthValue(),
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _passwordStrengthColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 16, color: _passwordStrengthColor),
                          const SizedBox(width: 6),
                          Text(
                            "Password strength: $_passwordStrengthLabel",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _passwordStrengthColor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),

                    _label("Confirm Password"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      decoration: _decor(
                        hint: "••••••••",
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_showConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (_passCtrl.text.isNotEmpty) {
                          if (v == null || v.isEmpty) return "Confirm password";
                          if (v != _passCtrl.text) return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Save Changes",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}
