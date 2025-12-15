// lib/screens/edit_profile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart'; // User model + kAccentColor

class EditProfileScreen extends StatefulWidget {
  final User user;
  final bool isDarkMode;

  const EditProfileScreen({
    Key? key,
    required this.user,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;

  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;

    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _locationCtrl = TextEditingController(text: widget.user.location);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _isDarkMode ? Colors.white : Colors.black,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(milliseconds: 900),
        ),
      );
      Navigator.pop(context);
    }
  }

  // --- Premium palette (white/black/blue) ---
  Color get _bg => _isDarkMode ? Colors.black : Colors.white;
  Color get _card =>
      _isDarkMode ? const Color(0xFF0F1117) : const Color(0xFFF7F8FC);
  Color get _text => _isDarkMode ? Colors.white : const Color(0xFF0B1220);
  Color get _muted => _isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
  Color get _border => _isDarkMode ? Colors.white12 : const Color(0xFFE5E7EB);
  Color get _fieldFill => _isDarkMode ? const Color(0xFF0B0D12) : Colors.white;

  TextStyle get _titleStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _text,
      );

  TextStyle get _hintStyle => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _muted,
      );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _muted,
      ),
      prefixIcon: Icon(icon, color: _muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAccentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      errorStyle: GoogleFonts.poppins(
        color: Colors.red,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
          bodyColor: _text,
          displayColor: _text,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: _bg,
          elevation: 0,
          surfaceTintColor: _bg,
          foregroundColor: _text,
          iconTheme: IconThemeData(color: _text),
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Edit Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: _text,
              ),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top subtle header card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kAccentColor
                              .withOpacity(_isDarkMode ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: kAccentColor.withOpacity(0.18)),
                        ),
                        child:
                            const Icon(Icons.edit_rounded, color: kAccentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Update your details', style: _titleStyle),
                            const SizedBox(height: 4),
                            Text(
                              'Keep your info accurate for bookings and vendors.',
                              style: _hintStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Form card (modern + clean)
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                          decoration: _inputDecoration(
                            label: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                          decoration: _inputDecoration(
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                          decoration: _inputDecoration(
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (v.trim().length < 6) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // ✅ Location editable (no lock)
                        TextFormField(
                          controller: _locationCtrl,
                          keyboardType: TextInputType.text,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                          decoration: _inputDecoration(
                            label: 'Location',
                            icon: Icons.location_on_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your location';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Save button (premium)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
