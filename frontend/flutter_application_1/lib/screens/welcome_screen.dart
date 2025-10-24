import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _buttonController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Title animation
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _titleFadeAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeInOut,
    );

    _titleSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.015), // ~12px slide
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
        );

    // Subtitle animation (staggered)
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _subtitleFadeAnimation = CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeInOut,
    );

    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero).animate(
          CurvedAnimation(parent: _subtitleController, curve: Curves.easeInOut),
        );

    // Button animation (staggered)
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    // Start animations with stagger
    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _subtitleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Widget _buildDecorativeFlower({
    required String assetPath,
    required Alignment alignment,
    required Animation<double> animation,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: alignment == Alignment.topRight
              ? const Offset(12, -12)
              : const Offset(-12, 12),
          child: FadeTransition(
            opacity: animation,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.15),
                BlendMode.plus,
              ),
              child: Image.asset(
                assetPath,
                width: 200,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC46060), // Lighter top maroon
              Color(0xFF7E2E2E), // Slightly lighter bottom maroon
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle inner shadow effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.06),
                    ],
                  ),
                ),
              ),
            ),
            // Center content only (flowers removed)
            SafeArea(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 5),
                      // Title with animation
                      FadeTransition(
                        opacity: _titleFadeAnimation,
                        child: SlideTransition(
                          position: _titleSlideAnimation,
                          child: Text(
                            'PlanMyWedding',
                            style: GoogleFonts.poppins(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFFFFF),
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Subtitle with staggered animation
                      FadeTransition(
                        opacity: _subtitleFadeAnimation,
                        child: SlideTransition(
                          position: _subtitleSlideAnimation,
                          child: Text(
                            'YOUR PERFECT DAY AWAITS',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFFFFFF).withOpacity(0.9),
                              letterSpacing: 2.0,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      // GET STARTED button with scale animation
                      ScaleTransition(
                        scale: _buttonScaleAnimation,
                        child: FadeTransition(
                          opacity: _buttonScaleAnimation,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Navigating to next screen...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    114,
                                    39,
                                    39,
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              // TODO: Add navigation logic here
                            },
                            child: Container(
                              width: 220,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6E7B2),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'GET STARTED!',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 145, 49, 49),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 5),
                    ],
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
