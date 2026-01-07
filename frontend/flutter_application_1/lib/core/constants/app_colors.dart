// lib/core/constants/app_colors.dart
// ╔════════════════════════════════════════════════════════════════════════════╗
// ║  🎨 App Colors - Centralized color definitions                              ║
// ║  All colors used across the app are defined here                            ║
// ╚════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

/// App Colors - Unified color palette
/// Use these instead of defining colors in individual files
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔵 Primary Colors (Brand)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Main brand color - Blue (ARGB: 215, 20, 20, 215)
  static const Color primary = Color.fromARGB(215, 20, 20, 215);
  
  /// Alias names for primary (for backward compatibility)
  static const Color brandBlue = primary;
  static const Color navBlue = primary;
  static const Color accentColor = primary;
  static const Color blue = primary;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏠 Background Colors
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Main page background - Light gray
  static const Color background = Color(0xFFF6F7FB);
  
  /// Alternative background (slightly different shade)
  static const Color backgroundAlt = Color(0xFFF7F8FC);
  
  /// Form/Input background
  static const Color backgroundForm = Color(0xFFF3F4F6);
  
  /// Card background
  static const Color card = Colors.white;
  
  /// Pure white
  static const Color white = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════════
  // ✏️ Text Colors
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary text - Dark
  static const Color textPrimary = Color(0xFF0B1220);
  
  /// Alternative text color
  static const Color textDark = Color(0xFF111827);
  
  /// Muted/Secondary text - Gray
  static const Color textMuted = Color(0xFF6B7280);
  
  /// More muted text
  static const Color textMutedLight = Color(0xFF9CA3AF);
  
  /// Black text
  static const Color textBlack = Colors.black;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 Status Colors
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Success - Green
  static const Color success = Color(0xFF10B981);
  
  /// Danger/Error - Red
  static const Color danger = Color(0xFFEF4444);
  
  /// Destructive - Pure Red
  static const Color destructive = Colors.red;
  
  /// Warning - Orange
  static const Color warning = Color(0xFFFF7A00);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔲 Border & Divider Colors
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Border color - Light gray
  static const Color border = Color(0xFFE5E7EB);
  
  /// Secondary/Muted border
  static const Color secondary = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 Special Colors (Provider/Contact)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Contact icon color - Orange
  static const Color contactIcon = Color(0xFFFF7A00);
  
  /// Contact circle background - Light orange
  static const Color contactCircle = Color(0xFFFFE6CC);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔄 Legacy Constants (for backward compatibility during migration)
// These will be deprecated after full migration
// ═══════════════════════════════════════════════════════════════════════════════

// Primary
const Color kPrimaryColor = AppColors.primary;
const Color kPrimary = AppColors.primary;
const Color kBrandBlue = AppColors.brandBlue;
const Color kNavBlue = AppColors.navBlue;
const Color kAccentColor = AppColors.accentColor;
const Color kBlue = AppColors.blue;

// Background
const Color kBg = AppColors.background;
const Color kPageBg = AppColors.background;
const Color kBgColor = AppColors.background;
const Color kBackgroundColor = AppColors.backgroundForm;
const Color kCard = AppColors.card;
const Color kCardColor = AppColors.card;

// Text
const Color kText = AppColors.textPrimary;
const Color kTextPrimary = AppColors.textPrimary;
const Color kTextColor = AppColors.textBlack;
const Color kMuted = AppColors.textMuted;
const Color kTextMuted = AppColors.textMuted;
const Color kMutedColor = AppColors.textMutedLight;

// Status
const Color kSuccess = AppColors.success;
const Color kSuccessColor = AppColors.success;
const Color kDanger = AppColors.danger;
const Color kDestructiveColor = AppColors.destructive;

// Border
const Color kBorder = AppColors.border;
const Color kSecondaryColor = AppColors.secondary;

// Special
const Color kContactIconColor = AppColors.contactIcon;
const Color kContactCircleColor = AppColors.contactCircle;
