// lib/widgets/auth/auth_responsive_wrapper.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// ✅ Primary brand color
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBgColor = Color(0xFFF6F7FB);

/// ✅ Responsive breakpoints
class AuthBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// ✅ Auth Page Type for different left panel designs
enum AuthPageType {
  signIn,
  signUp,
  chooseRole,
  forgotPassword,
  verification,
}

/// ✅ Responsive Auth Wrapper with Split Screen for Web
class AuthResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final AuthPageType pageType;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthResponsiveWrapper({
    super.key,
    required this.child,
    required this.pageType,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AuthBreakpoints.tablet;
        
        if (isDesktop && kIsWeb) {
          return _buildDesktopLayout(context, constraints);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  /// 🖥️ Desktop Layout: Split Screen
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Row(
        children: [
          // ✅ Left Panel - Branding & Illustration
          Expanded(
            flex: 5,
            child: _LeftBrandingPanel(pageType: pageType),
          ),
          
          // ✅ Right Panel - Form Content
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Mobile Layout: Modern centered layout
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Left Branding Panel for Desktop
class _LeftBrandingPanel extends StatelessWidget {
  final AuthPageType pageType;

  const _LeftBrandingPanel({required this.pageType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor,
            kPrimaryColor.withOpacity(0.85),
            const Color(0xFF1A1A4E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // ✅ Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePatternPainter(),
            ),
          ),
          
          // ✅ Content
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Eventry',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // ✅ Dynamic Content based on page type
                _buildPageContent(),
                
                const Spacer(),
                
                // ✅ Footer
                Text(
                  '© 2026 Eventry. All rights reserved.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (pageType) {
      case AuthPageType.signIn:
        return _ContentBlock(
          icon: Icons.waving_hand_rounded,
          title: 'Welcome Back!',
          subtitle: 'Sign in to continue planning your perfect events.',
          features: const [
            'Access your bookings & events',
            'Chat with service providers',
            'Track your wedding planning',
          ],
        );
        
      case AuthPageType.signUp:
        return _ContentBlock(
          icon: Icons.person_add_rounded,
          title: 'Join Our Community',
          subtitle: 'Create an account to start planning amazing events.',
          features: const [
            'Discover top-rated vendors',
            'Book services with ease',
            'Get personalized recommendations',
          ],
        );
        
      case AuthPageType.chooseRole:
        return _ContentBlock(
          icon: Icons.diversity_3_rounded,
          title: 'Choose Your Path',
          subtitle: 'Join as a customer or become a service provider.',
          features: const [
            'Customers: Plan your perfect event',
            'Providers: Grow your business',
            'Connect & collaborate',
          ],
        );
        
      case AuthPageType.forgotPassword:
        return _ContentBlock(
          icon: Icons.lock_reset_rounded,
          title: 'Reset Password',
          subtitle: 'Don\'t worry, we\'ll help you recover your account.',
          features: const [
            'Secure password reset',
            'Email verification',
            'Quick & easy process',
          ],
        );
        
      case AuthPageType.verification:
        return _ContentBlock(
          icon: Icons.verified_user_rounded,
          title: 'Verify Your Email',
          subtitle: 'Just one more step to complete your registration.',
          features: const [
            'Check your inbox',
            'Enter verification code',
            'Start planning your events',
          ],
        );
    }
  }
}

/// ✅ Content Block Widget
class _ContentBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;

  const _ContentBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 48),
        ),
        
        const SizedBox(height: 32),
        
        // Title
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Subtitle
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white.withOpacity(0.85),
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Features
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  f,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

/// ✅ Background Pattern Painter
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.2),
      120,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      80,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.75),
      150,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.85),
      100,
      paint,
    );
    
    // Draw subtle grid lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    
    for (var i = 0; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        linePaint,
      );
    }
    for (var i = 0; i < size.height; i += 60) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ✅ Reusable Auth Button
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kPrimaryColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildContent(kPrimaryColor),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildContent(Colors.white),
      ),
    );
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// ✅ Reusable Auth Text Field
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int? maxLength;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            prefixIcon: Icon(prefixIcon, color: Colors.grey),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// ✅ Auth Dropdown Field
class AuthDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AuthDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            prefixIcon: Icon(prefixIcon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// ✅ Auth Link Text
class AuthLinkText extends StatelessWidget {
  final String prefix;
  final String linkText;
  final VoidCallback onTap;

  const AuthLinkText({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
