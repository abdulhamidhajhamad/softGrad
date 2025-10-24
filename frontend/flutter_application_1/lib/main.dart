import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';

void main() => runApp(const PlanMyWeddingApp());

class PlanMyWeddingApp extends StatelessWidget {
  const PlanMyWeddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlanMyWedding',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBECEC), // Soft Blush
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
