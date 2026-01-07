import 'package:flutter/material.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF111827);
const Color kCardColor = Colors.white;
const Color kDestructiveColor = Colors.red;
const Color kSecondaryColor = Color(0xFFE5E7EB);
const Color kMutedColor = Color(0xFF9CA3AF);
const Color kSuccessColor = Color(0xFF10B981);

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
