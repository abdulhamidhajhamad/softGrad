// lib/screens/forgot_password_request.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/user_service/forgot_password_service.dart';
import 'package:flutter_application_1/widgets/auth/auth_responsive_wrapper.dart';

/// ✅ Responsive Forgot Password Screen for Mobile & Web
class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordRequestScreen> createState() => _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState extends State<ForgotPasswordRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final response = await ForgotPasswordService.requestPasswordReset(email);

        if (!mounted) return;

        if (response['success'] == true) {
          // Show success message
          _showSuccessDialog(email);
        } else {
          _showErrorSnackBar(
            response['message'] ?? 'Failed to send reset email. Please try again.',
          );
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('An error occurred. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Email Sent!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'We\'ve sent a password reset link to:\n\n$email\n\nPlease check your email and follow the instructions to reset your password.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to login
            },
            child: Text(
              'Back to Login',
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveWrapper(
      pageType: AuthPageType.forgotPassword,
      showBackButton: true,
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 48,
                color: kPrimaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Forgot Password?',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'No worries! Enter your email address and we\'ll send you a link to reset your password.',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Email Field
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Send Reset Link Button
            AuthButton(
              text: 'Send Reset Link',
              onPressed: _requestPasswordReset,
              isLoading: _isLoading,
              icon: Icons.send_rounded,
            ),

            const SizedBox(height: 24),

            // Back to Login Link
            AuthLinkText(
              prefix: 'Remember your password? ',
              linkText: 'Sign In',
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The reset link will expire in 15 minutes for security reasons.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}