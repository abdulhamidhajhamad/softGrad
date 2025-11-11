import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding screen that guides users through the core benefits of PlanMyWedding
/// Uses a PageView carousel with three steps and dot indicators for progress tracking
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controller for managing PageView navigation
  final PageController _pageController = PageController();

  // Current page index for tracking progress
  int _currentPage = 0;

  // Onboarding data model for each page
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Plan Together',
      description:
          'Collaborate with your partner to plan every detail of your perfect wedding day.',
      imagePath: 'assets/images/pic1.png',
      icon: Icons.favorite_rounded,
    ),
    OnboardingData(
      title: 'Find Vendors',
      description:
          'Connect with trusted local vendors and discover exclusive package deals.',
      imagePath: 'assets/images/pic2.png',
      icon: Icons.storefront_rounded,
    ),
    OnboardingData(
      title: 'Stay On Track',
      description:
          'Get personalized checklists and reminders to keep your wedding planning stress-free.',
      imagePath: 'assets/images/pic3.png',
      icon: Icons.checklist_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to the next page or complete onboarding
  void _onContinue() {
    if (_currentPage < _pages.length - 1) {
      // Move to next page with smooth animation
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to sign up screen on last page
      Navigator.pushReplacementNamed(context, '/signup');
    }
  }

  /// Build a single dot indicator for page progress
  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF2B7DE9)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top right
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signup');
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // PageView carousel for onboarding pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // Dot indicators for page progress
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDotIndicator(index),
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 8.0, 40.0, 80.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page widget
class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Image placeholder
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF2B7DE9).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Image.asset(
                data.imagePath,
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    data.icon,
                    size: 120,
                    color: const Color.fromARGB(215, 20, 20, 215),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Data model for onboarding page content
class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}
