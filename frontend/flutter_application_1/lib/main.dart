// lib/main.dart
import 'package:flutter/material.dart';

// Screens
import 'package:flutter_application_1/screens/splash.dart';
import 'package:flutter_application_1/screens/onboarding.dart';
import 'package:flutter_application_1/screens/signup_provider.dart';
import 'package:flutter_application_1/screens/signup_customer.dart';
import 'package:flutter_application_1/screens/signin.dart';
import 'package:flutter_application_1/screens/verification.dart';
import 'package:flutter_application_1/screens/home.dart';
import 'package:flutter_application_1/screens/vendors.dart';
import 'package:flutter_application_1/screens/templates.dart';
import 'package:flutter_application_1/screens/template_editor.dart';
import 'package:flutter_application_1/screens/choose_role.dart'; // NEW SCREEN

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

      // Static Routes
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/choose_role': (_) => const ChooseRoleScreen(), // ADDED
        '/signup': (_) => const SignUpScreen(),
        '/signin': (_) => const SignInScreen(),
        '/verification': (_) => const VerificationScreen(),
        '/home': (_) => const HomePage(),
        '/vendors': (_) => const VendorsListPage(),
        '/templates': (_) => const TemplatesPage(),
      },

      // Dynamic Routes
      onGenerateRoute: (settings) {
        // Keep explicit case for verification
        if (settings.name == '/verification') {
          return MaterialPageRoute(
            builder: (_) => const VerificationScreen(),
            settings: settings,
          );
        }

        // Template Editor Route
        if (settings.name == '/template_editor') {
          final args = settings.arguments as Map<String, dynamic>?;

          final templateName = args?['templateName'] as String? ?? 'Template';
          final imagePath =
              args?['imagePath'] as String? ?? 'assets/images/minimal.png';

          return MaterialPageRoute(
            builder: (_) => TemplateEditorPage(
              templateName: templateName,
              imagePath: imagePath,
            ),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
