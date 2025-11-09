// lib/main.dart
import 'package:flutter/material.dart';

// Screens
import 'package:flutter_application_1/screens/splash.dart';
import 'package:flutter_application_1/screens/onboarding.dart';
import 'package:flutter_application_1/screens/signup.dart';
import 'package:flutter_application_1/screens/signin.dart';
import 'package:flutter_application_1/screens/verification.dart';
import 'package:flutter_application_1/screens/home.dart'; // يستخدم HomePage الحقيقية

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanMyWedding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2B7DE9),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: false,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B7DE9),
          primary: const Color(0xFF2B7DE9),
          secondary: const Color(0xFF1414D7),
        ),
      ),

      home: const SplashScreen(),

      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/home': (context) => const HomePage(), // من home.dart
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
          return MaterialPageRoute(
            builder: (_) => const VerificationScreen(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
