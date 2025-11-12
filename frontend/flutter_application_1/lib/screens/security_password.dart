// lib/screens/security_password.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart'; // for kAccentColor

class SecurityPasswordScreen extends StatefulWidget {
  final bool isDarkMode;
  const SecurityPasswordScreen({Key? key, this.isDarkMode = false})
      : super(key: key);

  @override
  State<SecurityPasswordScreen> createState() => _SecurityPasswordScreenState();
}

class _SecurityPasswordScreenState extends State<SecurityPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isDarkMode = false;
  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Check password strength as user types
  void _checkStrength(String v) {
    setState(() {
      if (v.length < 6) {
        _passwordStrength = "Weak";
      } else if (v.length < 10) {
        _passwordStrength = "Medium";
      } else {
        _passwordStrength = "Strong";
      }
    });
  }

  // Input decoration style (kept unchanged)
  InputDecoration _input(String label, IconData icon,
      {bool obscure = false, VoidCallback? toggle}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: _isDarkMode ? Colors.white70 : Colors.grey.shade700,
      ),
      prefixIcon: Icon(icon,
          color: _isDarkMode ? Colors.white70 : Colors.grey.shade600),
      suffixIcon: obscure
          ? IconButton(
              icon: Icon(
                (_showOld && label == 'Current Password') ||
                        (_showNew && label == 'New Password') ||
                        (_showConfirm && label == 'Confirm Password')
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
              onPressed: toggle,
            )
          : null,
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kAccentColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = _isDarkMode ? Colors.black : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Change Password",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: textColor,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(height: 20),
                Text(
                  "For your account security, please set a strong password.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 28),

                // --- Current Password Field ---
                TextFormField(
                  controller: _oldCtrl,
                  obscureText: !_showOld,
                  decoration: _input('Current Password', Icons.lock_outline,
                      obscure: true,
                      toggle: () => setState(() => _showOld = !_showOld)),
                  style: TextStyle(color: textColor),
                  // Validator added
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please enter your current password";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- New Password Field ---
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_showNew,
                  onChanged: _checkStrength,
                  decoration: _input('New Password', Icons.lock_reset_outlined,
                      obscure: true,
                      toggle: () => setState(() => _showNew = !_showNew)),
                  style: TextStyle(color: textColor),
                  // Validator added
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please enter a new password";
                    } else if (v.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Password Strength Indicator
                if (_passwordStrength.isNotEmpty)
                  Text(
                    "Strength: $_passwordStrength",
                    style: GoogleFonts.poppins(
                      color: _passwordStrength == "Weak"
                          ? Colors.red
                          : _passwordStrength == "Medium"
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                const SizedBox(height: 16),

                // --- Confirm Password Field ---
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: _input(
                      'Confirm Password', Icons.verified_user_outlined,
                      obscure: true,
                      toggle: () =>
                          setState(() => _showConfirm = !_showConfirm)),
                  style: TextStyle(color: textColor),
                  // Validator added
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please confirm your new password";
                    } else if (v != _newCtrl.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // --- Update Button ---
                ElevatedButton(
                  onPressed: () {
                    // Validate form before proceeding
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password updated successfully!"),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Update Password",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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
