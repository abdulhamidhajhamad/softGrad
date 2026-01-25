import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class CustomerAuthService {
  static String getBaseUrl() {
    return 'https://softgrad.onrender.com';
  }

  static final String baseUrl = getBaseUrl();

  static Future<Map<String, dynamic>> signup({
    required String userName,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'email': email,
          'password': password,
          'phone': phone,
          'city': city,
          'role': 'user',
        }),
      );

      print('👤 Customer Signup Status: ${response.statusCode}');
      print('👤 Customer Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Customer signup failed');
      }
    } catch (e) {
      print('❌ Customer Signup Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl'));
      print('✅ Customer Server connection test: ${response.statusCode}');
    } catch (e) {
      print('❌ Customer Server connection failed: $e');
    }
  }
}
