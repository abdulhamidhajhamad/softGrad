import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Email verification screen with OTP input
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Controllers for OTP input fields
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  // Focus nodes for field navigation
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Verify OTP and navigate to home
  void _verifyEmail() {
    String code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the complete code',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Resend OTP logic (mock)
  void _resendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code resent successfully', style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(215, 20, 20, 215),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? email = ModalRoute.of(context)?.settings.arguments as String?;

    return WillPopScope(
      // Handle Android back button
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/signup');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: const Color(0xFF1A1A2E),
            onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Verify Your Email',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle with email info
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a code to '),
                      TextSpan(
                        text: email ?? 'wazanitamara@gmail.com',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // OTP input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 50,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: index == 0
                              ? const Color.fromARGB(215, 20, 20, 215)
                                  .withOpacity(0.1)
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: index == 0
                                  ? const Color.fromARGB(215, 20, 20, 215)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: index == 0
                                  ? const Color.fromARGB(215, 20, 20, 215)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Color.fromARGB(215, 20, 20, 215),
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 48),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                      foregroundColor: Colors.white,
                      elevation: 0,
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

                // Resend code section
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
