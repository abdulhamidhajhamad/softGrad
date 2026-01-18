import 'package:flutter/material.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF111827);
const Color kTextPrimary = Color(0xFF1A1D26);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kCardColor = Colors.white;
const Color kDestructiveColor = Colors.red;
const Color kSecondaryColor = Color(0xFFE5E7EB);
const Color kMutedColor = Color(0xFF9CA3AF);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFFF6B35);
const Color kErrorColor = Color(0xFFEF4444);
const Color kInfoColor = Color(0xFF3B82F6);

ThemeData appTheme = ThemeData(
  primaryColor: kPrimaryColor,
  scaffoldBackgroundColor: kBackgroundColor,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.light(
    primary: kPrimaryColor,
    secondary: kPrimaryColor,
    error: kDestructiveColor,
    surface: kCardColor,
  ),
  useMaterial3: true,
);
