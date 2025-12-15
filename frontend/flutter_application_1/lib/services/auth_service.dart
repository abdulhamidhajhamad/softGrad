// auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AuthService {
  static String getBaseUrl() {
    if (kIsWeb) {
      // Web (Chrome)
      return 'http://localhost:3000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator
      return 'http://10.0.2.2:3000';
    } else {
      // iOS / Desktop / غيره
      return 'http://localhost:3000';
    }
  }

  static final String baseUrl = getBaseUrl();

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token saved successfully.');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userString = prefs.getString('user_data');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('🔑 Retrieved token: ${token != null ? 'Found' : 'Not Found'}');
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🗑️ Token deleted successfully.');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }

  // 🆕 دالة لاستخراج دور المستخدم من التوكن
  static Future<String?> getUserRole() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      final payload = parts[1];
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final payloadData = utf8.decode(base64Decode(normalized));
      final decodedPayload = jsonDecode(payloadData);

      return decodedPayload['role'] ?? decodedPayload['userRole'] as String?;
    } catch (e) {
      print('❌ Error decoding token payload: $e');
      return null;
    }
  }

  // ====================== AUTHENTICATION METHODS =========================

  // 🆕 1. دالة اختبار الاتصال
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        print('✅ Backend connection successful.');
        return true;
      } else {
        print(
            '❌ Backend connection failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error during connection test: $e');
      return false;
    }
  }

  // 🔄 2. دالة تسجيل حساب مستخدم جديد (signup) - بدون كلمة مرور وبدون حقول المزود
  static Future<Map<String, dynamic>> signup({
    required String userName,
    required String email,
    String? password, // أصبح اختيارياً
    String? phone,
    String? city,
    required String role,
  }) async {
    try {
      // 🔑 إعداد الجسم لإرسال البيانات
      final Map<String, dynamic> body = {
        'userName': userName,
        'email': email,
        'phone': phone,
        'city': city,
        'role': role,
      };

      // 🔑 إضافة كلمة المرور فقط إذا كانت موجودة
      if (password != null) {
        body['password'] = password;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body), // استخدام الـ body المُجهز
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = responseBody['token'];
        if (token != null) {
          await saveToken(token);
        }
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'فشل في عملية التسجيل.');
      }
    } catch (e) {
      print('❌ Error in signup: $e');
      rethrow;
    }
  }

  // 🆕 3. دالة تسجيل الدخول (login)
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseBody['token'];
        if (token != null) {
          await saveToken(token);
        }
        return responseBody;
      } else {
        throw Exception(
            responseBody['message'] ?? 'فشل في عملية تسجيل الدخول.');
      }
    } catch (e) {
      print('❌ Error in login: $e');
      rethrow;
    }
  }

  // 🆕 4. دالة جلب ملف المستخدم (getUserProfile)
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('رمز المصادقة غير موجود. الرجاء تسجيل الدخول أولاً.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'فشل في جلب ملف المستخدم.');
      }
    } catch (e) {
      print('❌ Error in getUserProfile: $e');
      rethrow;
    }
  }

  // ====================== PROVIDER REGISTRATION =========================
  // 🔄 تم التعديل لحذف حقل category
  static Future<Map<String, dynamic>> registerProviderDetails({
    required String companyName,
    required String description,
    required String city,
    required String phone,
    required String email,
    // 🗑️ تم حذف: required String category,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      // The endpoint for provider details registration
      final response = await http.post(
        Uri.parse('$baseUrl/providers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'companyName': companyName,
          'description': description,
          // 🗑️ تم حذف: 'category': category,
          'location': {
            'city': city,
          },
          'details': {
            'phone': phone,
            'email': email,
          }
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ النجاح: فك تشفير الـ JSON وإرجاع البيانات
        return jsonDecode(response.body);
      } else {
        // ❌ فشل: التعامل مع رسالة الخطأ من الـ Backend
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to register provider details.');
      }
    } catch (e) {
      print('❌ Error in registerProviderDetails: $e');
      rethrow;
    }
  }
}
