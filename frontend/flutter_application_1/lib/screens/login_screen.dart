// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _hidePwd = true;

  // Brand color
  static const Color kBrand = Color(0xFFB14E56);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged in')));
      Navigator.pop(context); // TODO: navigate to home
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC55B63), Color(0xFFB14E56)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top-right flower
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  'assets/flowers/top_right.png',
                  width: 160,
                  fit: BoxFit.contain,
                ),
              ),

              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          height: 40,
                        ), // keep text away from flower
                        Text(
                          'PlanMyWedding',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cookie(
                            fontSize: 53,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log In',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please enter your credentials',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      final email = v?.trim() ?? '';
                                      final ok = RegExp(
                                        r'^[\w\.\-]+@[\w\.\-]+\.\w+$',
                                      ).hasMatch(email);
                                      return ok ? null : 'Enter a valid email';
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Password
                                  TextFormField(
                                    controller: _pwdCtrl,
                                    obscureText: _hidePwd,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _hidePwd = !_hidePwd,
                                        ),
                                        icon: Icon(
                                          _hidePwd
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 8)
                                        ? 'Min 8 characters'
                                        : null,
                                  ),

                                  const SizedBox(height: 5),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: forgot password flow
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kBrand,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Primary button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kBrand,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Log In',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Footer: go to Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
