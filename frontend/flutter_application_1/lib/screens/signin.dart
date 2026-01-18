import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/screens/user/home/home_customer.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/provider/home_provider.dart' hide kPrimaryColor;
import 'package:flutter_application_1/services/fcm_service.dart';
import 'package:flutter_application_1/screens/forgot_password/forgot_password_request.dart';
import 'package:flutter_application_1/screens/admin/admin_main_screen.dart';
import 'package:flutter_application_1/widgets/auth/auth_responsive_wrapper.dart';

/// ✅ Responsive Sign In Screen for Mobile & Web
class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    print('🔗 Testing connection to server...');
    await AuthService.testConnection();
  }

  // ✅ NEW: دالة حقيقية لجلب رمز FCM Token
Future<String?> _getFCMToken() async {
  try {
    final token = await FCMService.getToken();
    if (token != null) {
      print('🚀 Retrieved FCM Token for sign-in: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ FCM Token is null');
    }
    return token;
  } catch (e) {
    print('❌ Error retrieving FCM Token: $e');
    return null;
  }
}

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        // ✅ Get FCM Token
        final fcmToken = await _getFCMToken();
        
        if (fcmToken != null) {
          print('📤 Sending FCM token with login request');
        } else {
          print('⚠️ Proceeding without FCM token');
        }

        // ✅ Send login request with FCM token
        final response = await AuthService.login(
          email, 
          password, 
          fcmToken: fcmToken,
        );

       if (response.containsKey('token') && response.containsKey('user')) {
          print('✅ Login successful with FCM token saved');
          
          final userData = response['user'];
          final userName = userData['userName'] ?? 'Guest';
          final userRole = userData['role'] ?? 'user';

          // ⚠️  الدالة المساعدة الجديدة لإصلاح خطأ toDouble
          int _getStatCount(dynamic data, String key) {
            final value = data[key];
            if (value == null) return 0; // إذا كانت القيمة فارغة
            if (value is num) return value.toInt(); // إذا كانت رقم (int أو double)
            
            // إذا كانت القيمة هي Map (وهذا سبب خطأك الحالي)
            if (value is Map) {
              // نفترض أن القيمة المطلوبة موجودة داخل مفتاح 'count' أو 'total'
              // يجب عليك التأكد من اسم المفتاح الصحيح في الـ JSON الخاص بك
              final nestedValue = value['count'] ?? value['total'] ?? 0;
              if (nestedValue is num) return nestedValue.toInt();
              return 0;
            }
            return 0; // للحالات غير المتوقعة
          }
          // ⚠️  نهاية الدالة المساعدة

          if (userRole == 'vendor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomeProviderScreen(
                  provider: ProviderModel(
                    brandName: userName,
                    email: email,
                    phone: userData['phone'] ?? '',
                    description: userData['description'] ??
                        'Professional service provider',
                    city: userData['city'] ?? '',
                    // ⬇️ تم استخدام الدالة المساعدة الجديدة هنا لحل المشكلة ⬇️
                    bookings: _getStatCount(userData, 'bookings'),
                    views: _getStatCount(userData, 'views'),
                    messages: _getStatCount(userData, 'messages'),
                    reviews: _getStatCount(userData, 'reviews'),
                  ),
                ),
              ),
            );
          } else if (userRole == 'admin') {
            // ✅ Navigate to Admin Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AdminMainScreen(adminName: userName),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(userName: userName),
              ),
            );
          }
        } else {
          _showErrorDialog('Login failed. Please try again.');
        }
      } catch (e) {
        String errorMessage = 'An error occurred. Please try again.';

        if (e.toString().contains('Invalid Email/Pass')) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (e.toString().contains('verify your email')) {
          errorMessage = 'Please verify your email before logging in.';
        } else if (e.toString().contains('Network error')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _showErrorDialog(errorMessage);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Failed',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(215, 20, 20, 215),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveWrapper(
      pageType: AuthPageType.signIn,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title
            Text(
              'Welcome Back!',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Sign in to access your account',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 40),

            // Email Field
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Password Field
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Remember Me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        activeColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordRequestScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sign In Button
            AuthButton(
              text: 'Sign In',
              onPressed: _signIn,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 24),

            // Sign Up Link
            AuthLinkText(
              prefix: "Don't have an account? ",
              linkText: 'Sign Up',
              onTap: () => Navigator.pushReplacementNamed(context, '/choose_role'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
