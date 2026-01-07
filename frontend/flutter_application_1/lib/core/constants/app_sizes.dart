// lib/core/constants/app_sizes.dart
// ╔════════════════════════════════════════════════════════════════════════════╗
// ║  📐 App Sizes - Spacing, Padding, Border Radius                             ║
// ║  Consistent sizing across the app                                           ║
// ╚════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

/// App Sizes - Unified spacing and sizing
class AppSizes {
  AppSizes._(); // Private constructor

  // ═══════════════════════════════════════════════════════════════════════════
  // 📏 Spacing (Padding & Margin)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔘 Border Radius
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 24.0;
  static const double radiusCircular = 100.0;

  // BorderRadius objects
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);
  static final BorderRadius borderRadiusRound = BorderRadius.circular(radiusRound);

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 Component Sizes
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Buttons
  static const double buttonHeight = 50.0;
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightLarge = 56.0;

  // Icons
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;

  // Avatar
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXLarge = 80.0;

  // Cards
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;

  // Input fields
  static const double inputHeight = 48.0;
  static const double inputHeightLarge = 56.0;

  // Bottom navigation
  static const double bottomNavHeight = 62.0;
  static const double bottomNavHeightWithSafeArea = 84.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 Font Sizes
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeDefault = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeHeading = 28.0;
  static const double fontSizeTitle = 32.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🖼️ Image Sizes
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double imageThumbSmall = 60.0;
  static const double imageThumbMedium = 80.0;
  static const double imageThumbLarge = 120.0;
  static const double imageCardHeight = 180.0;
  static const double imageBannerHeight = 200.0;
}

/// Common EdgeInsets for padding
class AppPadding {
  AppPadding._();

  static const EdgeInsets all4 = EdgeInsets.all(4);
  static const EdgeInsets all8 = EdgeInsets.all(8);
  static const EdgeInsets all12 = EdgeInsets.all(12);
  static const EdgeInsets all16 = EdgeInsets.all(16);
  static const EdgeInsets all20 = EdgeInsets.all(20);
  static const EdgeInsets all24 = EdgeInsets.all(24);

  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets horizontal12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets horizontal20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: 24);

  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets vertical12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets vertical20 = EdgeInsets.symmetric(vertical: 20);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}
