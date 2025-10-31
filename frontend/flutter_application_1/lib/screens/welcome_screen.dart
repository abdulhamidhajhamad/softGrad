// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/screens/sign_up_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.88;

    return Scaffold(
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
        child: Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            constraints: BoxConstraints(maxHeight: size.height * 0.55),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/flowers/top_right.png',
                      width: 85,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/flowers/bottom_left.png',
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Main content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Heart image with circle background
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB14E56).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/flowers/heartIcon.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    // App name
                    Text(
                      'PlanMyWedding',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cookie(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 137, 23, 32),
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    Text(
                      'Wedding Planner',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.unicaOne(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB14E56).withOpacity(0.7),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB14E56),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFFB14E56),
                              width: 2,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Log In button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA64951),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Log In',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
