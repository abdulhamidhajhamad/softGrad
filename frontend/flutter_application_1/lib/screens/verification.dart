// lib/screens/verification.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home.dart';
import 'home_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // OTP Text Controllers
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  // Focus nodes for automatic movement
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ===========================================================
  // NAVIGATE BASED ON ROLE
  // ===========================================================
  void _goToHome({
    required String role,
    required String name,
    required String email,
    required String phone,
    required String category,
    required String description,
    required String city,
  }) {
    if (role.toLowerCase() == "customer") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(userName: name),
        ),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeProviderScreen(
            provider: ProviderModel(
              brandName: name,
              email: email,
              phone: phone,
              category: category,
              description: description,
              city: city,
            ),
          ),
        ),
        (_) => false,
      );
    }
  }

  // ===========================================================
  // VERIFY EMAIL
  // ===========================================================
  void _verifyEmail() {
    final args = ModalRoute.of(context)?.settings.arguments;

    // Defaults
    String email = "example@mail.com";
    String role = "customer";
    String name = "Guest";

    // Provider fields
    String category = "";
    String description = "";
    String city = "";
    String phone = "";

    // Extract arguments
    if (args is Map) {
      email = args["email"] ?? email;
      role = args["role"] ?? role;
      name = args["name"] ?? name;

      category = args["category"] ?? "";
      description = args["description"] ?? "";
      city = args["city"] ?? "";
      phone = args["phone"] ?? "";
    } else if (args is String) {
      email = args;
    }

    String code = _controllers.map((c) => c.text).join();

    if (code.length == 6) {
      _goToHome(
        role: role,
        name: name,
        email: email,
        phone: phone,
        category: category,
        description: description,
        city: city,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter the complete code",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===========================================================
  // RESEND OTP
  // ===========================================================
  void _resendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Code resent successfully",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color.fromARGB(215, 20, 20, 215),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    // Defaults
    String email = "example@mail.com";
    String role = "customer";
    String name = "Guest";

    // Provider fields
    String category = "";
    String description = "";
    String city = "";
    String phone = "";

    // Extract arguments
    if (args is Map) {
      email = args["email"] ?? email;
      role = args["role"] ?? role;
      name = args["name"] ?? name;

      category = args["category"] ?? "";
      description = args["description"] ?? "";
      city = args["city"] ?? "";
      phone = args["phone"] ?? "";
    } else if (args is String) {
      email = args;
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/signup');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        // AppBar
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.black87,
            onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
          ),

          // Skip button
          actions: [
            TextButton(
              onPressed: () {
                _goToHome(
                  role: role,
                  name: name,
                  email: email,
                  phone: phone,
                  category: category,
                  description: description,
                  city: city,
                );
              },
              child: Text(
                "Skip",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(215, 20, 20, 215),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // BODY
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Title
                Text(
                  'Verify Your Email',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    children: [
                      const TextSpan(text: 'We sent a code to '),
                      TextSpan(
                        text: email,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // OTP Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      width: 50,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (value.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 48),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Verify Email',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendCode,
                      child: Text(
                        'Resend',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(215, 20, 20, 215),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
