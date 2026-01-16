import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:app_links/app_links.dart'; // ✅ استيراد app_links

// Services
import 'package:flutter_application_1/services/fcm_service.dart';
import 'package:flutter_application_1/services/service_locator.dart';

// Screens
import 'package:flutter_application_1/screens/splash.dart';
import 'package:flutter_application_1/screens/onboarding.dart';
import 'package:flutter_application_1/screens/signup_provider.dart';
import 'package:flutter_application_1/screens/signup_customer.dart';
import 'package:flutter_application_1/screens/signin.dart';
import 'package:flutter_application_1/screens/verification.dart';
import 'package:flutter_application_1/screens/user/home/home_customer.dart';
import 'package:flutter_application_1/screens/user/vendors/vendors.dart';
import 'package:flutter_application_1/screens/templates.dart';
import 'package:flutter_application_1/screens/template_editor.dart';
import 'package:flutter_application_1/screens/choose_role.dart';
import 'package:flutter_application_1/screens/provider/home_provider.dart';
import 'package:flutter_application_1/screens/forgot_password/forgot_password_request.dart';
import 'package:flutter_application_1/screens/forgot_password/reset_password.dart';
import 'package:flutter_application_1/screens/Ai_Screen/ai_screen_layout.dart';

// ✅ Review System Screens
import 'package:flutter_application_1/screens/review_screen/my_bookings_screen.dart';
import 'package:flutter_application_1/screens/review_screen/pending_reviews_screen.dart';
import 'package:flutter_application_1/screens/review_screen/my_reviews_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM Service
  await FCMService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  // ✅ متغيرات لتحديد الصفحة الأولى
  String? _initialRoute;
  Map<String, dynamic>? _initialRouteArgs;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    _checkInitialUrlSync(); // ✅ فحص الـ URL فوراً قبل أي شيء
    _initDeepLinks();
  }
  
  /// ✅ فحص الـ URL فوراً عند بدء التشغيل (متزامن)
  void _checkInitialUrlSync() {
    if (kIsWeb) {
      try {
        final currentUrl = Uri.base.toString();
        print('🌐 Initial URL check: $currentUrl');
        
        if (currentUrl.contains('reset-password')) {
          final uri = Uri.parse(currentUrl);
          final fragment = uri.fragment;
          
          if (fragment.isNotEmpty && fragment.contains('reset-password')) {
            String? token;
            String? email;
            
            if (fragment.contains('?')) {
              final queryPart = fragment.split('?').last;
              final fragmentParams = Uri.splitQueryString(queryPart);
              token = fragmentParams['token'];
              email = fragmentParams['email'];
            }
            
            if (token != null && email != null) {
              print('✅ Reset password detected - Token: ${token.substring(0, 10)}..., Email: $email');
              _initialRoute = '/reset-password';
              _initialRouteArgs = {'token': token, 'email': email};
            }
          }
        }
      } catch (e) {
        print('❌ Error in initial URL check: $e');
      }
    }
    _initialCheckDone = true;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// ✅ معالجة Deep Links للويب والموبايل
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // ✅ للويب: الاستماع مباشرة للروابط
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('❌ Link error: $err');
      },
    );

    // ✅ للويب: تحقق من الرابط الحالي عند التشغيل
    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _checkCurrentUrl();
      });
    }
  }

  /// ✅ فحص الـ URL الحالي (للويب فقط)
  void _checkCurrentUrl() {
    try {
      // استخدام window.location.href مباشرة
      final currentUrl = Uri.base.toString();
      print('🌐 Current URL on startup: $currentUrl');

      // تحقق من وجود reset-password في الرابط
      if (currentUrl.contains('reset-password')) {
        print('✅ Reset password link detected in URL');
        
        // ✅ استخراج الـ fragment من الرابط (بعد #)
        final uri = Uri.parse(currentUrl);
        final fragment = uri.fragment; // مثال: /reset-password?token=...&email=...
        
        if (fragment.isNotEmpty && fragment.contains('reset-password')) {
          String? token;
          String? email;
          
          // استخراج الـ query parameters من الـ fragment
          if (fragment.contains('?')) {
            final queryPart = fragment.split('?').last;
            final fragmentParams = Uri.splitQueryString(queryPart);
            token = fragmentParams['token'];
            email = fragmentParams['email'];
          }
          
          print('🔑 Token from URL: ${token?.substring(0, 10) ?? 'null'}...');
          print('📧 Email from URL: $email');
          
          if (token != null && email != null) {
            // ✅ الانتقال مباشرة لصفحة إعادة تعيين كلمة المرور
            Future.delayed(const Duration(milliseconds: 100), () {
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/reset-password',
                (route) => false,
                arguments: {'token': token, 'email': email},
              );
            });
            return; // ✅ خروج مبكر لمنع أي معالجة إضافية
          }
        }
      }
    } catch (e) {
      print('❌ Error checking current URL: $e');
    }
  }

  /// ✅ معالجة الرابط والانتقال للصفحة المناسبة
  void _handleDeepLink(Uri uri) {
    print('📍 Processing deep link: ${uri.toString()}');
    print('📍 Path: ${uri.path}');
    print('📍 Fragment: ${uri.fragment}');
    print('📍 Query params: ${uri.queryParameters}');

    // التحقق من رابط إعادة تعيين كلمة المرور
    String path = uri.path;
    String fragment = uri.fragment;

    // للويب: الرابط قد يكون في fragment (/#/reset-password)
    if (kIsWeb && fragment.isNotEmpty) {
      path = fragment.split('?')[0]; // استخراج المسار من fragment
    }

    if (path.contains('reset-password')) {
      String? token;
      String? email;

      // استخراج المعاملات من query parameters أو fragment
      if (uri.queryParameters.isNotEmpty) {
        token = uri.queryParameters['token'];
        email = uri.queryParameters['email'];
      } else if (kIsWeb && fragment.contains('?')) {
        // للويب: استخراج المعاملات من fragment
        final queryPart = fragment.split('?').last;
        final fragmentParams = Uri.splitQueryString(queryPart);
        token = fragmentParams['token'];
        email = fragmentParams['email'];
      }

      if (token != null) {
        print('🔑 Token: ${token.substring(0, 10)}...');
      }
      print('📧 Email: $email');

      if (token != null && email != null) {
        // ✅ الانتقال لصفحة إعادة تعيين كلمة المرور باستخدام pushNamedAndRemoveUntil
        Future.delayed(const Duration(milliseconds: 100), () {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/reset-password',
            (route) => false,
            arguments: {'token': token, 'email': email},
          );
        });
      } else {
        print('⚠️ Token or email is missing');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تحديد الصفحة الأولى بناءً على الـ URL
    Widget homeWidget;
    if (_initialRoute == '/reset-password' && _initialRouteArgs != null) {
      homeWidget = ResetPasswordScreen(
        token: _initialRouteArgs!['token'],
        email: _initialRouteArgs!['email'],
      );
    } else {
      homeWidget = const SplashScreen();
    }
    
    return MaterialApp(
      title: 'PlanMyWedding',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // ✅ مهم جداً
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
      home: homeWidget, // ✅ استخدام الصفحة المحددة بناءً على الـ URL
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/choose_role': (_) => const ChooseRoleScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/signin': (_) => const SignInScreen(),
        '/verification': (_) => const VerificationScreen(),
        '/home': (_) => const HomePage(),
        '/vendors': (_) => const VendorsListPage(),
        '/templates': (_) => const TemplatesPage(),
        '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
        '/ai-generator': (context) => const AiScreenLayout(),

        // ✅ Review System Routes
        '/my-bookings': (_) => const MyBookingsScreen(),
        '/pending-reviews': (_) => const PendingReviewsScreen(),
        '/my-reviews': (_) => const MyReviewsScreen(),
      },
      onGenerateRoute: (settings) {
        print('📍 Route requested: ${settings.name}');
        print('📍 Arguments: ${settings.arguments}');

        if (settings.name == '/verification') {
          return MaterialPageRoute(
            builder: (_) => const VerificationScreen(),
            settings: settings,
          );
        }

        // ✅ ✅ ✅ التصحيح هنا: استخدام startsWith واستخراج البيانات من الرابط مباشرة
        if (settings.name != null &&
            settings.name!.startsWith('/reset-password')) {
          // محاولة جلب البيانات من Arguments (إذا تم الانتقال داخلياً)
          final args = settings.arguments as Map<String, dynamic>?;
          String? token = args?['token'];
          String? email = args?['email'];

          // إذا لم تكن في Arguments، نحاول جلبها من الرابط نفسه (عند الفتح من الإيميل)
          if (token == null || email == null) {
            try {
              final uri = Uri.parse(settings.name!);
              token = uri.queryParameters['token'];
              email = uri.queryParameters['email'];
            } catch (e) {
              print("Error parsing URI in onGenerateRoute: $e");
            }
          }

          print('🔑 Token final: $token');
          print('📧 Email final: $email');

          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: token,
              email: email,
            ),
            settings: settings,
          );
        }
        // ✅ نهاية التعديل

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

        if (settings.name == '/home_provider') {
          final args = settings.arguments;
          if (args != null && args is ProviderModel) {
            return MaterialPageRoute(
              builder: (_) => HomeProviderScreen(provider: args),
              settings: settings,
            );
          } else {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Provider data is required to access this page'),
                ),
              ),
            );
          }
        }

        return null;
      },
    );
  }
}