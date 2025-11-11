import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Logo/Title
              Text(
                'PlanMyWedding',
                style: GoogleFonts.cookie(
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'YOUR PERFECT DAY AWAITS!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 40),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: () {
                    // الانتقال إلى شاشة التعريف
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
