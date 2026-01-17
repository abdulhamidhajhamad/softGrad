// lib/screens/user/web/web_theme.dart
//
// ✅ Modern Web Design System
// ✅ Light purple/violet accent colors
// ✅ Clean, minimalist, user-friendly

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =====================================================
// 🎨 WEB COLOR PALETTE - Modern & Fresh
// =====================================================

/// Primary brand color (Light Purple/Violet - modern & fresh)
const Color kWebPrimary = Color(0xFF7C3AED);

/// Primary light variant
const Color kWebPrimaryLight = Color(0xFFA78BFA);

/// Primary dark variant
const Color kWebPrimaryDark = Color(0xFF5B21B6);

/// Accent color (Vibrant Indigo)
const Color kWebAccent = Color(0xFF6366F1);

/// Gradient start
const Color kWebGradientStart = Color(0xFF8B5CF6);

/// Gradient end
const Color kWebGradientEnd = Color(0xFF6366F1);

/// Background colors
const Color kWebBgPrimary = Color(0xFFF8FAFC);
const Color kWebBgSecondary = Color(0xFFF1F5F9);
const Color kWebBgCard = Colors.white;

/// Text colors
const Color kWebTextPrimary = Color(0xFF0F172A);
const Color kWebTextSecondary = Color(0xFF475569);
const Color kWebTextBody = Color(0xFF334155);
const Color kWebTextMuted = Color(0xFF94A3B8);
const Color kWebTextLight = Color(0xFFCBD5E1);

/// Border colors
const Color kWebBorder = Color(0xFFE2E8F0);
const Color kWebBorderLight = Color(0xFFF1F5F9);

/// Status colors
const Color kWebSuccess = Color(0xFF10B981);
const Color kWebSuccessLight = Color(0xFFD1FAE5);
const Color kWebWarning = Color(0xFFF59E0B);
const Color kWebWarningLight = Color(0xFFFEF3C7);
const Color kWebError = Color(0xFFEF4444);
const Color kWebErrorLight = Color(0xFFFEE2E2);
const Color kWebInfo = Color(0xFF3B82F6);
const Color kWebInfoLight = Color(0xFFDBEAFE);

/// Discount/Sale color
const Color kWebDiscount = Color(0xFFEC4899);

/// Sidebar colors
const Color kWebSidebarBg = Color(0xFF1E1B4B);
const Color kWebSidebarText = Color(0xFFE0E7FF);
const Color kWebSidebarActive = Color(0xFF7C3AED);

// =====================================================
// 🎨 GRADIENTS
// =====================================================

const LinearGradient kWebPrimaryGradient = LinearGradient(
  colors: [kWebGradientStart, kWebGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kWebHeroGradient = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF2563EB)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kWebSidebarGradient = LinearGradient(
  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const LinearGradient kWebCardGradient = LinearGradient(
  colors: [Colors.white, Color(0xFFFAFAFF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// =====================================================
// 📐 SPACING & SIZING
// =====================================================

class WebSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class WebRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double round = 100;
}

// =====================================================
// 🔤 TYPOGRAPHY
// =====================================================

class WebTypography {
  // Headings
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: kWebTextPrimary,
    height: 1.2,
  );
  
  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: kWebTextPrimary,
    height: 1.25,
  );
  
  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: kWebTextPrimary,
    height: 1.3,
  );
  
  static TextStyle h4 = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: kWebTextPrimary,
    height: 1.35,
  );
  
  static TextStyle h5 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: kWebTextPrimary,
    height: 1.4,
  );
  
  static TextStyle h6 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: kWebTextPrimary,
    height: 1.4,
  );
  
  // Body text
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: kWebTextSecondary,
    height: 1.6,
  );
  
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: kWebTextSecondary,
    height: 1.6,
  );
  
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: kWebTextSecondary,
    height: 1.5,
  );
  
  // Labels & Captions
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: kWebTextMuted,
    letterSpacing: 0.5,
  );
  
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: kWebTextMuted,
    height: 1.4,
  );
  
  // Button text
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );
  
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );
  
  static TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );
}

// =====================================================
// 🎭 SHADOWS
// =====================================================

class WebShadows {
  static List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> xl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
  
  static List<BoxShadow> primary = [
    BoxShadow(
      color: kWebPrimary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}

// =====================================================
// 🧩 DECORATIONS
// =====================================================

class WebDecorations {
  static BoxDecoration card = BoxDecoration(
    color: kWebBgCard,
    borderRadius: BorderRadius.circular(WebRadius.lg),
    boxShadow: WebShadows.card,
    border: Border.all(color: kWebBorder.withOpacity(0.5)),
  );
  
  static BoxDecoration cardHover = BoxDecoration(
    color: kWebBgCard,
    borderRadius: BorderRadius.circular(WebRadius.lg),
    boxShadow: WebShadows.md,
    border: Border.all(color: kWebPrimary.withOpacity(0.3)),
  );
  
  static BoxDecoration sidebar = BoxDecoration(
    gradient: kWebSidebarGradient,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(4, 0),
      ),
    ],
  );
  
  static BoxDecoration primaryButton = BoxDecoration(
    gradient: kWebPrimaryGradient,
    borderRadius: BorderRadius.circular(WebRadius.md),
    boxShadow: WebShadows.primary,
  );
  
  static BoxDecoration glassMorphism = BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(WebRadius.lg),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration searchField = BoxDecoration(
    color: kWebBgSecondary,
    borderRadius: BorderRadius.circular(WebRadius.xl),
    border: Border.all(color: kWebBorder),
  );
  
  static BoxDecoration chip = BoxDecoration(
    color: kWebPrimary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(WebRadius.round),
  );
  
  static BoxDecoration chipActive = BoxDecoration(
    gradient: kWebPrimaryGradient,
    borderRadius: BorderRadius.circular(WebRadius.round),
    boxShadow: WebShadows.primary,
  );
  
  static BoxDecoration badge = BoxDecoration(
    color: kWebError,
    borderRadius: BorderRadius.circular(WebRadius.round),
  );
}
