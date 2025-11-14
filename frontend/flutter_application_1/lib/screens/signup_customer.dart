import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otherCityCtrl = TextEditingController();

  // Cities Dropdown
  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

  String? _selectedCity = "Nablus";

  // Password strength
  String _passwordStrengthLabel = "";
  Color _passwordStrengthColor = Colors.transparent;

  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otherCityCtrl.dispose();
    super.dispose();
  }

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

  // ===============================================
  // SUBMIT (Send arguments to Verification Screen)
  // ===============================================
  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(
        context,
        '/verification',
        arguments: {
          "email": _emailCtrl.text.trim(),
          "role": "customer",
          "name": _nameCtrl.text.trim(),
        },
      );
    }
  }

  // Password Strength Logic (Simple)
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,

      // BACK BUTTON → يعود لصفحة choose_role
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
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
                  'Create Account as Customer',
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

                // Full Name
                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _nameCtrl,
                  decoration: _decor(
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),

                const SizedBox(height: 16),

                // Email
                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decor(
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your email';
                    }
                    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(v.trim());
                    return ok ? null : 'Enter a valid email';
                  },
                ),

                const SizedBox(height: 16),

                // Phone
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

                // City Dropdown
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
                    hint: 'Select your city',
                    icon: Icons.location_city_outlined,
                  ),
                  onChanged: (value) => setState(() => _selectedCity = value),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select your city' : null,
                ),

                if (_selectedCity == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: _otherCityCtrl,
                    decoration: _decor(
                      hint: 'Enter your city',
                      icon: Icons.edit_location_alt_outlined,
                    ),
                    validator: (v) {
                      if (_selectedCity == 'Other' &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Password
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
                      onPressed: () {
                        setState(() => _showPass = !_showPass);
                      },
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

                // Confirm Password
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
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryButtonColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign up as Customer',
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
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signin'),
                      child: Text(
                        '  Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryButtonColor,
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
