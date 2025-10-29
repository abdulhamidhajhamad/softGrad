// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/screens/splash_screen.dart';
import 'package:flutter_application_1/screens/onboarding_screen.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';
import 'package:flutter_application_1/screens/choose_role_screen.dart';
import 'package:flutter_application_1/screens/sign_up_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

void main() {
  runApp(const PlanMyWeddingApp());
}

class PlanMyWeddingApp extends StatelessWidget {
  const PlanMyWeddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanMyWedding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.montserratTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB14E56)),
        useMaterial3: false,
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/choose_role': (_) => const ChooseRoleScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
