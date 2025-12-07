import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/verification_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'home_customer.dart';
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

  bool _isLoading = false;
  bool _isResending = false;

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
    required String token,
  }) {
    AuthService.saveToken(token);

    if (role.toLowerCase() == "customer" || role.toLowerCase() == "user") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomePage(userName: name), // استخدام الكونستركتور الحالي
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
              email: email!,
              phone: phone,
              category: category,
              description: description,
              city: city,
            ),
            // استخدام الكونستركتور الحالي بدون token
          ),
        ),
        (_) => false,
      );
    }
  }

  // ===========================================================
  // VERIFY EMAIL (API Call)
  // ===========================================================
  Future<void> _verifyEmail() async {
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

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter the complete 6-digit code",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await VerificationService.verifyEmail(
        email: email,
        verificationCode: code,
      );

      // التحقق من أن الرد يحتوي على token و user
      if (response.containsKey('token') && response.containsKey('user')) {
        final userData = response['user'];
        final token = response['token'];

        // التحقق من أن isVerified أصبح true
        if (userData['isVerified'] == true) {
          // نجح التحقق - الانتقال للصفحة الرئيسية
          _goToHome(
            role: role,
            name: name,
            email: email,
            phone: phone,
            category: category,
            description: description,
            city: city,
            token: token,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Email verified successfully!",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog('Verification failed. User not verified.');
        }
      } else {
        _showErrorDialog('Verification failed. Please try again.');
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('Invalid verification code')) {
        errorMessage =
            'Invalid verification code. Please check the code and try again.';
      } else if (e.toString().contains('Verification code has expired')) {
        errorMessage =
            'Verification code has expired. Please request a new one.';
      } else if (e.toString().contains('No verification code found')) {
        errorMessage = 'No verification code found. Please request a new one.';
      } else if (e.toString().contains('Email is already verified')) {
        errorMessage = 'Email is already verified. You can proceed to login.';
        // إذا الإيميل مفعل أصلاً، ننتقل مباشرة للصفحة الرئيسية
        _navigateToLogin();
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'User not found. Please check your email.';
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

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Verification Failed',
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

  // ===========================================================
  // RESEND OTP (API Call)
  // ===========================================================
  Future<void> _resendCode() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String email = "example@mail.com";

    // Extract email from arguments
    if (args is Map) {
      email = args["email"] ?? email;
    } else if (args is String) {
      email = args;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final response = await VerificationService.resendVerificationCode(
        email: email,
      );

      if (response.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Verification code sent successfully!",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color.fromARGB(215, 20, 20, 215),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to resend code. Please try again.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      String errorMessage = "Failed to resend code. Please try again.";

      if (e.toString().contains('User not found')) {
        errorMessage = 'User not found. Please check your email.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
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
              onPressed: _isLoading
                  ? null
                  : () {
                      _navigateToLogin();
                    },
              child: Text(
                "Skip",
                style: GoogleFonts.poppins(
                  color: _isLoading
                      ? Colors.grey
                      : const Color.fromARGB(215, 20, 20, 215),
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
                    onPressed: _isLoading ? null : _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                      foregroundColor: Colors.white,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
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
                      onTap: _isResending ? null : _resendCode,
                      child: _isResending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color.fromARGB(215, 20, 20, 215),
                                ),
                              ),
                            )
                          : Text(
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
