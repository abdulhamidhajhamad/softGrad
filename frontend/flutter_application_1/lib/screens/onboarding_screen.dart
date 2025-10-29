// lib/screens/onboarding_screen.dart
//
// 3-page animated onboarding for PlanMyWedding app.
// Uses PageView, animated dots, skip, and continue logic.
// Cleaned up and fixed widget tree for correct vertical spacing.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Onboarding page data
  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      image: 'assets/flowers/pic1.png',
      title: 'Plan your Wedding!',
      body:
          'Plan your wedding according to your ease.\nContinue as a Groom or Bride.',
    ),
    _OnboardingPageData(
      image: 'assets/flowers/pic2.png',
      title: 'Invite all Guests!',
      body:
          'Plan your wedding according to your ease.\nContinue as a Groom or Bride.',
    ),
    _OnboardingPageData(
      image: 'assets/flowers/pic3.png',
      title: 'Select your Venue!',
      body:
          'Plan your wedding according to your ease.\nContinue as a Groom or Bride.',
    ),
  ];

  void _onContinue() {
    if (_currentPage < _pages.length - 1) {
      _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/choose_role');
    }
  }

  void _onSkip() {
    Navigator.of(context).pushReplacementNamed('/choose_role');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.88;
    final illustrationWidth = size.width.clamp(220, 260).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC55B63), Color(0xFFB14E56)],
            ),
          ),
          child: Stack(
            children: [
              // Skip button (top-right)
              Positioned(
                top: 18,
                right: 18,
                child: GestureDetector(
                  onTap: _onSkip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              // Centered card with PageView
              Center(
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  constraints: BoxConstraints(
                    minHeight: 340,
                    maxHeight: size.height * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Faint floral overlays (watermark)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Opacity(
                          opacity: 0.13,
                          child: Image.asset(
                            'assets/flowers/top_right.png',
                            width: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Opacity(
                          opacity: 0.13,
                          child: Image.asset(
                            'assets/flowers/bottom_left.png',
                            width: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // PageView with animated content
                      PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (i) {
                          setState(() => _currentPage = i);
                        },
                        itemBuilder: (context, i) {
                          final page = _pages[i];
                          return SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                Image.asset(
                                  page.image,
                                  width: illustrationWidth,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2B2B2B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  page.body,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(
                                      0xFF2B2B2B,
                                    ).withOpacity(0.75),
                                    height: 1.4,
                                  ),
                                ),
                                // زيادة المسافة قبل النقاط
                                const SizedBox(height: 70),
                                // Pagination dots
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_pages.length, (j) {
                                    final isActive = j == _currentPage;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      width: isActive ? 22 : 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFB14E56)
                                            : const Color(0xFFE6D6D8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  }),
                                ),
                                // زيادة المسافة بين النقاط والزر
                                const SizedBox(height: 28),
                                // Continue button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA64951),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      if (_currentPage == _pages.length - 1) {
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed('/welcome');
                                      } else {
                                        _onContinue();
                                      }
                                    },
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
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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

// Data class for onboarding pages
class _OnboardingPageData {
  final String image;
  final String title;
  final String body;
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.body,
  });
}
