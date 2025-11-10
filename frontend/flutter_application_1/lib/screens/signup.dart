import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Create Account screen — full-width, vertically centered hints, responsive, accessible.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Visibility
  bool _showPass = false;
  bool _showConfirm = false;

  // Design tokens
  static const double kFieldMinHeight = 52;
  static const kBrand = Color(0xFF1434E7); // modern blue
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(
        context,
        '/verification',
        arguments: _emailCtrl.text,
      );
    }
  }

  // Unified field decoration: rounded, centered hint, consistent height.
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
      // Keep the visual height consistent and center the hint/input vertically.
      constraints: const BoxConstraints(minHeight: kFieldMinHeight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      // Borders
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

  // Label text style
  Text _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      );

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
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // full-width children
              children: [
                // Header
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                    height: 2.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'All your wedding plans in one place',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 28),

                // Full Name
                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  keyboardType: TextInputType.name,
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _decor(
                      hint: 'Enter your full name', icon: Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),

                const SizedBox(height: 16),

                // Email
                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _decor(
                      hint: 'you@example.com', icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your email';
                    final email = v.trim();
                    final ok =
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
                    return ok ? null : 'Please enter a valid email';
                  },
                ),

                const SizedBox(height: 16),

                // Phone
                _label('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _decor(
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your phone number'
                      : null,
                ),

                const SizedBox(height: 16),

                // Password
                _label('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: !_showPass,
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
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
                    if (v == null || v.isEmpty)
                      return 'Please enter a password';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password
                _label('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: !_showConfirm,
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
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
                    if (v == null || v.isEmpty)
                      return 'Please confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 24),

                // Sign Up button — full width
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
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600),
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
                          fontSize: 14, color: Colors.grey.shade600),
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
