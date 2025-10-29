import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized styling for the app
class AppStyles {
  // Colors
  static const Color primaryMaroon = Color(0xFF7E2E2E);
  static const Color lightMaroon = Color(0xFFC46060);
  static const Color accentGold = Color(0xFFF6E7B2);
  static const Color textDark = Color(0xFF3B3B3B);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color subtitleGray = Color(0xFF4B5563);

  // Gradients
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFC3A0), // peach
      Color(0xFFFFAFBD), // pink
      Color(0xFFB993D6), // purple
    ],
  );

  // Glassmorphism card style
  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
    backgroundBlendMode: BlendMode.overlay,
  );

  // Micro-interaction shadow for hover/press
  static BoxShadow interactiveShadow = BoxShadow(
    color: Colors.white.withOpacity(0.25),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // Text Styles
  static TextStyle titleDark = GoogleFonts.poppins(
    fontSize: 38,
    fontWeight: FontWeight.bold,
    color: textDark,
    height: 1.1,
  );

  static TextStyle titleLight = GoogleFonts.poppins(
    fontSize: 38,
    fontWeight: FontWeight.bold,
    color: textLight,
    height: 1.1,
  );

  static TextStyle subtitleDark = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: subtitleGray,
    letterSpacing: 2.0,
    height: 1.4,
  );

  static TextStyle subtitleLight = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textLight.withOpacity(0.9),
    letterSpacing: 2.0,
    height: 1.4,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color.fromARGB(255, 145, 49, 49),
    letterSpacing: 0.5,
  );

  // Decorations
  static BoxDecoration buttonDecoration = BoxDecoration(
    color: accentGold,
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
