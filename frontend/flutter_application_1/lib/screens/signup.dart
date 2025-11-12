import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Create Account screen — responsive, clean, with password strength indicator.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Location dropdown
  final List<String> _locations = const [
    'Nablus',
    'Ramallah (Coming Soon)',
  ];
  String _selectedLocation = 'Nablus';

  // Visibility toggles
  bool _showPass = false;
  bool _showConfirm = false;

  // Password strength tracking
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  // Design tokens
  static const double kFieldMinHeight = 52;
  static const kBrand = Color(0xFF1434E7);
  static const kTextColor = Color(0xFF1A1A2E);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Password validation and navigation
  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(
        context,
        '/verification',
        arguments: _emailCtrl.text,
      );
    }
  }

  // Shared input decoration style
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
      constraints: const BoxConstraints(minHeight: kFieldMinHeight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: kBrand, width: 2),
      ),
    );
  }

  // Label style
  Text _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      );

  /// Evaluate password strength based on length and character diversity.
  void _evaluatePasswordStrength(String password) {
    String label;
    Color color;

    if (password.isEmpty) {
      // No input → no label and transparent color
      label = '';
      color = Colors.transparent;
    } else if (password.length < 6) {
      // 0–5 chars → Weak
      label = 'Weak';
      color = Colors.red;
    } else if (password.length < 16) {
      // 6–15 chars → Medium
      label = 'Medium';
      color = Colors.orange;
    } else {
      // 16+ chars → Strong
      label = 'Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  // map label to progress value
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
    final topInset = media.padding.top;
    final bottomInset = media.viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, topInset > 0 ? 16 : 24, 24, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'All your wedding plans in one place',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 28),

                // Name field
                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
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
                  controller: _emailCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decor(
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your email';
                    }
                    final email = v.trim();
                    final ok =
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
                    return ok ? null : 'Enter a valid email';
                  },
                ),

                const SizedBox(height: 16),

                // Phone
                _label('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  textInputAction: TextInputAction.next,
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

                // Location
                _label('Location'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  decoration: _decor(
                    hint: 'Select your location',
                    icon: Icons.location_on_outlined,
                  ),
                  items: _locations.map((loc) {
                    final bool disabled = loc.contains('Coming Soon');
                    return DropdownMenuItem<String>(
                      value: loc,
                      enabled: !disabled,
                      child: Text(
                        loc,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: disabled ? Colors.grey : kTextColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    if (!value.contains('Coming Soon')) {
                      setState(() => _selectedLocation = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Password field + live strength indicator
                _label('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  textInputAction: TextInputAction.next,
                  obscureText: !_showPass,
                  onChanged: _evaluatePasswordStrength,
                  decoration: _decor(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      tooltip: _showPass ? 'Hide password' : 'Show password',
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Icon(
                        _showPass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter a password';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Password strength bar + text below field
                if (_passwordStrengthLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _strengthValue(),
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 16, color: _passwordStrengthColor),
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

                // Confirm password
                _label('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  textInputAction: TextInputAction.done,
                  obscureText: !_showConfirm,
                  decoration: _decor(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      tooltip: _showConfirm ? 'Hide password' : 'Show password',
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      icon: Icon(
                        _showConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (v != _passCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 24),

                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign In link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signin'),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 4),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(215, 20, 20, 215),
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
