import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;

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
      duration: const Duration(milliseconds: 700),
    );

    _titleFadeAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeInOut,
    );

    _titleSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.02), // ~16px slide
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
        );

    // Subtitle animation (staggered)
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _subtitleFadeAnimation = CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeInOut,
    );

    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
          CurvedAnimation(parent: _subtitleController, curve: Curves.easeInOut),
        );

    // Start animations
    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _subtitleController.forward();
    });

    // Navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 10000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03), // 24px slide
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Widget _buildDecorativeFlower({
    required String assetPath,
    required Alignment alignment,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: alignment == Alignment.topRight
              ? const Offset(12, -12)
              : const Offset(-12, 12),
          child: Opacity(
            opacity: 0.85,
            child: Image.asset(
              assetPath,
              width: 200,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
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
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          // Top-right flower
          _buildDecorativeFlower(
            assetPath: 'assets/flowers/top_right.png',
            alignment: Alignment.topRight,
          ),
          // Bottom-left flower
          _buildDecorativeFlower(
            assetPath: 'assets/flowers/bottom_left.png',
            alignment: Alignment.bottomLeft,
          ),
          // Center content
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
                            color: const Color(0xFF3B3B3B),
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
                            color: const Color(0xFF4B5563),
                            letterSpacing: 2.0,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    const Spacer(flex: 3),
                    // Loading indicator at ~80-85% screen height
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C2D2D),
                        strokeWidth: 3,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
