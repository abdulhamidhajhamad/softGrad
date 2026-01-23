import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import screens
import 'signup_customer.dart';
import 'package:flutter_application_1/widgets/auth/auth_responsive_wrapper.dart';

enum UserRole { customer, provider }

/// ✅ Responsive Choose Role Screen
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({Key? key}) : super(key: key);

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  UserRole? _selectedRole;

  void _onContinue() {
    if (_selectedRole == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
        settings: RouteSettings(
          arguments: {
            'role': _selectedRole == UserRole.provider ? 'vendor' : 'user',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveWrapper(
      pageType: AuthPageType.chooseRole,
      showBackButton: true,
      onBack: () => Navigator.pushReplacementNamed(context, '/signin'),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Use screen width for responsive check, not constraints
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = kIsWeb || screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),

        // Title
        Text(
          "Choose Your Role",
          style: GoogleFonts.poppins(
            fontSize: isWide ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          "Select how you want to use Eventry",
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),

        // Role Cards - Always horizontal on web, responsive on mobile
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  title: "Customer",
                  subtitle: "Plan your perfect event",
                  icon: Icons.person_rounded,
                  isSelected: _selectedRole == UserRole.customer,
                  onTap: () => setState(() => _selectedRole = UserRole.customer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RoleCard(
                  title: "Provider",
                  subtitle: "Offer your services",
                  icon: Icons.storefront_rounded,
                  isSelected: _selectedRole == UserRole.provider,
                  onTap: () => setState(() => _selectedRole = UserRole.provider),
                ),
              ),
            ],
          )
        else
          // ✅ Mobile: Horizontal compact cards
          Row(
            children: [
              Expanded(
                child: _RoleCardMobile(
                  title: "Customer",
                  subtitle: "Plan events",
                  icon: Icons.person_rounded,
                  isSelected: _selectedRole == UserRole.customer,
                  onTap: () => setState(() => _selectedRole = UserRole.customer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleCardMobile(
                  title: "Provider",
                  subtitle: "Offer services",
                  icon: Icons.storefront_rounded,
                  isSelected: _selectedRole == UserRole.provider,
                  onTap: () => setState(() => _selectedRole = UserRole.provider),
                ),
              ),
            ],
          ),

        const SizedBox(height: 40),

        // Continue Button
        AuthButton(
          text: 'Continue',
          onPressed: _selectedRole != null ? _onContinue : null,
          icon: Icons.arrow_forward_rounded,
        ),

        const SizedBox(height: 24),

        // Sign In Link
        AuthLinkText(
          prefix: "Already have an account? ",
          linkText: 'Sign In',
          onTap: () => Navigator.pushReplacementNamed(context, '/signin'),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

/// ✅ Modern Role Card Widget (Desktop/Tablet)
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPrimaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? kPrimaryColor : const Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Selection Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ Compact Role Card for Mobile
class _RoleCardMobile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCardMobile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.06) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPrimaryColor : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? kPrimaryColor : const Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Selection Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
