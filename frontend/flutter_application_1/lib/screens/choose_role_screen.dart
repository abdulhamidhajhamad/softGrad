// lib/screens/choose_role_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum UserRole { groom, bride, guest }

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  static const Color kBrand = Color(0xFFB14E56);
  UserRole? _selected;

  void _onContinue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose a role',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
          ),
          backgroundColor: kBrand,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/welcome');
  }

  Widget _roleCard({
    required String title,
    required String asset,
    required UserRole role,
  }) {
    final selected = _selected == role;

    return InkWell(
      onTap: () => setState(() => _selected = role),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: selected ? kBrand : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? kBrand : const Color(0xFFE0E0E0),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.15 : 0.06),
              blurRadius: selected ? 20 : 10,
              offset: Offset(0, selected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Colors.white.withOpacity(0.95)
                    : const Color(0xFFF8F8F8),
                border: Border.all(
                  color: selected ? Colors.white : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(13),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF2B2B2B),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.88;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC55B63), Color(0xFFB14E56)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative flowers
              Positioned(
                top: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/flowers/top_right.png',
                    width: 140,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/flowers/bottom_left.png',
                    width: 160,
                  ),
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'Choose Your Role',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cookie(
                            fontSize: 33,
                            fontWeight: FontWeight.bold,
                            color: kBrand,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Role cards - all vertical
                        _roleCard(
                          title: 'Groom',
                          asset: 'assets/flowers/groom.png',
                          role: UserRole.groom,
                        ),
                        const SizedBox(height: 12),
                        _roleCard(
                          title: 'Bride',
                          asset: 'assets/flowers/bride.png',
                          role: UserRole.bride,
                        ),
                        const SizedBox(height: 12),
                        _roleCard(
                          title: 'Guest',
                          asset: 'assets/flowers/guest.png',
                          role: UserRole.guest,
                        ),
                        const SizedBox(height: 28),
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBrand,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(90),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
