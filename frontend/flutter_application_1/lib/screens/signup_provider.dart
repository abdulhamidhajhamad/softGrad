import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/vendor_auth_service.dart';

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
  final _descCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otherCityCtrl = TextEditingController();

  // Dropdowns
  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

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

  String? _selectedCategory;
  String? _selectedCity;
  String _passwordStrengthLabel = "";
  Color _passwordStrengthColor = Colors.transparent;
  bool _showPass = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    print('🔗 Testing vendor connection to server...');
    await VendorAuthService.testConnection();
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otherCityCtrl.dispose();
    super.dispose();
  }

  // Colors
  static const kPrimaryButtonColor = Color.fromARGB(215, 20, 20, 215);
  static const kTextColor = Colors.black;

  // Decoration
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
  // Submit → API Call
  // ======================================================
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await VendorAuthService.signup(
          userName: _brandCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim(),
          city: _selectedCity == "Other" 
              ? _otherCityCtrl.text.trim() 
              : _selectedCity!,
          category: _selectedCategory!,
          description: _descCtrl.text.trim(),
        );

        if (response.containsKey('message')) {
          // نجح التسجيل - الانتقال لشاشة التحقق
          Navigator.pushReplacementNamed(
            context,
            '/verification',
            arguments: {
              "email": _emailCtrl.text.trim(),
              "role": "provider",
              "name": _brandCtrl.text.trim(),
              "phone": _phoneCtrl.text.trim(),
              "category": _selectedCategory,
              "description": _descCtrl.text.trim(),
              "city": _selectedCity == "Other"
                  ? _otherCityCtrl.text.trim()
                  : _selectedCity,
            },
          );
        } else {
          _showErrorDialog('Signup failed. Please try again.');
        }
      } catch (e) {
        String errorMessage = 'An error occurred. Please try again.';
        
        if (e.toString().contains('email already exists')) {
          errorMessage = 'Email already exists. Please use a different email.';
        } else if (e.toString().contains('Network error')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        
        _showErrorDialog(errorMessage);
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
          'Signup Failed',
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

  // Password strength logic
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
                  'Create Account as Provider',
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join our wedding community in a few steps',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
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

                // EMAIL
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

                // CATEGORY
                _label('Category'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  value: _selectedCategory,
                  items: _categories.map((cat) {
                    final iconData = _categoryIcons[cat];
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(iconData, size: 18, color: kPrimaryButtonColor),
                          const SizedBox(width: 8),
                          Text(
                            cat,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: _decor(
                    hint: 'Select your category',
                    icon: Icons.category_outlined,
                  ),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 16),

                // DESCRIPTION
                _label('Business Description'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: _decor(
                    hint: 'Describe your services (max 200 words)',
                    icon: Icons.description_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter business description';
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

                const SizedBox(height: 16),

                // PASSWORD
                _label('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  onChanged: _evaluatePasswordStrength,
                  decoration: _decor(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Icon(
                        _showPass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter a password' : null,
                ),

                if (_passwordStrengthLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _strengthValue(),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _passwordStrengthColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: _passwordStrengthColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Password strength: $_passwordStrengthLabel',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _passwordStrengthColor,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                _label('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: _decor(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      icon: Icon(
                        _showConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),

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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign up as Provider',
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
                          : () => Navigator.pushReplacementNamed(context, '/signin'),
                      child: Text(
                        ' Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isLoading ? Colors.grey.shade400 : kPrimaryButtonColor,
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